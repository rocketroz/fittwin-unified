import { inMemoryStore } from 'src/lib/persistence/in-memory-store';
import { ProfileService } from 'src/modules/profiles/profile.service';
import { AvatarService } from 'src/modules/profiles/avatar.service';

describe('Profile Contracts', () => {
  let profileService: ProfileService;
  let avatarService: AvatarService;

  beforeAll(() => {
    avatarService = new AvatarService();
  });

  beforeEach(() => {
    inMemoryStore.reset();
    profileService = new ProfileService();
  });

  it('GET /me returns profile schema', async () => {
    const profile = await profileService.getProfile();

    expect(profile).toEqual(
      expect.objectContaining({
        userId: expect.any(String),
        email: expect.stringContaining('@'),
        username: expect.any(String),
        bodyMetrics: expect.objectContaining({
          heightCm: expect.any(Number),
        }),
        avatars: expect.any(Array),
        addresses: expect.any(Array),
        paymentMethods: expect.any(Array),
        consents: expect.objectContaining({
          terms: expect.any(Boolean),
          marketing: expect.any(Boolean),
          dataExportAvailable: expect.any(Boolean),
        }),
      })
    );
  });

  it('PUT /me/avatar triggers avatar job contract', async () => {
    const result = await avatarService.createAvatarJob({
      sources: {
        photos: [{ url: 'https://cdn.fittwin.local/photos/front.png', view: 'front' }],
      },
    });

    expect(result).toEqual(
      expect.objectContaining({
        avatarId: expect.any(String),
        status: 'processing',
      })
    );

    const stored = inMemoryStore.avatars.get(result.avatarId);
    expect(stored).toBeDefined();
    expect(stored?.status).toBe('queued');

    const profile = await profileService.getProfile();
    expect(profile.avatars).toEqual(
      expect.arrayContaining([expect.objectContaining({ avatarId: result.avatarId })])
    );
  });

  it('DELETE /me/avatar/{id} obeys deletion contract', async () => {
    const { avatarId } = await avatarService.createAvatarJob({
      sources: { measurements: { waist: 72 } },
    });

    await avatarService.deleteAvatar(avatarId);

    const profile = await profileService.getProfile();
    expect(profile.avatars).not.toEqual(
      expect.arrayContaining([expect.objectContaining({ avatarId })])
    );

    const stored = inMemoryStore.avatars.get(avatarId);
    expect(stored?.status).toBe('deleted');
  });
});
