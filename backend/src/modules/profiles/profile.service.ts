import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import {
  inMemoryStore,
  generateId,
  timestamp,
  AvatarRecord,
  ProfileRecord,
  AddressRecord,
  PaymentMethodRecord,
  DataExportJobRecord
} from '../../lib/persistence/in-memory-store';
import { hashPassword } from '../../lib/security/password';

interface UpdateProfilePayload {
  appearance?: Record<string, unknown>;
  stylePreferences?: Record<string, unknown>;
  username?: string;
}

interface UpdateBodyPayload {
  heightCm?: number;
  weightKg?: number;
  measurements?: Record<string, number>;
}

interface AddressPayload {
  label?: string;
  line1?: string;
  line2?: string;
  city?: string;
  state?: string;
  postalCode?: string;
  country?: string;
  type?: 'billing' | 'shipping';
}

interface PaymentMethodPayload {
  paymentMethodId?: string;
  billingAddressId?: string;
  provider?: string;
  brand?: string;
  lastFour?: string;
  expiresAt?: string;
}

@Injectable()
export class ProfileService {
  private readonly store = inMemoryStore;

  async getProfile(): Promise<Record<string, unknown>> {
    const profile = this.ensureProfile();
    const avatars = profile.avatars
      .map((avatarId) => this.store.avatars.get(avatarId))
      .filter((value): value is AvatarRecord => Boolean(value))
      .map((avatar) => ({
        avatarId: avatar.id,
        version: avatar.version,
        status: avatar.status,
        confidence: avatar.confidence,
        meshUrl: avatar.meshUrl,
        generatedAt: avatar.generatedAt
      }));

    const addresses = Array.from(this.store.addresses.values()).filter((address) => address.userId === profile.userId);
    const paymentMethods = Array.from(this.store.paymentMethods.values()).filter((method) => method.userId === profile.userId);

    const user = this.store.users.get(profile.userId);

    return {
      userId: profile.userId,
      email: profile.email,
      username: profile.username,
      appearance: profile.appearance,
      stylePreferences: profile.stylePreferences,
      bodyMetrics: profile.bodyMetrics,
      avatars,
      addresses,
      paymentMethods,
      consents: {
        terms: user?.consent.terms ?? false,
        marketing: user?.consent.marketing ?? false,
        dataExportAvailable: profile.consents.dataExportAvailable
      }
    };
  }

  async updateProfile(rawPayload: Record<string, unknown>) {
    const profile = this.ensureProfile();
    const payload = rawPayload as UpdateProfilePayload;

    if (payload.username && payload.username.length < 3) {
      throw new HttpException(
        { error: { code: 'PROFILE_USERNAME_INVALID', message: 'Username must be at least 3 characters.' } },
        HttpStatus.BAD_REQUEST
      );
    }

    if (payload.username && this.usernameTaken(payload.username, profile.userId)) {
      throw new HttpException(
        { error: { code: 'PROFILE_USERNAME_CONFLICT', message: 'Username already taken.' } },
        HttpStatus.CONFLICT
      );
    }

    const updated: ProfileRecord = {
      ...profile,
      username: payload.username ?? profile.username,
      appearance: {
        ...profile.appearance,
        ...(payload.appearance ?? {})
      },
      stylePreferences: {
        ...profile.stylePreferences,
        ...(payload.stylePreferences ?? {})
      },
      updatedAt: timestamp()
    };

    this.store.profiles.set(profile.userId, updated);
    return this.getProfile();
  }

  async updateBodyMetrics(rawPayload: Record<string, unknown>) {
    const profile = this.ensureProfile();
    const payload = rawPayload as UpdateBodyPayload;

    if (payload.heightCm && (payload.heightCm < 120 || payload.heightCm > 230)) {
      throw new HttpException(
        { error: { code: 'PROFILE_HEIGHT_OUT_OF_RANGE', message: 'Height must be between 120cm and 230cm.' } },
        HttpStatus.UNPROCESSABLE_ENTITY
      );
    }

    if (payload.weightKg && (payload.weightKg < 30 || payload.weightKg > 250)) {
      throw new HttpException(
        { error: { code: 'PROFILE_WEIGHT_OUT_OF_RANGE', message: 'Weight must be between 30kg and 250kg.' } },
        HttpStatus.UNPROCESSABLE_ENTITY
      );
    }

    const updated: ProfileRecord = {
      ...profile,
      bodyMetrics: {
        heightCm: payload.heightCm ?? profile.bodyMetrics.heightCm,
        weightKg: payload.weightKg ?? profile.bodyMetrics.weightKg,
        measurements: {
          ...(profile.bodyMetrics.measurements ?? {}),
          ...(payload.measurements ?? {})
        }
      },
      updatedAt: timestamp()
    };

    this.store.profiles.set(profile.userId, updated);
    return updated.bodyMetrics;
  }

