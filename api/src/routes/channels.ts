import { Hono } from 'hono';

import { prisma } from '../db.js';
import {
  requireAuth,
  type AuthVariables,
} from '../middleware/requireAuth.js';

export const channelsRoutes = new Hono<{ Variables: AuthVariables }>();

channelsRoutes.use('*', requireAuth);

channelsRoutes.get('/', async (c) => {
  const userId = c.var.userId;
  const channels = await prisma.channel.findMany({
    orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
  });
  const follows = await prisma.channelFollow.findMany({
    where: { userId },
    select: { channelId: true },
  });
  const followedSet = new Set(follows.map((f) => f.channelId));
  return c.json({
    channels: channels.map((ch) => ({
      ...ch,
      isFollowing: followedSet.has(ch.id),
    })),
  });
});

channelsRoutes.post('/:id/follow', async (c) => {
  const userId = c.var.userId;
  const channelId = c.req.param('id');

  const channel = await prisma.channel.findUnique({
    where: { id: channelId },
    select: { id: true },
  });
  if (!channel) return c.json({ error: 'not_found' }, 404);

  await prisma.channelFollow.upsert({
    where: { userId_channelId: { userId, channelId } },
    create: { userId, channelId },
    update: {},
  });
  return c.json({ isFollowing: true });
});

channelsRoutes.delete('/:id/follow', async (c) => {
  const userId = c.var.userId;
  const channelId = c.req.param('id');

  await prisma.channelFollow.deleteMany({
    where: { userId, channelId },
  });
  return c.json({ isFollowing: false });
});
