import { inMemoryStore } from 'src/lib/persistence/in-memory-store';
import { ProfileService } from 'src/modules/profiles/profile.service';
import { AvatarService } from 'src/modules/profiles/avatar.service';

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

describe('Scenario 2: Avatar regeneration & data rights', () => {
  let profileService: ProfileService;
  let avatarService: AvatarService;

  beforeAll(() => {
    avatarService = new AvatarService();
  });

  beforeEach(() => {
    inMemoryStore.reset();
    profileService = new ProfileService();
  });

  it('covers avatar regeneration, deletion, and data export', async () => {
    const profile = await profileService.getProfile();
    expect(profile.userId).toBeDefined();

    const firstAvatar = await avatarService.createAvatarJob({
      sources: { measurements: { waist: 72 } },
    });
    await sleep(250);
    const firstStatus = await avatarService.getAvatarStatus(firstAvatar.avatarId);
    expect(firstStatus.status).toBe('ready');

    const regenerated = await avatarService.createAvatarJob({
      sources: { photos: [{ url: 'https://cdn.fittwin.local/user/front.png', view: 'front' }] },
    });
    await sleep(250);
    const regeneratedStatus = await avatarService.getAvatarStatus(regenerated.avatarId);
    expect(regeneratedStatus.status).toBe('ready');
    expect(regeneratedStatus.generatedAt).toBeDefined();

    await avatarService.deleteAvatar(regenerated.avatarId);
    const storedAvatar = inMemoryStore.avatars.get(regenerated.avatarId);
    expect(storedAvatar?.status).toBe('deleted');

    const exportJob = await profileService.requestExport();
    expect(exportJob).toEqual(
      expect.objectContaining({
        jobId: expect.any(String),
        status: 'processing',
      })
    );
    expect(inMemoryStore.dataExportJobs.has(exportJob.jobId)).toBe(true);
  });
});
