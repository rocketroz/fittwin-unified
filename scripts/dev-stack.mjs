#!/usr/bin/env node
import fs from 'node:fs';
import { spawn, spawnSync } from 'node:child_process';
import path from 'node:path';
import process from 'node:process';
import url from 'node:url';

const dbMode = (process.env.DATABASE_MODE ?? 'local').toLowerCase();
const scriptDir = path.dirname(url.fileURLToPath(import.meta.url));
const rootDir = path.resolve(scriptDir, '..');
const preflightEnabled = (process.env.DEV_STACK_PREFLIGHT ?? '1') !== '0';
const manageDb = (process.env.DEV_STACK_MANAGE_DB ?? 'auto').toLowerCase();
const portList =
  process.env.DEV_STACK_PORTS?.split(',').map((value) => value.trim()).filter(Boolean) ?? [
    process.env.BACKEND_PORT ?? '3000',
    process.env.SHOPPER_PORT ?? '3001',
    process.env.BRAND_PORT ?? '3100',
  ];
const killPatterns =
  process.env.DEV_STACK_KILL_PATTERNS?.split(',').map((value) => value.trim()).filter(Boolean) ??
  ['scripts/dev-stack.mjs', 'next dev', 'npm run backend:dev', 'ns run', 'xcodebuild', 'Simulator'];
let lsofAvailable = true;
let pkillAvailable = true;
let dockerCheckRan = false;
let dockerAvailable = false;
let psqlCheckRan = false;
let psqlAvailable = false;

const services = [
  {
    label: 'backend',
    command: 'npx',
    args: [
      'nodemon',
      '--watch',
      'backend/src',
      '--ext',
      'ts,js,json',
      '--exec',
      'npm run backend:dev',
    ],
    env: {
      PORT: process.env.BACKEND_PORT ?? '3000',
      HOST: '0.0.0.0',
      DATABASE_MODE: process.env.DATABASE_MODE ?? 'local',
    },
  },
  {
    label: 'shopper',
    command: 'npm',
    args: ['--prefix', 'frontend/apps/shopper', 'run', 'dev'],
    env: {
      PORT: process.env.SHOPPER_PORT ?? '3001',
      BACKEND_BASE_URL: `http://localhost:${process.env.BACKEND_PORT ?? '3000'}`,
      NEXT_PUBLIC_BACKEND_BASE_URL: `http://localhost:${process.env.BACKEND_PORT ?? '3000'}`,
      NEXT_PUBLIC_API_PROXY_BASE: process.env.NEXT_PUBLIC_API_PROXY_BASE ?? '/api/backend',
      E2E_SHOPPER_URL: `http://localhost:${process.env.SHOPPER_PORT ?? '3001'}`,
    },
  },
  {
    label: 'brand',
    command: 'npm',
    args: ['--prefix', 'frontend/apps/brand-portal', 'run', 'dev'],
    env: {
      PORT: process.env.BRAND_PORT ?? '3100',
      BACKEND_BASE_URL: `http://localhost:${process.env.BACKEND_PORT ?? '3000'}`,
      NEXT_PUBLIC_BACKEND_BASE_URL: `http://localhost:${process.env.BACKEND_PORT ?? '3000'}`,
      NEXT_PUBLIC_API_PROXY_BASE: process.env.NEXT_PUBLIC_API_PROXY_BASE ?? '/api/backend',
      E2E_BRAND_URL: `http://localhost:${process.env.BRAND_PORT ?? '3100'}`,
    },
  },
];

const children = [];
let shuttingDown = false;

function cleanupLingeringProcesses() {
  if (!preflightEnabled) {
    console.log('[dev-stack] Prefight cleanup disabled (DEV_STACK_PREFLIGHT=0).');
    return;
  }

  console.log('[dev-stack] Checking for lingering FitTwin processes...');
  for (const port of portList) {
    killPort(port);
  }

  if (process.platform === 'win32') {
    console.log('[dev-stack] Pattern-based cleanup is skipped on Windows. Use DEV_STACK_KILL_PATTERNS manually if needed.');
    return;
  }

  for (const pattern of killPatterns) {
    killPattern(pattern);
  }
}

function killPort(port) {
  if (!port || !lsofAvailable) {
    return;
  }
  const result = spawnSync('lsof', ['-ti', `tcp:${port}`], { encoding: 'utf8' });
  if (result.error) {
    if (result.error.code === 'ENOENT' && lsofAvailable) {
      lsofAvailable = false;
      console.warn('[dev-stack] lsof not found; skipping port cleanup. Install lsof or set DEV_STACK_PREFLIGHT=0 to silence this.');
    }
    return;
  }
  if (result.status !== 0 || !result.stdout.trim()) {
    return;
  }
  const pids = [...new Set(result.stdout.trim().split('\n').filter(Boolean))];
  for (const pid of pids) {
    try {
      process.kill(Number(pid), 'SIGTERM');
      console.log(`[dev-stack] Terminated PID ${pid} listening on port ${port}.`);
    } catch (error) {
      console.warn(`[dev-stack] Failed to kill PID ${pid} on port ${port}: ${error.message}`);
    }
  }
}

