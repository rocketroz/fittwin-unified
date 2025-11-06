import { Device } from '@nativescript/core';
import { registerCaptureService } from './index';
import {
  captureBurst,
  ensureAndroidCameraPermission,
  isArCoreSupported,
  MeasurementBurstPayload,
} from './android/arcoreBridge';

registerCaptureService({
  async isSupported() {
    try {
      return isArCoreSupported();
    } catch (error) {
      console.warn('[NativeCapture][Android] Capability probe failed', error);
      return false;
    }
  },
  async requestPermissions() {
    const granted = await ensureAndroidCameraPermission();
    if (!granted) {
      throw new Error('Camera permission denied');
    }
  },
  async captureMeasurements() {
    try {
      const payload = await captureBurst('torso');
      return mapBurstToResult(payload);
    } catch (error) {
      console.error('[NativeCapture][Android] captureMeasurements failed', error);
      return {
        status: 'error',
        errorMessage: error instanceof Error ? error.message : 'Android capture failed',
      };
    }
  },
});

function mapBurstToResult(payload: MeasurementBurstPayload) {
  const firstSample = payload.samples[0];
  const captureId = payload.burstId;
  const timestamp = payload.capturedAt;

  return {
    status: 'completed' as const,
    metadata: {
      captureId,
      timestamp,
      platform: 'android',
      source: 'native-camera',
      deviceModel: Device.model,
      osVersion: Device.osVersion,
      burst: payload,
    },
    photos: firstSample
      ? [
          {
            uri: firstSample.rgbPlaceholder,
            view: payload.type,
          },
        ]
      : [],
    measurements: {
      distanceMeters: firstSample?.distanceMeters,
    },
  };
}
