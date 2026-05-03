import { Hono } from 'hono';

import { prisma } from '../db.js';
import {
  requireAuth,
  type AuthVariables,
} from '../middleware/requireAuth.js';

export const notificationsRoutes = new Hono<{ Variables: AuthVariables }>();

notificationsRoutes.use('*', requireAuth);

type Notification = {
  id: string;
  type: 'comment_on_my_post' | 'new_dm' | 'new_post_in_channel' | 'new_follower';
  createdAt: Date;
  actor: { id: string; nickname: string; avatarUrl: string | null };
  target?: Record<string, string | null>;
};

/**
 * Notifications are derived ad-hoc from existing tables — no Notification
 * table per ADR-0010 (we keep the schema small for portfolio scope and the
 * read load is cheap at this scale).
 *
 * Mix four feeds and return them by createdAt desc, capped at `limit`.
 */
notificationsRoutes.get('/', async (c) => {
  const userId = c.var.userId;
  const limit = 50;

  const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000); // last 30 days

  // 1) Comments on posts I authored (by other users)
  const commentsOnMine = await prisma.comment.findMany({
    where: {
      authorId: { not: userId },
      post: { authorId: userId },
      createdAt: { gte: since },
    },
    orderBy: { createdAt: 'desc' },
    take: limit,
    include: {
      author: { select: { id: true, nickname: true, avatarUrl: true } },
      post: { select: { id: true, title: true } },
    },
  });

  // 2) DMs received (latest from each conversation, by senderId != me)
  const dms = await prisma.message.findMany({
    where: {
      senderId: { not: userId },
      conversation: {
        OR: [{ userAId: userId }, { userBId: userId }],
      },
      createdAt: { gte: since },
    },
    orderBy: { createdAt: 'desc' },
    take: limit,
    include: {
      sender: { select: { id: true, nickname: true, avatarUrl: true } },
    },
  });

  // 3) New posts in channels I follow (authored by others)
  const followed = await prisma.channelFollow.findMany({
    where: { userId },
    select: { channelId: true },
  });
  const newPosts = followed.length === 0
    ? []
    : await prisma.post.findMany({
        where: {
          channelId: { in: followed.map((f) => f.channelId) },
          authorId: { not: userId },
          createdAt: { gte: since },
        },
        orderBy: { createdAt: 'desc' },
        take: 20,
        include: {
          author: { select: { id: true, nickname: true, avatarUrl: true } },
          channel: { select: { id: true, name: true, icon: true } },
        },
      });

  // 4) New followers (UserFollow where I am followingId)
  const newFollowers = await prisma.userFollow.findMany({
    where: { followingId: userId, createdAt: { gte: since } },
    orderBy: { createdAt: 'desc' },
    take: limit,
    include: {
      follower: { select: { id: true, nickname: true, avatarUrl: true } },
    },
  });

  const notifications: Notification[] = [
    ...commentsOnMine.map<Notification>((c2) => ({
      id: `comment:${c2.id}`,
      type: 'comment_on_my_post',
      createdAt: c2.createdAt,
      actor: c2.author,
      target: { postId: c2.post.id, postTitle: c2.post.title },
    })),
    ...dms.map<Notification>((m) => ({
      id: `dm:${m.id}`,
      type: 'new_dm',
      createdAt: m.createdAt,
      actor: m.sender,
      target: { conversationId: m.conversationId, body: m.body.slice(0, 80) },
    })),
    ...newPosts.map<Notification>((p) => ({
      id: `post:${p.id}`,
      type: 'new_post_in_channel',
      createdAt: p.createdAt,
      actor: p.author,
      target: {
        postId: p.id,
        postTitle: p.title,
        channelName: p.channel.name,
        channelIcon: p.channel.icon,
      },
    })),
    ...newFollowers.map<Notification>((f) => ({
      id: `follow:${f.followerId}-${f.followingId}`,
      type: 'new_follower',
      createdAt: f.createdAt,
      actor: f.follower,
    })),
  ]
    .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
    .slice(0, limit);

  return c.json({ notifications });
});
