import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import {
  inMemoryStore,
  generateId,
  timestamp,
  AvatarRecord,
  ProfileRecord
} from '../../lib/persistence/in-memory-store';
import { hashPassword } from '../../lib/security/password';
import { localQueue, QueueJob } from '../../lib/queue/local-queue';

interface AvatarSources {
  sources?: {
    height?: number;
    weight?: number;
    measurements?: Record<string, number>;
    photos?: Array<{ url: string; view: string }>;
  };
}

interface AvatarJobPayload {
  avatarId: string;
  userId: string;
}

@Injectable()
export class AvatarService {
  private readonly store = inMemoryStore;

  constructor() {
    localQueue.register<AvatarJobPayload>('avatar-generation', (job) => this.processAvatarJob(job));
  }

  async createAvatarJob(rawPayload: Record<string, unknown> = {}) {
    const profile = this.ensureProfile();
    const payload = rawPayload as AvatarSources;

    const activeAvatar = profile.avatars
      .map((id) => this.store.avatars.get(id))
      .find((avatar) => avatar && (avatar.status === 'queued' || avatar.status === 'processing'));

    if (activeAvatar) {
      throw new HttpException(
        { error: { code: 'AVATAR_IN_PROGRESS', message: 'Avatar generation already in progress.' } },
        HttpStatus.CONFLICT
      );
    }

    const avatarId = generateId();
    const record: AvatarRecord = {
      id: avatarId,
      userId: profile.userId,
      version: (profile.avatars.length ?? 0) + 1,
      status: 'queued',
      confidence: 0,
      source: {
        measurements: payload.sources?.measurements,
        photos: payload.sources?.photos?.map((photo) => photo.url)
      },
      updatedAt: timestamp()
    };

    this.store.avatars.set(avatarId, record);
    profile.avatars.push(avatarId);
    profile.updatedAt = timestamp();
    this.store.profiles.set(profile.userId, profile);

    // Emit telemetry event for observability purposes.
    const eventId = generateId();
    this.store.analyticsEvents.set(eventId, {
      id: eventId,
      type: 'avatar.requested',
      createdAt: timestamp(),
      attributes: {
        userId: profile.userId,
        avatarId,
        hasPhotos: Boolean(payload.sources?.photos?.length)
      }
    });

    localQueue.enqueue<AvatarJobPayload>('avatar-generation', { avatarId, userId: profile.userId });

    return { avatarId, status: 'processing' };
  }

  async getAvatarStatus(avatarId: string) {
    const profile = this.ensureProfile();
    const avatar = this.store.avatars.get(avatarId);
    if (!avatar || avatar.userId !== profile.userId) {
      throw new HttpException(
        { error: { code: 'AVATAR_NOT_FOUND', message: 'Avatar not found.' } },
        HttpStatus.NOT_FOUND
      );
    }

    return {
      avatarId: avatar.id,
      status: avatar.status === 'queued' ? 'processing' : avatar.status,
      meshUrl: avatar.meshUrl,
      confidence: avatar.confidence,
      generatedAt: avatar.generatedAt
    };
  }

  async deleteAvatar(avatarId: string) {
    const profile = this.ensureProfile();
    const avatar = this.store.avatars.get(avatarId);
    if (!avatar || avatar.userId !== profile.userId) {
      throw new HttpException(
        { error: { code: 'AVATAR_NOT_FOUND', message: 'Avatar not found.' } },
        HttpStatus.NOT_FOUND
      );
    }

    const pendingOrder = Array.from(this.store.orders.values()).find(
      (order) => order.userId === profile.userId && order.status !== 'delivered' && order.status !== 'cancelled'
    );

    if (pendingOrder) {
      throw new HttpException(
        { error: { code: 'AVATAR_IN_USE', message: 'Avatar cannot be deleted while an order is active.' } },
        HttpStatus.CONFLICT
      );
    }

    avatar.status = 'deleted';
    avatar.updatedAt = timestamp();
    this.store.avatars.set(avatarId, avatar);

    profile.avatars = profile.avatars.filter((id) => id !== avatarId);
    profile.updatedAt = timestamp();
    this.store.profiles.set(profile.userId, profile);

    const eventId = generateId();
    this.store.analyticsEvents.set(eventId, {
      id: eventId,
      type: 'avatar.deleted',
      createdAt: timestamp(),
      attributes: { userId: profile.userId, avatarId }
    });
  }

  private ensureProfile() {
    const profile = Array.from(this.store.profiles.values())[0];
    if (profile) {
      return profile;
    }

    // Seed a demo profile if none exists yet (useful for first-run environments).
    const email = 'demo@fittwin.local';
    const userId = generateId();
    const now = timestamp();
    const { hash, salt } = hashPassword('DemoPass!123');

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

    const seededProfile: ProfileRecord = {
      userId,
      email,
      username: 'fitfan',
      appearance: { hairColor: 'brown', eyeColor: 'green', skinTone: 'medium' },
      stylePreferences: { keywords: ['minimal'], fitPrefs: { tops: 'regular', bottoms: 'slim' } },
      bodyMetrics: { heightCm: 172, weightKg: 68, measurements: { waist: 74, inseam: 80 } },
      consents: { marketing: false, dataExportAvailable: false },
      avatars: [],
      updatedAt: now
    };
    this.store.profiles.set(userId, seededProfile);
    return seededProfile;
  }

  private async processAvatarJob(job: QueueJob<AvatarJobPayload>) {
    const avatar = this.store.avatars.get(job.data.avatarId);
    if (!avatar) {
      return;
    }

    avatar.status = 'processing';
    avatar.updatedAt = timestamp();
    this.store.avatars.set(avatar.id, avatar);

    await new Promise((resolve) => setTimeout(resolve, 150));

    avatar.status = 'ready';
    avatar.confidence = 90;
    avatar.meshUrl = `https://cdn.fittwin.local/avatars/${avatar.id}.glb`;
    avatar.generatedAt = timestamp();
    avatar.updatedAt = timestamp();
    this.store.avatars.set(avatar.id, avatar);

    const eventId = generateId();
    this.store.analyticsEvents.set(eventId, {
      id: eventId,
      type: 'avatar.completed',
      createdAt: timestamp(),
      attributes: { avatarId: avatar.id, jobId: job.id }
    });
  }
}
