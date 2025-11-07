/** @type {import('next').NextConfig} */
const backendBase = process.env.BACKEND_BASE_URL ?? 'http://localhost:3000';
const proxyBase = process.env.NEXT_PUBLIC_API_PROXY_BASE ?? '/api/backend';

const nextConfig = {
  reactStrictMode: true,
  async rewrites() {
    return [
      {
        source: `${proxyBase}/:path*`,
        destination: `${backendBase}/:path*`,
      },
    ];
  },
};

module.exports = nextConfig;
