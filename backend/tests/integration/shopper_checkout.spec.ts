import { inMemoryStore } from 'src/lib/persistence/in-memory-store';
import { ProfileService } from 'src/modules/profiles/profile.service';
import { AvatarService } from 'src/modules/profiles/avatar.service';
import { TryOnService } from 'src/modules/tryon/tryon.service';
import { OrdersService } from 'src/modules/commerce/orders.service';
import { CartService } from 'src/modules/commerce/cart.service';

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

describe('Scenario 1: Shopper signup → try-on → checkout', () => {
  let profileService: ProfileService;
  let ordersService: OrdersService;
  let cartService: CartService;
  let avatarService: AvatarService;
  let tryOnService: TryOnService;

  beforeAll(() => {
    avatarService = new AvatarService();
    tryOnService = new TryOnService();
  });

  beforeEach(() => {
    inMemoryStore.reset();
    profileService = new ProfileService();
    ordersService = new OrdersService();
    cartService = new CartService(ordersService);
  });

  async function seedCheckoutPrereqs() {
    const shipping = await profileService.addAddress({
      label: 'Ship',
      line1: '123 Fit Street',
      city: 'Austin',
      state: 'TX',
      postalCode: '73301',
      country: 'US',
      type: 'shipping',
    });

    const billing = await profileService.addAddress({
      label: 'Bill',
      line1: '456 Fit Lane',
      city: 'Austin',
      state: 'TX',
      postalCode: '73301',
      country: 'US',
      type: 'billing',
    });

    const paymentMethod = await profileService.addPaymentMethod({
      paymentMethodId: 'pm_checkout_demo',
      billingAddressId: billing.id,
      provider: 'stripe',
      brand: 'visa',
      lastFour: '4242',
    });

    return {
      shippingId: shipping.id,
      billingId: billing.id,
      paymentToken: paymentMethod.token,
    };
  }

  it('walks through signup, avatar, try-on, and checkout flow', async () => {
    const profile = await profileService.getProfile();
    expect(profile.userId).toBeDefined();

    const avatarJob = await avatarService.createAvatarJob({
      sources: { measurements: { waist: 72, chest: 96 } },
    });
    expect(avatarJob.avatarId).toBeDefined();

    await sleep(250); // allow the local queue to mark the avatar as ready
    const avatarStatus = await avatarService.getAvatarStatus(avatarJob.avatarId);
    expect(avatarStatus.status).toBe('ready');
    expect(avatarStatus.meshUrl).toContain(avatarJob.avatarId);

    const tryOnResult = await tryOnService.executeTryOn({
      productId: 'prod-core-tee',
      variantSku: 'FT-TEE-M',
      avatarId: avatarJob.avatarId,
    });
    expect(tryOnResult.sizeRec.confidence).toBeGreaterThanOrEqual(80);

    const tryOnId = Array.from(inMemoryStore.tryOnJobs.keys())[0];
    const polledTryOn = await tryOnService.pollTryOn(tryOnId);
    expect(polledTryOn.status).toBe('completed');

    const { shippingId, billingId, paymentToken } = await seedCheckoutPrereqs();
    const cart = await cartService.addItem({
      productId: 'prod-core-tee',
      variantSku: 'FT-TEE-M',
      qty: 1,
    });

    const checkout = await cartService.checkout({
      cartId: cart.cartId,
      paymentTokenId: paymentToken,
      shippingAddressId: shippingId,
      billingAddressId: billingId,
    });

    expect(checkout).toEqual(
      expect.objectContaining({
        orderId: expect.any(String),
        status: 'paid',
        paymentIntentRef: expect.stringContaining('pi_'),
      })
    );

    const order = ordersService.getOrder(checkout.orderId);
    expect(order.timeline).toEqual(
      expect.arrayContaining([expect.objectContaining({ status: 'paid' })])
    );
  });
});
