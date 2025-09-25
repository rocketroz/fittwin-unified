interface AvatarJobPayload {
  avatarId: string;
  userId: string;
  sources?: Record<string, unknown>;
}

export async function handler(job?: AvatarJobPayload) {
  const payload = job ?? loadJobFromEnv();
  if (!payload) {
    console.log('Avatar processor idle - no job payload provided');
    return;
  }

  console.log(`Processing avatar ${payload.avatarId} for user ${payload.userId}`);
  await new Promise((resolve) => setTimeout(resolve, 150));
  console.log(`Avatar ${payload.avatarId} mesh generated`);
}

function loadJobFromEnv(): AvatarJobPayload | undefined {
  const job = process.env.AVATAR_JOB;
  if (!job) {
    return undefined;
  }
  try {
    return JSON.parse(job) as AvatarJobPayload;
  } catch (error) {
    console.error('Failed to parse AVATAR_JOB payload', error);
    return undefined;
  }
}

if (require.main === module) {
  handler().catch((error) => {
    console.error('Avatar processor worker crashed', error);
    process.exit(1);
  });
}
