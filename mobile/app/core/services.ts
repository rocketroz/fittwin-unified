/**
 * Service initialization and dependency injection setup
 */

import { ApiClient } from '@shared/api-client';
import { MeasurementService } from '../services/measurement.service';
import { CameraService } from '../services/camera.service';
import { AuthService } from '../services/auth.service';

// Service instances
let apiClient: ApiClient;
let measurementService: MeasurementService;
let cameraService: CameraService;
let authService: AuthService;

export function setupServices(): void {
  console.log('Setting up services...');

  // Initialize API client
  apiClient = new ApiClient({
    baseUrl: process.env.API_URL || 'http://localhost:8000',
    apiKey: process.env.API_KEY || 'staging-secret-key'
  });

  // Initialize services
  measurementService = new MeasurementService(apiClient);
  cameraService = new CameraService();
  authService = new AuthService(apiClient);

  console.log('Services initialized');
}

// Service getters
export function getApiClient(): ApiClient {
  return apiClient;
}

export function getMeasurementService(): MeasurementService {
  return measurementService;
}

export function getCameraService(): CameraService {
  return cameraService;
}

export function getAuthService(): AuthService {
  return authService;
}
