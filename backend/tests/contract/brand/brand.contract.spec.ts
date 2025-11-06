import { CatalogService } from 'src/modules/brand/catalog.service';
import { inMemoryStore } from 'src/lib/persistence/in-memory-store';

describe('Brand Portal Contracts', () => {
  let catalogService: CatalogService;

  beforeEach(() => {
    inMemoryStore.reset();
    catalogService = new CatalogService();
  });

  it('POST /brand/catalog/upload validates csv contract', () => {
    const result = catalogService.uploadCatalog({
      brandId: 'brand-001',
      fileUrl: 'https://cdn.fittwin.local/catalogs/brand001.csv',
      schemaVersion: '1.0',
    });

    expect(result).toEqual(
      expect.objectContaining({
        ingestId: expect.any(String),
        status: 'processing',
      })
    );

    const storedJob = inMemoryStore.catalogIngestJobs.get(result.ingestId);
    expect(storedJob?.fileUrl).toContain('brand001.csv');
  });

  it('POST /brand/sizecharts honors schema contract', () => {
    const chart = catalogService.createSizeChart({
      brandId: 'brand-002',
      garmentType: 'tops',
      unitSystem: 'metric',
      measurementRules: {
        S: { chest: 88, waist: 72 },
        M: { chest: 94, waist: 78 },
      },
    });

    expect(chart).toEqual(
      expect.objectContaining({
        id: expect.any(String),
        brandId: 'brand-002',
        rows: expect.arrayContaining([
          expect.objectContaining({ measurement: 'S', chest: 88 }),
        ]),
      })
    );
  });

  it('POST /brand/fitmaps records analytics event contract', () => {
    const fitMap = catalogService.createFitMap({
      brandId: 'brand-003',
      garmentType: 'denim',
      ruleSet: { hip: 'flex' },
    });

    expect(fitMap).toEqual(
      expect.objectContaining({
        id: expect.any(String),
        fitNotes: expect.objectContaining({ garmentType: 'denim' }),
      })
    );

    const analyticsEvents = Array.from(inMemoryStore.analyticsEvents.values()).filter(
      (event) => event.type === 'brand.fitmap.created'
    );
    expect(analyticsEvents.length).toBe(1);
  });
});
