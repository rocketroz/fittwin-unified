import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import {
  inMemoryStore,
  generateId,
  timestamp,
  CartRecord,
  CartItemRecord,
  ProductRecord,
  ProductVariantRecord,
  CheckoutIntentRecord
} from '../../lib/persistence/in-memory-store';
import { OrdersService } from './orders.service';
import { hashPassword } from '../../lib/security/password';
import { stableStringify } from '../../lib/security/stable-stringify';

interface AddItemPayload {
  productId?: string;
  variantSku?: string;
  qty?: number;
  source?: string;
}

interface UpdateItemPayload {
  qty?: number;
  variantSku?: string;
}

interface CheckoutPayload {
  cartId?: string;
  paymentTokenId?: string;
  shippingAddressId?: string;
  billingAddressId?: string;
  rid?: string;
  idempotencyKey?: string;
}

@Injectable()
export class CartService {
  private readonly store = inMemoryStore;

  constructor(private readonly ordersService: OrdersService) {}

  async addItem(rawPayload: Record<string, unknown>) {
    const payload = rawPayload as AddItemPayload;
    if (!payload.productId || !payload.variantSku) {
      throw new HttpException(
        { error: { code: 'CART_INVALID_PAYLOAD', message: 'productId and variantSku are required.' } },
        HttpStatus.UNPROCESSABLE_ENTITY
      );
    }

    const quantity = payload.qty ?? 1;
    if (quantity <= 0 || quantity > 5) {
      throw new HttpException(
        { error: { code: 'CART_INVALID_QUANTITY', message: 'Quantity must be between 1 and 5.' } },
        HttpStatus.UNPROCESSABLE_ENTITY
      );
    }

    const product = this.ensureProduct(payload.productId);
    const variant = this.resolveVariant(product, payload.variantSku);
    if (variant.stock < quantity) {
      throw new HttpException(
        { error: { code: 'SKU_UNAVAILABLE', message: 'Insufficient inventory for variant.' } },
        HttpStatus.CONFLICT
      );
    }

    const cart = this.ensureCart();
    const existingItem = cart.items.find((item) => item.variantId === variant.id);
    if (existingItem) {
      existingItem.quantity = Math.min(existingItem.quantity + quantity, 5);
      cart.updatedAt = timestamp();
      this.store.carts.set(cart.id, cart);
      return this.formatAddItemResponse(cart, existingItem, product, variant);
    }

    const item: CartItemRecord = {
      id: generateId(),
      productId: product.id,
      variantId: variant.id,
      variantSku: variant.sku,
      quantity
    };

    cart.items.push(item);
    cart.updatedAt = timestamp();
    this.store.carts.set(cart.id, cart);

    return this.formatAddItemResponse(cart, item, product, variant);
  }

  async updateItem(itemId: string, rawPayload: Record<string, unknown>) {
    const payload = rawPayload as UpdateItemPayload;
    const cart = this.ensureCart();
    const item = cart.items.find((record) => record.id === itemId);
    if (!item) {
      throw new HttpException(
        { error: { code: 'CART_ITEM_NOT_FOUND', message: 'Cart item not found.' } },
        HttpStatus.NOT_FOUND
      );
    }

    if (payload.qty !== undefined) {
      if (payload.qty <= 0) {
        cart.items = cart.items.filter((record) => record.id !== itemId);
      } else {
        item.quantity = Math.min(payload.qty, 5);
      }
    }

    if (payload.variantSku) {
      const product = this.store.products.get(item.productId);
      if (!product) {
        throw new HttpException(
          { error: { code: 'CART_PRODUCT_NOT_FOUND', message: 'Product not found.' } },
          HttpStatus.NOT_FOUND
        );
      }
      const variant = this.resolveVariant(product, payload.variantSku);
      item.variantId = variant.id;
      item.variantSku = variant.sku;
    }

    cart.updatedAt = timestamp();
    this.store.carts.set(cart.id, cart);
    return this.getCart();
  }

  async removeItem(itemId: string) {
    const cart = this.ensureCart();
    const initialCount = cart.items.length;
    cart.items = cart.items.filter((record) => record.id !== itemId);
    if (cart.items.length === initialCount) {
      throw new HttpException(
        { error: { code: 'CART_ITEM_NOT_FOUND', message: 'Cart item not found.' } },
        HttpStatus.NOT_FOUND
      );
    }
    cart.updatedAt = timestamp();
    this.store.carts.set(cart.id, cart);
  }

  async getCart() {
    const cart = this.ensureCart();
    return this.formatCart(cart);
  }

  async checkout(rawPayload: Record<string, unknown>) {
    const payload = rawPayload as CheckoutPayload;
    const cart = this.ensureCart(payload.cartId);

    if (!payload.paymentTokenId || !payload.shippingAddressId || !payload.billingAddressId) {
      throw new HttpException(
        { error: { code: 'CHECKOUT_INVALID', message: 'Payment token and addresses are required.' } },
        HttpStatus.UNPROCESSABLE_ENTITY
      );
    }

    const idempotencyKey = payload.idempotencyKey ?? generateId();
    const payloadHash = stableStringify({ ...payload, cartId: cart.id });
    const existingIntent = this.store.checkoutIntents.get(idempotencyKey);
    if (existingIntent) {
      if (existingIntent.payloadHash !== payloadHash) {
        throw new HttpException(
          { error: { code: 'CHECKOUT_IDEMPOTENCY_CONFLICT', message: 'Payload differs for existing idempotency key.' } },
          HttpStatus.CONFLICT
        );
      }
      const existingOrder = this.store.orders.get(existingIntent.orderId);
      if (existingOrder) {
        return {
          orderId: existingOrder.id,
          status: existingOrder.status,
          paymentIntentRef: existingIntent.paymentIntentRef,
          next: {
            tracking: null,
            brandFulfillmentEta: new Date(Date.now() + 1000 * 60 * 60 * 24 * 5).toISOString().split('T')[0]
          }
        };
      }
    }

    const checkoutResult = this.ordersService.createOrderFromCart({
      cart,
      paymentTokenId: payload.paymentTokenId,
      shippingAddressId: payload.shippingAddressId,
      billingAddressId: payload.billingAddressId,
      rid: payload.rid
    });

    const intent: CheckoutIntentRecord = {
      idempotencyKey,
      payloadHash,
      orderId: checkoutResult.orderId,
      createdAt: timestamp(),
      paymentIntentRef: checkoutResult.paymentIntentRef
    };
    this.store.checkoutIntents.set(idempotencyKey, intent);

    return checkoutResult;
  }

