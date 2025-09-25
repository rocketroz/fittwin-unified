import { randomUUID } from 'crypto';

export type VerificationStatus = 'verification_pending' | 'active' | 'locked';

export interface UserRecord {
  id: string;
  email: string;
  passwordHash: string;
  passwordSalt: string;
  status: VerificationStatus;
  consent: {
    terms: boolean;
    marketing: boolean;
    privacy: boolean;
  };
  createdAt: string;
  updatedAt: string;
  failedAttempts: number;
  lastLoginAt?: string;
}

export interface RefreshTokenRecord {
  token: string;
  userId: string;
  deviceFingerprint?: string;
  issuedAt: string;
  expiresAt: string;
  revoked: boolean;
}

export interface VerificationTokenRecord {
  token: string;
  userId: string;
  expiresAt: string;
}

export interface AddressRecord {
  id: string;
  userId: string;
  label: string;
  line1: string;
  line2?: string;
  city: string;
  state?: string;
  postalCode: string;
  country: string;
  type: 'billing' | 'shipping';
  createdAt: string;
  updatedAt: string;
}

export interface PaymentMethodRecord {
  id: string;
  userId: string;
  provider: string;
  lastFour: string;
  brand: string;
  expiresAt: string;
  token: string;
  createdAt: string;
  updatedAt: string;
  default: boolean;
}

export interface ProfileRecord {
  userId: string;
  email: string;
  username: string;
  appearance: Record<string, unknown>;
  stylePreferences: Record<string, unknown>;
  bodyMetrics: {
    heightCm?: number;
    weightKg?: number;
    measurements?: Record<string, number>;
  };
  consents: {
    marketing: boolean;
    dataExportAvailable: boolean;
  };
  avatars: string[];
  updatedAt: string;
}

export type AvatarStatus = 'queued' | 'processing' | 'ready' | 'failed' | 'deleted';

export interface AvatarRecord {
  id: string;
  userId: string;
  version: number;
  status: AvatarStatus;
  confidence: number;
  meshUrl?: string;
  generatedAt?: string;
  updatedAt: string;
  source?: {
    measurements?: Record<string, number>;
    photos?: string[];
  };
}

export interface ProductRecord {
  id: string;
  brandId: string;
  name: string;
  description: string;
  heroImageUrl: string;
  sizeChartId?: string;
  fitMapId?: string;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ProductVariantRecord {
  id: string;
  productId: string;
  sku: string;
  label: string;
  attributes: Record<string, unknown>;
  stock: number;
  priceCents: number;
  currency: string;
  createdAt: string;
  updatedAt: string;
}

export interface SizeChartRecord {
  id: string;
  brandId: string;
  name: string;
  rows: Array<Record<string, number | string>>;
  createdAt: string;
}

export interface FitMapRecord {
  id: string;
  productId: string;
  avatarMetrics: Record<string, number>;
  fitNotes: Record<string, string>;
  createdAt: string;
}

export type OrderStatus =
  | 'created'
  | 'payment_pending'
  | 'paid'
  | 'sent_to_brand'
  | 'fulfilled'
  | 'delivered'
  | 'cancelled'
  | 'refunded';

export interface OrderItemRecord {
  id: string;
  orderId: string;
  productId: string;
  variantId: string;
  quantity: number;
  unitPriceCents: number;
  currency: string;
}

export interface OrderRecord {
  id: string;
  userId: string;
  status: OrderStatus;
  totalCents: number;
  subtotalCents?: number;
  taxCents?: number;
  shippingCents?: number;
  currency: string;
  createdAt: string;
  updatedAt: string;
  referralId?: string;
  lineItems: OrderItemRecord[];
  shippingAddressId?: string;
  paymentMethodId?: string;
}

export interface CartItemRecord {
  id: string;
  productId: string;
  variantId: string;
  variantSku: string;
  quantity: number;
}

export interface CartRecord {
  id: string;
  userId: string;
  items: CartItemRecord[];
  updatedAt: string;
}

export interface ReferralRecord {
  id: string;
  userId: string;
  code: string;
  url: string;
  productId?: string;
  status: 'active' | 'expired' | 'revoked';
  expiresAt: string;
  clicks: number;
  conversions: number;
  gmvCents: number;
  policy: {
    rewardType: string;
    rewardValue: number;
    currency: string;
    holdDays: number;
  };
  createdAt: string;
  totalRewardsCents: number;
}

export interface ReferralEventRecord {
  id: string;
  referralId: string;
  type: 'CLICK' | 'PURCHASE' | 'REWARD_RELEASED';
  orderId?: string;
  metadata?: Record<string, unknown>;
  createdAt: string;
}

export interface RewardLedgerEntryRecord {
  id: string;
  referralId: string;
  orderId: string;
  amountCents: number;
  status: 'pending' | 'released' | 'revoked';
  createdAt: string;
}

export interface BrandRecord {
  id: string;
  name: string;
  slug: string;
  onboarded: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface BrandUserRecord {
  id: string;
  brandId: string;
  email: string;
  role: 'owner' | 'manager' | 'analyst';
  createdAt: string;
}

export interface AnalyticsEventRecord {
  id: string;
  type: string;
  createdAt: string;
  attributes: Record<string, unknown>;
}

export interface TryOnJobRecord {
  id: string;
  userId?: string;
  avatarId?: string;
  productId: string;
  variantId?: string;
  status: 'queued' | 'processing' | 'completed' | 'failed';
  createdAt: string;
  updatedAt: string;
  result?: Record<string, unknown>;
  errorCode?: string;
}

export interface DataExportJobRecord {
  id: string;
  userId: string;
  status: 'processing' | 'ready';
  requestedAt: string;
  completedAt?: string;
  downloadUrl?: string;
}

export interface CheckoutIntentRecord {
  idempotencyKey: string;
  payloadHash: string;
  orderId: string;
  createdAt: string;
  paymentIntentRef: string;
}

export interface CatalogIngestJobRecord {
  id: string;
  brandId: string;
  fileUrl: string;
  status: 'processing' | 'completed' | 'failed';
  schemaVersion: string;
  createdAt: string;
  completedAt?: string;
  errors?: Array<{ row: number; message: string }>;
}

function nowIso(): string {
  return new Date().toISOString();
}

export class InMemoryStore {
  private static instance: InMemoryStore;

