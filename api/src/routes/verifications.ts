import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import { z } from 'zod';

import { prisma } from '../db.js';
import {
  requireAuth,
  type AuthVariables,
} from '../middleware/requireAuth.js';

export const verificationsRoutes = new Hono<{ Variables: AuthVariables }>();

verificationsRoutes.use('*', requireAuth);

const submitSchema = z.object({
  identityType: z.enum(['student', 'employee']),
  imageUrl: z.string().url(),
});

verificationsRoutes.post('/', zValidator('json', submitSchema), async (c) => {
  const userId = c.var.userId;
  const data = c.req.valid('json');

  // Per ADR-0004: review is simulated. The submission lands in the table
  // with status 'approved' immediately, and the user is marked verified.
  // The real-world surface (form, image upload, queue) exists; the queue
  // is a no-op.
  const result = await prisma.$transaction(async (tx) => {
    const v = await tx.verification.create({
      data: {
        userId,
        identityType: data.identityType,
        imageUrl: data.imageUrl,
        status: 'approved',
        reviewedAt: new Date(),
      },
    });
    await tx.user.update({
      where: { id: userId },
      data: { isVerified: true },
    });
    return v;
  });

  return c.json({ verification: result }, 201);
});

verificationsRoutes.get('/me', async (c) => {
  const userId = c.var.userId;
  const list = await prisma.verification.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
  });
  return c.json({ verifications: list });
});
