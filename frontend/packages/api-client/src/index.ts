const BACKEND_BASE = process.env.NEXT_PUBLIC_BACKEND_BASE_URL;
const PROXY_BASE = process.env.NEXT_PUBLIC_API_PROXY_BASE ?? '/api/backend';

const buildUrl = (path: string) => {
  if (BACKEND_BASE) {
    return `${BACKEND_BASE}${path}`;
  }
  return `${PROXY_BASE}${path}`;
};

interface RequestOptions {
  accessToken?: string;
  init?: RequestInit;
  parseJson?: boolean;
}

async function request<T = unknown>(path: string, options: RequestOptions = {}): Promise<T> {
  const { accessToken, init = {}, parseJson = true } = options;
  const headers = new Headers(init.headers);

  if (init.body && !headers.has('content-type') && !(init.body instanceof FormData)) {
    headers.set('content-type', 'application/json');
  }

  if (accessToken) {
    headers.set('authorization', `Bearer ${accessToken}`);
  }

  const response = await fetch(buildUrl(path), {
    ...init,
    headers,
    cache: 'no-store',
  });

  if (!response.ok) {
    let errorMessage = `${response.status} ${response.statusText}`;
    try {
      const payload = await response.json();
      errorMessage = payload?.error?.message ?? JSON.stringify(payload);
    } catch (error) {
      // Ignore JSON parse errors – default message will surface.
    }
    throw new Error(errorMessage);
  }

  if (!parseJson || response.status === 204) {
    return undefined as T;
  }

  const contentType = response.headers.get('content-type') ?? '';
  if (!contentType.includes('application/json')) {
    return undefined as T;
  }

  return (await response.json()) as T;
}

export interface SignupPayload {
  email: string;
  password: string;
  consent: {
    terms: boolean;
    marketing: boolean;
    privacy: boolean;
  };
}

export interface SignupResponse {
  userId: string;
  status: string;
  verificationToken: string;
}

export function signup(payload: SignupPayload) {
  return request<SignupResponse>('/auth/signup', {
    init: {
      method: 'POST',
      body: JSON.stringify(payload),
    },
    parseJson: true,
  });
}

export function verifyEmail(token: string) {
  return request<void>('/auth/verify', {
    init: {
      method: 'POST',
      body: JSON.stringify({ token }),
    },
    parseJson: false,
  });
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  mfaRequired: boolean;
}

export function login(email: string, password: string) {
  return request<LoginResponse>('/auth/login', {
    init: {
      method: 'POST',
      body: JSON.stringify({ email, password, device: { name: 'MVP Demo', fingerprint: 'demo-device' } }),
    },
  });
}

export function refresh(refreshToken: string, deviceFingerprint?: string) {
  return request<LoginResponse>('/auth/refresh', {
    init: {
      method: 'POST',
      body: JSON.stringify({ refreshToken, deviceFingerprint }),
    },
  });
}

export function logout(refreshToken: string) {
  return request<void>('/auth/logout', {
    init: {
      method: 'POST',
      body: JSON.stringify({ refreshToken }),
    },
    parseJson: false,
  });
}

export interface ProfileResponse {
  userId: string;
  email: string;
  username: string;
  appearance: Record<string, unknown>;
  stylePreferences: Record<string, unknown>;
  bodyMetrics: Record<string, unknown>;
  avatars: Array<Record<string, unknown>>;
  addresses: Array<Record<string, unknown>>;
  paymentMethods: Array<Record<string, unknown>>;
  consents: Record<string, unknown>;
}

export function getProfile(accessToken: string) {
  return request<ProfileResponse>('/me', {
    accessToken,
  });
}

export function updateBodyMetrics(accessToken: string, payload: Record<string, unknown>) {
  return request('/me/body', {
    accessToken,
    init: {
      method: 'PUT',
      body: JSON.stringify(payload),
    },
  });
}

export interface AvatarStatusResponse {
  avatarId: string;
  status: string;
  meshUrl?: string;
  confidence?: number;
  generatedAt?: string;
}

export interface AddressResponse {
  id: string;
  [key: string]: unknown;
}

export interface PaymentMethodResponse {
  id: string;
  token: string;
  [key: string]: unknown;
}

export function requestAvatar(accessToken: string, payload: Record<string, unknown> = {}) {
  return request<{ avatarId: string; status: string }>('/me/avatar', {
    accessToken,
    init: {
      method: 'POST',
      body: JSON.stringify(payload),
    },
  });
}

