import { Device } from '@nativescript/core';
import { CaptureResult } from './index';

const ENV = (globalThis as any)?.process?.env ?? {};

const DEFAULT_BASE = 'http://127.0.0.1:8000/api';
const API_BASE =
  ENV.NS_MEASUREMENTS_API_URL ||
  ENV.MEASUREMENTS_API_URL ||
  ENV.FITWIN_API_URL ||
  DEFAULT_BASE;
const API_KEY =
  ENV.NS_MEASUREMENTS_API_KEY ||
  ENV.MEASUREMENTS_API_KEY ||
  ENV.API_KEY ||
  ENV.FITWIN_API_KEY;

export interface MeasurementSubmissionResponse {
  valid?: boolean;
  measurements_cm?: Record<string, number>;
  recommended_size?: string | null;
  confidence?: number | null;
  recommendations?: Array<{
    category: string;
    size: string;
    confidence?: number;
    rationale?: string;
  }>;
  [key: string]: unknown;
}

export async function submitCaptureResult(
  capture: CaptureResult,
): Promise<MeasurementSubmissionResponse> {
  const endpoint = buildUrl('/measurements/validate');
  const payload = buildPayload(capture);

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (API_KEY) {
    headers['X-API-Key'] = API_KEY;
  }

  const response = await fetch(endpoint, {
    method: 'POST',
    headers,
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const body = await safeParse(response);
    throw new Error(
      `Measurement submission failed (${response.status}): ${
        body?.detail?.message ?? response.statusText
      }`,
    );
  }

  return (await response.json()) as MeasurementSubmissionResponse;
}

function buildPayload(capture: CaptureResult) {
  const now = Date.now();
  const captureId =
    (capture.metadata?.captureId as string | undefined) ?? `ns-${now}`;
  const capturedAt =
    (capture.metadata?.capturedAt as number | string | undefined) ??
    capture.metadata?.timestamp ??
    now;

  const photos = (capture.photos ?? []).map((photo, index) => ({
    uri: photo.uri,
    view: photo.view ?? `capture-${index}`,
  }));

  const device = {
    model: (capture.metadata?.deviceModel as string | undefined) ?? Device.model,
    platform:
      (capture.metadata?.platform as string | undefined) ??
      Device.os.toLowerCase(),
    osVersion: Device.osVersion,
    appVersion: ENV.NS_APP_VERSION || ENV.APP_VERSION || 'dev',
  };

  const metadata = {
    ...capture.metadata,
    captureId,
    capturedAt,
    device,
  };

  const payload = {
    captureId,
    source:
      (capture.metadata?.source as string | undefined) ?? 'native-camera',
    timestamp: toIsoString(capturedAt),
    metrics: capture.measurements ?? {},
    photos,
    depth: capture.depthDataUrl ? { uri: capture.depthDataUrl } : undefined,
    metadata,
    device,
  };

  return payload;
}

function buildUrl(path: string) {
  const trimmedBase = API_BASE.replace(/\/+$/, '');
  const trimmedPath = path.startsWith('/') ? path : `/${path}`;
  return `${trimmedBase}${trimmedPath}`;
}

function toIsoString(value: number | string) {
  if (typeof value === 'number') {
    return new Date(value).toISOString();
  }
  const parsed = Number(value);
  if (!Number.isNaN(parsed)) {
    return new Date(parsed).toISOString();
  }
  return new Date(value).toISOString();
}

async function safeParse(response: Response) {
  try {
    return await response.json();
  } catch {
    return undefined;
  }
}
