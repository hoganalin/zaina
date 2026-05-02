import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import { z } from 'zod';

import { prisma } from '../db.js';
import {
  requireAuth,
  type AuthVariables,
} from '../middleware/requireAuth.js';

export const postsRoutes = new Hono<{ Variables: AuthVariables }>();

postsRoutes.use('*', requireAuth);

const postInclude = {
  channel: { select: { id: true, slug: true, name: true, icon: true } },
  author: { select: { id: true, nickname: true, avatarUrl: true } },
} as const;

const createPostSchema = z.object({
  channelId: z.string().uuid(),
  title: z.string().min(1).max(120),
  body: z.string().min(1).max(2000),
  city: z.string().min(1).max(80),
  country: z.string().min(1).max(80),
  imageUrl: z.string().url().optional(),
});

postsRoutes.post('/', zValidator('json', createPostSchema), async (c) => {
  const authorId = c.var.userId;
  const data = c.req.valid('json');

  const channelExists = await prisma.channel.findUnique({
    where: { id: data.channelId },
    select: { id: true },
  });
  if (!channelExists) {
    return c.json({ error: 'invalid_channel_id' }, 400);
  }

  const post = await prisma.post.create({
    data: { ...data, authorId },
    include: postInclude,
  });

  return c.json({ post: { ...post, likedByMe: false } }, 201);
});

postsRoutes.get('/:id', async (c) => {
  const id = c.req.param('id');
  const userId = c.var.userId;

  const post = await prisma.post.findUnique({
    where: { id },
    include: postInclude,
  });
  if (!post) {
    return c.json({ error: 'not_found' }, 404);
  }

  const liked = await prisma.postLike.findUnique({
    where: { userId_postId: { userId, postId: id } },
    select: { postId: true },
  });

  return c.json({ post: { ...post, likedByMe: liked !== null } });
});

postsRoutes.post('/:id/like', async (c) => {
  const userId = c.var.userId;
  const postId = c.req.param('id');

  const post = await prisma.post.findUnique({
    where: { id: postId },
    select: { id: true },
  });
  if (!post) return c.json({ error: 'not_found' }, 404);

  const existing = await prisma.postLike.findUnique({
    where: { userId_postId: { userId, postId } },
    select: { postId: true },
  });
  if (existing) {
    const current = await prisma.post.findUnique({
      where: { id: postId },
      select: { likeCount: true },
    });
    return c.json({ likeCount: current?.likeCount ?? 0, likedByMe: true });
  }

  const updated = await prisma.$transaction(async (tx) => {
    await tx.postLike.create({ data: { userId, postId } });
    return tx.post.update({
      where: { id: postId },
      data: { likeCount: { increment: 1 } },
      select: { likeCount: true },
    });
  });

  return c.json({ likeCount: updated.likeCount, likedByMe: true });
});

postsRoutes.delete('/:id/like', async (c) => {
  const userId = c.var.userId;
  const postId = c.req.param('id');

  const result = await prisma.$transaction(async (tx) => {
    const post = await tx.post.findUnique({
      where: { id: postId },
      select: { id: true },
    });
    if (!post) return null;

    const deleted = await tx.postLike.deleteMany({
      where: { userId, postId },
    });
    if (deleted.count === 0) {
      const current = await tx.post.findUnique({
        where: { id: postId },
        select: { likeCount: true },
      });
      return { likeCount: current?.likeCount ?? 0, likedByMe: false };
    }

    const updated = await tx.post.update({
      where: { id: postId },
      data: { likeCount: { decrement: 1 } },
      select: { likeCount: true },
    });
    return { likeCount: updated.likeCount, likedByMe: false };
  });

  if (result === null) return c.json({ error: 'not_found' }, 404);
  return c.json(result);
});

const commentPaginationSchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});

postsRoutes.get(
  '/:id/comments',
  zValidator('query', commentPaginationSchema),
  async (c) => {
    const postId = c.req.param('id');
    const { limit, offset } = c.req.valid('query');

    const post = await prisma.post.findUnique({
      where: { id: postId },
      select: { id: true },
    });
    if (!post) return c.json({ error: 'not_found' }, 404);

    const comments = await prisma.comment.findMany({
      where: { postId },
      orderBy: { createdAt: 'asc' },
      take: limit + 1,
      skip: offset,
      include: {
        author: { select: { id: true, nickname: true, avatarUrl: true } },
      },
    });

    const hasMore = comments.length > limit;
    return c.json({
      comments: comments.slice(0, limit),
      nextOffset: hasMore ? offset + limit : null,
    });
  },
);

const createCommentSchema = z.object({
  body: z.string().min(1).max(1000),
});

postsRoutes.post(
  '/:id/comments',
  zValidator('json', createCommentSchema),
  async (c) => {
    const authorId = c.var.userId;
    const postId = c.req.param('id');
    const { body } = c.req.valid('json');

    const result = await prisma.$transaction(async (tx) => {
      const post = await tx.post.findUnique({
        where: { id: postId },
        select: { id: true },
      });
      if (!post) return null;

      const comment = await tx.comment.create({
        data: { postId, authorId, body },
        include: {
          author: { select: { id: true, nickname: true, avatarUrl: true } },
        },
      });
      await tx.post.update({
        where: { id: postId },
        data: { commentCount: { increment: 1 } },
      });
      return comment;
    });

    if (result === null) return c.json({ error: 'not_found' }, 404);
    return c.json({ comment: result }, 201);
  },
);
