import { getMessaging } from 'firebase-admin/messaging';

import { prisma } from './db.js';

export interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Best-effort FCM send. Silently no-ops if the user has no token registered;
 * silently catches transport / token-invalid errors so caller flows are not
 * coupled to push delivery.
 */
export async function sendPush(
  userId: string,
  payload: PushPayload,
): Promise<void> {
  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });
    if (!user?.fcmToken) return;

    await getMessaging().send({
      token: user.fcmToken,
      notification: { title: payload.title, body: payload.body },
      data: payload.data,
    });
  } catch (err) {
    console.warn(`[push] failed for ${userId}:`, err);
  }
}
