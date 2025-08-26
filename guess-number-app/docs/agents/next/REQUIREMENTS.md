# Next.js Agent - フロントエンド実装要件定義書

## 🎯 役割と責務

### 主要責務
Next.js Agentは、GuessNumberゲームのフロントエンド実装を担当し、最新のReact 18・Next.js 15技術を活用したモダンなWebアプリケーションを構築します。

### 専門領域
- **Next.js 15 App Router**: モダンなルーティングシステム
- **React 18機能**: Server Components、Suspense、Concurrent Features
- **TypeScript統合**: 型安全なコンポーネント開発
- **PWA実装**: Service Worker、オフライン対応
- **パフォーマンス最適化**: Core Web Vitals向上

## 🔧 技術実装要件

### 1. Next.js 15 App Router実装

#### ディレクトリ構造とルーティング
```typescript
// src/app/ ディレクトリ構造
src/app/
├── layout.tsx              // ルートレイアウト
├── page.tsx               // ホーム画面
├── loading.tsx            // ローディングUI
├── error.tsx             // エラーUI
├── not-found.tsx         // 404エラーUI
├── global-error.tsx      // グローバルエラーUI
├── globals.css           // グローバルスタイル
├── game/
│   ├── page.tsx          // ゲーム画面
│   ├── layout.tsx        // ゲームレイアウト
│   ├── loading.tsx       // ゲーム用ローディング
│   └── components/       // ゲーム専用コンポーネント
├── stats/
│   ├── page.tsx          // 統計画面
│   └── components/
├── settings/
│   ├── page.tsx          // 設定画面
│   └── components/
└── api/                  // API Routes (必要に応じて)
    └── game/
        └── route.ts
```

#### ルートレイアウトの実装
```typescript
// src/app/layout.tsx
import type { Metadata, Viewport } from 'next';
import { Inter } from 'next/font/google';
import { GameProvider } from '@/contexts/game-context';
import { ThemeProvider } from '@/contexts/theme-context';
import { AccessibilityProvider } from '@/contexts/accessibility-context';
import { ErrorBoundary } from '@/components/common/error-boundary';
import { PWAUpdateNotifier } from '@/components/pwa/update-notifier';
import './globals.css';

const inter = Inter({ 
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter'
});

export const metadata: Metadata = {
  title: {
    default: 'GuessNumber - 数当てゲーム',
    template: '%s | GuessNumber'
  },
  description: '楽しく論理的思考を鍛える数当てゲーム。PWA対応でオフラインでもプレイ可能。',
  keywords: ['ゲーム', '数当て', '論理思考', '教育', 'PWA'],
  authors: [{ name: 'GuessNumber Team' }],
  creator: 'GuessNumber Team',
  publisher: 'GuessNumber Team',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  metadataBase: new URL('https://guess-number.app'),
  alternates: {
    canonical: '/',
  },
  openGraph: {
    title: 'GuessNumber - 数当てゲーム',
    description: '楽しく論理的思考を鍛える数当てゲーム',
    type: 'website',
    locale: 'ja_JP',
    url: 'https://guess-number.app',
    siteName: 'GuessNumber',
    images: [
      {
        url: '/og-image.png',
        width: 1200,
        height: 630,
        alt: 'GuessNumber - 数当てゲーム',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'GuessNumber - 数当てゲーム',
    description: '楽しく論理的思考を鍛える数当てゲーム',
    images: ['/og-image.png'],
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: 'default',
    title: 'GuessNumber',
  },
  verification: {
    google: 'verification_token_here',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#3b82f6' },
    { media: '(prefers-color-scheme: dark)', color: '#1e40af' }
  ],
};

interface RootLayoutProps {
  children: React.ReactNode;
}

export default function RootLayout({ children }: RootLayoutProps) {
  return (
    <html lang="ja" className={inter.variable}>
      <body className="font-sans antialiased">
        <ErrorBoundary>
          <ThemeProvider>
            <AccessibilityProvider>
              <GameProvider>
                <div className="min-h-screen bg-background text-foreground">
                  <header className="sticky top-0 z-50 bg-background/80 backdrop-blur-sm border-b">
                    <nav className="container mx-auto px-4 h-16 flex items-center justify-between">
                      <h1 className="text-xl font-bold">
                        <Link href="/" className="hover:opacity-80 transition-opacity">
                          GuessNumber
                        </Link>
                      </h1>
                      <div className="flex items-center space-x-4">
                        <ThemeToggle />
                        <AccessibilityMenu />
                      </div>
                    </nav>
                  </header>
                  
                  <main className="flex-1">
                    {children}
                  </main>
                  
                  <footer className="border-t bg-muted/30 py-8">
                    <div className="container mx-auto px-4 text-center text-sm text-muted-foreground">
                      <p>&copy; 2025 GuessNumber. All rights reserved.</p>
                    </div>
                  </footer>
                </div>
                
                <PWAUpdateNotifier />
              </GameProvider>
            </AccessibilityProvider>
          </ThemeProvider>
        </ErrorBoundary>
      </body>
    </html>
  );
}
```

