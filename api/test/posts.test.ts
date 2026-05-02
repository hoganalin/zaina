import { afterAll, beforeEach, describe, expect, it, vi } from 'vitest';

const { verifyIdTokenMock } = vi.hoisted(() => ({
  verifyIdTokenMock: vi.fn(),
}));

vi.mock('firebase-admin/auth', () => ({
  getAuth: () => ({ verifyIdToken: verifyIdTokenMock }),
}));

const { app } = await import('../src/app.js');
const { prisma } = await import('../src/db.js');

const TEST_UID = 'firebase-uid-posts-test';

async function authedUser() {
  return prisma.user.create({
    data: {
      firebaseUid: TEST_UID,
      nickname: 'Posts Tester',
      city: 'Tokyo',
      country: 'Japan',
      onboardingCompleted: true,
    },
  });
}

describe('/api/posts', () => {
  beforeEach(async () => {
    verifyIdTokenMock.mockReset();
    await prisma.user.deleteMany({ where: { firebaseUid: TEST_UID } });
  });

  afterAll(async () => {
    await prisma.user.deleteMany({ where: { firebaseUid: TEST_UID } });
    await prisma.$disconnect();
  });

  describe('POST /api/posts', () => {
    it('creates a post and returns it with channel + author + likedByMe=false', async () => {
      await authedUser();
      const channel = await prisma.channel.findFirst();
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request('/api/posts', {
        method: 'POST',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          channelId: channel!.id,
          title: '東京哪邊有好吃豆花',
          body: '想找台灣味的，最好是傳統那種糖水',
          city: 'Tokyo',
          country: 'Japan',
        }),
      });

      expect(res.status).toBe(201);
      const body = (await res.json()) as { post: Record<string, unknown> };
      expect(body.post).toMatchObject({
        title: '東京哪邊有好吃豆花',
        city: 'Tokyo',
        likedByMe: false,
        likeCount: 0,
        commentCount: 0,
      });
      expect((body.post.channel as Record<string, unknown>).id).toBe(channel!.id);
    });

    it('returns 400 when title is missing', async () => {
      await authedUser();
      const channel = await prisma.channel.findFirst();
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request('/api/posts', {
        method: 'POST',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          channelId: channel!.id,
          body: 'no title',
          city: 'Tokyo',
          country: 'Japan',
        }),
      });
      expect(res.status).toBe(400);
    });

    it('returns 400 when channelId is unknown', async () => {
      await authedUser();
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request('/api/posts', {
        method: 'POST',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          channelId: '00000000-0000-0000-0000-000000000000',
          title: 'X',
          body: 'X',
          city: 'Tokyo',
          country: 'Japan',
        }),
      });
      expect(res.status).toBe(400);
    });
  });

  describe('GET /api/posts/:id', () => {
    it('returns 404 for unknown id', async () => {
      await authedUser();
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request(
        '/api/posts/00000000-0000-0000-0000-000000000000',
        { headers: { Authorization: 'Bearer t' } },
      );
      expect(res.status).toBe(404);
    });

    it('returns the post with likedByMe reflecting current user state', async () => {
      const user = await authedUser();
      const channel = await prisma.channel.findFirst();
      const post = await prisma.post.create({
        data: {
          authorId: user.id,
          channelId: channel!.id,
          title: 'detail-test',
          body: 'b',
          city: 'Tokyo',
          country: 'Japan',
        },
      });

      verifyIdTokenMock.mockResolvedValue({ uid: TEST_UID });

      const beforeLike = await app.request(`/api/posts/${post.id}`, {
        headers: { Authorization: 'Bearer t' },
      });
      const beforeBody = (await beforeLike.json()) as {
        post: { likedByMe: boolean };
      };
      expect(beforeBody.post.likedByMe).toBe(false);

      await prisma.postLike.create({ data: { userId: user.id, postId: post.id } });

      const afterLike = await app.request(`/api/posts/${post.id}`, {
        headers: { Authorization: 'Bearer t' },
      });
      const afterBody = (await afterLike.json()) as {
        post: { likedByMe: boolean };
      };
      expect(afterBody.post.likedByMe).toBe(true);
    });
  });

  describe('like / unlike', () => {
    async function setupPost() {
      const user = await authedUser();
      const channel = await prisma.channel.findFirst();
      const post = await prisma.post.create({
        data: {
          authorId: user.id,
          channelId: channel!.id,
          title: 'like-test',
          body: 'b',
          city: 'Tokyo',
          country: 'Japan',
        },
      });
      return { user, post };
    }

    it('POST /like increments likeCount and is idempotent', async () => {
      const { post } = await setupPost();
      verifyIdTokenMock.mockResolvedValue({ uid: TEST_UID });

      const first = await app.request(`/api/posts/${post.id}/like`, {
        method: 'POST',
        headers: { Authorization: 'Bearer t' },
      });
      expect(first.status).toBe(200);
      expect((await first.json()) as Record<string, unknown>).toMatchObject({
        likeCount: 1,
        likedByMe: true,
      });

      const second = await app.request(`/api/posts/${post.id}/like`, {
        method: 'POST',
        headers: { Authorization: 'Bearer t' },
      });
      expect((await second.json()) as Record<string, unknown>).toMatchObject({
        likeCount: 1,
        likedByMe: true,
      });

      const reload = await prisma.post.findUnique({ where: { id: post.id } });
      expect(reload?.likeCount).toBe(1);
    });

    it('DELETE /like decrements likeCount and is idempotent', async () => {
      const { post } = await setupPost();
      verifyIdTokenMock.mockResolvedValue({ uid: TEST_UID });

      await app.request(`/api/posts/${post.id}/like`, {
        method: 'POST',
        headers: { Authorization: 'Bearer t' },
      });

      const first = await app.request(`/api/posts/${post.id}/like`, {
        method: 'DELETE',
        headers: { Authorization: 'Bearer t' },
      });
      expect((await first.json()) as Record<string, unknown>).toMatchObject({
        likeCount: 0,
        likedByMe: false,
      });

      const second = await app.request(`/api/posts/${post.id}/like`, {
        method: 'DELETE',
        headers: { Authorization: 'Bearer t' },
      });
      expect((await second.json()) as Record<string, unknown>).toMatchObject({
        likeCount: 0,
        likedByMe: false,
      });
    });

    it('POST /like returns 404 for unknown post', async () => {
      await authedUser();
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request(
        '/api/posts/00000000-0000-0000-0000-000000000000/like',
        { method: 'POST', headers: { Authorization: 'Bearer t' } },
      );
      expect(res.status).toBe(404);
    });
  });

  describe('comments', () => {
    async function setupPost() {
      const user = await authedUser();
      const channel = await prisma.channel.findFirst();
      const post = await prisma.post.create({
        data: {
          authorId: user.id,
          channelId: channel!.id,
          title: 'comments-test',
          body: 'b',
          city: 'Tokyo',
          country: 'Japan',
        },
      });
      return { user, post };
    }

    it('POST /comments creates and increments commentCount', async () => {
      const { post } = await setupPost();
      verifyIdTokenMock.mockResolvedValue({ uid: TEST_UID });

      const res = await app.request(`/api/posts/${post.id}/comments`, {
        method: 'POST',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ body: '推一個' }),
      });
      expect(res.status).toBe(201);
      const body = (await res.json()) as {
        comment: { body: string; author: { nickname: string } };
      };
      expect(body.comment.body).toBe('推一個');
      expect(body.comment.author.nickname).toBe('Posts Tester');

      const reload = await prisma.post.findUnique({ where: { id: post.id } });
      expect(reload?.commentCount).toBe(1);
    });

    it('GET /comments returns comments asc by createdAt', async () => {
      const { user, post } = await setupPost();
      await prisma.comment.create({
        data: { postId: post.id, authorId: user.id, body: 'first' },
      });
      await new Promise((r) => setTimeout(r, 5));
      await prisma.comment.create({
        data: { postId: post.id, authorId: user.id, body: 'second' },
      });
      verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

      const res = await app.request(`/api/posts/${post.id}/comments`, {
        headers: { Authorization: 'Bearer t' },
      });
      const body = (await res.json()) as {
        comments: Array<{ body: string }>;
      };
      expect(body.comments.map((c) => c.body)).toEqual(['first', 'second']);
    });
  });
});
