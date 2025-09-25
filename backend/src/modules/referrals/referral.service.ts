import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import {
  inMemoryStore,
  generateId,
  timestamp,
  ReferralRecord,
  ReferralEventRecord
} from '../../lib/persistence/in-memory-store';
import { hashPassword } from '../../lib/security/password';

interface CreateReferralPayload {
  productId?: string;
  channel?: string;
}

interface ValidateReferralPayload {
  rid?: string;
  orderId?: string;
  userId?: string;
  deviceFingerprint?: string;
  ip?: string;
}

@Injectable()
export class ReferralService {
  private readonly store = inMemoryStore;

  createReferral(rawPayload: Record<string, unknown>) {
    const payload = rawPayload as CreateReferralPayload;
    if (!payload.productId) {
      throw new HttpException(
        { error: { code: 'RID_PRODUCT_REQUIRED', message: 'productId is required.' } },
        HttpStatus.BAD_REQUEST
      );
    }

    const userId = this.ensureUser();
    const activeReferralsToday = Array.from(this.store.referrals.values()).filter((referral) => {
      return referral.userId === userId && Date.now() - new Date(referral.createdAt).getTime() < 1000 * 60 * 60 * 24;
    });
    if (activeReferralsToday.length >= 10) {
      throw new HttpException(
        { error: { code: 'RID_RATE_LIMITED', message: 'Daily referral limit reached.' } },
        HttpStatus.TOO_MANY_REQUESTS
      );
    }

    const existing = Array.from(this.store.referrals.values()).find(
      (referral) => referral.userId === userId && referral.productId === payload.productId && referral.status === 'active'
    );
    if (existing) {
      return {
        rid: existing.code,
        shareUrl: existing.url,
        expiresAt: existing.expiresAt,
        policy: existing.policy,
        conflict: true
      };
    }

    const codeSource = `${userId}:${payload.productId}:${Date.now()}`;
    const rid = Buffer.from(codeSource).toString('base64url');
    const url = `https://app.fittwin.com/p/${payload.productId}?rid=${rid}`;
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30).toISOString();

    const record: ReferralRecord = {
      id: generateId(),
      userId,
      code: rid,
      url,
      productId: payload.productId,
      status: 'active',
      expiresAt,
      clicks: 0,
      conversions: 0,
      gmvCents: 0,
      policy: {
        rewardType: 'storeCredit',
        rewardValue: 1000,
        currency: 'USD',
        holdDays: 30
      },
      createdAt: timestamp(),
      totalRewardsCents: 0
    };

    this.store.referrals.set(record.id, record);

    return {
      rid,
      shareUrl: url,
      expiresAt,
      policy: record.policy
    };
  }

  getReferral(rid: string) {
    const referral = this.findReferralByCode(rid);
    if (!referral) {
      throw new HttpException(
        { error: { code: 'RID_NOT_FOUND', message: 'Referral link not found.' } },
        HttpStatus.NOT_FOUND
      );
    }

    return {
      rid: referral.code,
      clicks: referral.clicks,
      conversions: referral.conversions,
      gmv: referral.gmvCents,
      status: referral.status,
      expiresAt: referral.expiresAt,
      rewards: this.computeRewards(referral)
    };
  }

  listEvents(rid: string) {
    const referral = this.findReferralByCode(rid);
    if (!referral) {
      throw new HttpException(
        { error: { code: 'RID_NOT_FOUND', message: 'Referral link not found.' } },
        HttpStatus.NOT_FOUND
      );
    }

    const events = Array.from(this.store.referralEvents.values())
      .filter((event) => event.referralId === referral.id)
      .map((event) => ({
        eventId: event.id,
        eventType: event.type.toLowerCase(),
        timestamp: event.createdAt,
        orderId: event.orderId
      }));

    return {
      events,
      nextCursor: null
    };
  }

  validateReferral(rawPayload: Record<string, unknown>) {
    const payload = rawPayload as ValidateReferralPayload;
    if (!payload.rid) {
      throw new HttpException(
        { error: { code: 'RID_REQUIRED', message: 'rid is required.' } },
        HttpStatus.BAD_REQUEST
      );
    }

    const referral = this.findReferralByCode(payload.rid);
    if (!referral || referral.status !== 'active') {
      return { valid: false, attribution: null, reason: 'RID_EXPIRED' };
    }

    if (new Date(referral.expiresAt).getTime() < Date.now()) {
      referral.status = 'expired';
      this.store.referrals.set(referral.id, referral);
      return { valid: false, attribution: null, reason: 'RID_EXPIRED' };
    }

    if (payload.userId && payload.userId === referral.userId) {
      return { valid: false, attribution: null, reason: 'RID_SELF_PURCHASE_BLOCKED' };
    }

    referral.clicks += 1;
    this.store.referrals.set(referral.id, referral);

    const event: ReferralEventRecord = {
      id: generateId(),
      referralId: referral.id,
      type: 'CLICK',
      metadata: {
        channel: 'checkout_validation',
        deviceFingerprint: payload.deviceFingerprint,
        ip: payload.ip
      },
      createdAt: timestamp(),
      orderId: payload.orderId
    };
    this.store.referralEvents.set(event.id, event);

    return { valid: true, attribution: 'first_click', reason: null };
  }

  private computeRewards(referral: ReferralRecord) {
    const ledgerEntries = Array.from(this.store.rewardLedger.values()).filter(
      (entry) => entry.referralId === referral.id
    );
    return {
      pendingHold: ledgerEntries.filter((entry) => entry.status === 'pending').length,
      payable: ledgerEntries.filter((entry) => entry.status === 'released').length,
      paid: ledgerEntries.filter((entry) => entry.status === 'revoked').length
    };
  }

  private findReferralByCode(rid: string) {
    return Array.from(this.store.referrals.values()).find((record) => record.code === rid);
  }

  private ensureUser(): string {
    const existingUser = Array.from(this.store.users.values())[0];
    if (existingUser) {
      return existingUser.id;
    }

    const userId = generateId();
    const email = 'demo@fittwin.local';
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

    this.store.profiles.set(userId, {
      userId,
      email,
      username: 'fitfan',
      appearance: {},
      stylePreferences: {},
      bodyMetrics: {},
      consents: { marketing: false, dataExportAvailable: false },
      avatars: [],
      updatedAt: now
    });

    return userId;
  }
}