### 2. Server Components と Client Components戦略

#### Server Components（デフォルト）
```typescript
// src/app/page.tsx - Server Component
import { Suspense } from 'react';
import { GameModeSelector } from '@/components/game/game-mode-selector';
import { WelcomeSection } from '@/components/home/welcome-section';
import { StatsPreview } from '@/components/stats/stats-preview';
import { GameModeSelectorSkeleton } from '@/components/game/game-mode-selector-skeleton';

export default function HomePage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <WelcomeSection />
      
      <Suspense fallback={<GameModeSelectorSkeleton />}>
        <GameModeSelector />
      </Suspense>
      
      <Suspense fallback={<div className="animate-pulse h-32 bg-muted rounded-lg" />}>
        <StatsPreview />
      </Suspense>
    </div>
  );
}
```

#### Client Components（'use client'指定）
```typescript
// src/components/game/game-board.tsx - Client Component
'use client';

import { useState, useCallback, useEffect } from 'react';
import { useGameContext } from '@/contexts/game-context';
import { useTimer } from '@/hooks/use-timer';
import { useKeyboardShortcuts } from '@/hooks/use-keyboard-shortcuts';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { GameStatus } from '@/components/game/game-status';
import { AttemptHistory } from '@/components/game/attempt-history';

interface GameBoardProps {
  initialDifficulty?: Difficulty;
}

export function GameBoard({ initialDifficulty }: GameBoardProps) {
  const { gameState, actions } = useGameContext();
  const [inputValue, setInputValue] = useState('');
  const [error, setError] = useState<string | null>(null);
  
  const { timeLeft, isTimeUp } = useTimer({
    duration: gameState.difficulty?.timeLimit,
    onTimeUp: useCallback(() => {
      if (gameState.status === 'playing') {
        actions.endGame('time_up');
      }
    }, [gameState.status, actions])
  });

  // キーボードショートカット
  useKeyboardShortcuts({
    'Escape': () => actions.resetGame(),
    '?': () => actions.requestHint(),
    'Enter': () => document.getElementById('guess-submit')?.click()
  });

  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault();
    
    const guess = parseInt(inputValue, 10);
    
    // バリデーション
    if (isNaN(guess)) {
      setError('有効な数値を入力してください');
      return;
    }

    const range = gameState.difficulty?.range;
    if (range && (guess < range.min || guess > range.max)) {
      setError(`${range.min}から${range.max}の間で入力してください`);
      return;
    }

    setError(null);
    setInputValue('');

    try {
      await actions.makeGuess(guess);
    } catch (err) {
      setError(err instanceof Error ? err.message : '予期しないエラーが発生しました');
    }
  }, [inputValue, gameState.difficulty, actions]);

  // ゲーム状態に応じたUI制御
  const isGameActive = gameState.status === 'playing';
  const remainingAttempts = gameState.difficulty?.maxAttempts 
    ? gameState.difficulty.maxAttempts - gameState.attempts.length 
    : Infinity;

  return (
    <div className="max-w-2xl mx-auto p-6 space-y-6">
      {/* ゲーム状態表示 */}
      <GameStatus 
        gameState={gameState}
        timeLeft={timeLeft}
        remainingAttempts={remainingAttempts}
      />

      {/* 推測入力フォーム */}
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="space-y-2">
          <label 
            htmlFor="guess-input" 
            className="block text-sm font-medium"
          >
            数値を推測してください
            {gameState.difficulty && (
              <span className="ml-2 text-muted-foreground">
                ({gameState.difficulty.range.min}〜{gameState.difficulty.range.max})
              </span>
            )}
          </label>
          
          <div className="flex space-x-2">
            <Input
              id="guess-input"
              type="number"
              min={gameState.difficulty?.range.min}
              max={gameState.difficulty?.range.max}
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              placeholder={gameState.difficulty ? `${gameState.difficulty.range.min}〜${gameState.difficulty.range.max}` : '数値を入力'}
              disabled={!isGameActive || isTimeUp}
              className="flex-1"
              autoFocus
              aria-describedby={error ? 'guess-error' : 'guess-help'}
            />
            
            <Button 
              id="guess-submit"
              type="submit"
              disabled={!isGameActive || !inputValue || isTimeUp}
              className="min-w-[100px]"
            >
              推測する
            </Button>
          </div>
          
          {error && (
            <p id="guess-error" role="alert" className="text-sm text-destructive">
              {error}
            </p>
          )}
          
          <p id="guess-help" className="text-xs text-muted-foreground">
            キーボードショートカット: Escでリセット、?でヒント
          </p>
        </div>
      </form>

      {/* ヒントボタン */}
      {gameState.difficulty?.maxHints && gameState.difficulty.maxHints > 0 && (
        <div className="flex justify-center">
          <Button
            variant="outline"
            onClick={() => actions.requestHint()}
            disabled={!isGameActive || gameState.hintsUsed >= gameState.difficulty.maxHints}
            className="min-w-[120px]"
          >
            ヒント ({gameState.difficulty.maxHints - gameState.hintsUsed}回)
          </Button>
        </div>
      )}

      {/* 推測履歴 */}
      <AttemptHistory attempts={gameState.attempts} />

      {/* ゲーム終了時の表示 */}
      {(gameState.status === 'completed' || gameState.status === 'failed') && (
        <GameResult 
          gameState={gameState}
          onPlayAgain={() => actions.startNewGame(gameState.difficulty!)}
          onChangeDifficulty={() => actions.resetToHome()}
        />
      )}
    </div>
  );
}
```

