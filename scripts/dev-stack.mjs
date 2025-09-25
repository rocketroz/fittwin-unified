#!/usr/bin/env node
import { spawn } from 'node:child_process';
import process from 'node:process';

const services = [
  {
    label: 'backend',
    command: 'npm',
    args: ['run', 'start:dev', '--workspace', 'backend'],
    env: {
      PORT: process.env.BACKEND_PORT ?? '3000',
      HOST: '0.0.0.0',
    },
  },
  {
    label: 'shopper',
    command: 'npm',
    args: ['run', 'dev', '--workspace', 'frontend/apps/shopper'],
    env: {
      PORT: process.env.SHOPPER_PORT ?? '3001',
      BACKEND_BASE_URL: `http://localhost:${process.env.BACKEND_PORT ?? '3000'}`,
      NEXT_PUBLIC_API_PROXY_BASE: process.env.NEXT_PUBLIC_API_PROXY_BASE ?? '/api/backend',
      E2E_SHOPPER_URL: `http://localhost:${process.env.SHOPPER_PORT ?? '3001'}`,
    },
  },
  {
    label: 'brand',
    command: 'npm',
    args: ['run', 'dev', '--workspace', 'frontend/apps/brand-portal'],
    env: {
      PORT: process.env.BRAND_PORT ?? '3100',
      BACKEND_BASE_URL: `http://localhost:${process.env.BACKEND_PORT ?? '3000'}`,
      NEXT_PUBLIC_API_PROXY_BASE: process.env.NEXT_PUBLIC_API_PROXY_BASE ?? '/api/backend',
      E2E_BRAND_URL: `http://localhost:${process.env.BRAND_PORT ?? '3100'}`,
    },
  },
];

const children = [];
let shuttingDown = false;

function runService({ label, command, args, env }) {
  const child = spawn(command, args, {
    stdio: 'inherit',
    env: {
      ...process.env,
      ...env,
    },
    shell: process.platform === 'win32',
  });

  children.push({ label, child });

  child.on('exit', (code, signal) => {
    if (shuttingDown) {
      return;
    }
    console.log(`\n[dev-stack] ${label} exited with code ${code ?? 'null'} signal ${signal ?? 'null'}. Shutting down remaining services.`);
    shutdown(code ?? 0);
  });
}

function shutdown(exitCode = 0) {
  shuttingDown = true;
  for (const { child, label } of children) {
    if (child.exitCode === null) {
      console.log(`[dev-stack] stopping ${label}…`);
      child.kill('SIGTERM');
    }
  }
  setTimeout(() => process.exit(exitCode), 250);
}

process.on('SIGINT', () => shutdown(0));
process.on('SIGTERM', () => shutdown(0));

console.log('[dev-stack] Starting FitTwin stack. Press Ctrl+C to stop.');
for (const service of services) {
  runService(service);
}
