/**
 * LoadingSpinner - ローディング表示コンポーネント
 * 様々なサイズとバリエーションに対応
 * アクセシビリティ対応とアニメーション最適化
 */

import React from 'react';
import { cn } from '@/lib/utils';

export interface LoadingSpinnerProps {
  /** サイズ */
  size?: 'sm' | 'md' | 'lg' | 'xl';
  /** バリエーション */
  variant?: 'default' | 'primary' | 'success' | 'warning' | 'error';
  /** 表示テキスト */
  text?: string;
  /** フルスクリーン表示 */
  fullscreen?: boolean;
  /** カスタムクラス */
  className?: string;
  /** 表示状態 */
  show?: boolean;
}

/**
 * サイズ設定
 */
const sizeClasses = {
  sm: {
    spinner: 'w-4 h-4',
    text: 'text-sm',
  },
  md: {
    spinner: 'w-6 h-6',
    text: 'text-base',
  },
  lg: {
    spinner: 'w-8 h-8',
    text: 'text-lg',
  },
  xl: {
    spinner: 'w-12 h-12',
    text: 'text-xl',
  },
};

/**
 * カラーバリエーション
 */
const variantClasses = {
  default: 'text-neutral-600',
  primary: 'text-primary-600',
  success: 'text-success-600',
  warning: 'text-warning-600',
  error: 'text-error-600',
};

export const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  size = 'md',
  variant = 'default',
  text,
  fullscreen = false,
  className,
  show = true,
}) => {
  if (!show) return null;

  const sizeConfig = sizeClasses[size];
  const colorClass = variantClasses[variant];

  const spinner = (
    <div className={cn('inline-flex flex-col items-center gap-3', className)}>
      {/* スピナー本体 */}
      <div 
        className={cn(
          'animate-spin rounded-full border-2 border-current border-t-transparent',
          sizeConfig.spinner,
          colorClass
        )}
        role="status"
        aria-label={text || 'Loading'}
      >
        <span className="sr-only">Loading...</span>
      </div>
      
      {/* テキスト表示 */}
      {text && (
        <div className={cn(
          'font-medium text-center',
          sizeConfig.text,
          colorClass
        )}>
          {text}
        </div>
      )}
    </div>
  );

  // フルスクリーン表示
  if (fullscreen) {
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-white/80 backdrop-blur-sm">
        {spinner}
      </div>
    );
  }

  return spinner;
};

/**
 * ドットローディング - 代替アニメーション
 */
export const LoadingDots: React.FC<Omit<LoadingSpinnerProps, 'text'>> = ({
  size = 'md',
  variant = 'default',
  className,
  show = true,
}) => {
  if (!show) return null;

  const dotSizeMap = {
    sm: 'w-2 h-2',
    md: 'w-3 h-3',
    lg: 'w-4 h-4',
    xl: 'w-5 h-5',
  };

  const colorClass = variantClasses[variant];
  const dotSize = dotSizeMap[size];

  return (
    <div className={cn('inline-flex items-center space-x-1', className)} role="status" aria-label="Loading">
      <div className={cn('animate-bounce rounded-full bg-current', dotSize, colorClass)} style={{ animationDelay: '0ms' }} />
      <div className={cn('animate-bounce rounded-full bg-current', dotSize, colorClass)} style={{ animationDelay: '150ms' }} />
      <div className={cn('animate-bounce rounded-full bg-current', dotSize, colorClass)} style={{ animationDelay: '300ms' }} />
      <span className="sr-only">Loading...</span>
    </div>
  );
};

/**
 * プログレスバーローディング
 */
export const LoadingProgress: React.FC<{
  progress: number;
  size?: 'sm' | 'md' | 'lg';
  variant?: 'default' | 'primary' | 'success' | 'warning' | 'error';
  text?: string;
  className?: string;
  show?: boolean;
}> = ({
  progress,
  size = 'md',
  variant = 'primary',
  text,
  className,
  show = true,
}) => {
  if (!show) return null;

  const heightMap = {
    sm: 'h-1',
    md: 'h-2',
    lg: 'h-3',
  };

  const colorClass = variantClasses[variant];
  const height = heightMap[size];
  const clampedProgress = Math.max(0, Math.min(100, progress));

  return (
    <div className={cn('w-full space-y-2', className)} role="progressbar" aria-valuenow={clampedProgress} aria-valuemin={0} aria-valuemax={100}>
      {text && (
        <div className="flex justify-between text-sm">
          <span>{text}</span>
          <span>{Math.round(clampedProgress)}%</span>
        </div>
      )}
      <div className={cn('w-full bg-neutral-200 rounded-full overflow-hidden', height)}>
        <div 
          className={cn('rounded-full transition-all duration-300 ease-out', height, colorClass.replace('text-', 'bg-'))}
          style={{ width: `${clampedProgress}%` }}
        />
      </div>
    </div>
  );
};

/**
 * スケルトンローディング
 */
export const LoadingSkeleton: React.FC<{
  lines?: number;
  height?: string;
  className?: string;
  show?: boolean;
}> = ({
  lines = 3,
  height = 'h-4',
  className,
  show = true,
}) => {
  if (!show) return null;

  return (
    <div className={cn('animate-pulse space-y-3', className)} role="status" aria-label="Loading content">
      {Array.from({ length: lines }).map((_, i) => (
        <div key={i} className={cn('bg-neutral-300 rounded', height)} />
      ))}
      <span className="sr-only">Loading content...</span>
    </div>
  );
};

/**
 * ゲーム専用ローディング（数字テーマ）
 */
export const GameLoadingSpinner: React.FC<{
  text?: string;
  className?: string;
  show?: boolean;
}> = ({
  text = 'ゲーム準備中...',
  className,
  show = true,
}) => {
  if (!show) return null;

  return (
    <div className={cn('flex flex-col items-center gap-4', className)}>
      <div className="relative">
        {/* 外側の回転するリング */}
        <div className="w-16 h-16 border-4 border-primary-200 border-t-primary-600 rounded-full animate-spin"></div>
        
        {/* 中央の数字アイコン */}
        <div className="absolute inset-0 flex items-center justify-center">
          <span className="text-2xl animate-pulse">🎯</span>
        </div>
      </div>
      
      {text && (
        <div className="text-primary-600 font-medium text-center animate-pulse">
          {text}
        </div>
      )}
    </div>
  );
};

export default LoadingSpinner;