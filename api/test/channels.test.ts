import { afterAll, beforeEach, describe, expect, it, vi } from 'vitest';

const { verifyIdTokenMock } = vi.hoisted(() => ({
  verifyIdTokenMock: vi.fn(),
}));

vi.mock('firebase-admin/auth', () => ({
  getAuth: () => ({ verifyIdToken: verifyIdTokenMock }),
}));

const { app } = await import('../src/app.js');
const { prisma } = await import('../src/db.js');

const TEST_UID = 'firebase-uid-channels-test';

async function authedUser() {
  return prisma.user.create({
    data: { firebaseUid: TEST_UID, nickname: 'Test' },
  });
}

describe('/api/channels', () => {
  beforeEach(async () => {
    verifyIdTokenMock.mockReset();
    await prisma.user.deleteMany({ where: { firebaseUid: TEST_UID } });
  });

  afterAll(async () => {
    await prisma.user.deleteMany({ where: { firebaseUid: TEST_UID } });
    await prisma.$disconnect();
  });

  it('returns 401 when no Authorization header is provided', async () => {
    const res = await app.request('/api/channels');
    expect(res.status).toBe(401);
  });

  it('returns channels with isFollowing reflecting current follows', async () => {
    const user = await authedUser();
    const all = await prisma.channel.findMany();
    await prisma.channelFollow.create({
      data: { userId: user.id, channelId: all[0].id },
    });
    verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

    const res = await app.request('/api/channels', {
      headers: { Authorization: 'Bearer t' },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      channels: Array<{ id: string; sortOrder: number; isFollowing: boolean }>;
    };
    const followed = body.channels.filter((c) => c.isFollowing);
    expect(followed).toHaveLength(1);
    expect(followed[0].id).toBe(all[0].id);
  });

  it('POST /:id/follow is idempotent', async () => {
    const user = await authedUser();
    const channel = await prisma.channel.findFirst();
    verifyIdTokenMock.mockResolvedValue({ uid: TEST_UID });

    const first = await app.request(`/api/channels/${channel!.id}/follow`, {
      method: 'POST',
      headers: { Authorization: 'Bearer t' },
    });
    expect(first.status).toBe(200);
    expect((await first.json()) as Record<string, unknown>).toMatchObject({
      isFollowing: true,
    });

    const second = await app.request(`/api/channels/${channel!.id}/follow`, {
      method: 'POST',
      headers: { Authorization: 'Bearer t' },
    });
    expect(second.status).toBe(200);

    const follows = await prisma.channelFollow.findMany({
      where: { userId: user.id },
    });
    expect(follows).toHaveLength(1);
  });

  it('DELETE /:id/follow is idempotent', async () => {
    const user = await authedUser();
    const channel = await prisma.channel.findFirst();
    await prisma.channelFollow.create({
      data: { userId: user.id, channelId: channel!.id },
    });
    verifyIdTokenMock.mockResolvedValue({ uid: TEST_UID });

    const first = await app.request(`/api/channels/${channel!.id}/follow`, {
      method: 'DELETE',
      headers: { Authorization: 'Bearer t' },
    });
    expect(first.status).toBe(200);
    expect((await first.json()) as Record<string, unknown>).toMatchObject({
      isFollowing: false,
    });

    const second = await app.request(`/api/channels/${channel!.id}/follow`, {
      method: 'DELETE',
      headers: { Authorization: 'Bearer t' },
    });
    expect(second.status).toBe(200);
  });

  it('POST /:id/follow returns 404 for unknown channel', async () => {
    await authedUser();
    verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

    const res = await app.request(
      '/api/channels/00000000-0000-0000-0000-000000000000/follow',
      { method: 'POST', headers: { Authorization: 'Bearer t' } },
    );
    expect(res.status).toBe(404);
  });
});
