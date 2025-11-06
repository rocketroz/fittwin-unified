import { CartService } from 'src/modules/commerce/cart.service';
import { OrdersService } from 'src/modules/commerce/orders.service';
import { ProfileService } from 'src/modules/profiles/profile.service';
import { inMemoryStore } from 'src/lib/persistence/in-memory-store';

describe('Commerce Contracts', () => {
  let profileService: ProfileService;
  let ordersService: OrdersService;
  let cartService: CartService;

  beforeEach(() => {
    inMemoryStore.reset();
    profileService = new ProfileService();
    ordersService = new OrdersService();
    cartService = new CartService(ordersService);
  });

  async function seedCheckoutPrereqs() {
    const shipping = await profileService.addAddress({
      label: 'Primary Shipping',
      line1: '123 Fit Street',
      city: 'Austin',
      state: 'TX',
      postalCode: '73301',
      country: 'US',
      type: 'shipping',
    });

    const billing = await profileService.addAddress({
      label: 'Primary Billing',
      line1: '456 Fit Lane',
      city: 'Austin',
      state: 'TX',
      postalCode: '73301',
      country: 'US',
      type: 'billing',
    });

    const paymentMethod = await profileService.addPaymentMethod({
      paymentMethodId: 'pm_demo_123',
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

  it('POST /cart/items respects contract schema', async () => {
    const response = await cartService.addItem({
      productId: 'prod-core-tee',
      variantSku: 'FT-TEE-M',
      qty: 1,
      source: 'contract-test',
    });

    expect(response).toEqual(
      expect.objectContaining({
        cartId: expect.any(String),
        itemId: expect.any(String),
        item: expect.objectContaining({
          productId: 'prod-core-tee',
          variantSku: 'FT-TEE-M',
          name: expect.any(String),
          sizeLabel: expect.any(String),
          qty: 1,
          unitPrice: expect.any(Number),
          currency: 'USD',
          recommended: true,
          fitSummary: expect.objectContaining({
            confidence: expect.any(Number),
            notes: expect.arrayContaining([expect.any(String)]),
          }),
        }),
      })
    );
  });

  it('POST /checkout enforces PSP contract', async () => {
    const { shippingId, billingId, paymentToken } = await seedCheckoutPrereqs();
    const cart = await cartService.addItem({
      productId: 'prod-core-tee',
      variantSku: 'FT-TEE-M',
      qty: 1,
    });

    const result = await cartService.checkout({
      cartId: cart.cartId,
      paymentTokenId: paymentToken,
      shippingAddressId: shippingId,
      billingAddressId: billingId,
    });

    expect(result).toEqual(
      expect.objectContaining({
        orderId: expect.any(String),
        status: 'paid',
        paymentIntentRef: expect.stringContaining('pi_'),
        next: expect.objectContaining({
          brandFulfillmentEta: expect.any(String),
        }),
      })
    );
  });

  it('GET /orders/{id} returns order timeline contract', async () => {
    const { shippingId, billingId, paymentToken } = await seedCheckoutPrereqs();
    const cart = await cartService.addItem({
      productId: 'prod-core-tee',
      variantSku: 'FT-TEE-M',
      qty: 1,
    });

    const { orderId } = await cartService.checkout({
      cartId: cart.cartId,
      paymentTokenId: paymentToken,
      shippingAddressId: shippingId,
      billingAddressId: billingId,
    });

    const order = ordersService.getOrder(orderId);
    expect(order).toEqual(
      expect.objectContaining({
        id: orderId,
        totals: expect.objectContaining({
          subtotal: expect.any(Number),
          tax: expect.any(Number),
          shipping: expect.any(Number),
          currency: 'USD',
        }),
        items: expect.arrayContaining([
          expect.objectContaining({
            productId: 'prod-core-tee',
            quantity: 1,
            unitPriceCents: expect.any(Number),
          }),
        ]),
        timeline: expect.arrayContaining([
          expect.objectContaining({ status: 'paid', occurredAt: expect.any(String) }),
        ]),
      })
    );
  });
});
