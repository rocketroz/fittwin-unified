import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import {
  inMemoryStore,
  generateId,
  timestamp,
  RefreshTokenRecord,
  VerificationTokenRecord,
} from '../../lib/persistence/in-memory-store';
import {
  hashPassword,
  validatePasswordStrength,
  verifyPassword,
} from '../../lib/security/password';
import { isBreachedPassword } from '../../lib/security/breach-check';

interface SignupPayload {
  email: string;
  password: string;
  consent?: {
    terms?: boolean;
    marketing?: boolean;
    privacy?: boolean;
  };
}

interface VerifyPayload {
  token: string;
}

interface LoginPayload {
  email: string;
  password: string;
  device?: {
    name?: string;
    fingerprint?: string;
  };
}

interface RefreshPayload {
  refreshToken: string;
  deviceFingerprint?: string;
}

interface LogoutPayload {
  refreshToken: string;
}

type UnknownRecord = Record<string, unknown>;

const FAILED_ATTEMPT_LIMIT = 5;
const REFRESH_TTL_MS = 1000 * 60 * 60 * 24 * 30; // 30 days
const VERIFICATION_TTL_MS = 1000 * 60 * 60 * 24; // 24 hours

function ensureEmail(value: unknown): asserts value is string {
  if (typeof value !== 'string' || !value.includes('@')) {
    throw new HttpException(
      { error: { code: 'AUTH_INVALID_EMAIL', message: 'Valid email is required.' } },
      HttpStatus.BAD_REQUEST,
    );
  }
}

function ensurePassword(value: unknown): asserts value is string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpException(
      { error: { code: 'AUTH_INVALID_PASSWORD', message: 'Password is required.' } },
      HttpStatus.BAD_REQUEST,
    );
  }
}

@Injectable()
export class AuthService {
  private readonly store = inMemoryStore;

  async signup(rawPayload: UnknownRecord) {
    const payload = rawPayload as Partial<SignupPayload>;
    ensureEmail(payload.email);
    ensurePassword(payload.password);

    const { valid, errors } = validatePasswordStrength(payload.password as string);
    if (!valid) {
      throw new HttpException(
        { error: { code: 'AUTH_WEAK_PASSWORD', message: errors.join(' ') } },
        HttpStatus.BAD_REQUEST,
      );
    }

    if (isBreachedPassword(payload.password)) {
      throw new HttpException(
        {
          error: { code: 'AUTH_BREACHED_PASSWORD', message: 'Password appears in breach corpus.' },
        },
        HttpStatus.UNAUTHORIZED,
      );
    }

    const consent = payload.consent ?? {};
    if (!consent.terms || !consent.privacy) {
      throw new HttpException(
        {
          error: {
            code: 'AUTH_CONSENT_REQUIRED',
            message: 'Terms and privacy consent must be granted.',
          },
        },
        HttpStatus.BAD_REQUEST,
      );
    }

    const existingUser = this.findUserByEmail(payload.email);
    if (existingUser) {
      throw new HttpException(
        { error: { code: 'AUTH_EMAIL_EXISTS', message: 'Email already registered.' } },
        HttpStatus.CONFLICT,
      );
    }

    const { hash, salt } = hashPassword(payload.password);
    const userId = generateId();
    const now = timestamp();

    this.store.users.set(userId, {
      id: userId,
      email: payload.email.toLowerCase(),
      passwordHash: hash,
      passwordSalt: salt,
      status: 'verification_pending',
      consent: {
        terms: Boolean(consent.terms),
        marketing: Boolean(consent.marketing),
        privacy: Boolean(consent.privacy),
      },
      createdAt: now,
      updatedAt: now,
      failedAttempts: 0,
    });

    this.store.profiles.set(userId, {
      userId,
      email: payload.email.toLowerCase(),
      username: payload.email.split('@')[0],
      appearance: {},
      stylePreferences: {},
      bodyMetrics: {},
      consents: {
        marketing: Boolean(consent.marketing),
        dataExportAvailable: false,
      },
      avatars: [],
      updatedAt: now,
    });

    const verificationToken: VerificationTokenRecord = {
      token: randomUUID(),
      userId,
      expiresAt: new Date(Date.now() + VERIFICATION_TTL_MS).toISOString(),
    };
    this.store.verificationTokens.set(verificationToken.token, verificationToken);

    return {
      userId,
      status: 'verification_pending',
      verificationToken: verificationToken.token,
    };
  }

