import { afterAll, beforeEach, describe, expect, it, vi } from 'vitest';

const { verifyIdTokenMock } = vi.hoisted(() => ({
  verifyIdTokenMock: vi.fn(),
}));

vi.mock('firebase-admin/auth', () => ({
  getAuth: () => ({ verifyIdToken: verifyIdTokenMock }),
}));

const { app } = await import('../src/app.js');
const { prisma } = await import('../src/db.js');

const TEST_UID = 'firebase-uid-me-test';

async function authedUser() {
  return prisma.user.create({
    data: { firebaseUid: TEST_UID, nickname: 'Pre-onboarding' },
  });
}

describe('/api/me', () => {
  beforeEach(async () => {
    verifyIdTokenMock.mockReset();
    await prisma.user.deleteMany({ where: { firebaseUid: TEST_UID } });
  });

  afterAll(async () => {
    await prisma.user.deleteMany({ where: { firebaseUid: TEST_UID } });
    await prisma.$disconnect();
  });

  describe('GET /api/me', () => {
    it('returns 401 without Authorization header', async () => {
      const res = await app.request('/api/me');
      expect(res.status).toBe(401);
    });

    it('returns 401 when User row does not exist for the verified uid', async () => {
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });
      const res = await app.request('/api/me', {
        headers: { Authorization: 'Bearer t' },
      });
      expect(res.status).toBe(401);
    });

    it('returns the self-view for an authed user', async () => {
      await authedUser();
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request('/api/me', {
        headers: { Authorization: 'Bearer t' },
      });

      expect(res.status).toBe(200);
      const body = (await res.json()) as { user: Record<string, unknown> };
      expect(body.user.nickname).toBe('Pre-onboarding');
      expect(body.user.onboardingCompleted).toBe(false);
      expect(body.user.firebaseUid).toBeUndefined();
    });
  });

  describe('PATCH /api/me (profile edit)', () => {
    it('updates only the supplied fields and leaves onboardingCompleted alone', async () => {
      const user = await authedUser();
      await prisma.user.update({
        where: { id: user.id },
        data: { onboardingCompleted: true },
      });
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request('/api/me', {
        method: 'PATCH',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ bio: 'new bio', city: 'Lisbon' }),
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as { user: Record<string, unknown> };
      expect(body.user).toMatchObject({
        bio: 'new bio',
        city: 'Lisbon',
        nickname: 'Pre-onboarding',
        onboardingCompleted: true,
      });
    });

    it('rejects unknown fields (strict zod schema)', async () => {
      await authedUser();
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request('/api/me', {
        method: 'PATCH',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ onboardingCompleted: false }),
      });
      expect(res.status).toBe(400);
    });
  });

  describe('PATCH /api/me/onboarding', () => {
    it('returns 401 without Authorization header', async () => {
      const res = await app.request('/api/me/onboarding', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nickname: 'X' }),
      });
      expect(res.status).toBe(401);
    });

    it('returns 400 when nickname is missing', async () => {
      await authedUser();
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request('/api/me/onboarding', {
        method: 'PATCH',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({}),
      });
      expect(res.status).toBe(400);
    });

    it('updates User and creates UserInterest + ChannelFollow rows in a transaction', async () => {
      const user = await authedUser();
      const interests = await prisma.interest.findMany({ take: 3 });
      const channels = await prisma.channel.findMany({ take: 2 });
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request('/api/me/onboarding', {
        method: 'PATCH',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          nickname: 'Hogan Onboarded',
          gender: 'male',
          country: 'Japan',
          city: 'Tokyo',
          interestIds: interests.map((i) => i.id),
          channelIds: channels.map((ch) => ch.id),
        }),
      });

      expect(res.status).toBe(200);
      const body = (await res.json()) as { user: Record<string, unknown> };
      expect(body.user).toMatchObject({
        nickname: 'Hogan Onboarded',
        gender: 'male',
        country: 'Japan',
        city: 'Tokyo',
        onboardingCompleted: true,
      });

      const userInterests = await prisma.userInterest.findMany({
        where: { userId: user.id },
      });
      expect(userInterests).toHaveLength(3);

      const channelFollows = await prisma.channelFollow.findMany({
        where: { userId: user.id },
      });
      expect(channelFollows).toHaveLength(2);
    });

    it('replaces relations on re-submit (idempotent semantics)', async () => {
      const user = await authedUser();
      const allInterests = await prisma.interest.findMany();
      const allChannels = await prisma.channel.findMany();

      verifyIdTokenMock.mockResolvedValue({ uid: TEST_UID });

      const first = await app.request('/api/me/onboarding', {
        method: 'PATCH',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          nickname: 'A',
          interestIds: allInterests.slice(0, 5).map((i) => i.id),
          channelIds: allChannels.slice(0, 3).map((ch) => ch.id),
        }),
      });
      expect(first.status).toBe(200);

      const second = await app.request('/api/me/onboarding', {
        method: 'PATCH',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          nickname: 'B',
          interestIds: allInterests.slice(5, 7).map((i) => i.id),
          channelIds: allChannels.slice(3, 4).map((ch) => ch.id),
        }),
      });
      expect(second.status).toBe(200);

      const userInterests = await prisma.userInterest.findMany({
        where: { userId: user.id },
      });
      expect(userInterests).toHaveLength(2);

      const channelFollows = await prisma.channelFollow.findMany({
        where: { userId: user.id },
      });
      expect(channelFollows).toHaveLength(1);

      const reloaded = await prisma.user.findUnique({ where: { id: user.id } });
      expect(reloaded?.nickname).toBe('B');
    });

    it('returns 400 for unknown interest id', async () => {
      await authedUser();
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request('/api/me/onboarding', {
        method: 'PATCH',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          nickname: 'X',
          interestIds: ['00000000-0000-0000-0000-000000000000'],
        }),
      });
      expect(res.status).toBe(400);
    });
  });
});
