#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const cwd = process.cwd();
const outputPath =
  process.env.TEST_STATUS_OUTPUT ??
  path.join(cwd, 'test-results', 'status.json');
const commands =
  process.env.TEST_STATUS_COMMANDS?.split(';').map((cmd) => cmd.trim()).filter(Boolean) ??
  ['npm run test:full'];

const env = {
  ...process.env,
  npm_config_workspaces: 'false',
};

const suites = [];

async function main() {
  await runTestCommands();
  await collectConnectivity();
  writePayload();
}

main().catch((error) => {
  console.error('[test-status] Fatal error', error);
  process.exitCode = 1;
});

async function runTestCommands() {
  for (const command of commands) {
    console.log(`\n[test-status] Running "${command}"…`);
    const start = Date.now();
    const result = spawnSync(command, {
      shell: true,
      env,
      encoding: 'utf8',
      maxBuffer: 10 * 1024 * 1024,
    });
    if (result.stdout) {
      process.stdout.write(result.stdout);
    }
    if (result.stderr) {
      process.stderr.write(result.stderr);
    }
    const durationMs = Date.now() - start;
    const status = result.status === 0 ? 'pass' : 'fail';
    suites.push({
      name: command,
      status,
      durationMs,
      details: summarizeOutput(result.stdout || result.stderr || ''),
    });
    if (result.error) {
      suites[suites.length - 1].details = `${suites[suites.length - 1].details}\n${result.error.message}`;
    }
    if (result.status !== 0) {
      console.warn(`[test-status] Command "${command}" exited with code ${result.status}.`);
    }
  }
}

async function collectConnectivity() {
  const endpoints = getEndpoints();
  const pings = buildPingList(endpoints);
  for (const ping of pings) {
    // eslint-disable-next-line no-await-in-loop
    suites.push(await pingHttp(ping));
  }

  const dbCheck = checkDatabase();
  if (dbCheck) {
    suites.push(dbCheck);
  }
}

function getEndpoints() {
  return {
    devStack: `http://localhost:${process.env.BACKEND_PORT ?? '3000'}`,
    measurementApi:
      process.env.NS_MEASUREMENTS_API_URL ??
      process.env.MEASUREMENTS_API_URL ??
      process.env.FITWIN_API_URL ??
      '',
    cameraApi: process.env.NS_LAB_URL ?? '',
    database:
      process.env.DATABASE_URL ??
      (process.env.DATABASE_MODE === 'supa'
        ? process.env.SUPABASE_URL ?? ''
        : `postgresql://localhost:${process.env.POSTGRES_PORT ?? '54322'}`),
  };
}

function buildPingList(endpoints) {
  const list = [];
  if (endpoints.devStack) {
    list.push({ name: 'backend', url: endpoints.devStack });
  }
  if (endpoints.measurementApi) {
    list.push({ name: 'measurementApi', url: endpoints.measurementApi });
  }
  if (endpoints.cameraApi) {
    list.push({ name: 'cameraLab', url: endpoints.cameraApi });
  }

  const extra = process.env.TEST_STATUS_PING_ENDPOINTS;
  if (extra) {
    extra
      .split(',')
      .map((entry) => entry.trim())
      .filter(Boolean)
      .forEach((entry) => {
        const [label, urlValue] = entry.split('|').map((value) => value.trim());
        if (label && urlValue) {
          list.push({ name: label, url: urlValue });
        }
      });
  }
  return list;
}

async function pingHttp({ name, url }) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), Number(process.env.TEST_STATUS_PING_TIMEOUT ?? 5000));
  try {
    const response = await fetch(url, { method: 'HEAD', signal: controller.signal });
    clearTimeout(timeout);
    return {
      name: `ping:${name}`,
      status: response.ok ? 'pass' : 'fail',
      durationMs: undefined,
      details: response.ok ? `${response.status} ${response.statusText}` : `HTTP ${response.status}`,
      endpoint: url,
    };
  } catch (error) {
    clearTimeout(timeout);
    const message = error instanceof Error ? error.message : String(error);
    return {
      name: `ping:${name}`,
      status: 'fail',
      details: message,
      endpoint: url,
    };
  }
}

function checkDatabase() {
  if ((process.env.TEST_STATUS_SKIP_DB_CHECK ?? '0') === '1') {
    return undefined;
  }
  const dbUrl = getEndpoints().database;
  if (!dbUrl) {
    return undefined;
  }
  const parsed = new URL(dbUrl);
  const host = parsed.hostname ?? 'localhost';
  const port = parsed.port || '5432';
  const result = spawnSync('pg_isready', ['-h', host, '-p', port, '-d', parsed.pathname.replace('/', '')], {
    encoding: 'utf8',
  });
  if (result.error && result.error.code === 'ENOENT') {
    return {
      name: 'database:pg_isready',
      status: 'fail',
      details: 'pg_isready not found (install libpq or skip via TEST_STATUS_SKIP_DB_CHECK=1)',
      endpoint: dbUrl,
    };
  }
  return {
    name: 'database:pg_isready',
    status: result.status === 0 ? 'pass' : 'fail',
    details: result.stdout.trim() || result.stderr.trim(),
    endpoint: dbUrl,
  };
}

function writePayload() {
  const endpoints = getEndpoints();
  const statusPayload = {
    updatedAt: new Date().toISOString(),
    databaseMode: process.env.DATABASE_MODE ?? 'local',
    endpoints,
    suites,
  };

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, JSON.stringify(statusPayload, null, 2));
  console.log(`[test-status] Wrote results to ${outputPath}`);
}

function summarizeOutput(output) {
  const lines = output.split('\n').map((line) => line.trim()).filter(Boolean);
  return lines.slice(-5).join(' | ');
}
