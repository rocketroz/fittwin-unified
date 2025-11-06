import { AuthService } from 'src/modules/auth/auth.service';
import { inMemoryStore } from 'src/lib/persistence/in-memory-store';

describe('Auth Contracts', () => {
  let authService: AuthService;

  beforeEach(() => {
    inMemoryStore.reset();
    authService = new AuthService();
  });

  it('POST /auth/signup matches specification schema', async () => {
    const result = await authService.signup({
      email: 'shopperspec@example.com',
      password: 'StrongPass!123',
      consent: { terms: true, privacy: true, marketing: false },
    });

    expect(result).toEqual(
      expect.objectContaining({
        userId: expect.any(String),
        status: 'verification_pending',
        verificationToken: expect.any(String),
      })
    );

    const verificationRecord = inMemoryStore.verificationTokens.get(result.verificationToken);
    expect(verificationRecord?.userId).toBe(result.userId);
  });

  it('POST /auth/login matches specification schema', async () => {
    const { verificationToken, userId } = await authService.signup({
      email: 'loginspec@example.com',
      password: 'StrongPass!123',
      consent: { terms: true, privacy: true },
    });

    await authService.verify({ token: verificationToken });

    const login = await authService.login({
      email: 'loginspec@example.com',
      password: 'StrongPass!123',
      device: { name: 'ios', fingerprint: 'device-123' },
    });

    expect(login).toEqual(
      expect.objectContaining({
        accessToken: expect.stringContaining(`access-${userId}`),
        refreshToken: expect.any(String),
        expiresIn: 900,
        mfaRequired: false,
      })
    );
  });

  it('POST /auth/refresh matches specification schema', async () => {
    const { verificationToken } = await authService.signup({
      email: 'refreshspec@example.com',
      password: 'StrongPass!123',
      consent: { terms: true, privacy: true },
    });
    await authService.verify({ token: verificationToken });

    const login = await authService.login({
      email: 'refreshspec@example.com',
      password: 'StrongPass!123',
      device: { name: 'web', fingerprint: 'browser-001' },
    });

    const refreshed = await authService.refresh({
      refreshToken: login.refreshToken,
      deviceFingerprint: 'browser-001',
    });

    expect(refreshed).toEqual(
      expect.objectContaining({
        accessToken: expect.any(String),
        refreshToken: expect.any(String),
        expiresIn: 900,
      })
    );
  });
});
