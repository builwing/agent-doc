/**
 * PWAWrapper - PWA機能管理コンポーネント
 * Service Worker、オフライン状態、インストール促進を管理
 * Next.js 15 + next-pwa最適化
 */

'use client';

import React, { useEffect, useState, useCallback } from 'react';
import { Button } from '@/components/ui/Button';
import { Card, CardContent } from '@/components/ui/Card';
import { cn } from '@/lib/utils';

interface BeforeInstallPromptEvent extends Event {
  readonly platforms: string[];
  readonly userChoice: Promise<{
    outcome: 'accepted' | 'dismissed';
    platform: string;
  }>;
  prompt(): Promise<void>;
}

declare global {
  interface WindowEventMap {
    beforeinstallprompt: BeforeInstallPromptEvent;
  }
}

export const PWAWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // PWA状態管理
  const [isOnline, setIsOnline] = useState(true);
  const [installPrompt, setInstallPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  const [showInstallBanner, setShowInstallBanner] = useState(false);
  const [isInstalled, setIsInstalled] = useState(false);
  const [swUpdateAvailable, setSwUpdateAvailable] = useState(false);
  const [showOfflineBanner, setShowOfflineBanner] = useState(false);

  // オンライン/オフライン状態の監視
  useEffect(() => {
    const handleOnline = () => {
      setIsOnline(true);
      setShowOfflineBanner(false);
      console.log('🌐 オンラインに復帰しました');
    };

    const handleOffline = () => {
      setIsOnline(false);
      setShowOfflineBanner(true);
      console.log('📴 オフラインになりました');
    };

    // 初期状態設定
    setIsOnline(navigator.onLine);

    // イベントリスナー登録
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // インストール促進の管理
  useEffect(() => {
    const handleBeforeInstallPrompt = (e: BeforeInstallPromptEvent) => {
      // ブラウザのデフォルト動作を防止
      e.preventDefault();
      
      console.log('📱 PWAインストール促進イベントを検出');
      setInstallPrompt(e);
      
      // インストール済みでない場合はバナー表示
      if (!isInstalled) {
        setShowInstallBanner(true);
      }
    };

    // アプリがインストール済みかチェック
    const checkInstalled = () => {
      const isStandalone = window.matchMedia('(display-mode: standalone)').matches ||
                          window.matchMedia('(display-mode: fullscreen)').matches ||
                          (window.navigator as any).standalone === true;
      
      setIsInstalled(isStandalone);
      
      if (isStandalone) {
        console.log('📱 PWAアプリとして起動中');
        setShowInstallBanner(false);
      }
    };

    checkInstalled();
    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);

    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    };
  }, [isInstalled]);

  // Service Worker更新の管理
  useEffect(() => {
    if (typeof window !== 'undefined' && 'serviceWorker' in navigator) {
      const checkSWUpdate = async () => {
        try {
          const registration = await navigator.serviceWorker.ready;
          
          // 更新チェック
          registration.addEventListener('updatefound', () => {
            const newWorker = registration.installing;
            
            if (newWorker) {
              newWorker.addEventListener('statechange', () => {
                if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                  console.log('🔄 Service Worker更新が利用可能です');
                  setSwUpdateAvailable(true);
                }
              });
            }
          });
          
          // 手動更新チェック（5分ごと）
          const updateInterval = setInterval(() => {
            registration.update();
          }, 5 * 60 * 1000);

          return () => clearInterval(updateInterval);
        } catch (error) {
          console.warn('Service Worker更新チェックでエラー:', error);
        }
      };

      checkSWUpdate();
    }
  }, []);

  // PWAインストール実行
  const handleInstall = useCallback(async () => {
    if (!installPrompt) {
      console.warn('インストール促進イベントが利用できません');
      return;
    }

    try {
      // インストール促進を表示
      await installPrompt.prompt();
      
      // ユーザーの選択を待機
      const result = await installPrompt.userChoice;
      
      if (result.outcome === 'accepted') {
        console.log('✅ ユーザーがPWAインストールを承認しました');
      } else {
        console.log('❌ ユーザーがPWAインストールをキャンセルしました');
      }
      
      // バナーを非表示
      setShowInstallBanner(false);
      setInstallPrompt(null);
    } catch (error) {
      console.error('PWAインストールエラー:', error);
    }
  }, [installPrompt]);

  // Service Worker更新適用
  const handleSWUpdate = useCallback(() => {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.ready.then((registration) => {
        if (registration.waiting) {
          // 新しいService Workerに切り替え
          registration.waiting.postMessage({ type: 'SKIP_WAITING' });
          
          // ページを再読み込み
          window.location.reload();
        }
      });
    }
  }, []);

  // バナー非表示
  const dismissInstallBanner = useCallback(() => {
    setShowInstallBanner(false);
    // 24時間後まで再表示しない
    localStorage.setItem('pwa-install-dismissed', Date.now().toString());
  }, []);

  const dismissOfflineBanner = useCallback(() => {
    setShowOfflineBanner(false);
  }, []);

  return (
    <>
      {children}
      
      {/* オフライン通知バナー */}
      {showOfflineBanner && (
        <div 
          className={cn(
            'fixed top-0 left-0 right-0 z-50',
            'bg-warning-100 border-b border-warning-300 shadow-lg',
            'animate-slide-down'
          )}
          role="alert"
        >
          <div className="container mx-auto px-4 py-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="text-warning-600">📴</span>
                <span className="text-warning-800 font-medium">
                  オフライン中です
                </span>
                <span className="text-warning-700 text-sm">
                  保存されたデータでゲームを続行できます
                </span>
              </div>
              
              <button
                onClick={dismissOfflineBanner}
                className="text-warning-600 hover:text-warning-800 transition-colors"
                aria-label="通知を閉じる"
              >
                ✕
              </button>
            </div>
          </div>
        </div>
      )}

      {/* PWAインストール促進バナー */}
      {showInstallBanner && !isInstalled && (
        <div 
          className={cn(
            'fixed bottom-4 left-4 right-4 z-50 mx-auto max-w-md',
            'animate-slide-up'
          )}
          role="dialog"
          aria-labelledby="install-banner-title"
        >
          <Card className="shadow-2xl border-primary-200">
            <CardContent className="p-4">
              <div className="flex items-start gap-3">
                <div className="text-2xl">📱</div>
                <div className="flex-1">
                  <h3 
                    id="install-banner-title"
                    className="font-semibold text-primary-900 mb-1"
                  >
                    アプリをインストール
                  </h3>
                  <p className="text-sm text-primary-700 mb-3">
                    GuessNumberをホーム画面に追加してオフラインでも遊べます！
                  </p>
                  
                  <div className="flex gap-2">
                    <Button
                      variant="primary"
                      size="sm"
                      onClick={handleInstall}
                      className="text-xs"
                    >
                      インストール
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={dismissInstallBanner}
                      className="text-xs text-neutral-600"
                    >
                      後で
                    </Button>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Service Worker更新通知 */}
      {swUpdateAvailable && (
        <div 
          className={cn(
            'fixed bottom-4 left-4 right-4 z-50 mx-auto max-w-md',
            'animate-slide-up'
          )}
          role="dialog"
          aria-labelledby="update-banner-title"
        >
          <Card variant="info" className="shadow-2xl">
            <CardContent className="p-4">
              <div className="flex items-start gap-3">
                <div className="text-2xl">🔄</div>
                <div className="flex-1">
                  <h3 
                    id="update-banner-title"
                    className="font-semibold text-info-900 mb-1"
                  >
                    アップデートが利用可能
                  </h3>
                  <p className="text-sm text-info-700 mb-3">
                    新しいバージョンが利用可能です。更新しますか？
                  </p>
                  
                  <div className="flex gap-2">
                    <Button
                      variant="info"
                      size="sm"
                      onClick={handleSWUpdate}
                      className="text-xs"
                    >
                      更新する
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setSwUpdateAvailable(false)}
                      className="text-xs text-neutral-600"
                    >
                      後で
                    </Button>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* PWA状態インジケーター（開発環境のみ） */}
      {process.env.NODE_ENV === 'development' && (
        <div className="fixed top-4 left-4 z-50 p-2 bg-black/80 text-white text-xs rounded">
          <div>PWA: {isInstalled ? '✅' : '❌'}</div>
          <div>Online: {isOnline ? '🌐' : '📴'}</div>
          <div>SW: {'serviceWorker' in navigator ? '✅' : '❌'}</div>
        </div>
      )}
    </>
  );
};

export default PWAWrapper;