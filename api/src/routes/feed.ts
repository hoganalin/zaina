import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import { z } from 'zod';

import { getBlockedCounterparts } from '../blocks.js';
import { prisma } from '../db.js';
import {
  requireAuth,
  type AuthVariables,
} from '../middleware/requireAuth.js';

export const feedRoutes = new Hono<{ Variables: AuthVariables }>();

feedRoutes.use('*', requireAuth);

const paginationSchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

const postInclude = {
  channel: { select: { id: true, slug: true, name: true, icon: true } },
  author: { select: { id: true, nickname: true, avatarUrl: true } },
} as const;

async function annotateLikedByMe<T extends { id: string }>(
  posts: T[],
  userId: string,
): Promise<Array<T & { likedByMe: boolean }>> {
  if (posts.length === 0) return [];
  const likes = await prisma.postLike.findMany({
    where: { userId, postId: { in: posts.map((p) => p.id) } },
    select: { postId: true },
  });
  const likedSet = new Set(likes.map((l) => l.postId));
  return posts.map((p) => ({ ...p, likedByMe: likedSet.has(p.id) }));
}

feedRoutes.get(
  '/following',
  zValidator('query', paginationSchema),
  async (c) => {
    const userId = c.var.userId;
    const { limit, offset } = c.req.valid('query');

    const follows = await prisma.channelFollow.findMany({
      where: { userId },
      select: { channelId: true },
    });
    if (follows.length === 0) {
      return c.json({ posts: [], nextOffset: null });
    }

    const channelIds = follows.map((f) => f.channelId);
    const blocked = await getBlockedCounterparts(userId);
    const posts = await prisma.post.findMany({
      where: {
        channelId: { in: channelIds },
        authorId: { notIn: [...blocked] },
      },
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      skip: offset,
      include: postInclude,
    });

    const hasMore = posts.length > limit;
    const sliced = posts.slice(0, limit);
    const annotated = await annotateLikedByMe(sliced, userId);
    return c.json({
      posts: annotated,
      nextOffset: hasMore ? offset + limit : null,
    });
  },
);

feedRoutes.get(
  '/city',
  zValidator('query', paginationSchema),
  async (c) => {
    const { id: userId, city } = c.var.user;
    const { limit, offset } = c.req.valid('query');

    if (!city) {
      return c.json({ posts: [], nextOffset: null });
    }

    const blocked = await getBlockedCounterparts(userId);
    const posts = await prisma.post.findMany({
      where: {
        city,
        authorId: { notIn: [...blocked] },
      },
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      skip: offset,
      include: postInclude,
    });

    const hasMore = posts.length > limit;
    const sliced = posts.slice(0, limit);
    const annotated = await annotateLikedByMe(sliced, userId);
    return c.json({
      posts: annotated,
      nextOffset: hasMore ? offset + limit : null,
    });
  },
);
