import { afterAll, beforeEach, describe, expect, it, vi } from 'vitest';

const { verifyIdTokenMock } = vi.hoisted(() => ({
  verifyIdTokenMock: vi.fn(),
}));

vi.mock('firebase-admin/auth', () => ({
  getAuth: () => ({ verifyIdToken: verifyIdTokenMock }),
}));

const { app } = await import('../src/app.js');
const { prisma } = await import('../src/db.js');

const TEST_UID = 'firebase-uid-users-test';
const OTHER_UID = 'firebase-uid-users-other';

describe('/api/users/:id', () => {
  beforeEach(async () => {
    verifyIdTokenMock.mockReset();
    await prisma.user.deleteMany({
      where: { firebaseUid: { in: [TEST_UID, OTHER_UID] } },
    });
  });

  afterAll(async () => {
    await prisma.user.deleteMany({
      where: { firebaseUid: { in: [TEST_UID, OTHER_UID] } },
    });
    await prisma.$disconnect();
  });

  it('returns 404 for unknown user id', async () => {
    await prisma.user.create({
      data: { firebaseUid: TEST_UID, nickname: 'Me' },
    });
    verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

    const res = await app.request(
      '/api/users/00000000-0000-0000-0000-000000000000',
      { headers: { Authorization: 'Bearer t' } },
    );
    expect(res.status).toBe(404);
  });

  it('returns the public profile (no firebaseUid) plus postCount', async () => {
    const me = await prisma.user.create({
      data: { firebaseUid: TEST_UID, nickname: 'Me' },
    });
    const other = await prisma.user.create({
      data: {
        firebaseUid: OTHER_UID,
        nickname: 'Other',
        bio: 'hi',
        city: 'Paris',
        country: 'France',
      },
    });
    const channel = await prisma.channel.findFirst();
    await prisma.post.create({
      data: {
        authorId: other.id,
        channelId: channel!.id,
        title: 't',
        body: 'b',
        city: 'Paris',
        country: 'France',
      },
    });
    verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

    const res = await app.request(`/api/users/${other.id}`, {
      headers: { Authorization: 'Bearer t' },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { user: Record<string, unknown> };
    expect(body.user).toMatchObject({
      nickname: 'Other',
      bio: 'hi',
      city: 'Paris',
      postCount: 1,
    });
    expect(body.user.firebaseUid).toBeUndefined();
    expect(me.id).not.toBe(other.id);
  });

  it('returns paginated posts authored by the user with likedByMe', async () => {
    const me = await prisma.user.create({
      data: { firebaseUid: TEST_UID, nickname: 'Me' },
    });
    const other = await prisma.user.create({
      data: { firebaseUid: OTHER_UID, nickname: 'Other' },
    });
    const channel = await prisma.channel.findFirst();
    const posts = await Promise.all(
      [1, 2, 3].map((n) =>
        prisma.post.create({
          data: {
            authorId: other.id,
            channelId: channel!.id,
            title: `Post ${n}`,
            body: 'b',
            city: 'Paris',
            country: 'France',
          },
        }),
      ),
    );
    await prisma.postLike.create({
      data: { userId: me.id, postId: posts[0].id },
    });
    verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

    const res = await app.request(`/api/users/${other.id}/posts`, {
      headers: { Authorization: 'Bearer t' },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      posts: Array<{ id: string; likedByMe: boolean }>;
    };
    expect(body.posts).toHaveLength(3);
    const liked = body.posts.find((p) => p.id === posts[0].id);
    expect(liked!.likedByMe).toBe(true);
  });
});
