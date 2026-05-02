import { afterAll, beforeEach, describe, expect, it, vi } from 'vitest';

const { verifyIdTokenMock } = vi.hoisted(() => ({
  verifyIdTokenMock: vi.fn(),
}));

vi.mock('firebase-admin/auth', () => ({
  getAuth: () => ({ verifyIdToken: verifyIdTokenMock }),
}));

const { app } = await import('../src/app.js');
const { prisma } = await import('../src/db.js');

const TEST_UID = 'firebase-uid-channels-test';

describe('GET /api/channels', () => {
  beforeEach(async () => {
    verifyIdTokenMock.mockReset();
    await prisma.user.deleteMany({ where: { firebaseUid: TEST_UID } });
    await prisma.user.create({
      data: { firebaseUid: TEST_UID, nickname: 'Test' },
    });
  });

  afterAll(async () => {
    await prisma.user.deleteMany({ where: { firebaseUid: TEST_UID } });
    await prisma.$disconnect();
  });

  it('returns 401 when no Authorization header is provided', async () => {
    const res = await app.request('/api/channels');
    expect(res.status).toBe(401);
  });

  it('returns the seeded channels ordered by sortOrder', async () => {
    verifyIdTokenMock.mockResolvedValue({ uid: TEST_UID });

    const res = await app.request('/api/channels', {
      headers: { Authorization: 'Bearer t' },
    });

    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      channels: Array<{ id: string; slug: string; name: string; sortOrder: number }>;
    };
    expect(body.channels.length).toBeGreaterThan(0);
    for (let i = 1; i < body.channels.length; i++) {
      expect(body.channels[i].sortOrder).toBeGreaterThanOrEqual(
        body.channels[i - 1].sortOrder,
      );
    }
  });
});
