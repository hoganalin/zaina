import { describe, it, expect, vi, beforeEach, afterAll } from 'vitest';

const { verifyIdTokenMock } = vi.hoisted(() => ({
  verifyIdTokenMock: vi.fn(),
}));

vi.mock('firebase-admin/auth', () => ({
  getAuth: () => ({ verifyIdToken: verifyIdTokenMock }),
}));

const { app } = await import('../src/app.js');
const { prisma } = await import('../src/db.js');

describe('POST /api/auth/session', () => {
  beforeEach(async () => {
    verifyIdTokenMock.mockReset();
    await prisma.user.deleteMany();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('returns 401 when no Authorization header is provided', async () => {
    const res = await app.request('/api/auth/session', { method: 'POST' });
    expect(res.status).toBe(401);
  });

  it('returns 401 when the Firebase token is invalid', async () => {
    verifyIdTokenMock.mockRejectedValueOnce(new Error('invalid token'));
    const res = await app.request('/api/auth/session', {
      method: 'POST',
      headers: { Authorization: 'Bearer broken-token' },
    });
    expect(res.status).toBe(401);
  });

  it('creates a User on first valid token and returns self-view', async () => {
    const uid = 'firebase-uid-new-user';
    verifyIdTokenMock.mockResolvedValueOnce({ uid, name: 'Hogan Lin' });

    const res = await app.request('/api/auth/session', {
      method: 'POST',
      headers: { Authorization: 'Bearer valid-new-token' },
    });

    expect(res.status).toBe(200);
    const body = (await res.json()) as { user: Record<string, unknown> };
    expect(body.user).toMatchObject({
      nickname: 'Hogan Lin',
      onboardingCompleted: false,
      isVerified: false,
      gender: null,
      country: null,
      city: null,
      avatarUrl: null,
      bio: null,
    });
    expect(typeof body.user.id).toBe('string');
    expect(body.user.firebaseUid).toBeUndefined();

    const dbUser = await prisma.user.findUnique({ where: { firebaseUid: uid } });
    expect(dbUser).not.toBeNull();
    expect(dbUser?.nickname).toBe('Hogan Lin');
  });

  it('returns the same User on repeat sign-in (idempotent)', async () => {
    const uid = 'firebase-uid-repeat';
    verifyIdTokenMock.mockResolvedValue({ uid, name: 'Repeat User' });

    const res1 = await app.request('/api/auth/session', {
      method: 'POST',
      headers: { Authorization: 'Bearer first-token' },
    });
    const body1 = (await res1.json()) as { user: { id: string } };

    const res2 = await app.request('/api/auth/session', {
      method: 'POST',
      headers: { Authorization: 'Bearer second-token' },
    });
    const body2 = (await res2.json()) as { user: { id: string } };

    expect(res1.status).toBe(200);
    expect(res2.status).toBe(200);
    expect(body1.user.id).toBe(body2.user.id);

    const dbUsers = await prisma.user.findMany({ where: { firebaseUid: uid } });
    expect(dbUsers).toHaveLength(1);
  });
});
