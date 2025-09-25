interface TryOnJobPayload {
  tryOnId: string;
  productId: string;
  avatarId?: string;
}

export async function handler(job?: TryOnJobPayload) {
  const payload = job ?? loadJobFromEnv();
  if (!payload) {
    console.log('Try-on renderer idle - no job provided');
    return;
  }

  console.log(`Rendering try-on ${payload.tryOnId} for product ${payload.productId}`);
  await new Promise((resolve) => setTimeout(resolve, 120));
  console.log(`Try-on ${payload.tryOnId} completed`);
}

function loadJobFromEnv(): TryOnJobPayload | undefined {
  const job = process.env.TRYON_JOB;
  if (!job) {
    return undefined;
  }
  try {
    return JSON.parse(job) as TryOnJobPayload;
  } catch (error) {
    console.error('Failed to parse TRYON_JOB payload', error);
    return undefined;
  }
}

if (require.main === module) {
  handler().catch((error) => {
    console.error('Try-on renderer worker crashed', error);
    process.exit(1);
  });
}
