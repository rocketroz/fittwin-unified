import { ReferralService } from 'src/modules/referrals/referral.service';
import { inMemoryStore } from 'src/lib/persistence/in-memory-store';

describe('Referrals Contracts', () => {
  let referralService: ReferralService;

  beforeEach(() => {
    inMemoryStore.reset();
    referralService = new ReferralService();
  });

  it('POST /referrals issues RID contract', () => {
    const referral = referralService.createReferral({ productId: 'prod-core-tee' });

    expect(referral).toEqual(
      expect.objectContaining({
        rid: expect.any(String),
        shareUrl: expect.stringContaining('?rid='),
        expiresAt: expect.any(String),
      })
    );

    const stored = referralService.getReferral(referral.rid);
    expect(stored.status).toBe('active');
  });

  it('POST /referrals/validate enforces fraud policy contract', () => {
    const referral = referralService.createReferral({ productId: 'prod-core-tee' });
    const referrer = Array.from(inMemoryStore.users.values())[0];
    expect(referrer).toBeDefined();
    const referrerId = referrer!.id;

    const selfPurchase = referralService.validateReferral({ rid: referral.rid, userId: referrerId });
    expect(selfPurchase).toEqual(
      expect.objectContaining({
        valid: false,
        reason: 'RID_SELF_PURCHASE_BLOCKED',
      })
    );

    const guestPurchase = referralService.validateReferral({ rid: referral.rid, userId: 'guest-001' });
    expect(guestPurchase).toEqual(
      expect.objectContaining({
        valid: true,
        attribution: 'first_click',
      })
    );
  });
});
