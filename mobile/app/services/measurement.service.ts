/**
 * Measurement Service
 * 
 * Handles body measurement extraction, validation, and submission to backend API.
 */

import { ApiClient } from '@shared/api-client';

export interface MeasurementData {
  waist_natural: number;
  hip_low: number;
  chest?: number;
  inseam?: number;
  unit: 'in' | 'cm';
  session_id: string;
  model_version: string;
  confidence?: number;
}

export interface MeasurementValidationResult {
  valid: boolean;
  errors?: string[];
  warnings?: string[];
}

export interface SizeRecommendation {
  size: string;
  confidence: number;
  fit_notes: string[];
  alternatives?: Array<{
    size: string;
    delta: string;
  }>;
}

export class MeasurementService {
  constructor(private apiClient: ApiClient) {}

  /**
   * Validate measurements before submission
   */
  async validateMeasurements(data: MeasurementData): Promise<MeasurementValidationResult> {
    try {
      const response = await this.apiClient.post('/measurements/validate', data);
      return response.data;
    } catch (error) {
      console.error('Failed to validate measurements:', error);
      throw error;
    }
  }

  /**
   * Get size recommendations based on measurements
   */
  async getRecommendations(data: MeasurementData): Promise<SizeRecommendation[]> {
    try {
      const response = await this.apiClient.post('/measurements/recommend', {
        waist_natural_cm: data.unit === 'cm' ? data.waist_natural : data.waist_natural * 2.54,
        hip_low_cm: data.unit === 'cm' ? data.hip_low : data.hip_low * 2.54,
        chest_cm: data.chest ? (data.unit === 'cm' ? data.chest : data.chest * 2.54) : undefined,
        model_version: data.model_version
      });
      return response.data.recommendations;
    } catch (error) {
      console.error('Failed to get recommendations:', error);
      throw error;
    }
  }

  /**
   * Submit measurements with provenance data
   */
  async submitMeasurements(data: MeasurementData, provenance: any): Promise<string> {
    try {
      const response = await this.apiClient.post('/measurements/submit', {
        ...data,
        provenance
      });
      return response.data.measurement_id;
    } catch (error) {
      console.error('Failed to submit measurements:', error);
      throw error;
    }
  }
}