### 3. Context API とState Management

#### GameContextの実装
```typescript
// src/contexts/game-context.tsx
'use client';

import React, { createContext, useContext, useReducer, useCallback } from 'react';
import { GameEngine } from '@/lib/game-engine/core';
import { ScoreCalculator } from '@/lib/game-engine/score';
import { OfflineGameManager } from '@/lib/storage/offline-game-manager';
import type { GameState, GameActions, Difficulty } from '@/types/game';

interface GameContextValue {
  gameState: GameState;
  actions: GameActions;
  isLoading: boolean;
  error: string | null;
}

const GameContext = createContext<GameContextValue | undefined>(undefined);

type GameAction =
  | { type: 'GAME_START'; payload: { difficulty: Difficulty } }
  | { type: 'GUESS_MADE'; payload: { guess: number; result: GuessResult } }
  | { type: 'HINT_REQUESTED'; payload: { hint: Hint } }
  | { type: 'GAME_END'; payload: { reason: 'completed' | 'failed' | 'time_up' } }
  | { type: 'GAME_RESET' }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string | null }
  | { type: 'RESTORE_STATE'; payload: GameState };

function gameReducer(state: GameState, action: GameAction): GameState {
  switch (action.type) {
    case 'GAME_START': {
      return {
        ...state,
        difficulty: action.payload.difficulty,
        status: 'playing',
        attempts: [],
        hintsUsed: 0,
        startTime: Date.now(),
        endTime: null,
        currentScore: 0,
        error: null
      };
    }
    
    case 'GUESS_MADE': {
      const newAttempt = action.payload.result.attempt;
      return {
        ...state,
        attempts: [...state.attempts, newAttempt],
        status: action.payload.result.isCorrect ? 'completed' : 
                action.payload.result.isGameOver ? 'failed' : 'playing',
        endTime: action.payload.result.isGameOver ? Date.now() : null,
        currentScore: action.payload.result.isCorrect ? 
          action.payload.result.finalScore || 0 : state.currentScore
      };
    }
    
    case 'HINT_REQUESTED': {
      return {
        ...state,
        hintsUsed: state.hintsUsed + 1,
        lastHint: action.payload.hint
      };
    }
    
    case 'GAME_END': {
      return {
        ...state,
        status: action.payload.reason === 'completed' ? 'completed' : 'failed',
        endTime: Date.now()
      };
    }
    
    case 'GAME_RESET': {
      return {
        ...state,
        status: 'idle',
        attempts: [],
        hintsUsed: 0,
        startTime: 0,
        endTime: null,
        currentScore: 0,
        error: null,
        lastHint: undefined
      };
    }
    
    case 'SET_LOADING': {
      return { ...state, isLoading: action.payload };
    }
    
    case 'SET_ERROR': {
      return { ...state, error: action.payload };
    }
    
    case 'RESTORE_STATE': {
      return action.payload;
    }
    
    default:
      return state;
  }
}

const initialState: GameState = {
  status: 'idle',
  attempts: [],
  hintsUsed: 0,
  startTime: 0,
  endTime: null,
  currentScore: 0,
  isLoading: false,
  error: null
};

interface GameProviderProps {
  children: React.ReactNode;
}

export function GameProvider({ children }: GameProviderProps) {
  const [state, dispatch] = useReducer(gameReducer, initialState);
  const [gameEngine, setGameEngine] = React.useState<GameEngine | null>(null);

  // ゲーム状態の復元
  React.useEffect(() => {
    const savedState = OfflineGameManager.loadGameState();
    if (savedState) {
      dispatch({ type: 'RESTORE_STATE', payload: savedState });
    }
  }, []);

  // ゲーム状態の自動保存
  React.useEffect(() => {
    if (state.status !== 'idle') {
      OfflineGameManager.saveGameState(state);
    }
  }, [state]);

  const actions: GameActions = {
    startGame: useCallback(async (difficulty: Difficulty) => {
      dispatch({ type: 'SET_LOADING', payload: true });
      dispatch({ type: 'SET_ERROR', payload: null });
      
      try {
        const engine = new GameEngine(difficulty);
        setGameEngine(engine);
        dispatch({ type: 'GAME_START', payload: { difficulty } });
      } catch (error) {
        dispatch({ 
          type: 'SET_ERROR', 
          payload: error instanceof Error ? error.message : '予期しないエラーが発生しました' 
        });
      } finally {
        dispatch({ type: 'SET_LOADING', payload: false });
      }
    }, []),

    makeGuess: useCallback(async (guess: number) => {
      if (!gameEngine || state.status !== 'playing') return;
      
      dispatch({ type: 'SET_LOADING', payload: true });
      
      try {
        const result = gameEngine.makeGuess(guess);
        
        if (result.success) {
          dispatch({ type: 'GUESS_MADE', payload: { guess, result } });
          
          // スコア保存（ゲーム完了時）
          if (result.isCorrect) {
            const score = gameEngine.calculateFinalScore();
            OfflineGameManager.saveScore({
              ...score,
              difficulty: state.difficulty!,
              timestamp: Date.now()
            });
          }
        } else {
          throw new Error(result.error);
        }
      } catch (error) {
        dispatch({ 
          type: 'SET_ERROR', 
          payload: error instanceof Error ? error.message : '推測処理でエラーが発生しました' 
        });
      } finally {
        dispatch({ type: 'SET_LOADING', payload: false });
      }
    }, [gameEngine, state.status, state.difficulty]),

    requestHint: useCallback(async () => {
      if (!gameEngine || state.status !== 'playing') return;
      
      try {
        const hint = gameEngine.generateHint();
        if (hint) {
          dispatch({ type: 'HINT_REQUESTED', payload: { hint } });
        }
      } catch (error) {
        dispatch({ 
          type: 'SET_ERROR', 
          payload: error instanceof Error ? error.message : 'ヒント生成でエラーが発生しました' 
        });
      }
    }, [gameEngine, state.status]),

    resetGame: useCallback(() => {
      setGameEngine(null);
      dispatch({ type: 'GAME_RESET' });
      OfflineGameManager.clearGameState();
    }, []),

    endGame: useCallback((reason: 'completed' | 'failed' | 'time_up') => {
      dispatch({ type: 'GAME_END', payload: { reason } });
    }, [])
  };

  const contextValue: GameContextValue = {
    gameState: state,
    actions,
    isLoading: state.isLoading || false,
    error: state.error
  };

  return (
    <GameContext.Provider value={contextValue}>
      {children}
    </GameContext.Provider>
  );
}

export function useGameContext() {
  const context = useContext(GameContext);
  if (context === undefined) {
    throw new Error('useGameContext must be used within a GameProvider');
  }
  return context;
}
```

