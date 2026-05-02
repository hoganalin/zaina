import { afterAll, beforeEach, describe, expect, it, vi } from 'vitest';

const { verifyIdTokenMock } = vi.hoisted(() => ({
  verifyIdTokenMock: vi.fn(),
}));

vi.mock('firebase-admin/auth', () => ({
  getAuth: () => ({ verifyIdToken: verifyIdTokenMock }),
}));

const { app } = await import('../src/app.js');
const { prisma } = await import('../src/db.js');

const TEST_UID = 'firebase-uid-interests-test';

describe('GET /api/interests', () => {
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
    const res = await app.request('/api/interests');
    expect(res.status).toBe(401);
  });

  it('returns the seeded interests for an authed user', async () => {
    verifyIdTokenMock.mockResolvedValue({ uid: TEST_UID });

    const res = await app.request('/api/interests', {
      headers: { Authorization: 'Bearer t' },
    });

    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      interests: Array<{ id: string; slug: string; name: string; category: string }>;
    };
    expect(body.interests.length).toBeGreaterThan(0);
    for (const i of body.interests) {
      expect(typeof i.id).toBe('string');
      expect(typeof i.slug).toBe('string');
      expect(typeof i.name).toBe('string');
      expect(['active', 'static']).toContain(i.category);
    }
  });
});
