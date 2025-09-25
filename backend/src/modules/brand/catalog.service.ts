import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import {
  inMemoryStore,
  generateId,
  timestamp,
  BrandRecord,
  CatalogIngestJobRecord,
  ProductRecord,
  ProductVariantRecord,
  SizeChartRecord,
  FitMapRecord
} from '../../lib/persistence/in-memory-store';

interface CatalogUploadPayload {
  brandId?: string;
  fileUrl?: string;
  schemaVersion?: string;
}

interface UpsertProductPayload {
  brandId?: string;
  products?: Array<{
    externalId?: string;
    title?: string;
    description?: string;
    category?: string;
    assets?: Record<string, unknown>;
    sizeChartId?: string;
    fitMapId?: string;
    variants?: Array<{
      sku?: string;
      sizeLabel?: string;
      color?: string;
      price?: { amount?: number; currency?: string };
      inventory?: number;
    }>;
  }>;
}

interface SizeChartPayload {
  brandId?: string;
  garmentType?: string;
  unitSystem?: string;
  measurementRules?: Record<string, Record<string, number>>;
  gradingRules?: Record<string, unknown>;
}

interface FitMapPayload {
  brandId?: string;
  garmentType?: string;
  ruleSet?: Record<string, unknown>;
  confidenceModel?: Record<string, unknown>;
}

@Injectable()
export class CatalogService {
  private readonly store = inMemoryStore;

  uploadCatalog(rawPayload: Record<string, unknown>) {
    const payload = rawPayload as CatalogUploadPayload;
    if (!payload.brandId || !payload.fileUrl) {
      throw new HttpException(
        { error: { code: 'CATALOG_INVALID_PAYLOAD', message: 'brandId and fileUrl are required.' } },
        HttpStatus.BAD_REQUEST
      );
    }

    if (payload.schemaVersion && payload.schemaVersion !== '1.0') {
      throw new HttpException(
        { error: { code: 'CATALOG_SCHEMA_INVALID', message: 'Unsupported schema version.' } },
        HttpStatus.BAD_REQUEST
      );
    }

    const brand = this.ensureBrand(payload.brandId);
    const activeJob = Array.from(this.store.catalogIngestJobs.values()).find(
      (job) => job.brandId === brand.id && job.status === 'processing'
    );
    if (activeJob) {
      throw new HttpException(
        { error: { code: 'CATALOG_JOB_EXISTS', message: 'Catalog ingest already in progress.' } },
        HttpStatus.CONFLICT
      );
    }

    const job: CatalogIngestJobRecord = {
      id: generateId(),
      brandId: brand.id,
      fileUrl: payload.fileUrl,
      status: 'processing',
      schemaVersion: payload.schemaVersion ?? '1.0',
      createdAt: timestamp()
    };
    this.store.catalogIngestJobs.set(job.id, job);

    return { ingestId: job.id, status: job.status };
  }

  getIngestStatus(ingestId: string) {
    const job = this.store.catalogIngestJobs.get(ingestId);
    if (!job) {
      throw new HttpException(
        { error: { code: 'CATALOG_INGEST_NOT_FOUND', message: 'Catalog ingest not found.' } },
        HttpStatus.NOT_FOUND
      );
    }
    return job;
  }

  upsertProduct(rawPayload: Record<string, unknown>) {
    const payload = rawPayload as UpsertProductPayload;
    if (!payload.brandId || !payload.products?.length) {
      throw new HttpException(
        { error: { code: 'CATALOG_INVALID_PAYLOAD', message: 'brandId and products array are required.' } },
        HttpStatus.BAD_REQUEST
      );
    }

    const brand = this.ensureBrand(payload.brandId);
    const results = payload.products.map((product) => this.persistProduct(brand, product));

    const errors = results.filter((result) => !result.success);
    const status = errors.length && errors.length !== results.length ? HttpStatus.MULTI_STATUS : HttpStatus.CREATED;

    return {
      status,
      summary: {
        successCount: results.filter((result) => result.success).length,
        errorCount: errors.length
      },
      results
    };
  }

