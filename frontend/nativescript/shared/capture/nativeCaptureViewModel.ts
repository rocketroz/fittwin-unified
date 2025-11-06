import { Observable } from '@nativescript/core';
import { captureMeasurements, CaptureResult } from './index';
import {
  MeasurementSubmissionResponse,
  submitCaptureResult,
} from './measurementClient';

function formatSubmission(result: MeasurementSubmissionResponse | null) {
  if (!result) {
    return '';
  }

  const size = result.recommended_size
    ? `Recommended size: ${result.recommended_size}${
        result.confidence ? ` (${Math.round(result.confidence * 100)}% confidence)` : ''
      }`
    : 'Backend accepted capture.';

  return [size, result.measurements_cm ? `Measurements: ${JSON.stringify(result.measurements_cm)}` : undefined]
    .filter(Boolean)
    .join('\n');
}

export class NativeCaptureViewModel extends Observable {
  status = 'Ready';
  lastCapture: CaptureResult | null = null;
  lastSubmission: MeasurementSubmissionResponse | null = null;
  submissionSummary = '';

  constructor(private readonly autoSubmit = true) {
    super();
    this.set('status', this.status);
    this.set('submissionSummary', this.submissionSummary);
  }

  async startCapture() {
    this.set('status', 'Capturing…');
    this.set('submissionSummary', '');

    try {
      const capture = await captureMeasurements();
      this.lastCapture = capture;

      if (capture.status !== 'completed') {
        this.set('status', capture.errorMessage ?? `Status: ${capture.status}`);
        return;
      }

      if (!this.autoSubmit) {
        this.set('status', 'Capture completed. Submission disabled.');
        return;
      }

      this.set('status', 'Submitting to measurement service…');
      const submission = await submitCaptureResult(capture);
      this.lastSubmission = submission;

      const summary = formatSubmission(submission);
      this.set('submissionSummary', summary);
      this.set('status', summary || 'Capture submitted.');
    } catch (error) {
      console.error('[NativeCaptureViewModel] capture flow failed', error);
      this.set(
        'status',
        error instanceof Error ? error.message : 'Capture flow failed',
      );
    }
  }
}
