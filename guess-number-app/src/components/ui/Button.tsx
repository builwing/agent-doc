/**
 * GuessNumber - Buttonコンポーネント
 * アクセシビリティ対応の汎用ボタンコンポーネント
 * WCAG 2.1 AA準拠
 */

import React, { forwardRef } from 'react';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

// ボタンのバリエーション定義
const buttonVariants = cva(
  // ベーススタイル（全バリエーション共通）
  [
    'game-button',
    'inline-flex items-center justify-center',
    'px-4 py-2',
    'text-sm font-medium',
    'transition-all duration-200',
    'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2',
    'disabled:pointer-events-none disabled:opacity-50',
    'select-none',
    // タッチデバイス対応
    'touch-manipulation',
    // アクセシビリティ：最小タッチターゲットサイズ
    'min-h-touch min-w-touch',
  ],
  {
    variants: {
      variant: {
        primary: [
          'bg-primary-600 text-white shadow-button',
          'hover:bg-primary-700 hover:shadow-buttonHover',
          'focus-visible:ring-primary-500',
          'active:bg-primary-800',
        ],
        secondary: [
          'bg-white text-neutral-700 border border-neutral-300 shadow-button',
          'hover:bg-neutral-50 hover:border-neutral-400 hover:shadow-buttonHover',
          'focus-visible:ring-neutral-500',
          'active:bg-neutral-100',
        ],
        success: [
          'bg-success-600 text-white shadow-button',
          'hover:bg-success-700 hover:shadow-buttonHover',
          'focus-visible:ring-success-500',
          'active:bg-success-800',
        ],
        error: [
          'bg-error-600 text-white shadow-button',
          'hover:bg-error-700 hover:shadow-buttonHover',
          'focus-visible:ring-error-500',
          'active:bg-error-800',
        ],
        warning: [
          'bg-warning-600 text-white shadow-button',
          'hover:bg-warning-700 hover:shadow-buttonHover',
          'focus-visible:ring-warning-500',
          'active:bg-warning-800',
        ],
        outline: [
          'border border-current bg-transparent',
          'hover:bg-current hover:text-white',
          'focus-visible:ring-2 focus-visible:ring-current',
        ],
        ghost: [
          'bg-transparent border-transparent',
          'hover:bg-neutral-100 hover:text-neutral-900',
          'focus-visible:ring-neutral-500',
        ],
        link: [
          'bg-transparent underline-offset-4 text-primary-600',
          'hover:underline hover:text-primary-700',
          'focus-visible:ring-primary-500',
        ],
      },
      size: {
        sm: 'h-8 px-3 text-xs',
        md: 'h-10 px-4 py-2 text-sm',
        lg: 'h-12 px-6 py-3 text-base',
        xl: 'h-14 px-8 py-4 text-lg',
        icon: 'h-10 w-10 p-0',
      },
      fullWidth: {
        true: 'w-full',
        false: 'w-auto',
      },
      loading: {
        true: 'pointer-events-none',
        false: '',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
      fullWidth: false,
      loading: false,
    },
  }
);

// ローディングスピナーコンポーネント
const LoadingSpinner = ({ size = 16 }: { size?: number }) => (
  <svg
    className="animate-spin"
    width={size}
    height={size}
    viewBox="0 0 24 24"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <circle
      className="opacity-25"
      cx="12"
      cy="12"
      r="10"
      stroke="currentColor"
      strokeWidth="4"
    />
    <path
      className="opacity-75"
      fill="currentColor"
      d="m4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
    />
  </svg>
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  /** ボタンのテキストまたはコンテンツ */
  children: React.ReactNode;
  /** ローディング状態 */
  loading?: boolean;
  /** ローディング時のテキスト */
  loadingText?: string;
  /** アイコンを左側に配置 */
  leftIcon?: React.ReactNode;
  /** アイコンを右側に配置 */
  rightIcon?: React.ReactNode;
  /** フルWidth適用 */
  fullWidth?: boolean;
  /** カスタムクラス */
  className?: string;
}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      className,
      variant,
      size,
      fullWidth,
      loading = false,
      loadingText,
      leftIcon,
      rightIcon,
      children,
      disabled,
      ...props
    },
    ref
  ) => {
    const isDisabled = disabled || loading;

    return (
      <button
        className={cn(
          buttonVariants({ variant, size, fullWidth, loading }),
          className
        )}
        ref={ref}
        disabled={isDisabled}
        aria-disabled={isDisabled}
        {...props}
      >
        {loading && (
          <>
            <LoadingSpinner size={size === 'sm' ? 14 : size === 'lg' ? 18 : 16} />
            <span className="ml-2">
              {loadingText || 'ローディング中...'}
            </span>
          </>
        )}
        {!loading && (
          <>
            {leftIcon && <span className="mr-2">{leftIcon}</span>}
            {children}
            {rightIcon && <span className="ml-2">{rightIcon}</span>}
          </>
        )}
      </button>
    );
  }
);

Button.displayName = 'Button';

export { Button, buttonVariants };
export type { VariantProps } from 'class-variance-authority';