  async requestExport() {
    const profile = this.ensureProfile();
    const job: DataExportJobRecord = {
      id: generateId(),
      userId: profile.userId,
      status: 'processing',
      requestedAt: timestamp()
    };
    this.store.dataExportJobs.set(job.id, job);

    profile.consents.dataExportAvailable = true;
    profile.updatedAt = timestamp();
    this.store.profiles.set(profile.userId, profile);

    return { jobId: job.id, status: job.status };
  }

  async deleteProfile() {
    const profile = this.ensureProfile();
    const user = this.store.users.get(profile.userId);
    if (user) {
      user.status = 'locked';
      user.updatedAt = timestamp();
      this.store.users.set(user.id, user);
    }
    return { status: 'scheduled' };
  }

  async addAddress(rawPayload: Record<string, unknown>) {
    const profile = this.ensureProfile();
    const payload = rawPayload as AddressPayload;

    if (!payload.line1 || !payload.city || !payload.postalCode || !payload.country) {
      throw new HttpException(
        { error: { code: 'PROFILE_ADDRESS_INVALID', message: 'Address line1, city, postalCode, and country are required.' } },
        HttpStatus.UNPROCESSABLE_ENTITY
      );
    }

    const record: AddressRecord = {
      id: generateId(),
      userId: profile.userId,
      label: payload.label ?? 'Primary',
      line1: payload.line1,
      line2: payload.line2,
      city: payload.city,
      state: payload.state,
      postalCode: payload.postalCode,
      country: payload.country,
      type: payload.type ?? 'shipping',
      createdAt: timestamp(),
      updatedAt: timestamp()
    };

    this.store.addresses.set(record.id, record);
    return record;
  }

  async addPaymentMethod(rawPayload: Record<string, unknown>) {
    const profile = this.ensureProfile();
    const payload = rawPayload as PaymentMethodPayload;

    if (!payload.paymentMethodId || !payload.billingAddressId) {
      throw new HttpException(
        { error: { code: 'PROFILE_PAYMENT_INVALID', message: 'paymentMethodId and billingAddressId are required.' } },
        HttpStatus.BAD_REQUEST
      );
    }

    if (!this.store.addresses.has(payload.billingAddressId)) {
      throw new HttpException(
        { error: { code: 'PROFILE_ADDRESS_NOT_FOUND', message: 'Billing address not found.' } },
        HttpStatus.NOT_FOUND
      );
    }

    const record: PaymentMethodRecord = {
      id: generateId(),
      userId: profile.userId,
      provider: payload.provider ?? 'stripe',
      lastFour: payload.lastFour ?? '4242',
      brand: payload.brand ?? 'visa',
      expiresAt: payload.expiresAt ?? new Date(Date.now() + 1000 * 60 * 60 * 24 * 365).toISOString(),
      token: payload.paymentMethodId,
      createdAt: timestamp(),
      updatedAt: timestamp(),
      default: true
    };

    this.store.paymentMethods.set(record.id, record);
    return record;
  }

  private ensureProfile(): ProfileRecord {
    const activeUser = Array.from(this.store.users.values()).find((user) => user.status !== 'locked');
    if (!activeUser) {
      const seed = this.seedUser();
      return seed;
    }

    const profile = this.store.profiles.get(activeUser.id);
    if (!profile) {
      const seeded = this.seedProfile(activeUser.id, activeUser.email);
      return seeded;
    }

    return profile;
  }

  private usernameTaken(username: string, currentUserId: string): boolean {
    for (const profile of this.store.profiles.values()) {
      if (profile.username === username && profile.userId !== currentUserId) {
        return true;
      }
    }
    return false;
  }

  private seedUser(): ProfileRecord {
    const email = 'demo@fittwin.local';
    const { hash, salt } = hashPassword('DemoPass!123');
    const userId = generateId();
    const now = timestamp();

    this.store.users.set(userId, {
      id: userId,
      email,
      passwordHash: hash,
      passwordSalt: salt,
      status: 'active',
      consent: { terms: true, marketing: false, privacy: true },
      createdAt: now,
      updatedAt: now,
      failedAttempts: 0
    });

    const profile = this.seedProfile(userId, email);
    return profile;
  }

  private seedProfile(userId: string, email: string): ProfileRecord {
    const profile: ProfileRecord = {
      userId,
      email,
      username: email.split('@')[0],
      appearance: {
        hairColor: 'brown',
        eyeColor: 'green',
        skinTone: 'medium'
      },
      stylePreferences: {
        keywords: ['minimal', 'athleisure'],
        fitPrefs: { tops: 'regular', bottoms: 'slim' }
      },
      bodyMetrics: {
        heightCm: 172,
        weightKg: 68,
        measurements: { waist: 74, inseam: 80 }
      },
      consents: { marketing: false, dataExportAvailable: false },
      avatars: [],
      updatedAt: timestamp()
    };

    this.store.profiles.set(userId, profile);
    return profile;
  }
}