### 4. カスタムHooks

#### useTimerフック
```typescript
// src/hooks/use-timer.ts
import { useState, useEffect, useRef, useCallback } from 'react';

interface UseTimerOptions {
  duration?: number; // milliseconds
  onTimeUp?: () => void;
  interval?: number; // update interval in milliseconds
}

interface UseTimerReturn {
  timeLeft: number;
  isRunning: boolean;
  isTimeUp: boolean;
  start: () => void;
  pause: () => void;
  resume: () => void;
  reset: () => void;
  formatTime: (time: number) => string;
}

export function useTimer({
  duration,
  onTimeUp,
  interval = 100
}: UseTimerOptions = {}): UseTimerReturn {
  const [timeLeft, setTimeLeft] = useState(duration || 0);
  const [isRunning, setIsRunning] = useState(false);
  const intervalRef = useRef<NodeJS.Timeout | null>(null);
  const startTimeRef = useRef<number>(0);
  const pausedTimeRef = useRef<number>(0);

  const start = useCallback(() => {
    if (!duration) return;
    
    startTimeRef.current = Date.now();
    pausedTimeRef.current = 0;
    setTimeLeft(duration);
    setIsRunning(true);
  }, [duration]);

  const pause = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
    setIsRunning(false);
    pausedTimeRef.current = Date.now() - startTimeRef.current;
  }, []);

  const resume = useCallback(() => {
    if (pausedTimeRef.current > 0) {
      startTimeRef.current = Date.now() - pausedTimeRef.current;
      setIsRunning(true);
    }
  }, []);

  const reset = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
    setTimeLeft(duration || 0);
    setIsRunning(false);
    startTimeRef.current = 0;
    pausedTimeRef.current = 0;
  }, [duration]);

  const formatTime = useCallback((time: number): string => {
    const minutes = Math.floor(time / 60000);
    const seconds = Math.floor((time % 60000) / 1000);
    const milliseconds = Math.floor((time % 1000) / 100);
    
    if (minutes > 0) {
      return `${minutes}:${seconds.toString().padStart(2, '0')}.${milliseconds}`;
    } else {
      return `${seconds}.${milliseconds}`;
    }
  }, []);

  useEffect(() => {
    if (isRunning && duration) {
      intervalRef.current = setInterval(() => {
        const elapsed = Date.now() - startTimeRef.current;
        const remaining = Math.max(0, duration - elapsed);
        
        setTimeLeft(remaining);
        
        if (remaining === 0) {
          setIsRunning(false);
          if (intervalRef.current) {
            clearInterval(intervalRef.current);
            intervalRef.current = null;
          }
          onTimeUp?.();
        }
      }, interval);
    } else if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [isRunning, duration, onTimeUp, interval]);

  const isTimeUp = timeLeft === 0 && duration !== undefined;

  return {
    timeLeft,
    isRunning,
    isTimeUp,
    start,
    pause,
    resume,
    reset,
    formatTime
  };
}
```