  createSizeChart(rawPayload: Record<string, unknown>) {
    const payload = rawPayload as SizeChartPayload;
    if (!payload.brandId || !payload.garmentType) {
      throw new HttpException(
        { error: { code: 'SIZECHART_INVALID', message: 'brandId and garmentType are required.' } },
        HttpStatus.BAD_REQUEST
      );
    }

    const brand = this.ensureBrand(payload.brandId);
    const chartId = generateId();
    const record: SizeChartRecord = {
      id: chartId,
      brandId: brand.id,
      name: payload.garmentType,
      rows: Object.entries(payload.measurementRules ?? {}).map(([key, rules]) => ({
        measurement: key,
        ...rules
      })),
      createdAt: timestamp()
    };
    this.store.sizeCharts.set(chartId, record);
    return record;
  }

  createFitMap(rawPayload: Record<string, unknown>) {
    const payload = rawPayload as FitMapPayload;
    if (!payload.brandId || !payload.garmentType) {
      throw new HttpException(
        { error: { code: 'FITMAP_INVALID', message: 'brandId and garmentType are required.' } },
        HttpStatus.BAD_REQUEST
      );
    }

    const brand = this.ensureBrand(payload.brandId);
    const mapId = generateId();
    const record: FitMapRecord = {
      id: mapId,
      productId: mapId,
      avatarMetrics: { baseline: 0 },
      fitNotes: { garmentType: payload.garmentType },
      createdAt: timestamp()
    };
    this.store.fitMaps.set(mapId, record);

    const eventId = generateId();
    this.store.analyticsEvents.set(eventId, {
      id: eventId,
      type: 'brand.fitmap.created',
      createdAt: timestamp(),
      attributes: { brandId: brand.id, garmentType: payload.garmentType }
    });

    return record;
  }

  private ensureBrand(brandId: string): BrandRecord {
    const brand = this.store.brands.get(brandId);
    if (brand) {
      return brand;
    }

    const record: BrandRecord = {
      id: brandId,
      name: 'Partner Brand',
      slug: `brand-${brandId.slice(0, 6)}`,
      onboarded: true,
      createdAt: timestamp(),
      updatedAt: timestamp()
    };
    this.store.brands.set(brandId, record);
    return record;
  }

  private persistProduct(brand: BrandRecord, product: UpsertProductPayload['products'][number]) {
    if (!product?.variants?.length) {
      return {
        success: false,
        externalId: product?.externalId,
        errors: ['At least one variant is required.']
      };
    }

    const productId = product.externalId ? `product-${product.externalId}` : generateId();
    const record: ProductRecord = {
      id: productId,
      brandId: brand.id,
      name: product.title ?? 'Untitled Product',
      description: product.description ?? '',
      heroImageUrl: String(product.assets?.['hero'] ?? 'https://cdn.fittwin.local/placeholder.png'),
      sizeChartId: product.sizeChartId,
      fitMapId: product.fitMapId,
      active: true,
      createdAt: timestamp(),
      updatedAt: timestamp()
    };
    this.store.products.set(productId, record);

    product.variants?.forEach((variant) => {
      if (!variant?.sku) {
        return;
      }
      const variantId = generateId();
      const variantRecord: ProductVariantRecord = {
        id: variantId,
        productId,
        sku: variant.sku,
        label: variant.sizeLabel ?? variant.sku,
        attributes: { color: variant.color },
        stock: variant.inventory ?? 0,
        priceCents: variant.price?.amount ?? 0,
        currency: variant.price?.currency ?? 'USD',
        createdAt: timestamp(),
        updatedAt: timestamp()
      };
      this.store.variants.set(variantId, variantRecord);
    });

    return {
      success: true,
      externalId: product.externalId,
      productId
    };
  }
}
