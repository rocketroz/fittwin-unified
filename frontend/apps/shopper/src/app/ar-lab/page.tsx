'use client';

import Link from 'next/link';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

type StackStatus = 'checking' | 'online' | 'offline';
type CameraPhase = 'checking' | 'idle' | 'requesting' | 'streaming' | 'unsupported' | 'error';

const FEATURE_FLAG = process.env.NEXT_PUBLIC_FEATURE_AR_LAB ?? process.env.FEATURE_AR_LAB;
const LAB_BRIEF_URL = 'https://www.notion.so/fittwin/FitTwin-AR-Lab-draft';

export default function ArLabPage() {
  const [stackStatus, setStackStatus] = useState<StackStatus>('checking');
  const [stackMessage, setStackMessage] = useState<string | null>(null);
  const [cameraPhase, setCameraPhase] = useState<CameraPhase>('checking');
  const [cameraMessage, setCameraMessage] = useState<string>('Checking camera capabilities…');
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);

  // Verify the backend is reachable so /ar-lab can function end-to-end.
  useEffect(() => {
    let cancelled = false;

    async function checkStack() {
      try {
        const response = await fetch('/api/backend/health', { cache: 'no-store' });
        if (cancelled) return;

        if (response.ok) {
          setStackStatus('online');
          setStackMessage('Backend health check succeeded.');
        } else {
          setStackStatus('offline');
          setStackMessage(`Backend health check failed (${response.status}).`);
        }
      } catch (_error) {
        if (!cancelled) {
          setStackStatus('offline');
          setStackMessage(
            'Unable to reach backend. Start the local stack with `node scripts/dev-stack.mjs`.',
          );
        }
      }
    }

    checkStack();

    return () => {
      cancelled = true;
    };
  }, []);

  // Detect camera support in the current environment.
  useEffect(() => {
    let mounted = true;

    if (typeof window === 'undefined') {
      return undefined;
    }

    const supportsCamera = !!navigator.mediaDevices?.getUserMedia;

    if (!supportsCamera) {
      if (mounted) {
        setCameraPhase('unsupported');
        setCameraMessage(
          'Camera access is unavailable in this environment. Connect a physical device to test the live capture experience.',
        );
      }
    } else if (mounted) {
      setCameraPhase('idle');
      setCameraMessage('Ready when you are. Launch capture to preview the live feed.');
    }

    return () => {
      mounted = false;
      if (streamRef.current) {
        streamRef.current.getTracks().forEach((track) => track.stop());
        streamRef.current = null;
      }
    };
  }, []);

  const startCapture = useCallback(async () => {
    if (cameraPhase === 'streaming' || cameraPhase === 'requesting') {
      return;
    }

    if (!navigator.mediaDevices?.getUserMedia) {
      setCameraPhase('unsupported');
      setCameraMessage('Camera API unavailable. Test on a physical device to enable live capture.');
      return;
    }

    try {
      setCameraPhase('requesting');
      setCameraMessage('Requesting camera access…');
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'environment' },
        audio: false,
      });

      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        await videoRef.current.play().catch(() => undefined);
      }

      setCameraPhase('streaming');
      setCameraMessage('Live preview active. Align the subject within the guides and hold steady.');
    } catch (_error) {
      console.error('AR Lab camera error', error);
      const description =
        error instanceof Error ? error.message : 'Camera permission was denied or unavailable.';
      setCameraPhase('error');
      setCameraMessage(description);
    }
  }, [cameraPhase]);

  const stopCapture = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    }

    if (videoRef.current) {
      videoRef.current.pause();
      videoRef.current.srcObject = null;
    }

    if (navigator.mediaDevices?.getUserMedia) {
      setCameraPhase('idle');
      setCameraMessage('Capture paused. Relaunch the preview when you are ready.');
    } else {
      setCameraPhase('unsupported');
      setCameraMessage('Camera API unavailable in this environment.');
    }
  }, []);

  const checklist = useMemo(
    () => [
      {
        title: 'Start the FitTwin stack',
        detail:
          'Launch `node scripts/dev-stack.mjs` in the project root. The script boots the backend and shopper web app on ports 3000/3001.',
      },
      {
        title: 'Open the shopper app',
        detail:
          'Visit http://localhost:3001 in your desktop browser to confirm the AR Lab route renders.',
      },
      {
        title: 'Point the native shell',
        detail:
          'In the NativeScript shell, keep the URL field set to http://localhost:3001/ar-lab or paste a custom endpoint.',
      },
      {
        title: 'Switch to a physical device',
        detail:
          'Connect an iOS/Android device to validate AR capture with the real camera feed. Simulators show the guided placeholder instead.',
      },
    ],
    [],
  );

  const captureSteps = useMemo(
    () => [
      {
        label: 'Calibrate',
        copy: 'Place the FitTwin scale marker or reference object within the frame so the adapter can normalize measurements.',
      },
      {
        label: 'Capture burst',
        copy: 'Record 6–10 frames while guiding the shopper through positioning prompts (shoe, hem, torso).',
      },
      {
        label: 'QA feedback',
        copy: 'Display fit notes, confidence, and instructions for retakes when the quality gates fail.',
      },
    ],
    [],
  );

  const pipeline = useMemo(
    () => [
      'Submit burst → /measure/burst (metrics, QA gates)',
      'Tailor worker aligns metrics with catalog + fit map',
      'Return size recommendation + style insights to shopper',
      'Optional: feed assets into Virtual Tailor projection',
    ],
    [],
  );

  const featureEnabled = FEATURE_FLAG === '1';

  return (
    <main className="ar-lab">
      <section className="ar-lab__section ar-lab__hero">
        <span className="ar-lab__tag">FitTwin Labs</span>
        <h1 className="ar-lab__title">AR Measurement Lab</h1>
        <p className="ar-lab__subtitle">
          Stage, test, and iterate on the capture-to-recommendation pipeline. This module will host
          the production AR adapter once native ARKit/ARCore capture lands. Until then, use the
          guided preview to rehearse the flow and validate integrations.
        </p>
        <div className="ar-lab__hero-actions">
          <Link
            href={LAB_BRIEF_URL}
            target="_blank"
            rel="noreferrer"
            className="ar-lab__button ar-lab__button--primary"
          >
            Read the design brief →
          </Link>
          <a
            href="mailto:labs@fittwin.ai?subject=AR%20Lab%20Feedback"
            className="ar-lab__button ar-lab__button--ghost"
          >
            Share feedback
          </a>
        </div>
      </section>

      {!featureEnabled && (
        <section className="ar-lab__section ar-lab__callout">
          <h2>Feature flag disabled</h2>
          <p>
            Set <code>NEXT_PUBLIC_FEATURE_AR_LAB=1</code> (or update <code>stack.env</code>) and
            restart the web app to expose this view in production.
          </p>
        </section>
      )}

      <section className="ar-lab__section ar-lab__capture">
        <div className="ar-lab__capture-media">
          <div className="ar-lab__preview">
            <video
              ref={videoRef}
              className={`ar-lab__video ${cameraPhase === 'streaming' ? 'is-visible' : ''}`}
              playsInline
              muted
            />
            {cameraPhase !== 'streaming' && (
              <div className="ar-lab__placeholder">
                <div className="ar-lab__placeholder-graphic">
                  <span className="ar-lab__placeholder-circle" />
                  <span className="ar-lab__placeholder-rect" />
                  <span className="ar-lab__placeholder-line" />
                </div>
                <p>
                  {cameraPhase === 'unsupported'
                    ? 'Simulator mode. Connect a physical device to unlock live camera capture.'
                    : 'Live preview paused. Start capture to activate getUserMedia.'}
                </p>
              </div>
            )}
          </div>

          <div className="ar-lab__controls">
            <div className="ar-lab__control-row">
              <button
                type="button"
                className="ar-lab__button ar-lab__button--primary"
                onClick={startCapture}
                disabled={
                  cameraPhase === 'streaming' ||
                  cameraPhase === 'requesting' ||
                  cameraPhase === 'unsupported'
                }
              >
                {cameraPhase === 'requesting'
                  ? 'Requesting access…'
                  : cameraPhase === 'streaming'
                    ? 'Streaming'
                    : 'Start capture'}
              </button>
              <button
                type="button"
                className="ar-lab__button ar-lab__button--ghost"
                onClick={stopCapture}
                disabled={cameraPhase !== 'streaming'}
              >
                Stop
              </button>
            </div>
            <p className="ar-lab__status-text">{cameraMessage}</p>
            {cameraPhase === 'unsupported' && (
              <p className="ar-lab__status-note">
                Simulators block camera APIs. Build and run the NativeScript shell on a device (or
                load this page in a mobile browser) to verify live capture.
              </p>
            )}
          </div>
        </div>

        <aside className="ar-lab__capture-notes">
          <h3>Guided capture flow</h3>
          <ul className="ar-lab__list">
            {captureSteps.map((step) => (
              <li key={step.label} className="ar-lab__list-item">
                <span className="ar-lab__pill">{step.label}</span>
                <p>{step.copy}</p>
              </li>
            ))}
          </ul>
        </aside>
      </section>

      <section className="ar-lab__grid">
        <div className="ar-lab__section">
          <div className="ar-lab__grid-header">
            <h2>Environment check</h2>
            <span className={`ar-lab__status-badge ar-lab__status-badge--${stackStatus}`}>
              <span className="ar-lab__status-dot" />
              {stackStatus === 'checking' && 'Checking…'}
              {stackStatus === 'online' && 'Online'}
              {stackStatus === 'offline' && 'Offline'}
            </span>
          </div>
          <p className="ar-lab__status-text">{stackMessage ?? 'Verifying backend connectivity.'}</p>
          <ul className="ar-lab__list ar-lab__list--compact">
            {checklist.map((item) => (
              <li key={item.title} className="ar-lab__list-item">
                <strong>{item.title}</strong>
                <p>{item.detail}</p>
              </li>
            ))}
          </ul>
        </div>

        <div className="ar-lab__section">
          <h2>Pipeline snapshot</h2>
          <p className="ar-lab__status-text">
            Each burst flows through measurement QA, tailoring, and optional projection. Use these
            milestones to verify end-to-end coverage.
          </p>
          <ol className="ar-lab__pipeline">
            {pipeline.map((entry) => (
              <li key={entry}>{entry}</li>
            ))}
          </ol>
        </div>
      </section>

      <section className="ar-lab__section ar-lab__footer">
        <h2>What’s next?</h2>
        <p>
          Swap the placeholder adapter for the production AR capture module. When the measurement
          service lands, post the burst payload to
          <code>/measure/burst</code> and surface the QA results directly in this view. Until then,
          the lab doubles as a staging ground for UX, camera prompts, and onboarding flows.
        </p>
      </section>
    </main>
  );
}
