#!/usr/bin/env node
import { spawn, spawnSync } from 'node:child_process';
import path from 'node:path';
import process from 'node:process';
import url from 'node:url';

const dbMode = (process.env.DATABASE_MODE ?? 'local').toLowerCase();
const scriptDir = path.dirname(url.fileURLToPath(import.meta.url));
const rootDir = path.resolve(scriptDir, '..');

const backendPort = process.env.BACKEND_PORT ?? '3000';
const shopperPort = process.env.SHOPPER_PORT ?? '3001';
const brandPort = process.env.BRAND_PORT ?? '3100';

const services = [
  {
    label: 'backend',
    command: 'npx',
    args: ['nodemon', '--watch', 'backend/src', '--ext', 'ts,js,json', '--exec', 'npm run backend:dev'],
    env: {
      PORT: backendPort,
      HOST: '0.0.0.0',
      DATABASE_MODE: process.env.DATABASE_MODE ?? 'local',
    },
  },
  {
    label: 'shopper',
    command: 'npm',
    args: ['run', 'dev', '--workspace', 'frontend/apps/shopper'],
    env: {
      PORT: shopperPort,
      BACKEND_BASE_URL: `http://localhost:${backendPort}`,
      NEXT_PUBLIC_BACKEND_BASE_URL: `http://localhost:${backendPort}`,
      NEXT_PUBLIC_API_PROXY_BASE: process.env.NEXT_PUBLIC_API_PROXY_BASE ?? '/api/backend',
      E2E_SHOPPER_URL: `http://localhost:${shopperPort}`,
    },
  },
  {
    label: 'brand',
    command: 'npm',
    args: ['run', 'dev', '--workspace', 'frontend/apps/brand-portal'],
    env: {
      PORT: brandPort,
      BACKEND_BASE_URL: `http://localhost:${backendPort}`,
      NEXT_PUBLIC_BACKEND_BASE_URL: `http://localhost:${backendPort}`,
      NEXT_PUBLIC_API_PROXY_BASE: process.env.NEXT_PUBLIC_API_PROXY_BASE ?? '/api/backend',
      E2E_BRAND_URL: `http://localhost:${brandPort}`,
    },
  },
];

function ensurePortFree(port, label) {
  const lookup = spawnSync('lsof', ['-ti', `tcp:${port}`], { encoding: 'utf8' });
  if (lookup.status !== 0 || !lookup.stdout.trim()) {
    return;
  }
  console.log(`[dev-stack] ${label} port ${port} already in use; terminating existing processes.`);
  for (const pid of lookup.stdout.trim().split('\n')) {
    if (!pid) continue;
    try {
      process.kill(Number(pid), 'SIGTERM');
    } catch {
      // ignore; process may already be gone
    }
  }
}

const portGuards = [
  { port: backendPort, label: 'backend' },
  { port: shopperPort, label: 'shopper' },
  { port: brandPort, label: 'brand' },
];

for (const guard of portGuards) {
  ensurePortFree(guard.port, guard.label);
}

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

console.log(`[dev-stack] Starting FitTwin stack (database mode: ${dbMode}). Press Ctrl+C to stop.`);
for (const service of services) {
  runService(service);
}
