export type CaptureStatus = 'idle' | 'capturing' | 'processing' | 'completed' | 'error';

export interface CaptureResult {
  status: CaptureStatus;
  measurements?: {
    heightCm?: number;
    weightKg?: number;
    [key: string]: unknown;
  };
  photos?: Array<{ uri: string; view?: string }>;
  depthDataUrl?: string;
  errorMessage?: string;
  metadata?: Record<string, unknown>;
}

export interface NativeCaptureService {
  isSupported(): Promise<boolean>;
  requestPermissions(): Promise<void>;
  captureMeasurements(): Promise<CaptureResult>;
}

let implementation: NativeCaptureService | null = null;

export function registerCaptureService(service: NativeCaptureService) {
  implementation = service;
}

export async function captureMeasurements(): Promise<CaptureResult> {
  if (!implementation) {
    return {
      status: 'error',
      errorMessage: 'Native capture service not registered',
    };
  }

  const supported = await implementation.isSupported();
  if (!supported) {
    return {
      status: 'error',
      errorMessage: 'Native capture not supported on this device',
    };
  }

  await implementation.requestPermissions();
  return implementation.captureMeasurements();
}