export function getAvatar(accessToken: string, avatarId: string) {
  return request<AvatarStatusResponse>(`/me/avatar/${avatarId}`, {
    accessToken,
  });
}

export function addAddress(accessToken: string, payload: Record<string, unknown>) {
  return request<AddressResponse>('/me/addresses', {
    accessToken,
    init: {
      method: 'POST',
      body: JSON.stringify(payload),
    },
  });
}

export function addPaymentMethod(accessToken: string, payload: Record<string, unknown>) {
  return request<PaymentMethodResponse>('/me/payment-methods', {
    accessToken,
    init: {
      method: 'POST',
      body: JSON.stringify(payload),
    },
  });
}

export interface TryOnPayload {
  productId: string;
  variantSku?: string;
  avatarId?: string;
  quickEstimate?: { heightCm?: number; weightKg?: number };
}

export interface TryOnResponse {
  images: Array<Record<string, unknown>>;
  sizeRec: Record<string, unknown>;
  altSizes: Array<Record<string, unknown>>;
  processingTimeMs: number;
  fitZones: Record<string, unknown>;
}

export function executeTryOn(accessToken: string | undefined, payload: TryOnPayload) {
  return request<TryOnResponse>('/tryon', {
    accessToken,
    init: {
      method: 'POST',
      body: JSON.stringify(payload),
    },
  });
}

export interface CartResponse {
  cartId: string;
  items: Array<Record<string, unknown>>;
  totals: Record<string, unknown>;
  recommendations: Array<Record<string, unknown>>;
}

export function addCartItem(accessToken: string | undefined, payload: Record<string, unknown>) {
  return request('/cart/items', {
    accessToken,
    init: {
      method: 'POST',
      body: JSON.stringify(payload),
    },
  });
}

export function getCart(accessToken: string | undefined) {
  return request<CartResponse>('/cart', {
    accessToken,
  });
}

export interface CheckoutPayload {
  cartId: string;
  paymentTokenId: string;
  shippingAddressId: string;
  billingAddressId: string;
  rid?: string;
  idempotencyKey?: string;
}

export interface CheckoutResponse {
  orderId: string;
  status: string;
  paymentIntentRef: string;
  next: Record<string, unknown>;
}

export function checkout(accessToken: string | undefined, payload: CheckoutPayload) {
  return request<CheckoutResponse>('/checkout', {
    accessToken,
    init: {
      method: 'POST',
      body: JSON.stringify(payload),
    },
  });
}

export interface ReferralResponse {
  rid: string;
  shareUrl: string;
  expiresAt: string;
  policy: Record<string, unknown>;
  conflict?: boolean;
}

export function createReferral(accessToken: string | undefined, payload: Record<string, unknown>) {
  return request<ReferralResponse>('/referrals', {
    accessToken,
    init: {
      method: 'POST',
      body: JSON.stringify(payload),
    },
  });
}

export function getReferral(accessToken: string | undefined, rid: string) {
  return request<Record<string, unknown>>(`/referrals/${rid}`, {
    accessToken,
  });
}

export function listReferralEvents(accessToken: string | undefined, rid: string) {
  return request<Record<string, unknown>>(`/referrals/${rid}/events`, {
    accessToken,
  });
}

export interface AnalyticsResponse {
  range: { start: string; end: string };
  conversionRate: number;
  returnRate: number;
  fitAccuracy: number;
  referralAttribution: Record<string, unknown>;
  totals: Record<string, unknown>;
}

export function getBrandAnalytics(query: { brandId: string; rangeStart?: string; rangeEnd?: string }) {
  const params = new URLSearchParams(query as Record<string, string>);
  return request<AnalyticsResponse>(`/brand/analytics?${params.toString()}`);
}

export function uploadCatalog(payload: Record<string, unknown>) {
  return request('/brand/catalog/upload', {
    init: {
      method: 'POST',
      body: JSON.stringify(payload),
    },
  });
}

export function upsertProducts(payload: Record<string, unknown>) {
  return request('/brand/catalog/products', {
    init: {
      method: 'POST',
      body: JSON.stringify(payload),
    },
  });
}

export function createSizeChart(payload: Record<string, unknown>) {
  return request('/brand/sizecharts', {
    init: {
      method: 'POST',
      body: JSON.stringify(payload),
    },
  });
}

export function createFitMap(payload: Record<string, unknown>) {
  return request('/brand/fitmaps', {
    init: {
      method: 'POST',
      body: JSON.stringify(payload),
    },
  });
}