#### useKeyboardShortcutsフック
```typescript
// src/hooks/use-keyboard-shortcuts.ts
import { useEffect } from 'react';

interface KeyboardShortcuts {
  [key: string]: () => void;
}

export function useKeyboardShortcuts(shortcuts: KeyboardShortcuts) {
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      // 入力フィールドにフォーカスがある場合はスキップ
      const target = event.target as HTMLElement;
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') {
        return;
      }

      // 修飾キーが押されている場合はスキップ
      if (event.ctrlKey || event.metaKey || event.altKey) {
        return;
      }

      const handler = shortcuts[event.key];
      if (handler) {
        event.preventDefault();
        handler();
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    
    return () => {
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [shortcuts]);
}
```

### 5. PWA実装

#### next-pwa設定
```javascript
// next.config.mjs
import withPWA from 'next-pwa';

const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  
  // TypeScript設定
  typescript: {
    ignoreBuildErrors: false,
  },
  
  // ESLint設定
  eslint: {
    ignoreDuringBuilds: false,
  },
  
  // 実験的機能
  experimental: {
    optimizeCss: true,
    optimizePackageImports: ['lucide-react', '@radix-ui/react-icons'],
  },
  
  // 画像最適化
  images: {
    formats: ['image/webp', 'image/avif'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
  },
  
  // Headers設定
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
        ],
      },
    ];
  },
};

const withPWAConfig = withPWA({
  dest: 'public',
  disable: process.env.NODE_ENV === 'development',
  register: true,
  skipWaiting: true,
  runtimeCaching: [
    {
      urlPattern: /^https?.*\.(png|jpe?g|webp|svg|gif|tiff|js|css)$/,
      handler: 'CacheFirst',
      options: {
        cacheName: 'static-assets',
        expiration: {
          maxEntries: 100,
          maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
        },
      },
    },
    {
      urlPattern: /^https?.*\/api\/.*/,
      handler: 'NetworkFirst',
      options: {
        cacheName: 'api-cache',
        expiration: {
          maxEntries: 50,
          maxAgeSeconds: 5 * 60, // 5 minutes
        },
        networkTimeoutSeconds: 3,
      },
    },
  ],
  buildExcludes: [/middleware-manifest\.json$/],
  fallbacks: {
    document: '/offline',
  },
});

export default withPWAConfig(nextConfig);
```

