import { TryOnService } from 'src/modules/tryon/tryon.service';
import { inMemoryStore } from 'src/lib/persistence/in-memory-store';

describe('Try-On Contracts', () => {
  let service: TryOnService;

  beforeAll(() => {
    service = new TryOnService();
  });

  beforeEach(() => {
    inMemoryStore.reset();
  });

  it('POST /tryon returns sizeRec payload', async () => {
    const response = await service.executeTryOn({
      productId: 'prod-core-tee',
      quickEstimate: { heightCm: 172, weightKg: 68 },
    });

    expect(response.images).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          view: 'front',
          url: expect.stringContaining('https://cdn.fittwin.local/renders/'),
        }),
      ])
    );
    expect(response.sizeRec).toEqual(
      expect.objectContaining({
        label: expect.any(String),
        confidence: expect.any(Number),
        notes: expect.arrayContaining([expect.any(String)]),
        rationale: expect.arrayContaining([expect.any(String)]),
      })
    );
    expect(response.altSizes.length).toBeGreaterThan(0);
    expect(response.processingTimeMs).toBeGreaterThan(0);
    expect(response.fitZones).toBeDefined();
  });

  it('GET /tryon/{id} polls async try-on jobs', async () => {
    await service.executeTryOn({
      productId: 'prod-core-tee',
      quickEstimate: { heightCm: 170, weightKg: 70 },
    });

    const storedJobId = Array.from(inMemoryStore.tryOnJobs.keys())[0];
    expect(storedJobId).toBeDefined();

    const poll = await service.pollTryOn(storedJobId);
    expect(poll.tryOnId).toBe(storedJobId);
    expect(poll.status).toBe('completed');
    expect(poll.status).toBe('completed');
    if (poll.status !== 'completed' || !('sizeRec' in poll) || !('images' in poll)) {
      throw new Error('expected completed try-on payload with result details');
    }
    const completed = poll as typeof poll & { sizeRec: unknown; images: unknown };
    expect(completed.sizeRec).toBeDefined();
    expect(completed.images).toBeDefined();
  });
});