function killPattern(pattern) {
  if (!pattern || !pkillAvailable) {
    return;
  }
  const result = spawnSync('pkill', ['-f', pattern], { stdio: 'ignore' });
  if (result.error) {
    if (result.error.code === 'ENOENT' && pkillAvailable) {
      pkillAvailable = false;
      console.warn('[dev-stack] pkill not found; skipping pattern cleanup. Install procps or set DEV_STACK_KILL_PATTERNS="" to skip.');
    }
    return;
  }
  if (result.status === 0) {
    console.log(`[dev-stack] Stopped lingering process matching "${pattern}".`);
  }
}

function postgresIsReady(port) {
  const result = spawnSync('pg_isready', ['-q', '-p', String(port)], { env: process.env });
  if (result.error && result.error.code === 'ENOENT') {
    console.warn('[dev-stack] pg_isready not found; install PostgreSQL client tools for readiness probes.');
    return false;
  }
  return result.status === 0;
}

function ensureLocalPostgres() {
  const dbAutomationEnabled = manageDb !== 'off' && manageDb !== '0';
  if (!dbAutomationEnabled) {
    console.log(`[dev-stack] Skipping Postgres bootstrap (DEV_STACK_MANAGE_DB=${manageDb}).`);
    return;
  }

  const port = Number(process.env.POSTGRES_PORT ?? '54322');
  if (Number.isNaN(port)) {
    console.warn('[dev-stack] Invalid POSTGRES_PORT; falling back to 54322.');
  }
  if (postgresIsReady(port)) {
    console.log(`[dev-stack] Local Postgres already running on port ${port}.`);
    return;
  }

  const setupScript = path.join(rootDir, 'scripts', 'setup_postgres_test_db.sh');
  if (!fs.existsSync(setupScript)) {
    console.warn('[dev-stack] Cannot find scripts/setup_postgres_test_db.sh, skipping automatic Postgres bootstrap.');
    return;
  }

  let startDocker = process.env.START_DOCKER ?? '0';
  const dockerReady = startDocker !== '0' && isDockerAvailable();
  if (startDocker !== '0' && !dockerReady) {
    console.warn('[dev-stack] Docker daemon not reachable; falling back to START_DOCKER=0. Ensure Postgres is running manually.');
    startDocker = '0';
  }

  const psqlReady = hasPsql();
  if (!psqlReady) {
    console.warn(
      '[dev-stack] psql command unavailable; skipping automatic Postgres bootstrap. Start your own Postgres instance or install PostgreSQL client tools.',
    );
    return;
  }

  console.log('[dev-stack] Bootstrapping local Postgres for DATABASE_MODE=local...');
  const env = {
    ...process.env,
    START_DOCKER: startDocker,
    POSTGRES_PORT: String(port),
  };
  const result = spawnSync('bash', [setupScript], { stdio: 'inherit', env });
  if (result.status !== 0) {
    console.warn('[dev-stack] Postgres bootstrap exited with errors; backend may fail if DATABASE_MODE=local.');
  }
}

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

function isDockerAvailable() {
  if (dockerCheckRan) {
    return dockerAvailable;
  }
  dockerCheckRan = true;
  try {
    const result = spawnSync('docker', ['info'], {
      stdio: 'ignore',
      timeout: 2000,
    });
    dockerAvailable = result.status === 0;
    if (!dockerAvailable) {
      console.warn('[dev-stack] docker info exited with non-zero status; treating Docker as unavailable.');
    }
  } catch (error) {
    dockerAvailable = false;
    if (error.code === 'ENOENT') {
      console.warn('[dev-stack] docker command not found. Install Docker or set START_DOCKER=0.');
    } else {
      console.warn(`[dev-stack] Unable to query Docker daemon (${error.message}).`);
    }
  }
  return dockerAvailable;
}

function hasPsql() {
  if (psqlCheckRan) {
    return psqlAvailable;
  }
  psqlCheckRan = true;
  try {
    const result = spawnSync('psql', ['--version'], { stdio: 'ignore' });
    psqlAvailable = result.status === 0;
    if (!psqlAvailable) {
      console.warn('[dev-stack] psql command returned non-zero status; migrations may be skipped.');
    }
  } catch (error) {
    psqlAvailable = false;
    if (error.code === 'ENOENT') {
      console.warn('[dev-stack] psql command not found. Install PostgreSQL client tools or rely on Docker-managed Postgres.');
    } else {
      console.warn(`[dev-stack] Unable to invoke psql (${error.message}).`);
    }
  }
  return psqlAvailable;
}

process.on('SIGINT', () => shutdown(0));
process.on('SIGTERM', () => shutdown(0));

cleanupLingeringProcesses();
if (dbMode === 'local') {
  ensureLocalPostgres();
} else if (dbMode !== 'supa') {
  console.log(`[dev-stack] DATABASE_MODE=${dbMode}; skipping Postgres bootstrap.`);
}

console.log(`[dev-stack] Starting FitTwin stack (database mode: ${dbMode}). Press Ctrl+C to stop.`);
for (const service of services) {
  runService(service);
}
