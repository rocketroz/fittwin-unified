import { NextRequest } from 'next/server';

const BACKEND_BASE_URL = process.env.BACKEND_BASE_URL ?? 'http://localhost:3000';

async function proxy(request: NextRequest, context: { params: { path: string[] } }) {
  const segments = context.params.path ?? [];
  const targetUrl = new URL(`${BACKEND_BASE_URL}/${segments.join('/')}`.replace(/\/$/, ''));
  const search = request.nextUrl.search;
  if (search) {
    targetUrl.search = search;
  }

  const initHeaders = new Headers(request.headers);
  initHeaders.delete('host');
  initHeaders.delete('connection');
  initHeaders.delete('content-length');

  const body = request.body ? Buffer.from(await request.arrayBuffer()) : undefined;

  const backendResponse = await fetch(targetUrl, {
    method: request.method,
    headers: initHeaders,
    body,
    redirect: 'manual',
  });

  const responseHeaders = new Headers(backendResponse.headers);
  return new Response(backendResponse.body, {
    status: backendResponse.status,
    statusText: backendResponse.statusText,
    headers: responseHeaders,
  });
}

export const dynamic = 'force-dynamic';

export const GET = proxy;
export const POST = proxy;
export const PUT = proxy;
export const DELETE = proxy;
export const PATCH = proxy;
export const OPTIONS = proxy;
