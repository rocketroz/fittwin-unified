import { isIOS } from '@nativescript/core';

interface LiDARCapabilities {
  hasLiDAR: boolean;
  hasTrueDepth: boolean;
  supportsDepthCapture: boolean;
}

export interface LiDARCaptureResult {
  frontImagePath: string;
  sideImagePath: string;
  depthDataAvailable: boolean;
  timestamp: number;
}

interface DepthMap {
  width: number;
  height: number;
  format: string;
  dataPath: string;
}

declare const FitTwinLiDARBridge: any;

default export class IOSLiDARBridge {
  private nativeBridge: any;

  constructor() {
    if (!isIOS) {
      throw new Error('IOSLiDARBridge can only be used on iOS');
    }

    this.nativeBridge = FitTwinLiDARBridge?.alloc?.()?.init?.();
    if (!this.nativeBridge) {
      throw new Error('FitTwinLiDARBridge not available. Ensure the Swift plugin is bundled.');
    }
  }

  checkCapabilities(): Promise<LiDARCapabilities> {
    return new Promise((resolve, reject) => {
      try {
        this.nativeBridge.checkCapabilities((capabilities: any) => {
          resolve({
            hasLiDAR: !!capabilities?.hasLiDAR,
            hasTrueDepth: !!capabilities?.hasTrueDepth,
            supportsDepthCapture: !!capabilities?.supportsDepthCapture,
          });
        });
      } catch (error) {
        reject(error);
      }
    });
  }

  requestPermissions(): Promise<boolean> {
    return new Promise((resolve, reject) => {
      try {
        this.nativeBridge.requestPermissions((granted: boolean) => resolve(!!granted));
      } catch (error) {
        reject(error);
      }
    });
  }

  startCapture(): Promise<LiDARCaptureResult> {
    return new Promise((resolve, reject) => {
      try {
        this.nativeBridge.startCapture((result: any, error: any) => {
          if (error) {
            reject(new Error(error.localizedDescription ?? 'LiDAR capture failed'));
            return;
          }

          resolve({
            frontImagePath: result.frontImagePath,
            sideImagePath: result.sideImagePath,
            depthDataAvailable: !!result.depthDataAvailable,
            timestamp: Number(result.timestamp ?? Date.now()),
          });
        });
      } catch (error) {
        reject(error);
      }
    });
  }

  extractDepthMap(imagePath: string): Promise<DepthMap> {
    return new Promise((resolve, reject) => {
      try {
        this.nativeBridge.extractDepthMap(imagePath, (depthMap: any, error: any) => {
          if (error) {
            reject(new Error(error.localizedDescription ?? 'Depth extraction failed'));
            return;
          }

          resolve({
            width: Number(depthMap.width ?? 0),
            height: Number(depthMap.height ?? 0),
            format: depthMap.format ?? 'float32',
            dataPath: depthMap.dataPath ?? '',
          });
        });
      } catch (error) {
        reject(error);
      }
    });
  }
}
