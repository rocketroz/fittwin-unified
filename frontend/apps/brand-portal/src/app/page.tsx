'use client';

import { useState } from 'react';
import {
  PageContainer,
  SectionCard,
  SectionTitle,
  SectionDescription,
  Button,
  TextInput,
  Label,
  Badge,
  Form,
  OutputPanel,
  Fieldset,
} from '@fittwin/ui';
import {
  createFitMap,
  createSizeChart,
  getBrandAnalytics,
  uploadCatalog,
  upsertProducts,
  type AnalyticsResponse,
} from '@fittwin/api-client';

const DEFAULT_BRAND_ID = 'brand-demo-001';

function safeEntityId(entity: unknown): string | undefined {
  if (entity && typeof entity === 'object' && 'id' in entity) {
    const value = (entity as { id?: unknown }).id;
    return typeof value === 'string' ? value : value !== undefined ? String(value) : undefined;
  }
  return undefined;
}

export default function BrandPortalHome() {
  const [brandId, setBrandId] = useState(DEFAULT_BRAND_ID);
  const [fileUrl, setFileUrl] = useState('https://uploads.fittwin.fake/catalog.csv');
  const [analytics, setAnalytics] = useState<AnalyticsResponse | null>(null);
  const [catalogJob, setCatalogJob] = useState<unknown>(null);
  const [sizeChart, setSizeChart] = useState<unknown>(null);
  const [fitMap, setFitMap] = useState<unknown>(null);
  const [productIngest, setProductIngest] = useState<unknown>(null);
  const [isBusy, setIsBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleAsync = async <T,>(label: string, fn: () => Promise<T>): Promise<T | null> => {
    setIsBusy(label);
    setError(null);
    try {
      return await fn();
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : String(caught));
      return null;
    } finally {
      setIsBusy(null);
    }
  };

  return (
    <PageContainer>
      <header style={{ marginBottom: '32px', textAlign: 'center' }}>
        <Badge>Brand Portal Preview</Badge>
        <h1 style={{ fontSize: '2.5rem', margin: '12px 0 8px', color: '#0f172a' }}>FitTwin Brand Console</h1>
        <p style={{ color: '#475569', fontSize: '1rem', lineHeight: 1.6 }}>
          Demonstrate the core operator flows: catalog ingest, size-map definition, and performance
          analytics – all backed by the v1 platform contracts.
        </p>
      </header>

      <SectionCard>
        <SectionTitle>1 · Catalog Ingest</SectionTitle>
        <SectionDescription>
          Simulate a catalog CSV ingest by providing a signed upload URL. The backend queues a processing job
          and responds with a tracking ID.
        </SectionDescription>

        <Form
          onSubmit={async (event) => {
            event.preventDefault();
            const job = await handleAsync('catalog', () =>
              uploadCatalog({ brandId, fileUrl, schemaVersion: '1.0' })
            );
            if (job) {
              setCatalogJob(job);
            }
          }}
        >
          <div>
            <Label htmlFor="brandId">Brand ID</Label>
            <TextInput id="brandId" value={brandId} onChange={(event) => setBrandId(event.target.value)} />
          </div>
          <div>
            <Label htmlFor="fileUrl">Signed file URL</Label>
            <TextInput id="fileUrl" value={fileUrl} onChange={(event) => setFileUrl(event.target.value)} />
          </div>
          <Button type="submit" disabled={isBusy !== null}>
            {isBusy === 'catalog' ? 'Submitting…' : 'Queue ingest job'}
          </Button>
        </Form>

        {catalogJob ? <OutputPanel title="Ingest status" data={catalogJob} /> : null}
      </SectionCard>

      <SectionCard>
        <SectionTitle>2 · Product API Ingest</SectionTitle>
        <SectionDescription>
          Push a batched product payload – mirroring the headless integration. Variants, fit maps, and
          assets are stored for downstream try-on alignment.
        </SectionDescription>

        <Button
          disabled={isBusy !== null}
          onClick={async () => {
              const payload = {
                brandId,
                products: [
                  {
                    externalId: 'tee-001',
                    title: 'Core Fit Tee',
                    description: 'Lightweight performance tee optimised for FitTwin.',
                    category: 'tops',
                    assets: { hero: 'https://cdn.fittwin.fake/tee-core.png' },
                    sizeChartId: safeEntityId(sizeChart),
                    fitMapId: safeEntityId(fitMap),
                  variants: [
                    {
                      sku: 'FT-TEE-M',
                      sizeLabel: 'M',
                      color: 'Black',
                      price: { amount: 4200, currency: 'USD' },
                      inventory: 48,
                    },
                    {
                      sku: 'FT-TEE-L',
                      sizeLabel: 'L',
                      color: 'Black',
                      price: { amount: 4200, currency: 'USD' },
                      inventory: 52,
                    },
                  ],
                },
              ],
            };
            const result = await handleAsync('products', () => upsertProducts(payload));
            if (result) {
              setProductIngest(result);
            }
          }}
        >
          {isBusy === 'products' ? 'Upserting…' : 'Publish product batch'}
        </Button>

        {productIngest ? <OutputPanel title="Product ingest result" data={productIngest} /> : null}
      </SectionCard>

      <SectionCard>
        <SectionTitle>3 · Size & Fit Intelligence</SectionTitle>
        <SectionDescription>
          Define measurement grading rules and fit adjustments to unlock confident size recommendations in
          the shopper experience.
        </SectionDescription>

        <Fieldset legend="Size chart">
          <Button
            variant="secondary"
            disabled={isBusy !== null}
            onClick={async () => {
              const chart = await handleAsync('sizeChart', () =>
                createSizeChart({
                  brandId,
                  garmentType: 'tops',
                  unitSystem: 'metric',
                  measurementRules: {
                    chest: { min: 80, max: 120, tolerance: 2 },
                    waist: { min: 70, max: 110, tolerance: 2 },
                  },
                  gradingRules: {
                    sizeOrder: ['XS', 'S', 'M', 'L', 'XL'],
                    increments: { chest: 4, waist: 3 },
                  },
                })
              );
              if (chart) {
                setSizeChart(chart);
              }
            }}
          >
            {isBusy === 'sizeChart' ? 'Saving…' : 'Create size chart'}
          </Button>
          {sizeChart ? <OutputPanel title="Size chart" data={sizeChart} /> : null}
        </Fieldset>

        <Fieldset legend="Fit map">
          <Button
            variant="secondary"
            disabled={isBusy !== null}
            onClick={async () => {
              const map = await handleAsync('fitMap', () =>
                createFitMap({
                  brandId,
                  garmentType: 'tops',
                  ruleSet: {
                    model: 'parametric',
                    parameters: { waistEase: 2.5, hipEase: 1.5 },
                  },
                  confidenceModel: {
                    baseline: 80,
                    modifiers: [{ factor: 'materialStretch', delta: 5 }],
                  },
                })
              );
              if (map) {
                setFitMap(map);
              }
            }}
          >
            {isBusy === 'fitMap' ? 'Calibrating…' : 'Create fit map'}
          </Button>
          {fitMap ? <OutputPanel title="Fit map" data={fitMap} /> : null}
        </Fieldset>
      </SectionCard>

      <SectionCard>
        <SectionTitle>4 · Performance Analytics</SectionTitle>
        <SectionDescription>
          Retrieve aggregated commerce KPIs for the selected brand across the default 30-day window and
          validate referral attribution is tracked.
        </SectionDescription>

        <Button
          disabled={isBusy !== null}
          onClick={async () => {
            const data = await handleAsync('analytics', () =>
              getBrandAnalytics({ brandId, rangeStart: undefined, rangeEnd: undefined })
            );
            if (data) {
              setAnalytics(data);
            }
          }}
        >
          {isBusy === 'analytics' ? 'Querying…' : 'Refresh analytics'}
        </Button>

        {analytics ? <OutputPanel title="Analytics" data={analytics} /> : null}
      </SectionCard>

      {error ? (
        <SectionCard style={{ borderColor: '#f97316', background: '#fff7ed' }}>
          <SectionTitle>Heads up</SectionTitle>
          <SectionDescription>{error}</SectionDescription>
        </SectionCard>
      ) : null}
    </PageContainer>
  );
}
