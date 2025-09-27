import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import {
  inMemoryStore,
  generateId,
  timestamp,
  AvatarRecord,
  ProductRecord,
  ProductVariantRecord,
  TryOnJobRecord,
} from '../../lib/persistence/in-memory-store';
import { localQueue, QueueJob } from '../../lib/queue/local-queue';

interface TryOnPayload {
  productId?: string;
  variantSku?: string;
  avatarId?: string;
  quickEstimate?: {
    heightCm?: number;
    weightKg?: number;
  };
  context?: {
    rid?: string;
    channel?: string;
    locale?: string;
  };
}

interface TryOnRenderJobPayload {
  tryOnId: string;
  avatarId?: string;
  productId: string;
  variantId: string;
}

@Injectable()
export class TryOnService {
  private readonly store = inMemoryStore;

  constructor() {
    localQueue.register<TryOnRenderJobPayload>('tryon-render', (job) => this.onTryOnJob(job));
  }

  async executeTryOn(rawPayload: Record<string, unknown>) {
    const payload = rawPayload as TryOnPayload;

    if (!payload.productId) {
      throw new HttpException(
        { error: { code: 'TRYON_PRODUCT_REQUIRED', message: 'productId is required.' } },
        HttpStatus.BAD_REQUEST,
      );
    }

    if (!payload.avatarId && !payload.quickEstimate) {
      throw new HttpException(
        { error: { code: 'TRYON_INPUT_REQUIRED', message: 'Provide avatarId or quickEstimate.' } },
        HttpStatus.BAD_REQUEST,
      );
    }

    const product = this.ensureProduct(payload.productId);
    const variant = this.resolveVariant(product, payload.variantSku);

    const avatar = payload.avatarId ? this.resolveAvatar(payload.avatarId) : undefined;
    if (avatar && avatar.status !== 'ready') {
      throw new HttpException(
        { error: { code: 'TRYON_AVATAR_PENDING', message: 'Avatar currently regenerating.' } },
        HttpStatus.CONFLICT,
      );
    }

    const metrics = avatar?.source?.measurements ?? {};
    const baseConfidence = avatar ? 90 : 70;
    const confidenceAdjustment = this.estimateConfidenceAdjustment(payload.quickEstimate, metrics);

    const result = {
      images: [
        {
          view: 'front',
          url: `https://cdn.fittwin.local/renders/${product.id}/${variant.id}/front.png`,
          expiresAt: new Date(Date.now() + 1000 * 60 * 60).toISOString(),
        },
      ],
      sizeRec: {
        label: variant.label,
        confidence: Math.min(100, baseConfidence + confidenceAdjustment),
        notes: [
          avatar
            ? 'Render tuned to avatar body metrics.'
            : 'Estimate based on provided height/weight.',
        ],
        rationale: [avatar ? 'avatar_metrics' : 'quick_estimate'],
      },
      altSizes: this.composeAltSizes(product, variant),
      processingTimeMs: avatar ? 2400 : 3200,
      fitZones: this.buildFitZones(metrics),
    };

    const tryOnId = generateId();
    const job: TryOnJobRecord = {
      id: tryOnId,
      userId: avatar?.userId,
      avatarId: avatar?.id,
      productId: product.id,
      variantId: variant.id,
      status: 'completed',
      createdAt: timestamp(),
      updatedAt: timestamp(),
      result,
    };
    this.store.tryOnJobs.set(tryOnId, job);

    localQueue.enqueue<TryOnRenderJobPayload>('tryon-render', {
      tryOnId,
      avatarId: avatar?.id,
      productId: product.id,
      variantId: variant.id,
    });

    const eventId = generateId();
    const analyticsAttributes: Record<string, unknown> = {
      productId: product.id,
      variantId: variant.id,
      avatarBased: Boolean(avatar),
      confidence: result.sizeRec.confidence,
      rid: payload.context?.rid,
      job: {
        tryOnId,
        avatarId: avatar?.id,
        productId: product.id,
        variantId: variant.id,
      },
    };

    this.store.analyticsEvents.set(eventId, {
      id: eventId,
      type: 'tryon.completed',
      createdAt: timestamp(),
      attributes: analyticsAttributes,
    });

    return result;
  }

  async pollTryOn(id: string) {
    const job = this.store.tryOnJobs.get(id);
    if (!job) {
      throw new HttpException(
        { error: { code: 'TRYON_JOB_NOT_FOUND', message: 'Try-on job not found or expired.' } },
        HttpStatus.GONE,
      );
    }

    if (job.status !== 'completed') {
      return { tryOnId: job.id, status: job.status };
    }

    return {
      tryOnId: job.id,
      status: job.status,
      ...job.result,
    };
  }

  private resolveAvatar(avatarId: string): AvatarRecord {
    const avatar = this.store.avatars.get(avatarId);
    if (!avatar) {
      throw new HttpException(
        { error: { code: 'TRYON_AVATAR_NOT_FOUND', message: 'Avatar not found.' } },
        HttpStatus.BAD_REQUEST,
      );
    }
    return avatar;
  }

