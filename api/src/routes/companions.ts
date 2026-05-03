import { zValidator } from '@hono/zod-validator';
import { Hono } from 'hono';
import { z } from 'zod';

import { getBlockedCounterparts } from '../blocks.js';
import { prisma } from '../db.js';
import {
  requireAuth,
  type AuthVariables,
} from '../middleware/requireAuth.js';

export const companionsRoutes = new Hono<{ Variables: AuthVariables }>();

companionsRoutes.use('*', requireAuth);

const querySchema = z.object({
  limit: z.coerce.number().int().min(1).max(20).default(10),
});

/**
 * Daily 夥伴 recommendations: same city OR shared interest, not me, not blocked
 * either way, not already followed. Sorted by # of shared interests desc.
 *
 * Per ADR-0002 there is no swipe and no symmetric match — these are unilateral
 * follow candidates, not a dating queue.
 */
companionsRoutes.get('/daily', zValidator('query', querySchema), async (c) => {
  const me = c.var.user;
  const { limit } = c.req.valid('query');

  const myInterests = await prisma.userInterest.findMany({
    where: { userId: me.id },
    select: { interestId: true },
  });
  const myInterestIds = myInterests.map((i) => i.interestId);

  const blocked = await getBlockedCounterparts(me.id);

  const followed = await prisma.userFollow.findMany({
    where: { followerId: me.id },
    select: { followingId: true },
  });
  const excludeIds = new Set<string>([me.id, ...blocked, ...followed.map((f) => f.followingId)]);

  // Pull a candidate pool of onboarded users matching either filter; rank in TS
  // since the join with shared-interest count would need raw SQL otherwise.
  const candidates = await prisma.user.findMany({
    where: {
      onboardingCompleted: true,
      id: { notIn: [...excludeIds] },
      OR: [
        ...(me.city ? [{ city: me.city }] : []),
        ...(myInterestIds.length > 0
          ? [{ interests: { some: { interestId: { in: myInterestIds } } } }]
          : []),
      ],
    },
    select: {
      id: true,
      nickname: true,
      username: true,
      city: true,
      country: true,
      avatarUrl: true,
      bio: true,
      isVerified: true,
      interests: { select: { interestId: true } },
    },
    take: limit * 4,
  });

  const ranked = candidates
    .map((u) => {
      const sharedInterestIds = u.interests
        .map((ui) => ui.interestId)
        .filter((id) => myInterestIds.includes(id));
      return {
        id: u.id,
        nickname: u.nickname,
        username: u.username,
        city: u.city,
        country: u.country,
        avatarUrl: u.avatarUrl,
        bio: u.bio,
        isVerified: u.isVerified,
        sharedCity: !!me.city && u.city === me.city,
        sharedInterestCount: sharedInterestIds.length,
      };
    })
    .sort((a, b) => {
      // Prefer same city, then more shared interests.
      if (a.sharedCity !== b.sharedCity) return a.sharedCity ? -1 : 1;
      return b.sharedInterestCount - a.sharedInterestCount;
    })
    .slice(0, limit);

  return c.json({ companions: ranked });
});
