/**
 * GuessNumber - Inputコンポーネント
 * アクセシビリティ対応の数値入力フィールド
 * WCAG 2.1 AA準拠、ゲーム専用最適化
 */

import React, { forwardRef } from 'react';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

// 入力フィールドのバリエーション定義
const inputVariants = cva(
  // ベーススタイル
  [
    'flex w-full border border-input bg-background',
    'transition-colors duration-200',
    'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
    'disabled:cursor-not-allowed disabled:opacity-50',
    'placeholder:text-muted-foreground',
    // アクセシビリティ：最小タッチターゲット
    'min-h-touch',
  ],
  {
    variants: {
      variant: {
        default: [
          'border-neutral-300 bg-white text-neutral-900',
          'focus-visible:border-primary-500 focus-visible:ring-primary-500',
          'hover:border-neutral-400',
        ],
        error: [
          'border-error-300 bg-error-50 text-error-900',
          'focus-visible:border-error-500 focus-visible:ring-error-500',
          'hover:border-error-400',
        ],
        success: [
          'border-success-300 bg-success-50 text-success-900',
          'focus-visible:border-success-500 focus-visible:ring-success-500',
          'hover:border-success-400',
        ],
        warning: [
          'border-warning-300 bg-warning-50 text-warning-900',
          'focus-visible:border-warning-500 focus-visible:ring-warning-500',
          'hover:border-warning-400',
        ],
      },
      size: {
        sm: 'h-9 px-3 py-1 text-sm',
        md: 'h-10 px-3 py-2 text-base',
        lg: 'h-12 px-4 py-3 text-lg',
        xl: 'h-14 px-6 py-4 text-xl',
      },
      inputType: {
        text: 'font-sans',
        number: 'game-number-input',
        email: 'font-mono text-sm',
        password: 'font-mono tracking-wide',
      },
      rounded: {
        none: 'rounded-none',
        sm: 'rounded-sm',
        md: 'rounded-md',
        lg: 'rounded-lg',
        xl: 'rounded-xl',
        full: 'rounded-full',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'md',
      inputType: 'text',
      rounded: 'lg',
    },
  }
);

export interface InputProps
  extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'size'>,
    VariantProps<typeof inputVariants> {
  /** エラー状態 */
  error?: boolean;
  /** エラーメッセージ */
  errorMessage?: string;
  /** ヘルパーテキスト */
  helperText?: string;
  /** ラベルテキスト */
  label?: string;
  /** 必須フィールドかどうか */
  required?: boolean;
  /** 左側のアイコン */
  leftIcon?: React.ReactNode;
  /** 右側のアイコン */
  rightIcon?: React.ReactNode;
  /** カスタムクラス */
  className?: string;
  /** コンテナのクラス */
  containerClassName?: string;
  /** ラベルのクラス */
  labelClassName?: string;
}

const Input = forwardRef<HTMLInputElement, InputProps>(
  (
    {
      className,
      containerClassName,
      labelClassName,
      variant,
      size,
      inputType = 'text',
      rounded,
      type = 'text',
      error = false,
      errorMessage,
      helperText,
      label,
      required = false,
      leftIcon,
      rightIcon,
      id,
      'aria-describedby': ariaDescribedBy,
      ...props
    },
    ref
  ) => {
    // IDを生成（ラベルとの関連付け用）
    const inputId = id || `input-${Math.random().toString(36).substr(2, 9)}`;
    const helperTextId = `${inputId}-helper`;
    const errorMessageId = `${inputId}-error`;

    // aria-describedby を構築
    const describedByIds = [
      ariaDescribedBy,
      helperText && helperTextId,
      error && errorMessage && errorMessageId,
    ].filter(Boolean).join(' ') || undefined;

    // 実際のinputタイプ設定
    const actualType = inputType === 'number' ? 'number' : type;
    
    // バリアント決定（エラー状態を考慮）
    const actualVariant = error ? 'error' : variant;

    return (
      <div className={cn('w-full space-y-2', containerClassName)}>
        {/* ラベル */}
        {label && (
          <label
            htmlFor={inputId}
            className={cn(
              'text-sm font-medium leading-none text-neutral-700',
              'peer-disabled:cursor-not-allowed peer-disabled:opacity-70',
              labelClassName
            )}
          >
            {label}
            {required && (
              <span className="ml-1 text-error-500 font-bold" aria-label="必須項目">
                *
              </span>
            )}
          </label>
        )}

        {/* 入力フィールドコンテナ */}
        <div className="relative">
          {/* 左側アイコン */}
          {leftIcon && (
            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-neutral-500">
              {leftIcon}
            </div>
          )}

          {/* メイン入力フィールド */}
          <input
            type={actualType}
            className={cn(
              inputVariants({ variant: actualVariant, size, inputType, rounded }),
              leftIcon && 'pl-10',
              rightIcon && 'pr-10',
              className
            )}
            ref={ref}
            id={inputId}
            aria-invalid={error}
            aria-describedby={describedByIds}
            aria-required={required}
            {...props}
          />

          {/* 右側アイコン */}
          {rightIcon && (
            <div className="absolute right-3 top-1/2 -translate-y-1/2 text-neutral-500">
              {rightIcon}
            </div>
          )}
        </div>

        {/* ヘルパーテキストまたはエラーメッセージ */}
        {(helperText || (error && errorMessage)) && (
          <div className="space-y-1">
            {/* ヘルパーテキスト */}
            {helperText && !error && (
              <p
                id={helperTextId}
                className="text-xs text-neutral-600 leading-relaxed"
              >
                {helperText}
              </p>
            )}
            
            {/* エラーメッセージ */}
            {error && errorMessage && (
              <p
                id={errorMessageId}
                className="text-xs text-error-600 font-medium leading-relaxed"
                role="alert"
                aria-live="polite"
              >
                <span className="inline-flex items-center">
                  <svg
                    className="w-3 h-3 mr-1 flex-shrink-0"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path
                      fillRule="evenodd"
                      d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
                      clipRule="evenodd"
                    />
                  </svg>
                  {errorMessage}
                </span>
              </p>
            )}
          </div>
        )}
      </div>
    );
  }
);
Input.displayName = 'Input';

export { Input, inputVariants };