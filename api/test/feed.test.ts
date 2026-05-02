import { afterAll, beforeEach, describe, expect, it, vi } from 'vitest';

const { verifyIdTokenMock } = vi.hoisted(() => ({
  verifyIdTokenMock: vi.fn(),
}));

vi.mock('firebase-admin/auth', () => ({
  getAuth: () => ({ verifyIdToken: verifyIdTokenMock }),
}));

const { app } = await import('../src/app.js');
const { prisma } = await import('../src/db.js');

const TEST_UID = 'firebase-uid-feed-test';

async function authedUserWith({ city }: { city?: string } = {}) {
  return prisma.user.create({
    data: {
      firebaseUid: TEST_UID,
      nickname: 'Feed Tester',
      city,
      onboardingCompleted: true,
    },
  });
}

type FeedResponse = {
  posts: Array<{
    id: string;
    title: string;
    createdAt: string;
    city: string;
    channel: { id: string; slug: string };
    author: { id: string; nickname: string };
  }>;
  nextOffset: number | null;
};

describe('GET /api/feed', () => {
  beforeEach(async () => {
    verifyIdTokenMock.mockReset();
    await prisma.user.deleteMany({ where: { firebaseUid: TEST_UID } });
  });

  afterAll(async () => {
    await prisma.user.deleteMany({ where: { firebaseUid: TEST_UID } });
    await prisma.$disconnect();
  });

  describe('/following', () => {
    it('returns 401 without Authorization header', async () => {
      const res = await app.request('/api/feed/following');
      expect(res.status).toBe(401);
    });

    it('returns empty when the user follows no channels', async () => {
      await authedUserWith();
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request('/api/feed/following', {
        headers: { Authorization: 'Bearer t' },
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as FeedResponse;
      expect(body.posts).toEqual([]);
      expect(body.nextOffset).toBeNull();
    });

    it('returns posts only from followed channels, ordered desc', async () => {
      const user = await authedUserWith();
      const channels = await prisma.channel.findMany({ take: 2 });
      await prisma.channelFollow.create({
        data: { userId: user.id, channelId: channels[0].id },
      });
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request('/api/feed/following', {
        headers: { Authorization: 'Bearer t' },
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as FeedResponse;
      expect(body.posts.length).toBeGreaterThan(0);
      for (const p of body.posts) {
        expect(p.channel.id).toBe(channels[0].id);
        expect(typeof p.author.nickname).toBe('string');
      }
      const timestamps = body.posts.map((p) => new Date(p.createdAt).getTime());
      const sorted = [...timestamps].sort((a, b) => b - a);
      expect(timestamps).toEqual(sorted);
    });

    it('respects pagination', async () => {
      const user = await authedUserWith();
      const channels = await prisma.channel.findMany();
      await prisma.channelFollow.createMany({
        data: channels.map((ch) => ({ userId: user.id, channelId: ch.id })),
      });
      verifyIdTokenMock.mockResolvedValue({ uid: TEST_UID });

      const first = await app.request('/api/feed/following?limit=5&offset=0', {
        headers: { Authorization: 'Bearer t' },
      });
      const firstBody = (await first.json()) as FeedResponse;
      expect(firstBody.posts).toHaveLength(5);
      expect(firstBody.nextOffset).toBe(5);

      const second = await app.request('/api/feed/following?limit=5&offset=5', {
        headers: { Authorization: 'Bearer t' },
      });
      const secondBody = (await second.json()) as FeedResponse;
      expect(secondBody.posts).toHaveLength(5);
      const firstIds = new Set(firstBody.posts.map((p) => p.id));
      for (const p of secondBody.posts) {
        expect(firstIds.has(p.id)).toBe(false);
      }
    });
  });

  describe('/city', () => {
    it('returns empty when the authed user has no city', async () => {
      await authedUserWith();
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request('/api/feed/city', {
        headers: { Authorization: 'Bearer t' },
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as FeedResponse;
      expect(body.posts).toEqual([]);
    });

    it('returns posts whose city matches the authed user, ordered desc', async () => {
      await authedUserWith({ city: 'Tokyo' });
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request('/api/feed/city', {
        headers: { Authorization: 'Bearer t' },
      });
      expect(res.status).toBe(200);
      const body = (await res.json()) as FeedResponse;
      expect(body.posts.length).toBeGreaterThan(0);
      for (const p of body.posts) {
        expect(p.city).toBe('Tokyo');
      }
    });
  });
});
