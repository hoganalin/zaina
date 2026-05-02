import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import { z } from 'zod';

import { prisma } from '../db.js';
import { canDM, orderUserPair } from '../eligibility.js';
import {
  requireAuth,
  type AuthVariables,
} from '../middleware/requireAuth.js';
import { sendPush } from '../push.js';
import { emitToUser } from '../realtime.js';

export const conversationsRoutes = new Hono<{ Variables: AuthVariables }>();

conversationsRoutes.use('*', requireAuth);

const userLite = {
  select: { id: true, nickname: true, avatarUrl: true },
} as const;

conversationsRoutes.get('/', async (c) => {
  const me = c.var.userId;
  const conversations = await prisma.conversation.findMany({
    where: { OR: [{ userAId: me }, { userBId: me }] },
    orderBy: { lastMessageAt: 'desc' },
    include: {
      userA: userLite,
      userB: userLite,
      messages: { orderBy: { createdAt: 'desc' }, take: 1 },
    },
  });
  const summary = conversations.map((cv) => {
    const other = cv.userAId === me ? cv.userB : cv.userA;
    const lastMessage = cv.messages[0] ?? null;
    return {
      id: cv.id,
      status: cv.status,
      lastMessageAt: cv.lastMessageAt,
      other,
      lastMessage,
    };
  });
  return c.json({ conversations: summary });
});

const createConversationSchema = z.object({
  userId: z.string().uuid(),
});

conversationsRoutes.post(
  '/',
  zValidator('json', createConversationSchema),
  async (c) => {
    const me = c.var.userId;
    const { userId: other } = c.req.valid('json');

    if (me === other) {
      return c.json({ error: 'cannot_dm_self' }, 400);
    }

    const otherUser = await prisma.user.findUnique({
      where: { id: other },
      select: { id: true },
    });
    if (!otherUser) return c.json({ error: 'not_found' }, 404);

    const { userAId, userBId } = orderUserPair(me, other);

    const existing = await prisma.conversation.findUnique({
      where: { userAId_userBId: { userAId, userBId } },
      include: { userA: userLite, userB: userLite },
    });
    if (existing) {
      return c.json({ conversation: existing });
    }

    const eligible = await canDM(me, other);
    if (!eligible) {
      return c.json({ error: 'not_eligible' }, 403);
    }

    const created = await prisma.conversation.create({
      data: {
        userAId,
        userBId,
        status: 'message_request',
      },
      include: { userA: userLite, userB: userLite },
    });
    return c.json({ conversation: created }, 201);
  },
);

conversationsRoutes.get('/:id/messages', async (c) => {
  const me = c.var.userId;
  const conversationId = c.req.param('id');

  const conv = await prisma.conversation.findUnique({
    where: { id: conversationId },
    select: { id: true, userAId: true, userBId: true },
  });
  if (!conv) return c.json({ error: 'not_found' }, 404);
  if (conv.userAId !== me && conv.userBId !== me) {
    return c.json({ error: 'forbidden' }, 403);
  }

  const messages = await prisma.message.findMany({
    where: { conversationId },
    orderBy: { createdAt: 'asc' },
  });
  return c.json({ messages });
});

const sendMessageSchema = z.object({
  body: z.string().min(1).max(2000),
});

conversationsRoutes.post(
  '/:id/messages',
  zValidator('json', sendMessageSchema),
  async (c) => {
    const me = c.var.userId;
    const conversationId = c.req.param('id');
    const { body } = c.req.valid('json');

    const conv = await prisma.conversation.findUnique({
      where: { id: conversationId },
      select: {
        id: true,
        userAId: true,
        userBId: true,
        status: true,
      },
    });
    if (!conv) return c.json({ error: 'not_found' }, 404);
    if (conv.userAId !== me && conv.userBId !== me) {
      return c.json({ error: 'forbidden' }, 403);
    }

    const otherUserId = conv.userAId === me ? conv.userBId : conv.userAId;

    // Detect if this send promotes a message_request → active.
    // Promotion happens when the recipient (B) sends their first reply.
    let willPromote = false;
    if (conv.status === 'message_request') {
      const senderHasSentBefore = await prisma.message.findFirst({
        where: { conversationId, senderId: me },
        select: { id: true },
      });
      if (!senderHasSentBefore) {
        // Sender's first message in this conversation. If there were any
        // earlier messages in the convo (from the other user), this is the
        // reply that promotes it.
        const earlier = await prisma.message.findFirst({
          where: { conversationId },
          select: { id: true },
        });
        if (earlier) willPromote = true;
      }
    }

    const result = await prisma.$transaction(async (tx) => {
      const message = await tx.message.create({
        data: { conversationId, senderId: me, body },
      });
      await tx.conversation.update({
        where: { id: conversationId },
        data: {
          lastMessageAt: message.createdAt,
          ...(willPromote ? { status: 'active' as const } : {}),
        },
      });
      return message;
    });

    emitToUser(otherUserId, 'message:new', {
      conversationId,
      message: result,
    });

    const sender = await prisma.user.findUnique({
      where: { id: me },
      select: { nickname: true },
    });
    void sendPush(otherUserId, {
      title: sender?.nickname ?? '新訊息',
      body: body.length > 80 ? `${body.slice(0, 80)}…` : body,
      data: { conversationId, type: 'dm' },
    });

    return c.json({ message: result }, 201);
  },
);
