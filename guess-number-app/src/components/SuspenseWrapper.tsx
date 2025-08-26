/**
 * SuspenseWrapper - React Suspense用ラッパーコンポーネント
 * 動的インポートコンポーネントのローディング状態を管理
 * エラーバウンダリと組み合わせたフォールバック表示
 */

'use client';

import React, { Suspense } from 'react';
import { LoadingSpinner, GameLoadingSpinner, LoadingSkeleton } from '@/components/ui/LoadingSpinner';
import { cn } from '@/lib/utils';

export interface SuspenseWrapperProps {
  children: React.ReactNode;
  /** フォールバックの種類 */
  fallback?: 'spinner' | 'game' | 'skeleton' | 'custom';
  /** カスタムフォールバック */
  customFallback?: React.ReactNode;
  /** ローディングテキスト */
  loadingText?: string;
  /** エラー時のフォールバック */
  errorFallback?: React.ReactNode;
  /** カスタムクラス */
  className?: string;
}

/**
 * 基本的なSuspenseWrapper
 */
export const SuspenseWrapper: React.FC<SuspenseWrapperProps> = ({
  children,
  fallback = 'spinner',
  customFallback,
  loadingText,
  className,
}) => {
  const getFallbackComponent = () => {
    if (customFallback) {
      return customFallback;
    }

    switch (fallback) {
      case 'game':
        return (
          <div className={cn('flex justify-center py-8', className)}>
            <GameLoadingSpinner text={loadingText} />
          </div>
        );
      case 'skeleton':
        return (
          <div className={cn('p-4', className)}>
            <LoadingSkeleton lines={3} />
          </div>
        );
      case 'spinner':
      default:
        return (
          <div className={cn('flex justify-center py-8', className)}>
            <LoadingSpinner size="lg" text={loadingText} />
          </div>
        );
    }
  };

  return (
    <Suspense fallback={getFallbackComponent()}>
      {children}
    </Suspense>
  );
};

/**
 * ゲームコンポーネント専用のSuspenseWrapper
 */
export const GameSuspenseWrapper: React.FC<{
  children: React.ReactNode;
  loadingText?: string;
  className?: string;
}> = ({ children, loadingText = 'コンポーネント読み込み中...', className }) => {
  return (
    <SuspenseWrapper
      fallback="game"
      loadingText={loadingText}
      className={className}
    >
      {children}
    </SuspenseWrapper>
  );
};

/**
 * カード型レイアウト用のSuspenseWrapper
 */
export const CardSuspenseWrapper: React.FC<{
  children: React.ReactNode;
  title?: string;
  className?: string;
}> = ({ children, title, className }) => {
  return (
    <Suspense
      fallback={
        <div className={cn('card', className)}>
          <div className="card-body">
            {title && <h3 className="font-semibold mb-3">{title}</h3>}
            <LoadingSkeleton lines={4} />
          </div>
        </div>
      }
    >
      {children}
    </Suspense>
  );
};

/**
 * Modal用のSuspenseWrapper
 */
export const ModalSuspenseWrapper: React.FC<{
  children: React.ReactNode;
  isOpen: boolean;
  className?: string;
}> = ({ children, isOpen, className }) => {
  if (!isOpen) return null;

  return (
    <Suspense
      fallback={
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
          <div className={cn('card w-full max-w-lg mx-auto', className)}>
            <div className="card-body text-center p-8">
              <GameLoadingSpinner text="モーダル読み込み中..." />
            </div>
          </div>
        </div>
      }
    >
      {children}
    </Suspense>
  );
};

/**
 * 段階的ローディング用のSuspenseWrapper
 * 複数のコンポーネントを順次読み込む場合に使用
 */
export const ProgressiveSuspenseWrapper: React.FC<{
  children: React.ReactNode[];
  loadingTexts?: string[];
  className?: string;
}> = ({ children, loadingTexts = [], className }) => {
  const [loadedCount, setLoadedCount] = React.useState(0);

  React.useEffect(() => {
    // 実際の実装では、各コンポーネントの読み込み完了を監視
    // ここでは簡略化
    const timer = setInterval(() => {
      setLoadedCount(prev => {
        const next = prev + 1;
        if (next >= children.length) {
          clearInterval(timer);
        }
        return Math.min(next, children.length);
      });
    }, 500);

    return () => clearInterval(timer);
  }, [children.length]);

  return (
    <div className={cn('space-y-4', className)}>
      {children.map((child, index) => {
        if (index < loadedCount) {
          return (
            <SuspenseWrapper 
              key={index}
              fallback="skeleton"
              loadingText={loadingTexts[index]}
            >
              {child}
            </SuspenseWrapper>
          );
        }
        
        if (index === loadedCount) {
          return (
            <div key={index} className="animate-fade-in">
              <SuspenseWrapper
                fallback="game"
                loadingText={loadingTexts[index] || `コンポーネント${index + 1}読み込み中...`}
              >
                {child}
              </SuspenseWrapper>
            </div>
          );
        }
        
        // まだ読み込み待ちのコンポーネント
        return (
          <div key={index} className="opacity-30">
            <LoadingSkeleton lines={2} height="h-8" />
          </div>
        );
      })}
    </div>
  );
};

/**
 * 遅延ローディング用のHook
 */
export const useLazyLoading = (delay: number = 300) => {
  const [isReady, setIsReady] = React.useState(false);

  React.useEffect(() => {
    const timer = setTimeout(() => {
      setIsReady(true);
    }, delay);

    return () => clearTimeout(timer);
  }, [delay]);

  return isReady;
};

/**
 * バッチローディング用のHook
 * 複数のリソースを効率的に読み込む
 */
export const useBatchLoading = <T,>(
  loadFunctions: (() => Promise<T>)[],
  options: {
    batchSize?: number;
    delay?: number;
  } = {}
) => {
  const { batchSize = 2, delay = 100 } = options;
  const [results, setResults] = React.useState<T[]>([]);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState<Error | null>(null);

  const loadBatch = React.useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const allResults: T[] = [];
      
      // バッチごとに処理
      for (let i = 0; i < loadFunctions.length; i += batchSize) {
        const batch = loadFunctions.slice(i, i + batchSize);
        const batchResults = await Promise.all(batch.map(fn => fn()));
        
        allResults.push(...batchResults);
        setResults([...allResults]); // 段階的更新
        
        // 次のバッチまで少し待機
        if (i + batchSize < loadFunctions.length) {
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Loading failed'));
    } finally {
      setLoading(false);
    }
  }, [loadFunctions, batchSize, delay]);

  return { results, loading, error, loadBatch };
};

export default SuspenseWrapper;