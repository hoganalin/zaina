import { Hono } from 'hono';
import { getAuth } from 'firebase-admin/auth';
import { prisma } from '../db.js';

export const authRoutes = new Hono();

authRoutes.post('/session', async (c) => {
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

  const placeholderNickname = decoded.name ?? '新朋友';
  const user = await prisma.user.upsert({
    where: { firebaseUid: decoded.uid },
    update: {},
    create: {
      firebaseUid: decoded.uid,
      nickname: placeholderNickname,
    },
  });

  const { firebaseUid: _firebaseUid, ...selfView } = user;
  return c.json({ user: selfView });
});
