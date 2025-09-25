'use client';

import { useCallback, useMemo, useState } from 'react';
import {
  PageContainer,
  SectionCard,
  SectionTitle,
  SectionDescription,
  Button,
  TextInput,
  Label,
  Badge,
  OutputPanel,
  Form,
  Fieldset,
} from '@fittwin/ui';
import {
  addAddress,
  addCartItem,
  addPaymentMethod,
  checkout,
  createReferral,
  executeTryOn,
  getAvatar,
  getCart,
  getProfile,
  getReferral,
  listReferralEvents,
  login,
  refresh,
  requestAvatar,
  signup,
  updateBodyMetrics,
  verifyEmail,
  type AvatarStatusResponse,
  type CartResponse,
  type CheckoutResponse,
  type ProfileResponse,
  type TryOnResponse,
  type AddressResponse,
  type PaymentMethodResponse,
} from '@fittwin/api-client';

interface AuthState {
  accessToken?: string;
  refreshToken?: string;
  verificationToken?: string;
  userId?: string;
}

const DEFAULT_EMAIL = 'shopper.demo@fittwin.local';
const DEFAULT_PASSWORD = 'StrongPass!42';
const DEFAULT_PRODUCT_ID = 'demo-core-fit-tee';
const DEFAULT_SKU = 'FT-TEE-M';

