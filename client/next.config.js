/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  images: {
    domains: ['localhost'],
    remotePatterns: [
      {
        protocol: 'http',
        hostname: 'localhost',
        port: '8088',
        pathname: '/media/**',
      },
    ],
  },
  i18n: {
    locales: ['en', 'ne'],
    defaultLocale: 'en',
  },
  eslint: {
    ignoreDuringBuilds: true
  }
}

module.exports = nextConfig
