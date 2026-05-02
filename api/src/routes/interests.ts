import { Hono } from 'hono';

import { prisma } from '../db.js';
import {
  requireAuth,
  type AuthVariables,
} from '../middleware/requireAuth.js';

export const interestsRoutes = new Hono<{ Variables: AuthVariables }>();

interestsRoutes.use('*', requireAuth);

interestsRoutes.get('/', async (c) => {
  const interests = await prisma.interest.findMany({
    orderBy: [{ category: 'asc' }, { name: 'asc' }],
  });
  return c.json({ interests });
});