#### PWA更新通知コンポーネント
```typescript
// src/components/pwa/update-notifier.tsx
'use client';

import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Toast } from '@/components/ui/toast';

export function PWAUpdateNotifier() {
  const [showUpdate, setShowUpdate] = useState(false);
  const [registration, setRegistration] = useState<ServiceWorkerRegistration | null>(null);

  useEffect(() => {
    if (typeof window !== 'undefined' && 'serviceWorker' in navigator) {
      navigator.serviceWorker.ready
        .then((reg) => {
          setRegistration(reg);
          
          // アップデート検出
          reg.addEventListener('updatefound', () => {
            const newWorker = reg.installing;
            if (newWorker) {
              newWorker.addEventListener('statechange', () => {
                if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                  setShowUpdate(true);
                }
              });
            }
          });
        });

      // メッセージ受信
      navigator.serviceWorker.addEventListener('message', (event) => {
        if (event.data && event.data.type === 'SW_UPDATED') {
          setShowUpdate(true);
        }
      });
    }
  }, []);

  const handleUpdate = () => {
    if (registration && registration.waiting) {
      registration.waiting.postMessage({ type: 'SKIP_WAITING' });
      registration.waiting.addEventListener('statechange', () => {
        if (registration.waiting?.state === 'activated') {
          window.location.reload();
        }
      });
    }
    setShowUpdate(false);
  };

  if (!showUpdate) return null;

  return (
    <Toast
      open={showUpdate}
      onOpenChange={setShowUpdate}
      className="fixed bottom-4 right-4 z-50"
    >
      <div className="space-y-2">
        <div className="text-sm font-medium">
          新しいバージョンが利用可能です
        </div>
        <div className="text-xs text-muted-foreground">
          最新の機能を使用するには更新してください
        </div>
        <div className="flex space-x-2">
          <Button size="sm" onClick={handleUpdate}>
            更新する
          </Button>
          <Button 
            size="sm" 
            variant="outline" 
            onClick={() => setShowUpdate(false)}
          >
            後で
          </Button>
        </div>
      </div>
    </Toast>
  );
}
```

### 6. パフォーマンス最適化

#### 動的インポート戦略
```typescript
// src/components/stats/stats-page.tsx
import { Suspense, lazy } from 'react';

// チャート関連は必要時のみロード
const GameHistoryChart = lazy(() => import('./game-history-chart'));
const PerformanceChart = lazy(() => import('./performance-chart'));
const DetailedAnalytics = lazy(() => import('./detailed-analytics'));

export function StatsPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">統計情報</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        {/* 基本統計は即座に表示 */}
        <BasicStats />
        <RecentGames />
        <Achievements />
      </div>
      
      {/* 重いチャートは遅延ロード */}
      <div className="space-y-8">
        <Suspense fallback={<ChartSkeleton />}>
          <GameHistoryChart />
        </Suspense>
        
        <Suspense fallback={<ChartSkeleton />}>
          <PerformanceChart />
        </Suspense>
        
        <Suspense fallback={<DetailedAnalyticsSkeleton />}>
          <DetailedAnalytics />
        </Suspense>
      </div>
    </div>
  );
}
```

