import type { Metadata, Viewport } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

// コンポーネント
import ErrorBoundary from '@/components/ErrorBoundary';
import { StoreInitializer } from '@/components/StoreInitializer';
import PWAWrapper from '@/components/PWAWrapper';

const inter = Inter({ subsets: ['latin'] });

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  themeColor: '#3b82f6',
};

export const metadata: Metadata = {
  title: 'GuessNumber - 数当てゲーム',
  description: '楽しい数当てゲーム - PWA対応で、オフラインでも遊べます。',
  manifest: '/manifest.json',
  keywords: ['ゲーム', '数当て', 'PWA', 'オフライン', '学習'],
  authors: [{ name: 'GuessNumber Team' }],
  creator: 'GuessNumber Team',
  publisher: 'GuessNumber Team',
  applicationName: 'GuessNumber',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'default',
    title: 'GuessNumber',
  },
  formatDetection: {
    telephone: false,
  },
  openGraph: {
    type: 'website',
    siteName: 'GuessNumber',
    title: 'GuessNumber - 数当てゲーム',
    description: '楽しい数当てゲーム - PWA対応で、オフラインでも遊べます。',
    locale: 'ja_JP',
  },
  twitter: {
    card: 'summary',
    title: 'GuessNumber - 数当てゲーム',
    description: '楽しい数当てゲーム - PWA対応で、オフラインでも遊べます。',
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ja" suppressHydrationWarning>
      <head>
        {/* PWA対応メタタグ */}
        <link rel="apple-touch-icon" href="/icons/icon-192x192.png" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="default" />
        <meta name="apple-mobile-web-app-title" content="GuessNumber" />
        <meta name="mobile-web-app-capable" content="yes" />
        
        {/* フォント最適化 */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
      </head>
      <body className={`${inter.className} bg-slate-50 text-slate-900 antialiased`}>
        {/* メインアプリケーション */}
        <div className="min-h-screen flex flex-col">
          <header className="bg-primary-600 text-white shadow-lg">
            <div className="container mx-auto px-4 py-4">
              <h1 className="text-2xl font-bold text-center">
                🎯 GuessNumber
              </h1>
              <p className="text-center text-primary-100 text-sm mt-1">
                数当てゲーム
              </p>
            </div>
          </header>
          
          <main className="flex-1 container mx-auto px-4 py-6 max-w-4xl">
            <PWAWrapper>
              <ErrorBoundary
                onError={(error, errorInfo) => {
                  console.error('Application Error:', error, errorInfo);
                  // 本番環境では外部ログサービスに送信可能
                }}
                maxRetries={3}
              >
                <StoreInitializer />
                {children}
              </ErrorBoundary>
            </PWAWrapper>
          </main>
          
          <footer className="bg-slate-200 text-slate-600 py-4 text-center text-sm">
            <div className="container mx-auto px-4">
              <p>&copy; 2025 GuessNumber. Made with Next.js 15</p>
              <p className="mt-1 text-xs">
                PWA対応 | オフラインプレイ可能
              </p>
            </div>
          </footer>
        </div>
        
        {/* Service Worker登録用スクリプト */}
        {process.env.NODE_ENV === 'production' && (
          <script
            dangerouslySetInnerHTML={{
              __html: `
                if ('serviceWorker' in navigator) {
                  window.addEventListener('load', () => {
                    navigator.serviceWorker.register('/sw.js')
                      .then((registration) => {
                        console.log('SW registered: ', registration);
                      })
                      .catch((registrationError) => {
                        console.log('SW registration failed: ', registrationError);
                      });
                  });
                }
              `,
            }}
          />
        )}
      </body>
    </html>
  );
}