  private ensureCart(cartId?: string): CartRecord {
    const userId = this.ensureUser();
    if (cartId) {
      const cart = this.store.carts.get(cartId);
      if (!cart) {
        throw new HttpException(
          { error: { code: 'CART_NOT_FOUND', message: 'Cart not found.' } },
          HttpStatus.NOT_FOUND
        );
      }
      return cart;
    }

    let cart = Array.from(this.store.carts.values()).find((record) => record.userId === userId);
    if (!cart) {
      cart = {
        id: generateId(),
        userId,
        items: [],
        updatedAt: timestamp()
      };
      this.store.carts.set(cart.id, cart);
    }
    return cart;
  }

  private ensureProduct(productId: string): ProductRecord {
    const product = this.store.products.get(productId);
    if (product) {
      return product;
    }

    const brandId = generateId();
    this.store.brands.set(brandId, {
      id: brandId,
      name: 'Core Fit Brand',
      slug: 'core-fit',
      onboarded: true,
      createdAt: timestamp(),
      updatedAt: timestamp()
    });

    const record: ProductRecord = {
      id: productId,
      brandId,
      name: 'Core Fit Tee',
      description: 'Lightweight tee optimized for FitTwin try-on.',
      heroImageUrl: 'https://cdn.fittwin.local/products/core-fit-tee.png',
      active: true,
      sizeChartId: undefined,
      fitMapId: undefined,
      createdAt: timestamp(),
      updatedAt: timestamp()
    };
    this.store.products.set(productId, record);

    const variant: ProductVariantRecord = {
      id: generateId(),
      productId,
      sku: 'FT-TEE-M',
      label: 'M',
      attributes: { chest: 100, waist: 82 },
      stock: 50,
      priceCents: 4200,
      currency: 'USD',
      createdAt: timestamp(),
      updatedAt: timestamp()
    };
    this.store.variants.set(variant.id, variant);

    const altVariant: ProductVariantRecord = {
      id: generateId(),
      productId,
      sku: 'FT-TEE-L',
      label: 'L',
      attributes: { chest: 106, waist: 88 },
      stock: 30,
      priceCents: 4200,
      currency: 'USD',
      createdAt: timestamp(),
      updatedAt: timestamp()
    };
    this.store.variants.set(altVariant.id, altVariant);

    return record;
  }

  private resolveVariant(product: ProductRecord, variantSku: string): ProductVariantRecord {
    const variants = Array.from(this.store.variants.values()).filter((variant) => variant.productId === product.id);
    const match = variants.find((variant) => variant.sku === variantSku);
    if (!match) {
      throw new HttpException(
        { error: { code: 'SKU_UNAVAILABLE', message: 'Variant SKU not recognized for product.' } },
        HttpStatus.UNPROCESSABLE_ENTITY
      );
    }
    return match;
  }

  private ensureUser(): string {
    const existingUser = Array.from(this.store.users.values())[0];
    if (existingUser) {
      return existingUser.id;
    }

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

  private formatCart(cart: CartRecord) {
    const items = cart.items.map((item) => {
      const product = this.store.products.get(item.productId);
      const variant = this.store.variants.get(item.variantId);
      return {
        itemId: item.id,
        productId: item.productId,
        variantSku: item.variantSku,
        name: product?.name ?? 'Unknown product',
        sizeLabel: variant?.label ?? 'N/A',
        qty: item.quantity,
        unitPrice: variant?.priceCents ?? 0,
        currency: variant?.currency ?? 'USD',
        recommended: true,
        fitSummary: { confidence: 88, notes: ['waist snug'] }
      };
    });

    const subtotal = items.reduce((sum, item) => sum + (item.unitPrice ?? 0) * item.qty, 0);
    const tax = Math.round(subtotal * 0.0825);
    const shipping = subtotal > 10000 ? 0 : 1200;

    return {
      cartId: cart.id,
      items,
      totals: {
        subtotal,
        shipping,
        tax,
        currency: 'USD'
      },
      recommendations: items.slice(0, 1).map((item) => ({ productId: item.productId, sizeRec: item.sizeLabel }))
    };
  }

  private formatAddItemResponse(
    cart: CartRecord,
    item: CartItemRecord,
    product: ProductRecord,
    variant: ProductVariantRecord
  ) {
    return {
      cartId: cart.id,
      itemId: item.id,
      item: {
        productId: product.id,
        variantSku: variant.sku,
        name: product.name,
        sizeLabel: variant.label,
        qty: item.quantity,
        unitPrice: variant.priceCents,
        currency: variant.currency,
        recommended: true,
        fitSummary: { confidence: 88, notes: ['waist snug'] }
      }
    };
  }
}
