import { CatalogService } from 'src/modules/brand/catalog.service';
import { inMemoryStore } from 'src/lib/persistence/in-memory-store';

describe('Scenario 3: Brand onboarding & catalog ingest', () => {
  let catalogService: CatalogService;

  beforeEach(() => {
    inMemoryStore.reset();
    catalogService = new CatalogService();
  });

  it('validates catalog upload, size map, and analytics readiness', () => {
    const upload = catalogService.uploadCatalog({
      brandId: 'brand-004',
      fileUrl: 'https://cdn.fittwin.local/catalogs/brand004.csv',
    });
    expect(upload.status).toBe('processing');

    const catalogStatus = catalogService.getIngestStatus(upload.ingestId);
    expect(catalogStatus.brandId).toBe('brand-004');

    const products = catalogService.upsertProduct({
      brandId: 'brand-004',
      products: [
        {
          externalId: 'tee-001',
          title: 'Fit Tee',
          variants: [
            {
              sku: 'TEE-001-S',
              sizeLabel: 'S',
              price: { amount: 3200, currency: 'USD' },
              inventory: 25,
            },
          ],
        },
      ],
    });
    expect(products.summary.successCount).toBe(1);
    expect(products.results[0]).toEqual(
      expect.objectContaining({
        success: true,
        productId: expect.any(String),
      })
    );

    const chart = catalogService.createSizeChart({
      brandId: 'brand-004',
      garmentType: 'tops',
      measurementRules: { S: { chest: 88, waist: 72 } },
    });
    expect(chart.rows.length).toBeGreaterThan(0);

    const fitMap = catalogService.createFitMap({
      brandId: 'brand-004',
      garmentType: 'tops',
      ruleSet: { bust: 'ease' },
    });
    expect(fitMap.fitNotes.garmentType).toBe('tops');

    const analyticsEvents = Array.from(inMemoryStore.analyticsEvents.values());
    expect(analyticsEvents.some((event) => event.type === 'brand.fitmap.created')).toBe(true);
  });
});