  static shared(): InMemoryStore {
    if (!InMemoryStore.instance) {
      InMemoryStore.instance = new InMemoryStore();
    }
    return InMemoryStore.instance;
  }

  readonly users = new Map<string, UserRecord>();
  readonly refreshTokens = new Map<string, RefreshTokenRecord>();
  readonly verificationTokens = new Map<string, VerificationTokenRecord>();
  readonly profiles = new Map<string, ProfileRecord>();
  readonly avatars = new Map<string, AvatarRecord>();
  readonly products = new Map<string, ProductRecord>();
  readonly variants = new Map<string, ProductVariantRecord>();
  readonly sizeCharts = new Map<string, SizeChartRecord>();
  readonly fitMaps = new Map<string, FitMapRecord>();
  readonly carts = new Map<string, CartRecord>();
  readonly orders = new Map<string, OrderRecord>();
  readonly addresses = new Map<string, AddressRecord>();
  readonly paymentMethods = new Map<string, PaymentMethodRecord>();
  readonly referrals = new Map<string, ReferralRecord>();
  readonly referralEvents = new Map<string, ReferralEventRecord>();
  readonly rewardLedger = new Map<string, RewardLedgerEntryRecord>();
  readonly brands = new Map<string, BrandRecord>();
  readonly brandUsers = new Map<string, BrandUserRecord>();
  readonly analyticsEvents = new Map<string, AnalyticsEventRecord>();
  readonly tryOnJobs = new Map<string, TryOnJobRecord>();
  readonly dataExportJobs = new Map<string, DataExportJobRecord>();
  readonly checkoutIntents = new Map<string, CheckoutIntentRecord>();
  readonly catalogIngestJobs = new Map<string, CatalogIngestJobRecord>();

  reset(): void {
    this.users.clear();
    this.refreshTokens.clear();
    this.verificationTokens.clear();
    this.profiles.clear();
    this.avatars.clear();
    this.products.clear();
    this.variants.clear();
    this.sizeCharts.clear();
    this.fitMaps.clear();
    this.carts.clear();
    this.orders.clear();
    this.addresses.clear();
    this.paymentMethods.clear();
    this.referrals.clear();
    this.referralEvents.clear();
    this.rewardLedger.clear();
    this.brands.clear();
    this.brandUsers.clear();
    this.analyticsEvents.clear();
    this.tryOnJobs.clear();
    this.dataExportJobs.clear();
    this.checkoutIntents.clear();
    this.catalogIngestJobs.clear();
  }

  seedDefaultBrand(): void {
    if (this.brands.size > 0) {
      return;
    }
    const brandId = randomUUID();
    this.brands.set(brandId, {
      id: brandId,
      name: 'Core Fit Brand',
      slug: 'core-fit-brand',
      onboarded: true,
      createdAt: nowIso(),
      updatedAt: nowIso()
    });
  }
}

export const inMemoryStore = InMemoryStore.shared();

export function generateId(): string {
  return randomUUID();
}

export function timestamp(): string {
  return nowIso();
}
