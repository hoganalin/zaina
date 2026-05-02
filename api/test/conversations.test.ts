import { afterAll, beforeEach, describe, expect, it, vi } from 'vitest';

const { verifyIdTokenMock } = vi.hoisted(() => ({
  verifyIdTokenMock: vi.fn(),
}));

vi.mock('firebase-admin/auth', () => ({
  getAuth: () => ({ verifyIdToken: verifyIdTokenMock }),
}));

const { app } = await import('../src/app.js');
const { prisma } = await import('../src/db.js');

const A_UID = 'firebase-uid-conv-a';
const B_UID = 'firebase-uid-conv-b';

async function cleanup() {
  await prisma.user.deleteMany({
    where: { firebaseUid: { in: [A_UID, B_UID] } },
  });
}

async function createPair() {
  const a = await prisma.user.create({
    data: { firebaseUid: A_UID, nickname: 'A', onboardingCompleted: true },
  });
  const b = await prisma.user.create({
    data: { firebaseUid: B_UID, nickname: 'B', onboardingCompleted: true },
  });
  return { a, b };
}

async function makeAEligibleByCommentingOnBPost(aId: string, bId: string) {
  const channel = await prisma.channel.findFirst();
  const post = await prisma.post.create({
    data: {
      authorId: bId,
      channelId: channel!.id,
      title: 'B post',
      body: 'b',
      city: 'Tokyo',
      country: 'Japan',
    },
  });
  await prisma.comment.create({
    data: { postId: post.id, authorId: aId, body: 'A comment' },
  });
}

describe('/api/conversations', () => {
  beforeEach(async () => {
    verifyIdTokenMock.mockReset();
    await cleanup();
  });

  afterAll(async () => {
    await cleanup();
    await prisma.$disconnect();
  });

  describe('POST /api/conversations', () => {
    it('returns 400 when the target is self', async () => {
      const { a } = await createPair();
      verifyIdTokenMock.mockResolvedValueOnce({ uid: A_UID });

      const res = await app.request('/api/conversations', {
        method: 'POST',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: a.id }),
      });
      expect(res.status).toBe(400);
    });

    it('returns 403 when not eligible to DM', async () => {
      const { b } = await createPair();
      verifyIdTokenMock.mockResolvedValueOnce({ uid: A_UID });

      const res = await app.request('/api/conversations', {
        method: 'POST',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: b.id }),
      });
      expect(res.status).toBe(403);
    });

    it('creates a message_request conversation when A is eligible', async () => {
      const { a, b } = await createPair();
      await makeAEligibleByCommentingOnBPost(a.id, b.id);
      verifyIdTokenMock.mockResolvedValueOnce({ uid: A_UID });

      const res = await app.request('/api/conversations', {
        method: 'POST',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: b.id }),
      });
      expect(res.status).toBe(201);
      const body = (await res.json()) as {
        conversation: { id: string; status: string };
      };
      expect(body.conversation.status).toBe('message_request');
    });

    it('returns existing conversation on repeat (idempotent)', async () => {
      const { a, b } = await createPair();
      await makeAEligibleByCommentingOnBPost(a.id, b.id);
      verifyIdTokenMock.mockResolvedValue({ uid: A_UID });

      const first = await app.request('/api/conversations', {
        method: 'POST',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: b.id }),
      });
      const firstBody = (await first.json()) as {
        conversation: { id: string };
      };

      const second = await app.request('/api/conversations', {
        method: 'POST',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: b.id }),
      });
      const secondBody = (await second.json()) as {
        conversation: { id: string };
      };
      expect(firstBody.conversation.id).toBe(secondBody.conversation.id);
    });
  });

  describe('messages', () => {
    async function setup() {
      const { a, b } = await createPair();
      await makeAEligibleByCommentingOnBPost(a.id, b.id);
      verifyIdTokenMock.mockResolvedValueOnce({ uid: A_UID });
      const create = await app.request('/api/conversations', {
        method: 'POST',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: b.id }),
      });
      const conv = (await create.json()) as {
        conversation: { id: string; status: string };
      };
      return { a, b, conversationId: conv.conversation.id };
    }

    it('forbids sending from a user that is not a participant', async () => {
      const { conversationId } = await setup();
      // Make a third user (not in the conversation)
      const stranger = await prisma.user.create({
        data: {
          firebaseUid: 'firebase-uid-conv-stranger',
          nickname: 'C',
          onboardingCompleted: true,
        },
      });
      verifyIdTokenMock.mockResolvedValueOnce({ uid: 'firebase-uid-conv-stranger' });

      const res = await app.request(
        `/api/conversations/${conversationId}/messages`,
        {
          method: 'POST',
          headers: {
            Authorization: 'Bearer t',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ body: 'hi' }),
        },
      );
      expect(res.status).toBe(403);

      await prisma.user.delete({ where: { id: stranger.id } });
    });

    it("flips message_request → active on B's first reply", async () => {
      const { conversationId } = await setup();

      // A sends first message — convo stays message_request
      verifyIdTokenMock.mockResolvedValueOnce({ uid: A_UID });
      const aSend = await app.request(
        `/api/conversations/${conversationId}/messages`,
        {
          method: 'POST',
          headers: {
            Authorization: 'Bearer t',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ body: '哈囉' }),
        },
      );
      expect(aSend.status).toBe(201);
      const afterA = await prisma.conversation.findUnique({
        where: { id: conversationId },
      });
      expect(afterA?.status).toBe('message_request');

      // B replies — convo flips to active
      verifyIdTokenMock.mockResolvedValueOnce({ uid: B_UID });
      const bSend = await app.request(
        `/api/conversations/${conversationId}/messages`,
        {
          method: 'POST',
          headers: {
            Authorization: 'Bearer t',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ body: '嗨' }),
        },
      );
      expect(bSend.status).toBe(201);
      const afterB = await prisma.conversation.findUnique({
        where: { id: conversationId },
      });
      expect(afterB?.status).toBe('active');
    });

    it('GET /messages returns conversation messages asc by createdAt', async () => {
      const { conversationId } = await setup();
      verifyIdTokenMock.mockResolvedValue({ uid: A_UID });
      await app.request(`/api/conversations/${conversationId}/messages`, {
        method: 'POST',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ body: 'one' }),
      });
      await new Promise((r) => setTimeout(r, 5));
      await app.request(`/api/conversations/${conversationId}/messages`, {
        method: 'POST',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ body: 'two' }),
      });

      const res = await app.request(
        `/api/conversations/${conversationId}/messages`,
        { headers: { Authorization: 'Bearer t' } },
      );
      const body = (await res.json()) as {
        messages: Array<{ body: string }>;
      };
      expect(body.messages.map((m) => m.body)).toEqual(['one', 'two']);
    });
  });

  describe('GET /api/conversations', () => {
    it("lists only the requester's conversations", async () => {
      const { a, b } = await createPair();
      await makeAEligibleByCommentingOnBPost(a.id, b.id);
      verifyIdTokenMock.mockResolvedValue({ uid: A_UID });
      await app.request('/api/conversations', {
        method: 'POST',
        headers: {
          Authorization: 'Bearer t',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: b.id }),
      });

      const list = await app.request('/api/conversations', {
        headers: { Authorization: 'Bearer t' },
      });
      const body = (await list.json()) as {
        conversations: Array<{ other: { id: string } }>;
      };
      expect(body.conversations).toHaveLength(1);
      expect(body.conversations[0].other.id).toBe(b.id);
    });
  });
});