#### Image最適化
```typescript
// src/components/common/optimized-image.tsx
import Image, { ImageProps } from 'next/image';
import { useState } from 'react';

interface OptimizedImageProps extends Omit<ImageProps, 'onLoad' | 'onError'> {
  fallbackSrc?: string;
  showLoadingSpinner?: boolean;
}

export function OptimizedImage({
  src,
  alt,
  fallbackSrc = '/images/placeholder.svg',
  showLoadingSpinner = true,
  ...props
}: OptimizedImageProps) {
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  return (
    <div className="relative">
      {isLoading && showLoadingSpinner && (
        <div className="absolute inset-0 flex items-center justify-center bg-muted rounded">
          <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin" />
        </div>
      )}
      
      <Image
        src={hasError ? fallbackSrc : src}
        alt={alt}
        onLoad={() => setIsLoading(false)}
        onError={() => {
          setHasError(true);
          setIsLoading(false);
        }}
        className={`transition-opacity duration-300 ${
          isLoading ? 'opacity-0' : 'opacity-100'
        }`}
        {...props}
      />
    </div>
  );
}
```

## 🧪 テスト要件

### 1. コンポーネントテスト
```typescript
// __tests__/components/game/game-board.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { GameProvider } from '@/contexts/game-context';
import { GameBoard } from '@/components/game/game-board';
import { DIFFICULTIES } from '@/lib/constants/game';

const renderWithProvider = (component: React.ReactElement) => {
  return render(
    <GameProvider>
      {component}
    </GameProvider>
  );
};

describe('GameBoard', () => {
  it('正常な推測を送信できる', async () => {
    const user = userEvent.setup();
    
    renderWithProvider(<GameBoard initialDifficulty={DIFFICULTIES.easy} />);
    
    const input = screen.getByLabelText(/数値を推測してください/);
    const submitButton = screen.getByRole('button', { name: '推測する' });
    
    await user.type(input, '15');
    await user.click(submitButton);
    
    await waitFor(() => {
      expect(screen.getByText(/推測履歴/)).toBeInTheDocument();
    });
  });

  it('範囲外の値でエラーメッセージを表示する', async () => {
    const user = userEvent.setup();
    
    renderWithProvider(<GameBoard initialDifficulty={DIFFICULTIES.easy} />);
    
    const input = screen.getByLabelText(/数値を推測してください/);
    const submitButton = screen.getByRole('button', { name: '推測する' });
    
    await user.type(input, '50'); // 範囲外（1-30）
    await user.click(submitButton);
    
    expect(screen.getByRole('alert')).toHaveTextContent('1から30の間で入力してください');
  });

  it('キーボードショートカットが機能する', async () => {
    const user = userEvent.setup();
    
    renderWithProvider(<GameBoard initialDifficulty={DIFFICULTIES.easy} />);
    
    // Escapeキーでリセット
    await user.keyboard('{Escape}');
    
    // リセット確認ダイアログが表示されることを確認
    expect(screen.getByText(/ゲームをリセットしますか/)).toBeInTheDocument();
  });
});
```

