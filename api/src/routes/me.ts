import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import { z } from 'zod';

import { prisma } from '../db.js';
import {
  requireAuth,
  type AuthVariables,
} from '../middleware/requireAuth.js';

export const meRoutes = new Hono<{ Variables: AuthVariables }>();

meRoutes.use('*', requireAuth);

const stripFirebaseUid = <T extends { firebaseUid: string }>(user: T) => {
  const { firebaseUid: _firebaseUid, ...rest } = user;
  return rest;
};

meRoutes.get('/', (c) => {
  return c.json({ user: stripFirebaseUid(c.var.user) });
});

const usernameRegex = /^[a-zA-Z0-9_]{3,20}$/;

const profileEditSchema = z
  .object({
    nickname: z.string().min(1).max(40).optional(),
    username: z
      .string()
      .regex(usernameRegex, 'username must be 3-20 chars, letters/digits/_')
      .nullable()
      .optional(),
    gender: z.enum(['male', 'female', 'non_binary']).nullable().optional(),
    country: z.string().min(1).max(80).nullable().optional(),
    city: z.string().min(1).max(80).nullable().optional(),
    bio: z.string().max(500).nullable().optional(),
    avatarUrl: z.string().url().nullable().optional(),
  })
  .strict();

meRoutes.get('/check-username', async (c) => {
  const u = c.req.query('u') ?? '';
  if (!usernameRegex.test(u)) {
    return c.json({ available: false, reason: 'invalid_format' });
  }
  const existing = await prisma.user.findUnique({
    where: { username: u },
    select: { id: true },
  });
  const taken = existing !== null && existing.id !== c.var.userId;
  return c.json({ available: !taken });
});

meRoutes.patch('/', zValidator('json', profileEditSchema), async (c) => {
  const userId = c.var.userId;
  const data = c.req.valid('json');

  if (data.username) {
    const owned = await prisma.user.findUnique({
      where: { username: data.username },
      select: { id: true },
    });
    if (owned && owned.id !== userId) {
      return c.json({ error: 'username_taken' }, 409);
    }
  }

  try {
    const updated = await prisma.user.update({
      where: { id: userId },
      data,
    });
    return c.json({ user: stripFirebaseUid(updated) });
  } catch (err) {
    if ((err as { code?: string }).code === 'P2002') {
      return c.json({ error: 'username_taken' }, 409);
    }
    throw err;
  }
});

const pushTokenSchema = z.object({
  fcmToken: z.string().min(1).nullable(),
});

meRoutes.patch(
  '/push-token',
  zValidator('json', pushTokenSchema),
  async (c) => {
    const userId = c.var.userId;
    const { fcmToken } = c.req.valid('json');
    await prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });
    return c.json({ ok: true });
  },
);

const onboardingSchema = z.object({
  nickname: z.string().min(1).max(40),
  username: z.string().regex(usernameRegex).optional(),
  gender: z.enum(['male', 'female', 'non_binary']).optional(),
  country: z.string().min(1).max(80).optional(),
  city: z.string().min(1).max(80).optional(),
  interestIds: z.array(z.string().uuid()).default([]),
  channelIds: z.array(z.string().uuid()).default([]),
});

meRoutes.patch(
  '/onboarding',
  zValidator('json', onboardingSchema),
  async (c) => {
    const userId = c.var.userId;
    const data = c.req.valid('json');

    if (data.interestIds.length > 0) {
      const found = await prisma.interest.count({
        where: { id: { in: data.interestIds } },
      });
      if (found !== data.interestIds.length) {
        return c.json({ error: 'invalid_interest_id' }, 400);
      }
    }
    if (data.channelIds.length > 0) {
      const found = await prisma.channel.count({
        where: { id: { in: data.channelIds } },
      });
      if (found !== data.channelIds.length) {
        return c.json({ error: 'invalid_channel_id' }, 400);
      }
    }

    if (data.username) {
      const owned = await prisma.user.findUnique({
        where: { username: data.username },
        select: { id: true },
      });
      if (owned && owned.id !== userId) {
        return c.json({ error: 'username_taken' }, 409);
      }
    }

    const updated = await prisma.$transaction(async (tx) => {
      const user = await tx.user.update({
        where: { id: userId },
        data: {
          nickname: data.nickname,
          username: data.username,
          gender: data.gender,
          country: data.country,
          city: data.city,
          onboardingCompleted: true,
        },
      });

      await tx.userInterest.deleteMany({ where: { userId } });
      if (data.interestIds.length > 0) {
        await tx.userInterest.createMany({
          data: data.interestIds.map((interestId) => ({
            userId,
            interestId,
          })),
        });
      }

      await tx.channelFollow.deleteMany({ where: { userId } });
      if (data.channelIds.length > 0) {
        await tx.channelFollow.createMany({
          data: data.channelIds.map((channelId) => ({
            userId,
            channelId,
          })),
        });
      }

      return user;
    });

    return c.json({ user: stripFirebaseUid(updated) });
  },
);
