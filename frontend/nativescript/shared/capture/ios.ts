import { Device, isIOS } from '@nativescript/core';
import { registerCaptureService } from './index';
import IOSLiDARBridge from './ios/bridge';

let bridge: IOSLiDARBridge | null = null;

registerCaptureService({
  async isSupported() {
    if (!isIOS) {
      return false;
    }

    try {
      ensureBridge();
      const capabilities = await bridge!.checkCapabilities();
      return capabilities.supportsDepthCapture || capabilities.hasTrueDepth;
    } catch (error) {
      console.warn('[NativeCapture][iOS] Capability probe failed', error);
      return false;
    }
  },
  async requestPermissions() {
    ensureBridge();
    const granted = await bridge!.requestPermissions();
    if (!granted) {
      throw new Error('Camera permission denied');
    }
  },
  async captureMeasurements() {
    ensureBridge();
    try {
      const result = await bridge!.startCapture();
      const captureId = `ios-${result.timestamp}`;
      return {
        status: 'completed' as const,
        photos: [
          { uri: result.frontImagePath, view: 'front' },
          { uri: result.sideImagePath, view: 'side' },
        ].filter((photo) => !!photo.uri),
        metadata: {
          captureId,
          timestamp: result.timestamp,
          platform: 'ios',
          source: 'native-camera',
          deviceModel: Device.model,
          osVersion: Device.osVersion,
          depthAvailable: result.depthDataAvailable,
        },
        measurements: {
          depthAvailable: result.depthDataAvailable,
        },
      };
    } catch (error) {
      console.error('[NativeCapture][iOS] captureMeasurements failed', error);
      return {
        status: 'error',
        errorMessage: error instanceof Error ? error.message : 'iOS capture failed',
      };
    }
  },
});

function ensureBridge() {
  if (!bridge) {
    bridge = new IOSLiDARBridge();
  }
}