### 2. E2Eテスト（Playwright）
```typescript
// e2e/game-flow.spec.ts
import { test, expect } from '@playwright/test';

test.describe('ゲーム全体フロー', () => {
  test('完全なゲームセッション', async ({ page }) => {
    await page.goto('/');
    
    // 難易度選択
    await page.click('text=ふつう');
    await page.click('text=ゲーム開始');
    
    // ゲーム画面に遷移
    await expect(page).toHaveURL('/game');
    
    // 推測入力
    const guessInput = page.locator('[data-testid=guess-input]');
    const submitButton = page.locator('text=推測する');
    
    await guessInput.fill('25');
    await submitButton.click();
    
    // フィードバック確認
    await expect(page.locator('[data-testid=feedback]')).toBeVisible();
    
    // スコア表示確認
    await expect(page.locator('[data-testid=score]')).toContainText('スコア:');
  });

  test('PWA機能', async ({ page, context }) => {
    await page.goto('/');
    
    // Service Worker登録確認
    const swPromise = page.waitForEvent('serviceworker');
    await page.reload();
    const sw = await swPromise;
    expect(sw.url()).toContain('sw.js');
    
    // オフライン時の動作確認
    await context.setOffline(true);
    await page.reload();
    
    // ゲーム機能が利用可能であることを確認
    await expect(page.locator('text=GuessNumber')).toBeVisible();
  });

  test('アクセシビリティ', async ({ page }) => {
    await page.goto('/game');
    
    // キーボードナビゲーション
    await page.keyboard.press('Tab');
    await expect(page.locator(':focus')).toHaveAttribute('data-testid', 'guess-input');
    
    // スクリーンリーダー対応
    await expect(page.locator('[aria-label]')).toHaveCount({ min: 1 });
    await expect(page.locator('[role="alert"]')).toHaveCount({ min: 0 });
  });
});
```

## 📊 品質指標

### パフォーマンス目標
- **First Contentful Paint**: 1.2秒以内
- **Largest Contentful Paint**: 2.5秒以内
- **Cumulative Layout Shift**: 0.1以下
- **First Input Delay**: 100ms以内
- **Time to Interactive**: 3.0秒以内

### バンドルサイズ目標
- **Initial Bundle**: 200KB以下（gzip）
- **Total Bundle**: 500KB以下（gzip）
- **Code Splitting**: ページごとに適切な分割

### アクセシビリティ目標
- **Lighthouse Accessibility**: 95点以上
- **WCAG 2.1 AA準拠**: 100%
- **キーボード操作**: 全機能対応
- **スクリーンリーダー**: 完全対応

## 🔄 デプロイと運用

### Vercel設定
```json
{
  "version": 2,
  "builds": [
    {
      "src": "next.config.mjs",
      "use": "@vercel/next"
    }
  ],
  "env": {
    "NEXT_PUBLIC_APP_ENV": "production"
  },
  "headers": [
    {
      "source": "/sw.js",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "no-cache, no-store, must-revalidate"
        }
      ]
    }
  ]
}
```

### 環境変数管理
```typescript
// src/lib/env.ts
const requiredEnvVars = [
  'NEXT_PUBLIC_APP_ENV',
] as const;

const optionalEnvVars = [
  'NEXT_PUBLIC_GA_ID',
  'NEXT_PUBLIC_SENTRY_DSN',
] as const;

export const env = {
  NEXT_PUBLIC_APP_ENV: process.env.NEXT_PUBLIC_APP_ENV || 'development',
  NEXT_PUBLIC_GA_ID: process.env.NEXT_PUBLIC_GA_ID,
  NEXT_PUBLIC_SENTRY_DSN: process.env.NEXT_PUBLIC_SENTRY_DSN,
} as const;

// 必須環境変数のバリデーション
if (process.env.NODE_ENV === 'production') {
  for (const envVar of requiredEnvVars) {
    if (!process.env[envVar]) {
      throw new Error(`Missing required environment variable: ${envVar}`);
    }
  }
}
```

## 📝 実装チェックリスト

### 必須実装項目
- [ ] Next.js 15 App Router完全移行
- [ ] Server/Client Components適切な分離
- [ ] PWA機能（オフライン対応、インストール）
- [ ] Context API状態管理
- [ ] カスタムHooks実装
- [ ] TypeScript strict mode
- [ ] アクセシビリティ対応
- [ ] パフォーマンス最適化
- [ ] エラーバウンダリ
- [ ] SEO最適化

### 品質保証項目
- [ ] コンポーネントテストカバレッジ80%以上
- [ ] E2Eテスト主要フロー網羅
- [ ] Lighthouse Performance 90点以上
- [ ] Lighthouse PWA 90点以上
- [ ] 型安全性100%保証
- [ ] アクセシビリティ検証通過

---

Next.js Agentは、最新のReact/Next.js技術を駆使して、高性能でアクセシブルなPWAアプリケーションを構築します。ユーザー体験を最優先に、技術的な優秀性と実用性を両立した実装を提供します。