  async verify(rawPayload: UnknownRecord): Promise<void> {
    const payload = this.parseVerifyPayload(rawPayload);

    const record = this.store.verificationTokens.get(payload.token);
    if (!record) {
      throw new HttpException(
        { error: { code: 'AUTH_TOKEN_NOT_FOUND', message: 'Verification token not recognized.' } },
        HttpStatus.NOT_FOUND,
      );
    }

    if (new Date(record.expiresAt).getTime() < Date.now()) {
      this.store.verificationTokens.delete(payload.token);
      throw new HttpException(
        { error: { code: 'AUTH_TOKEN_EXPIRED', message: 'Verification token expired.' } },
        HttpStatus.BAD_REQUEST,
      );
    }

    const user = this.store.users.get(record.userId);
    if (!user) {
      this.store.verificationTokens.delete(payload.token);
      throw new HttpException(
        { error: { code: 'AUTH_USER_NOT_FOUND', message: 'User for token missing.' } },
        HttpStatus.NOT_FOUND,
      );
    }

    user.status = 'active';
    user.updatedAt = timestamp();
    this.store.users.set(user.id, user);
    this.store.verificationTokens.delete(payload.token);
  }

  async login(rawPayload: UnknownRecord) {
    const payload = this.parseLoginPayload(rawPayload);

    const user = this.findUserByEmail(payload.email);
    if (!user) {
      throw new HttpException(
        { error: { code: 'AUTH_INVALID_CREDENTIALS', message: 'Invalid email or password.' } },
        HttpStatus.UNAUTHORIZED,
      );
    }

    if (user.status === 'verification_pending') {
      throw new HttpException(
        { error: { code: 'AUTH_VERIFICATION_REQUIRED', message: 'Email verification pending.' } },
        HttpStatus.FORBIDDEN,
      );
    }

    if (user.status === 'locked') {
      throw new HttpException(
        { error: { code: 'AUTH_ACCOUNT_LOCKED', message: 'Account temporarily locked.' } },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const passwordOk = verifyPassword(payload.password, {
      hash: user.passwordHash,
      salt: user.passwordSalt,
    });

    if (!passwordOk) {
      user.failedAttempts += 1;
      if (user.failedAttempts >= FAILED_ATTEMPT_LIMIT) {
        user.status = 'locked';
      }
      user.updatedAt = timestamp();
      this.store.users.set(user.id, user);
      throw new HttpException(
        { error: { code: 'AUTH_INVALID_CREDENTIALS', message: 'Invalid email or password.' } },
        HttpStatus.UNAUTHORIZED,
      );
    }

    user.failedAttempts = 0;
    user.lastLoginAt = timestamp();
    user.updatedAt = user.lastLoginAt;
    this.store.users.set(user.id, user);

    const deviceFingerprint = payload.device?.fingerprint;
    const refreshToken = this.createRefreshToken(user.id, deviceFingerprint);

    return {
      accessToken: this.createAccessToken(user.id),
      refreshToken: refreshToken.token,
      expiresIn: 900,
      mfaRequired: false,
    };
  }

  async refresh(rawPayload: UnknownRecord) {
    const payload = this.parseRefreshPayload(rawPayload);

    const record = this.store.refreshTokens.get(payload.refreshToken);
    if (!record || record.revoked) {
      throw new HttpException(
        { error: { code: 'AUTH_REFRESH_INVALID', message: 'Refresh token invalid.' } },
        HttpStatus.UNAUTHORIZED,
      );
    }

    if (new Date(record.expiresAt).getTime() < Date.now()) {
      this.store.refreshTokens.delete(payload.refreshToken);
      throw new HttpException(
        { error: { code: 'AUTH_REFRESH_EXPIRED', message: 'Refresh token expired.' } },
        HttpStatus.UNAUTHORIZED,
      );
    }

    if (
      payload.deviceFingerprint &&
      record.deviceFingerprint &&
      payload.deviceFingerprint !== record.deviceFingerprint
    ) {
      throw new HttpException(
        { error: { code: 'AUTH_FINGERPRINT_MISMATCH', message: 'Device fingerprint mismatch.' } },
        HttpStatus.CONFLICT,
      );
    }

    const newToken = this.createRefreshToken(record.userId, record.deviceFingerprint);
    record.revoked = true;
    this.store.refreshTokens.set(record.token, record);

    return {
      accessToken: this.createAccessToken(record.userId),
      refreshToken: newToken.token,
      expiresIn: 900,
    };
  }

  async logout(rawPayload: UnknownRecord): Promise<void> {
    const payload = this.parseLogoutPayload(rawPayload);

    const record = this.store.refreshTokens.get(payload.refreshToken);
    if (!record) {
      throw new HttpException(
        { error: { code: 'AUTH_REFRESH_INVALID', message: 'Refresh token invalid.' } },
        HttpStatus.UNAUTHORIZED,
      );
    }

    record.revoked = true;
    this.store.refreshTokens.set(record.token, record);
  }

  private parseVerifyPayload(raw: UnknownRecord): VerifyPayload {
    const token = raw.token;
    if (typeof token !== 'string' || !token.trim()) {
      throw new HttpException(
        { error: { code: 'AUTH_TOKEN_REQUIRED', message: 'Verification token is required.' } },
        HttpStatus.BAD_REQUEST,
      );
    }
    return { token };
  }

  private parseLoginPayload(raw: UnknownRecord): LoginPayload {
    const email = raw.email;
    const password = raw.password;
    ensureEmail(email);
    ensurePassword(password);
    const device = this.normalizeDevice(raw.device);
    return {
      email: email.toLowerCase(),
      password,
      device,
    };
  }

  private parseRefreshPayload(raw: UnknownRecord): RefreshPayload {
    const refreshToken = typeof raw.refreshToken === 'string' ? raw.refreshToken.trim() : '';
    if (!refreshToken) {
      throw new HttpException(
        { error: { code: 'AUTH_REFRESH_REQUIRED', message: 'Refresh token is required.' } },
        HttpStatus.BAD_REQUEST,
      );
    }

    const fingerprint =
      typeof raw.deviceFingerprint === 'string' ? raw.deviceFingerprint : undefined;
    return { refreshToken, deviceFingerprint: fingerprint };
  }

  private parseLogoutPayload(raw: UnknownRecord): LogoutPayload {
    const refreshToken = typeof raw.refreshToken === 'string' ? raw.refreshToken.trim() : '';
    if (!refreshToken) {
      throw new HttpException(
        { error: { code: 'AUTH_REFRESH_REQUIRED', message: 'Refresh token is required.' } },
        HttpStatus.BAD_REQUEST,
      );
    }
    return { refreshToken };
  }

  private normalizeDevice(input: unknown): LoginPayload['device'] | undefined {
    if (!input || typeof input !== 'object') {
      return undefined;
    }
    const candidate = input as UnknownRecord;
    const name = typeof candidate.name === 'string' ? candidate.name : undefined;
    const fingerprint =
      typeof candidate.fingerprint === 'string' ? candidate.fingerprint : undefined;
    if (!name && !fingerprint) {
      return undefined;
    }
    return { name, fingerprint };
  }

  private findUserByEmail(email: string) {
    const normalized = email.toLowerCase();
    for (const user of this.store.users.values()) {
      if (user.email === normalized) {
        return user;
      }
    }
    return undefined;
  }

  private createAccessToken(userId: string): string {
    return `access-${userId}-${randomUUID()}`;
  }

  private createRefreshToken(userId: string, deviceFingerprint?: string): RefreshTokenRecord {
    const token = generateId();
    const record: RefreshTokenRecord = {
      token,
      userId,
      deviceFingerprint,
      issuedAt: timestamp(),
      expiresAt: new Date(Date.now() + REFRESH_TTL_MS).toISOString(),
      revoked: false,
    };
    this.store.refreshTokens.set(token, record);
    return record;
  }
}