export default function ShopperExperiencePage() {
  const [email, setEmail] = useState(DEFAULT_EMAIL);
  const [password, setPassword] = useState(DEFAULT_PASSWORD);
  const [auth, setAuth] = useState<AuthState>({});
  const [profile, setProfile] = useState<ProfileResponse | null>(null);
  const [bodyMetrics, setBodyMetrics] = useState({ heightCm: 172, weightKg: 68 });
  const [avatarId, setAvatarId] = useState<string | null>(null);
  const [avatarStatus, setAvatarStatus] = useState<AvatarStatusResponse | null>(null);
  const [productId, setProductId] = useState(DEFAULT_PRODUCT_ID);
  const [variantSku, setVariantSku] = useState(DEFAULT_SKU);
  const [tryOnResult, setTryOnResult] = useState<TryOnResponse | null>(null);
  const [cartSnapshot, setCartSnapshot] = useState<CartResponse | null>(null);
  const [checkoutReceipt, setCheckoutReceipt] = useState<CheckoutResponse | null>(null);
  const [shippingAddressId, setShippingAddressId] = useState<string | null>(null);
  const [billingAddressId, setBillingAddressId] = useState<string | null>(null);
  const [paymentTokenId, setPaymentTokenId] = useState<string | null>(null);
  const [lastRid, setLastRid] = useState<string | null>(null);
  const [referralSummary, setReferralSummary] = useState<Record<string, unknown> | null>(null);
  const [referralEvents, setReferralEvents] = useState<Record<string, unknown> | null>(null);
  const [isBusy, setIsBusy] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const hasSession = Boolean(auth.accessToken);

  const handleAsync = useCallback(
    async <T,>(label: string, fn: () => Promise<T>): Promise<T | null> => {
      setIsBusy(label);
      setErrorMessage(null);
      try {
        const result = await fn();
        return result;
      } catch (error) {
        setErrorMessage(error instanceof Error ? error.message : String(error));
        return null;
      } finally {
        setIsBusy(null);
      }
    },
    []
  );

  const sessionBadge = useMemo(() => {
    if (!auth.accessToken) {
      return <Badge>No active session</Badge>;
    }
    return <Badge>Session ready · token exp in {auth.accessToken.length} chars</Badge>;
  }, [auth.accessToken]);

  return (
    <PageContainer>
      <header style={{ marginBottom: '32px', textAlign: 'center' }}>
        <Badge>Shopper MVP Walkthrough</Badge>
        <h1 style={{ fontSize: '2.5rem', margin: '12px 0 8px', color: '#0f172a' }}>FitTwin Shopper Demo</h1>
        <p style={{ color: '#475569', fontSize: '1rem', lineHeight: 1.6 }}>
          Drive the end-to-end shopper journey: account creation, AI twin bootstrapping, virtual try-on,
          cart + checkout, and referral sharing – all backed by the stubbed API contracts.
        </p>
      </header>

      <SectionCard>
        <SectionTitle>1 · Account Setup</SectionTitle>
        <SectionDescription>
          Create a shopper account, verify email, and authenticate to unlock protected endpoints. Use the
          generated verification token for a simulated click-through experience.
        </SectionDescription>

        <Form
          onSubmit={async (event) => {
            event.preventDefault();
            const result = await handleAsync('signup', () =>
              signup({
                email,
                password,
                consent: { terms: true, marketing: false, privacy: true },
              })
            );
            if (result) {
              setAuth((prev) => ({ ...prev, verificationToken: result.verificationToken, userId: result.userId }));
            }
          }}
        >
          <div>
            <Label htmlFor="email">Email</Label>
            <TextInput
              id="email"
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="you@example.com"
              required
            />
          </div>
          <div>
            <Label htmlFor="password">Password</Label>
            <TextInput
              id="password"
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              required
            />
          </div>
          <Button type="submit" disabled={isBusy !== null}>
            {isBusy === 'signup' ? 'Creating account…' : 'Sign up & queue verification'}
          </Button>
        </Form>

        <Fieldset legend="Email verification">
          <Form
            onSubmit={async (event) => {
              event.preventDefault();
              if (!auth.verificationToken) {
                setErrorMessage('No verification token available – run signup first.');
                return;
              }
              const verified = await handleAsync('verify', () => verifyEmail(auth.verificationToken!));
              if (verified !== null) {
                setErrorMessage(null);
              }
            }}
            style={{ gridTemplateColumns: '1fr auto', alignItems: 'end' }}
          >
            <div>
              <Label htmlFor="verificationToken">Verification token</Label>
              <TextInput
                id="verificationToken"
                value={auth.verificationToken ?? ''}
                onChange={(event) => setAuth((prev) => ({ ...prev, verificationToken: event.target.value }))}
              />
            </div>
            <Button type="submit" disabled={isBusy !== null}>
              {isBusy === 'verify' ? 'Verifying…' : 'Verify email'}
            </Button>
          </Form>
        </Fieldset>

        <Fieldset legend="Authenticate">
          <Form
            onSubmit={async (event) => {
              event.preventDefault();
              const result = await handleAsync('login', () => login(email, password));
              if (result) {
                setAuth((prev) => ({
                  ...prev,
                  accessToken: result.accessToken,
                  refreshToken: result.refreshToken,
                }));
              }
            }}
            style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px' }}
          >
            <div style={{ gridColumn: '1 / -1', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              {sessionBadge}
              <Button type="submit" disabled={isBusy !== null}>
                {isBusy === 'login' ? 'Authorizing…' : 'Login & issue tokens'}
              </Button>
            </div>
            <Button
              type="button"
              variant="secondary"
              disabled={!auth.refreshToken || isBusy !== null}
              onClick={async () => {
                if (!auth.refreshToken) return;
                const result = await handleAsync('refresh', () => refresh(auth.refreshToken!, 'demo-device'));
                if (result) {
                  setAuth((prev) => ({
                    ...prev,
                    accessToken: result.accessToken,
                    refreshToken: result.refreshToken,
                  }));
                }
              }}
            >
              {isBusy === 'refresh' ? 'Refreshing…' : 'Rotate refresh token'}
            </Button>
          </Form>
        </Fieldset>
      </SectionCard>

      <SectionCard>
        <SectionTitle>2 · Profile, Measurements & AI Twin</SectionTitle>
        <SectionDescription>
          Pull the latest profile snapshot, tweak measurements, and queue an avatar build. Poll the job to
          observe status changes.
        </SectionDescription>

        <Form
          onSubmit={async (event) => {
            event.preventDefault();
            if (!auth.accessToken) {
              setErrorMessage('Authenticate before fetching profile.');
              return;
            }
            const data = await handleAsync('profile', () => getProfile(auth.accessToken!));
            if (data) {
              setProfile(data);
            }
          }}
          style={{ gridTemplateColumns: 'auto auto', alignItems: 'center', gap: '12px' }}
        >
          <Button type="submit" disabled={!hasSession || isBusy !== null}>
            {isBusy === 'profile' ? 'Loading profile…' : 'Fetch profile snapshot'}
          </Button>
          {profile ? <Badge>Username · {String(profile.username)}</Badge> : null}
        </Form>

        <Fieldset legend="Update body metrics">
          <Form
            onSubmit={async (event) => {
              event.preventDefault();
              if (!auth.accessToken) {
                setErrorMessage('Login required to update body metrics.');
                return;
              }
              const result = await handleAsync('bodyMetrics', () =>
                updateBodyMetrics(auth.accessToken!, {
                  heightCm: Number(bodyMetrics.heightCm),
                  weightKg: Number(bodyMetrics.weightKg),
                  measurements: { waist: 74, inseam: 80 },
                })
              );
              if (result) {
                const refreshed = await getProfile(auth.accessToken!);
                setProfile(refreshed);
              }
            }}
            style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))' }}
          >
            <div>
              <Label htmlFor="height">Height (cm)</Label>
              <TextInput
                id="height"
                type="number"
                value={bodyMetrics.heightCm}
                onChange={(event) => setBodyMetrics((prev) => ({ ...prev, heightCm: Number(event.target.value) }))}
              />
            </div>
            <div>
              <Label htmlFor="weight">Weight (kg)</Label>
              <TextInput
                id="weight"
                type="number"
                value={bodyMetrics.weightKg}
                onChange={(event) => setBodyMetrics((prev) => ({ ...prev, weightKg: Number(event.target.value) }))}
              />
            </div>
            <Button type="submit" disabled={!hasSession || isBusy !== null}>
              {isBusy === 'bodyMetrics' ? 'Saving…' : 'Persist measurements'}
            </Button>
          </Form>
        </Fieldset>

        <Fieldset legend="AI Twin">
          <Form
            onSubmit={async (event) => {
              event.preventDefault();
              if (!auth.accessToken) {
                setErrorMessage('Login required to trigger avatar job.');
                return;
              }
              const response = await handleAsync('avatar', () =>
                requestAvatar(auth.accessToken!, {
                  sources: {
                    height: bodyMetrics.heightCm,
                    weight: bodyMetrics.weightKg,
                    measurements: { waist: 74, inseam: 80 },
                  },
                })
              );
              if (response) {
                setAvatarId(response.avatarId);
                const status = await getAvatar(auth.accessToken!, response.avatarId);
                setAvatarStatus(status);
              }
            }}
            style={{ gridTemplateColumns: 'auto auto', alignItems: 'center', gap: '12px' }}
          >
            <Button type="submit" disabled={!hasSession || isBusy !== null}>
              {isBusy === 'avatar' ? 'Queueing…' : 'Generate avatar'}
            </Button>
            {avatarId ? <Badge>Avatar · {avatarId.slice(0, 8)}</Badge> : null}
          </Form>

          <Button
            variant="secondary"
            disabled={!hasSession || !avatarId || isBusy !== null}
            onClick={async () => {
              if (!auth.accessToken || !avatarId) return;
              const status = await handleAsync('avatarStatus', () => getAvatar(auth.accessToken!, avatarId));
              if (status) {
                setAvatarStatus(status);
              }
            }}
          >
            {isBusy === 'avatarStatus' ? 'Polling…' : 'Refresh avatar status'}
          </Button>

          {avatarStatus ? <OutputPanel title="Avatar status" data={avatarStatus} /> : null}
        </Fieldset>

        {profile ? <OutputPanel title="Profile snapshot" data={profile} /> : null}
      </SectionCard>

      <SectionCard>
        <SectionTitle>3 · Virtual Try-On</SectionTitle>
        <SectionDescription>
          Execute the try-on contract using either the freshly generated avatar or quick estimates. Inspect
          size recommendation details and alternate size deltas.
        </SectionDescription>

        <Form
          onSubmit={async (event) => {
            event.preventDefault();
            const response = await handleAsync('tryon', () =>
              executeTryOn(auth.accessToken, {
                productId,
                variantSku,
                avatarId: avatarId ?? undefined,
                quickEstimate: avatarId ? undefined : { heightCm: bodyMetrics.heightCm, weightKg: bodyMetrics.weightKg },
              })
            );
            if (response) {
              setTryOnResult(response);
            }
          }}
          style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))' }}
        >
          <div>
            <Label htmlFor="productId">Product ID</Label>
            <TextInput id="productId" value={productId} onChange={(event) => setProductId(event.target.value)} />
          </div>
          <div>
            <Label htmlFor="variant">Variant SKU</Label>
            <TextInput id="variant" value={variantSku} onChange={(event) => setVariantSku(event.target.value)} />
          </div>
          <Button type="submit" disabled={isBusy !== null}>
            {isBusy === 'tryon' ? 'Rendering…' : 'Run virtual try-on'}
          </Button>
        </Form>

        {tryOnResult ? <OutputPanel title="Try-on response" data={tryOnResult} /> : null}
      </SectionCard>

      <SectionCard>
        <SectionTitle>4 · Cart & Checkout</SectionTitle>
        <SectionDescription>
          Set up shopper commerce primitives, add the recommended SKU to cart, and complete checkout with
          idempotent payments.
        </SectionDescription>

        <Fieldset legend="Addresses & payment">
          <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
            <Button
              variant="secondary"
              disabled={!hasSession || isBusy !== null}
              onClick={async () => {
                if (!auth.accessToken) return;
                const address = await handleAsync<AddressResponse>('address', () =>
                  addAddress(auth.accessToken!, {
                    label: 'Home',
                    line1: '123 Market Street',
                    city: 'San Francisco',
                    state: 'CA',
                    postalCode: '94105',
                    country: 'US',
                    type: 'shipping',
                  })
                );
                if (address) {
                  setShippingAddressId(address.id);
                  setBillingAddressId(address.id);
                }
              }}
            >
              {isBusy === 'address' ? 'Saving…' : 'Create shipping address'}
            </Button>
            <Button
              variant="secondary"
              disabled={!hasSession || isBusy !== null}
              onClick={async () => {
                if (!auth.accessToken) return;
                const payment = await handleAsync<PaymentMethodResponse>('payment', () =>
                  addPaymentMethod(auth.accessToken!, {
                    paymentMethodId: 'pm_demo_4242',
                    billingAddressId: shippingAddressId,
                    provider: 'stripe',
                    brand: 'visa',
                    lastFour: '4242',
                  })
                );
                if (payment) {
                  setPaymentTokenId(payment.token);
                }
              }}
            >
              {isBusy === 'payment' ? 'Configuring…' : 'Add payment token'}
            </Button>
          </div>
        </Fieldset>

        <Fieldset legend="Cart actions">
          <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
            <Button
              disabled={isBusy !== null}
              onClick={async () => {
                const result = await handleAsync('cartAdd', () =>
                  addCartItem(auth.accessToken, {
                    productId,
                    variantSku,
                    qty: 1,
                    source: 'tryon',
                  })
                );
                if (result) {
                  const cart = await getCart(auth.accessToken);
                  setCartSnapshot(cart);
                }
              }}
            >
              {isBusy === 'cartAdd' ? 'Adding…' : 'Add recommended SKU'}
            </Button>

            <Button
              variant="secondary"
              disabled={isBusy !== null}
              onClick={async () => {
                const cart = await handleAsync('cartFetch', () => getCart(auth.accessToken));
                if (cart) {
                  setCartSnapshot(cart);
                }
              }}
            >
              {isBusy === 'cartFetch' ? 'Refreshing…' : 'Refresh cart'}
            </Button>
          </div>
          {cartSnapshot ? <OutputPanel title="Cart" data={cartSnapshot} /> : null}
        </Fieldset>

        <Fieldset legend="Checkout">
          <Button
            disabled={!cartSnapshot || !paymentTokenId || !shippingAddressId || isBusy !== null}
            onClick={async () => {
              if (!cartSnapshot || !paymentTokenId || !shippingAddressId) {
                setErrorMessage('Cart, payment, and shipping must be configured before checkout.');
                return;
              }
              const receipt = await handleAsync('checkout', () =>
                checkout(auth.accessToken, {
                  cartId: cartSnapshot.cartId as string,
                  paymentTokenId,
                  shippingAddressId,
                  billingAddressId: billingAddressId ?? shippingAddressId,
                  rid: lastRid ?? undefined,
                })
              );
              if (receipt) {
                setCheckoutReceipt(receipt);
              }
            }}
          >
            {isBusy === 'checkout' ? 'Submitting…' : 'Complete checkout'}
          </Button>
          {checkoutReceipt ? <OutputPanel title="Order receipt" data={checkoutReceipt} /> : null}
        </Fieldset>
      </SectionCard>

      <SectionCard>
        <SectionTitle>5 · Social Referral Loop</SectionTitle>
        <SectionDescription>
          Issue a referral ID for the current product, then inspect attribution stats and event history.
        </SectionDescription>

        <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', alignItems: 'center' }}>
          <Button
            disabled={isBusy !== null}
            onClick={async () => {
              const referral = await handleAsync('referralCreate', () =>
                createReferral(auth.accessToken, { productId, channel: 'social' })
              );
              if (referral) {
                setLastRid(referral.rid);
                const summary = await getReferral(auth.accessToken, referral.rid);
                setReferralSummary(summary);
                const events = await listReferralEvents(auth.accessToken, referral.rid);
                setReferralEvents(events);
              }
            }}
          >
            {isBusy === 'referralCreate' ? 'Generating…' : 'Generate referral URL'}
          </Button>
          {lastRid ? <Badge>RID · {lastRid.slice(0, 10)}</Badge> : null}
        </div>

        {referralSummary ? <OutputPanel title="Referral summary" data={referralSummary} /> : null}
        {referralEvents ? <OutputPanel title="Referral events" data={referralEvents} /> : null}
      </SectionCard>

      {errorMessage ? (
        <SectionCard style={{ borderColor: '#f97316', background: '#fff7ed' }}>
          <SectionTitle>Heads up</SectionTitle>
          <SectionDescription>{errorMessage}</SectionDescription>
        </SectionCard>
      ) : null}
    </PageContainer>
  );
}
