import { ReferralService } from 'src/modules/referrals/referral.service';
import { inMemoryStore } from 'src/lib/persistence/in-memory-store';

describe('Scenario 4: Referral attribution & rewards', () => {
  let referralService: ReferralService;

  beforeEach(() => {
    inMemoryStore.reset();
    referralService = new ReferralService();
  });

  it('covers RID sharing, attribution, and reward ledger transitions', () => {
    const referral = referralService.createReferral({ productId: 'prod-core-tee' });

    expect(referral).toEqual(
      expect.objectContaining({
        rid: expect.any(String),
        shareUrl: expect.stringContaining('?rid='),
        expiresAt: expect.any(String),
      })
    );

    const attribution = referralService.validateReferral({
      rid: referral.rid,
      userId: 'shopper-guest',
      orderId: 'order-123',
    });

    expect(attribution).toEqual(
      expect.objectContaining({
        valid: true,
        attribution: 'first_click',
        reason: null,
      })
    );

    const storedReferral = referralService.getReferral(referral.rid);
    expect(storedReferral.clicks).toBe(1);
    expect(storedReferral.rewards).toEqual({ pendingHold: 0, payable: 0, paid: 0 });
    expect(inMemoryStore.referralEvents.size).toBe(1);
  });
});
