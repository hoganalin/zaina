import { prisma } from './db.js';

/**
 * Returns the set of user ids that should be excluded from `userId`'s
 * post feeds and DM eligibility — block is symmetric in v1: if A blocks B
 * (or vice versa), neither sees the other's content.
 */
export async function getBlockedCounterparts(userId: string): Promise<Set<string>> {
  const rows = await prisma.block.findMany({
    where: {
      OR: [{ blockerId: userId }, { blockedId: userId }],
    },
    select: { blockerId: true, blockedId: true },
  });
  const ids = new Set<string>();
  for (const row of rows) {
    if (row.blockerId !== userId) ids.add(row.blockerId);
    if (row.blockedId !== userId) ids.add(row.blockedId);
  }
  return ids;
}
