#!/usr/bin/env node
import { spawn } from 'node:child_process';

const isTurboChild = Boolean(process.env.TURBO_HASH || process.env.TURBO_TASK_NAME);
if (isTurboChild) {
  console.log('[turbo-tests] Nested turbo invocation detected; skipping to avoid recursion.');
  process.exit(0);
}

const extraArgs = process.argv.slice(2);
const turboArgs = extraArgs.length > 0 ? extraArgs : ['run', 'test'];

const timeoutMsRaw = Number(process.env.TURBO_TEST_TIMEOUT_MS ?? process.env.TEST_TIMEOUT_MS ?? 30_000);
const timeoutMs = Number.isFinite(timeoutMsRaw) && timeoutMsRaw > 0 ? timeoutMsRaw : 30_000;
const killGraceMs = Number(process.env.TURBO_TEST_KILL_GRACE_MS ?? 5_000);

const env = {
  ...process.env,
  CI: process.env.CI ?? '1',
};

const runner = process.platform === 'win32' ? 'npx.cmd' : 'npx';
const child = spawn(runner, ['turbo', ...turboArgs], {
  stdio: 'inherit',
  env,
});

let timedOut = false;
let killTimer;

const timeout = setTimeout(() => {
  timedOut = true;
  console.warn(`[turbo-tests] Command exceeded ${formatDuration(timeoutMs)}. Sending SIGTERM…`);
  child.kill('SIGTERM');
  killTimer = setTimeout(() => {
    if (!child.killed) {
      console.warn('[turbo-tests] Command still running; sending SIGKILL.');
      child.kill('SIGKILL');
    }
  }, killGraceMs);
  killTimer.unref?.();
}, timeoutMs);

timeout.unref?.();

child.on('exit', (code, signal) => {
  clearTimeout(timeout);
  if (killTimer) {
    clearTimeout(killTimer);
  }
  if (timedOut) {
    console.error(
      `[turbo-tests] Timed out after ${formatDuration(timeoutMs)}. Adjust TURBO_TEST_TIMEOUT_MS if you need a longer window.`,
    );
    process.exitCode = 124;
    return;
  }
  if (signal) {
    console.warn(`[turbo-tests] Exited via ${signal}.`);
    process.exitCode = 128;
    return;
  }
  process.exitCode = code;
});

child.on('error', (error) => {
  clearTimeout(timeout);
  if (killTimer) {
    clearTimeout(killTimer);
  }
  console.error('[turbo-tests] Failed to launch turbo run test:', error);
  process.exitCode = 1;
});

['SIGINT', 'SIGTERM'].forEach((sig) => {
  process.on(sig, () => {
    if (!child.killed) {
      child.kill(sig);
    }
  });
});

function formatDuration(ms) {
  if (!Number.isFinite(ms) || ms <= 0) {
    return 'configured timeout';
  }
  if (ms < 1000) {
    return `${ms}ms`;
  }
  const seconds = Math.round(ms / 1000);
  if (seconds < 60) {
    return `${seconds}s`;
  }
  const minutes = seconds / 60;
  if (minutes < 60) {
    return `${minutes.toFixed(minutes >= 10 ? 0 : 1)}m`;
  }
  const hours = minutes / 60;
  return `${hours.toFixed(hours >= 10 ? 0 : 1)}h`;
}
