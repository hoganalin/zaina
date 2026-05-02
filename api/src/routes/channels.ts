import { Hono } from 'hono';

import { prisma } from '../db.js';
import {
  requireAuth,
  type AuthVariables,
} from '../middleware/requireAuth.js';

export const channelsRoutes = new Hono<{ Variables: AuthVariables }>();

channelsRoutes.use('*', requireAuth);

channelsRoutes.get('/', async (c) => {
  const channels = await prisma.channel.findMany({
    orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
  });
  return c.json({ channels });
});
