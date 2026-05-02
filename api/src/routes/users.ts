import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import { z } from 'zod';

import { prisma } from '../db.js';
import {
  requireAuth,
  type AuthVariables,
} from '../middleware/requireAuth.js';

export const usersRoutes = new Hono<{ Variables: AuthVariables }>();

usersRoutes.use('*', requireAuth);

const publicUserSelect = {
  id: true,
  nickname: true,
  gender: true,
  country: true,
  city: true,
  avatarUrl: true,
  bio: true,
  isVerified: true,
  createdAt: true,
} as const;

usersRoutes.get('/:id', async (c) => {
  const id = c.req.param('id');
  const user = await prisma.user.findUnique({
    where: { id },
    select: publicUserSelect,
  });
  if (!user) return c.json({ error: 'not_found' }, 404);

  const postCount = await prisma.post.count({ where: { authorId: id } });
  return c.json({ user: { ...user, postCount } });
});

const paginationSchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

usersRoutes.get(
  '/:id/posts',
  zValidator('query', paginationSchema),
  async (c) => {
    const userId = c.var.userId;
    const authorId = c.req.param('id');
    const { limit, offset } = c.req.valid('query');

    const author = await prisma.user.findUnique({
      where: { id: authorId },
      select: { id: true },
    });
    if (!author) return c.json({ error: 'not_found' }, 404);

    const posts = await prisma.post.findMany({
      where: { authorId },
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      skip: offset,
      include: {
        channel: { select: { id: true, slug: true, name: true, icon: true } },
        author: { select: { id: true, nickname: true, avatarUrl: true } },
      },
    });

    const hasMore = posts.length > limit;
    const sliced = posts.slice(0, limit);
    const likes = await prisma.postLike.findMany({
      where: { userId, postId: { in: sliced.map((p) => p.id) } },
      select: { postId: true },
    });
    const likedSet = new Set(likes.map((l) => l.postId));
    const annotated = sliced.map((p) => ({
      ...p,
      likedByMe: likedSet.has(p.id),
    }));

    return c.json({
      posts: annotated,
      nextOffset: hasMore ? offset + limit : null,
    });
  },
);
