import { prisma } from './db.js';

/**
 * Per ADR-0003: A may DM B if any of the following holds:
 *  - A commented on a Post authored by B
 *  - B commented on a Post authored by A
 *  - A and B both commented on the same Post
 *
 * The check runs against the `Comment` table; no eligibility table exists.
 */
export async function canDM(aId: string, bId: string): Promise<boolean> {
  if (aId === bId) return false;

  const aOnB = await prisma.comment.findFirst({
    where: { authorId: aId, post: { authorId: bId } },
    select: { id: true },
  });
  if (aOnB) return true;

  const bOnA = await prisma.comment.findFirst({
    where: { authorId: bId, post: { authorId: aId } },
    select: { id: true },
  });
  if (bOnA) return true;

  const aPosts = await prisma.comment.findMany({
    where: { authorId: aId },
    select: { postId: true },
    distinct: ['postId'],
  });
  if (aPosts.length === 0) return false;

  const both = await prisma.comment.findFirst({
    where: { authorId: bId, postId: { in: aPosts.map((c) => c.postId) } },
    select: { id: true },
  });
  return both !== null;
}

export function orderUserPair(a: string, b: string): { userAId: string; userBId: string } {
  return a < b ? { userAId: a, userBId: b } : { userAId: b, userBId: a };
}
