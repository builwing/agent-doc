import withPWA from 'next-pwa';

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Next.js 15設定
  reactStrictMode: true,
  experimental: {
    // Next.js 15の新機能を有効化
    scrollRestoration: true,
  },
};

// PWA設定を適用
export default withPWA({
  dest: 'public',
  register: true,
  skipWaiting: true,
  disable: process.env.NODE_ENV === 'development',
  runtimeCaching: [
    {
      urlPattern: /^https?.*/,
      handler: 'NetworkFirst',
      options: {
        cacheName: 'offlineCache',
        expiration: {
          maxEntries: 200,
          maxAgeSeconds: 24 * 60 * 60, // 24時間
        },
      },
    },
  ],
})(nextConfig);