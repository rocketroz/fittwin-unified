import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import {
  inMemoryStore,
  generateId,
  timestamp,
  CartRecord,
  OrderItemRecord,
  OrderRecord,
  OrderStatus,
  ReferralRecord,
  RewardLedgerEntryRecord
} from '../../lib/persistence/in-memory-store';

interface ListOrdersQuery {
  status?: OrderStatus;
  page?: number;
  pageSize?: number;
}

interface CheckoutContext {
  cart: CartRecord;
  paymentTokenId: string;
  shippingAddressId: string;
  billingAddressId: string;
  rid?: string;
}

@Injectable()
export class OrdersService {
  private readonly store = inMemoryStore;

  createOrderFromCart(context: CheckoutContext) {
    const { cart, paymentTokenId, shippingAddressId, billingAddressId, rid } = context;

    if (!cart.items.length) {
      throw new HttpException(
        { error: { code: 'CART_EMPTY', message: 'Cart is empty.' } },
        HttpStatus.UNPROCESSABLE_ENTITY
      );
    }

    const shippingAddress = this.store.addresses.get(shippingAddressId);
    if (!shippingAddress) {
      throw new HttpException(
        { error: { code: 'SHIPPING_ADDRESS_REQUIRED', message: 'Shipping address is required.' } },
        HttpStatus.UNPROCESSABLE_ENTITY
      );
    }

    if (!this.store.paymentMethods.has(billingAddressId) && !this.store.addresses.has(billingAddressId)) {
      throw new HttpException(
        { error: { code: 'BILLING_ADDRESS_INVALID', message: 'Billing address not found.' } },
        HttpStatus.UNPROCESSABLE_ENTITY
      );
    }

    const paymentMethod = Array.from(this.store.paymentMethods.values()).find(
      (method) => method.token === paymentTokenId
    );
    if (!paymentMethod) {
      throw new HttpException(
        { error: { code: 'PAYMENT_METHOD_NOT_FOUND', message: 'Payment method not found.' } },
        HttpStatus.PAYMENT_REQUIRED
      );
    }

    let subtotal = 0;
    const orderItems: OrderItemRecord[] = cart.items.map((item) => {
      const variant = this.store.variants.get(item.variantId);
      if (!variant) {
        throw new HttpException(
          { error: { code: 'SKU_UNAVAILABLE', message: 'Variant unavailable during checkout.' } },
          HttpStatus.CONFLICT
        );
      }

      if (variant.stock < item.quantity) {
        throw new HttpException(
          { error: { code: 'SKU_OUT_OF_STOCK', message: 'Insufficient inventory for variant.' } },
          HttpStatus.CONFLICT
        );
      }

      variant.stock -= item.quantity;
      this.store.variants.set(variant.id, variant);

      const unitPrice = variant.priceCents;
      subtotal += unitPrice * item.quantity;

      return {
        id: generateId(),
        orderId: '',
        productId: item.productId,
        variantId: item.variantId,
        quantity: item.quantity,
        unitPriceCents: unitPrice,
        currency: variant.currency
      };
    });

    const tax = Math.round(subtotal * 0.0825);
    const shipping = subtotal > 10000 ? 0 : 1200;
    const total = subtotal + tax + shipping;

    const orderId = generateId();
    const paymentIntentRef = `pi_${generateId()}`;
    const now = timestamp();

    const referral = rid ? this.resolveReferral(rid) : undefined;

    const order: OrderRecord = {
      id: orderId,
      userId: cart.userId,
      status: 'paid',
      totalCents: total,
      subtotalCents: subtotal,
      taxCents: tax,
      shippingCents: shipping,
      currency: 'USD',
      createdAt: now,
      updatedAt: now,
      referralId: referral?.id,
      lineItems: orderItems.map((item) => ({ ...item, orderId })),
      shippingAddressId,
      paymentMethodId: paymentMethod.id
    };

    this.store.orders.set(orderId, order);

    if (referral) {
      const ledger: RewardLedgerEntryRecord = {
        id: generateId(),
        referralId: referral.id,
        orderId,
        amountCents: Math.round(total * 0.05),
        status: 'pending',
        createdAt: now
      };
      this.store.rewardLedger.set(ledger.id, ledger);

      const eventId = generateId();
      this.store.referralEvents.set(eventId, {
        id: eventId,
        referralId: referral.id,
        type: 'PURCHASE',
        orderId,
        metadata: { userId: cart.userId, rid },
        createdAt: now
      });
    }

    cart.items = [];
    cart.updatedAt = now;
    this.store.carts.set(cart.id, cart);

    return {
      orderId,
      status: order.status,
      paymentIntentRef,
      next: {
        tracking: null,
        brandFulfillmentEta: new Date(Date.now() + 1000 * 60 * 60 * 24 * 5).toISOString().split('T')[0]
      }
    };
  }

  getOrder(orderId: string) {
    const order = this.store.orders.get(orderId);
    if (!order) {
      throw new HttpException(
        { error: { code: 'ORDER_NOT_FOUND', message: 'Order not found.' } },
        HttpStatus.NOT_FOUND
      );
    }

    const items = order.lineItems.map((item) => ({
      ...item,
      product: this.store.products.get(item.productId),
      variant: this.store.variants.get(item.variantId)
    }));

    return {
      ...order,
      totals: {
        subtotal: order.subtotalCents ?? items.reduce((sum, item) => sum + item.unitPriceCents * item.quantity, 0),
        tax: order.taxCents ?? Math.round((order.subtotalCents ?? 0) * 0.0825),
        shipping: order.shippingCents ?? 0,
        currency: order.currency
      },
      items,
      timeline: [
        { status: 'paid', occurredAt: order.createdAt },
        { status: 'sent_to_brand', occurredAt: order.createdAt }
      ]
    };
  }

  listOrders(query: ListOrdersQuery = {}) {
    const page = query.page ?? 1;
    const pageSize = Math.min(query.pageSize ?? 10, 50);
    const allOrders = Array.from(this.store.orders.values()).filter((order) =>
      query.status ? order.status === query.status : true
    );

    const start = (page - 1) * pageSize;
    const items = allOrders.slice(start, start + pageSize).map((order) => this.getOrder(order.id));

    return {
      page,
      pageSize,
      totalCount: allOrders.length,
      items
    };
  }

  updateOrderStatus(orderId: string, status: OrderStatus) {
    const order = this.store.orders.get(orderId);
    if (!order) {
      throw new HttpException(
        { error: { code: 'ORDER_NOT_FOUND', message: 'Order not found.' } },
        HttpStatus.NOT_FOUND
      );
    }

    order.status = status;
    order.updatedAt = timestamp();
    this.store.orders.set(orderId, order);
    return order;
  }

  handleWebhook(event: Record<string, unknown>) {
    const eventId = generateId();
    this.store.analyticsEvents.set(eventId, {
      id: eventId,
      type: 'orders.webhook_received',
      createdAt: timestamp(),
      attributes: event
    });
    return { received: true };
  }

  private resolveReferral(rid: string): ReferralRecord | undefined {
    const referral = Array.from(this.store.referrals.values()).find((record) => record.code === rid);
    if (!referral) {
      return undefined;
    }

    this.store.referrals.set(referral.id, referral);
    return referral;
  }
}
