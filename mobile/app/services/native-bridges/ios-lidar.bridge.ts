/**
 * TypeScript wrapper for iOS LiDAR Bridge
 * 
 * This module provides a TypeScript interface to the native Swift LiDAR bridge.
 */

import { isIOS } from '@nativescript/core';

interface LiDARCapabilities {
  hasLiDAR: boolean;
  hasTrueDepth: boolean;
  supportsDepthCapture: boolean;
}

interface CaptureResult {
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

/**
 * iOS LiDAR Bridge
 * Provides access to native iOS ARKit and LiDAR functionality
 */
export class IOSLiDARBridge {
  private nativeBridge: any;

  constructor() {
    if (!isIOS) {
      throw new Error('IOSLiDARBridge can only be used on iOS');
    }

    // Get reference to native Swift bridge
    // This will be available after NativeScript compiles the Swift code
    this.nativeBridge = FitTwinLiDARBridge.alloc().init();
  }

  /**
   * Check device capabilities for LiDAR and depth capture
   */
  async checkCapabilities(): Promise<LiDARCapabilities> {
    return new Promise((resolve) => {
      this.nativeBridge.checkCapabilities((capabilities: any) => {
        resolve({
          hasLiDAR: capabilities.hasLiDAR,
          hasTrueDepth: capabilities.hasTrueDepth,
          supportsDepthCapture: capabilities.supportsDepthCapture
        });
      });
    });
  }

  /**
   * Request camera permissions
   */
  async requestPermissions(): Promise<boolean> {
    return new Promise((resolve) => {
      this.nativeBridge.requestPermissions((granted: boolean) => {
        resolve(granted);
      });
    });
  }

  /**
   * Start LiDAR capture flow
   */
  async startCapture(): Promise<CaptureResult> {
    return new Promise((resolve, reject) => {
      this.nativeBridge.startCapture((result: any, error: any) => {
        if (error) {
          reject(new Error(error.localizedDescription));
        } else {
          resolve({
            frontImagePath: result.frontImagePath,
            sideImagePath: result.sideImagePath,
            depthDataAvailable: result.depthDataAvailable,
            timestamp: result.timestamp
          });
        }
      });
    });
  }

  /**
   * Extract depth map from captured image
   */
  async extractDepthMap(imagePath: string): Promise<DepthMap> {
    return new Promise((resolve, reject) => {
      this.nativeBridge.extractDepthMap(imagePath, (depthMap: any, error: any) => {
        if (error) {
          reject(new Error(error.localizedDescription));
        } else {
          resolve({
            width: depthMap.width,
            height: depthMap.height,
            format: depthMap.format,
            dataPath: depthMap.dataPath
          });
        }
      });
    });
  }
}

// Singleton instance
let instance: IOSLiDARBridge | null = null;

export function getIOSLiDARBridge(): IOSLiDARBridge {
  if (!instance && isIOS) {
    instance = new IOSLiDARBridge();
  }
  if (!instance) {
    throw new Error('IOSLiDARBridge not available on this platform');
  }
  return instance;
}
