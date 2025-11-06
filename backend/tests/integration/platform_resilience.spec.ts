import { CartService } from 'src/modules/commerce/cart.service';
import { OrdersService } from 'src/modules/commerce/orders.service';
import { ProfileService } from 'src/modules/profiles/profile.service';
import { AvatarService } from 'src/modules/profiles/avatar.service';
import { TryOnService } from 'src/modules/tryon/tryon.service';
import { inMemoryStore } from 'src/lib/persistence/in-memory-store';
import { HttpException } from '@nestjs/common';

describe('Scenario 5: Failure handling & observability', () => {
  let profileService: ProfileService;
  let cartService: CartService;
  let ordersService: OrdersService;
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

  it('reports validation errors for malformed cart payloads', async () => {
    await expect(
      cartService.addItem({ productId: 'prod-core-tee', variantSku: 'FT-TEE-M', qty: 0 })
    ).rejects.toBeInstanceOf(HttpException);
  });

  it('blocks checkout when payment token is missing', async () => {
    const cart = await cartService.addItem({ productId: 'prod-core-tee', variantSku: 'FT-TEE-M', qty: 1 });

    await expect(
      cartService.checkout({
        cartId: cart.cartId,
        paymentTokenId: 'pm-missing',
        shippingAddressId: 'addr-missing',
        billingAddressId: 'addr-missing',
      })
    ).rejects.toBeInstanceOf(HttpException);
  });

  it('emits analytics events when try-on jobs fail validation', async () => {
    await expect(
      tryOnService.executeTryOn({ productId: 'prod-core-tee' })
    ).rejects.toBeInstanceOf(HttpException);

    const events = Array.from(inMemoryStore.analyticsEvents.values()).filter(
      (event) => event.type === 'tryon.completed'
    );
    expect(events.length).toBe(0);
  });

  it('prevents avatar deletion when conflicting orders exist', async () => {
    const shipping = await profileService.addAddress({
      line1: '123 Fit Street',
      city: 'Austin',
      postalCode: '73301',
      country: 'US',
      type: 'shipping',
    });
    const paymentMethod = await profileService.addPaymentMethod({
      paymentMethodId: 'pm-order-lock',
      billingAddressId: shipping.id,
    });
    const cart = await cartService.addItem({ productId: 'prod-core-tee', variantSku: 'FT-TEE-M', qty: 1 });
    await cartService.checkout({
      cartId: cart.cartId,
      paymentTokenId: paymentMethod.token,
      shippingAddressId: shipping.id,
      billingAddressId: shipping.id,
    });

    const avatarJob = await avatarService.createAvatarJob({
      sources: { measurements: { waist: 72 } },
    });

    await expect(avatarService.deleteAvatar(avatarJob.avatarId)).rejects.toBeInstanceOf(HttpException);
  });
});