  private ensureProduct(productId: string): ProductRecord {
    const existing = this.store.products.get(productId);
    if (existing) {
      return existing;
    }

    // Seed product for first run to keep contract flow operable.
    const brandId = generateId();
    this.store.brands.set(brandId, {
      id: brandId,
      name: 'Core Fit Brand',
      slug: 'core-fit',
      onboarded: true,
      createdAt: timestamp(),
      updatedAt: timestamp(),
    });

    const product: ProductRecord = {
      id: productId,
      brandId,
      name: 'Core Fit Tee',
      description: 'Lightweight tee optimized for FitTwin try-on.',
      heroImageUrl: 'https://cdn.fittwin.local/products/core-fit-tee.png',
      sizeChartId: undefined,
      fitMapId: undefined,
      active: true,
      createdAt: timestamp(),
      updatedAt: timestamp(),
    };
    this.store.products.set(productId, product);

    const baseVariant: ProductVariantRecord = {
      id: generateId(),
      productId,
      sku: 'FT-TEE-M',
      label: 'M',
      attributes: { chest: 100, waist: 82 },
      stock: 42,
      priceCents: 4200,
      currency: 'USD',
      createdAt: timestamp(),
      updatedAt: timestamp(),
    };
    this.store.variants.set(baseVariant.id, baseVariant);

    const altVariant: ProductVariantRecord = {
      id: generateId(),
      productId,
      sku: 'FT-TEE-S',
      label: 'S',
      attributes: { chest: 94, waist: 76 },
      stock: 37,
      priceCents: 4200,
      currency: 'USD',
      createdAt: timestamp(),
      updatedAt: timestamp(),
    };
    this.store.variants.set(altVariant.id, altVariant);

    return product;
  }

  private resolveVariant(product: ProductRecord, variantSku?: string): ProductVariantRecord {
    const variants = Array.from(this.store.variants.values()).filter(
      (variant) => variant.productId === product.id,
    );
    if (variantSku) {
      const bySku = variants.find((variant) => variant.sku === variantSku);
      if (!bySku) {
        throw new HttpException(
          { error: { code: 'TRYON_VARIANT_NOT_FOUND', message: 'Variant not found for product.' } },
          HttpStatus.NOT_FOUND,
        );
      }
      return bySku;
    }

    if (variants.length === 0) {
      throw new HttpException(
        { error: { code: 'TRYON_NO_VARIANTS', message: 'No variants configured for product.' } },
        HttpStatus.CONFLICT,
      );
    }

    return variants[0];
  }

  private composeAltSizes(product: ProductRecord, primaryVariant: ProductVariantRecord) {
    const variants = Array.from(this.store.variants.values()).filter(
      (variant) => variant.productId === product.id && variant.id !== primaryVariant.id,
    );

    return variants.slice(0, 2).map((variant) => ({
      label: variant.label,
      fitDeltas: {
        waist: this.delta(primaryVariant.attributes?.['waist'], variant.attributes?.['waist']),
        chest: this.delta(primaryVariant.attributes?.['chest'], variant.attributes?.['chest']),
      },
      confidence: 65,
    }));
  }

  private delta(primary?: unknown, alternate?: unknown) {
    if (typeof primary === 'number' && typeof alternate === 'number') {
      const diff = alternate - primary;
      return diff === 0 ? '0' : `${diff > 0 ? '+' : ''}${diff}`;
    }
    return 'n/a';
  }

  private estimateConfidenceAdjustment(
    quickEstimate: TryOnPayload['quickEstimate'],
    metrics: Record<string, number | undefined>,
  ): number {
    if (!quickEstimate) {
      return 0;
    }
    const weight = quickEstimate.weightKg ?? metrics['weightKg'] ?? 0;
    if (weight && weight >= 55 && weight <= 90) {
      return 5;
    }
    return -5;
  }

  private buildFitZones(metrics: Record<string, number | undefined>) {
    const waist = metrics['waist'];
    return {
      waist: this.zoneFromMeasurement(waist),
      hips: this.zoneFromMeasurement(metrics['hips'] ?? waist),
      inseam: this.zoneFromMeasurement(metrics['inseam']),
    };
  }

  private zoneFromMeasurement(value?: number) {
    if (!value) {
      return 'ideal';
    }
    if (value < 70) {
      return 'relaxed';
    }
    if (value > 100) {
      return 'snug';
    }
    return 'ideal';
  }

  private onTryOnJob(job: QueueJob<TryOnRenderJobPayload>) {
    const { tryOnId, avatarId, productId, variantId } = job.data;
    const eventId = generateId();
    const attributes: Record<string, unknown> = {
      tryOnId,
      avatarId,
      productId,
      variantId,
    };

    this.store.analyticsEvents.set(eventId, {
      id: eventId,
      type: 'tryon.post_process',
      createdAt: timestamp(),
      attributes,
    });
  }
}
