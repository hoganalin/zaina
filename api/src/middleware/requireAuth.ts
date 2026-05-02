import type { User } from '@prisma/client';
import { getAuth } from 'firebase-admin/auth';
import { createMiddleware } from 'hono/factory';

import { prisma } from '../db.js';

export type AuthVariables = {
  userId: string;
  user: User;
};

export const requireAuth = createMiddleware<{ Variables: AuthVariables }>(
  async (c, next) => {
    const authHeader = c.req.header('Authorization');
    if (!authHeader) {
      return c.json({ error: 'unauthorized' }, 401);
    }
    const token = authHeader.replace(/^Bearer\s+/, '');

    let decoded;
    try {
      decoded = await getAuth().verifyIdToken(token);
    } catch {
      return c.json({ error: 'unauthorized' }, 401);
    }

    const user = await prisma.user.findUnique({
      where: { firebaseUid: decoded.uid },
    });
    if (!user) {
      return c.json({ error: 'unauthorized' }, 401);
    }

    c.set('userId', user.id);
    c.set('user', user);
    await next();
  },
);
