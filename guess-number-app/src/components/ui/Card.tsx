/**
 * GuessNumber - Cardコンポーネント
 * ゲーム用カードレイアウトコンポーネント
 * アクセシビリティ対応のコンテナ
 */

import React, { forwardRef } from 'react';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

// カードのバリエーション定義
const cardVariants = cva(
  // ベーススタイル
  [
    'game-card',
    'relative',
    'overflow-hidden',
  ],
  {
    variants: {
      variant: {
        default: 'bg-white border border-neutral-200',
        elevated: 'bg-white border border-neutral-200 shadow-cardHover',
        outlined: 'bg-white border-2 border-neutral-300',
        filled: 'bg-neutral-50 border border-neutral-200',
        success: 'bg-success-50 border border-success-200',
        error: 'bg-error-50 border border-error-200',
        warning: 'bg-warning-50 border border-warning-200',
        primary: 'bg-primary-50 border border-primary-200',
      },
      size: {
        sm: 'p-4',
        md: 'p-6',
        lg: 'p-8',
        xl: 'p-10',
      },
      interactive: {
        true: [
          'cursor-pointer',
          'transition-all duration-200',
          'hover:shadow-cardHover hover:scale-[1.02]',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-primary-500',
          'active:scale-[0.98]',
        ],
        false: '',
      },
      rounded: {
        none: 'rounded-none',
        sm: 'rounded-sm',
        md: 'rounded-md',
        lg: 'rounded-lg',
        xl: 'rounded-xl',
        '2xl': 'rounded-2xl',
        '3xl': 'rounded-3xl',
        full: 'rounded-full',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'md',
      interactive: false,
      rounded: '2xl',
    },
  }
);

const cardHeaderVariants = cva([
  'flex flex-col space-y-1.5',
]);

const cardTitleVariants = cva([
  'text-lg font-semibold leading-none tracking-tight',
  'text-neutral-900',
]);

const cardDescriptionVariants = cva([
  'text-sm text-neutral-600',
  'leading-relaxed',
]);

const cardContentVariants = cva([
  'pt-0',
]);

const cardFooterVariants = cva([
  'flex items-center',
  'pt-4',
]);

export interface CardProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof cardVariants> {
  /** クリック可能な場合のコールバック */
  onClick?: () => void;
  /** ARIA role - インタラクティブな場合に自動設定 */
  role?: string;
  /** カスタムクラス */
  className?: string;
}

export interface CardHeaderProps extends React.HTMLAttributes<HTMLDivElement> {
  className?: string;
}

export interface CardTitleProps extends React.HTMLAttributes<HTMLHeadingElement> {
  /** ヘディングレベル */
  level?: 1 | 2 | 3 | 4 | 5 | 6;
  className?: string;
}

export interface CardDescriptionProps extends React.HTMLAttributes<HTMLParagraphElement> {
  className?: string;
}

export interface CardContentProps extends React.HTMLAttributes<HTMLDivElement> {
  className?: string;
}

export interface CardFooterProps extends React.HTMLAttributes<HTMLDivElement> {
  className?: string;
}

const Card = forwardRef<HTMLDivElement, CardProps>(
  ({ className, variant, size, interactive, rounded, onClick, role, ...props }, ref) => {
    const isInteractive = interactive || !!onClick;
    const cardRole = role || (isInteractive ? 'button' : undefined);
    
    return (
      <div
        ref={ref}
        className={cn(cardVariants({ variant, size, interactive: isInteractive, rounded }), className)}
        onClick={onClick}
        role={cardRole}
        tabIndex={isInteractive ? 0 : undefined}
        onKeyDown={isInteractive ? (e) => {
          if ((e.key === 'Enter' || e.key === ' ') && onClick) {
            e.preventDefault();
            onClick();
          }
        } : undefined}
        {...props}
      />
    );
  }
);
Card.displayName = 'Card';

const CardHeader = forwardRef<HTMLDivElement, CardHeaderProps>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn(cardHeaderVariants(), className)} {...props} />
  )
);
CardHeader.displayName = 'CardHeader';

const CardTitle = forwardRef<HTMLHeadingElement, CardTitleProps>(
  ({ className, level = 3, children, ...props }, ref) => {
    const Tag = `h${level}` as 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6';
    
    return (
      <Tag
        ref={ref}
        className={cn(cardTitleVariants(), className)}
        {...props}
      >
        {children}
      </Tag>
    );
  }
);
CardTitle.displayName = 'CardTitle';

const CardDescription = forwardRef<HTMLParagraphElement, CardDescriptionProps>(
  ({ className, ...props }, ref) => (
    <p ref={ref} className={cn(cardDescriptionVariants(), className)} {...props} />
  )
);
CardDescription.displayName = 'CardDescription';

const CardContent = forwardRef<HTMLDivElement, CardContentProps>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn(cardContentVariants(), className)} {...props} />
  )
);
CardContent.displayName = 'CardContent';

const CardFooter = forwardRef<HTMLDivElement, CardFooterProps>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn(cardFooterVariants(), className)} {...props} />
  )
);
CardFooter.displayName = 'CardFooter';

export {
  Card,
  CardHeader,
  CardFooter,
  CardTitle,
  CardDescription,
  CardContent,
  cardVariants,
};