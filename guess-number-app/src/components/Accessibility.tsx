/**
 * Accessibility - アクセシビリティ支援コンポーネント群
 * WCAG 2.1 AA準拠、スクリーンリーダー対応
 * キーボードナビゲーション、フォーカス管理
 */

'use client';

import React, { useEffect, useRef, useState, useCallback } from 'react';
import { cn } from '@/lib/utils';

/**
 * ライブリージョン - 動的コンテンツの読み上げ用
 */
export interface LiveRegionProps {
  message: string | null;
  priority?: 'polite' | 'assertive';
  className?: string;
}

export const LiveRegion: React.FC<LiveRegionProps> = ({
  message,
  priority = 'polite',
  className,
}) => {
  const [currentMessage, setCurrentMessage] = useState<string>('');

  useEffect(() => {
    if (message && message !== currentMessage) {
      setCurrentMessage(message);
      
      // メッセージをクリアするタイマー
      const timer = setTimeout(() => {
        setCurrentMessage('');
      }, 5000);
      
      return () => clearTimeout(timer);
    }
  }, [message, currentMessage]);

  return (
    <div
      aria-live={priority}
      aria-atomic="true"
      className={cn('sr-only', className)}
    >
      {currentMessage}
    </div>
  );
};

/**
 * スキップリンク - メインコンテンツへの移動
 */
export const SkipLink: React.FC<{
  targetId: string;
  text?: string;
  className?: string;
}> = ({
  targetId,
  text = 'メインコンテンツへスキップ',
  className,
}) => {
  const handleClick = (e: React.MouseEvent) => {
    e.preventDefault();
    const target = document.getElementById(targetId);
    if (target) {
      target.focus();
      target.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <a
      href={`#${targetId}`}
      onClick={handleClick}
      className={cn(
        'absolute top-0 left-0 z-50 px-4 py-2 bg-primary-600 text-white font-medium',
        'transform -translate-y-full focus:translate-y-0',
        'transition-transform duration-200',
        'focus:outline-none focus:ring-2 focus:ring-primary-300',
        className
      )}
    >
      {text}
    </a>
  );
};

/**
 * フォーカストラップ - モーダル内でのフォーカス制御
 */
export interface FocusTrapProps {
  children: React.ReactNode;
  isActive: boolean;
  restoreFocus?: boolean;
  className?: string;
}

export const FocusTrap: React.FC<FocusTrapProps> = ({
  children,
  isActive,
  restoreFocus = true,
  className,
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const previousActiveElementRef = useRef<Element | null>(null);

  useEffect(() => {
    if (!isActive) return;

    // アクティブになったときの処理
    previousActiveElementRef.current = document.activeElement;
    
    const container = containerRef.current;
    if (!container) return;

    // フォーカス可能な要素を取得
    const getFocusableElements = () => {
      const selector = [
        'button:not([disabled])',
        'input:not([disabled])',
        'textarea:not([disabled])',
        'select:not([disabled])',
        'a[href]',
        '[tabindex]:not([tabindex="-1"])',
      ].join(', ');
      
      return Array.from(container.querySelectorAll(selector)) as HTMLElement[];
    };

    // キーボードイベントハンドラー
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key !== 'Tab') return;

      const focusableElements = getFocusableElements();
      if (focusableElements.length === 0) return;

      const firstElement = focusableElements[0];
      const lastElement = focusableElements[focusableElements.length - 1];

      if (e.shiftKey && document.activeElement === firstElement) {
        e.preventDefault();
        lastElement.focus();
      } else if (!e.shiftKey && document.activeElement === lastElement) {
        e.preventDefault();
        firstElement.focus();
      }
    };

    // イベントリスナー登録
    document.addEventListener('keydown', handleKeyDown);

    // 最初のフォーカス可能要素にフォーカス
    const focusableElements = getFocusableElements();
    if (focusableElements.length > 0) {
      focusableElements[0].focus();
    }

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      
      // フォーカスを復元
      if (restoreFocus && previousActiveElementRef.current) {
        (previousActiveElementRef.current as HTMLElement).focus?.();
      }
    };
  }, [isActive, restoreFocus]);

  return (
    <div
      ref={containerRef}
      className={className}
    >
      {children}
    </div>
  );
};

/**
 * キーボードヘルプ - ショートカット表示
 */
export const KeyboardHelp: React.FC<{
  shortcuts: Array<{ key: string; description: string }>;
  className?: string;
}> = ({ shortcuts, className }) => {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === '?' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault();
        setIsVisible(prev => !prev);
      } else if (e.key === 'Escape' && isVisible) {
        setIsVisible(false);
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isVisible]);

  if (!isVisible) return null;

  return (
    <div 
      className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-4"
      role="dialog"
      aria-labelledby="keyboard-help-title"
      aria-modal="true"
    >
      <div className={cn('bg-white rounded-lg shadow-2xl max-w-md w-full p-6', className)}>
        <h2 id="keyboard-help-title" className="text-lg font-semibold mb-4">
          キーボードショートカット
        </h2>
        
        <div className="space-y-2">
          {shortcuts.map((shortcut, index) => (
            <div key={index} className="flex justify-between items-center">
              <span className="text-sm">{shortcut.description}</span>
              <kbd className="px-2 py-1 bg-neutral-100 rounded text-xs font-mono">
                {shortcut.key}
              </kbd>
            </div>
          ))}
        </div>
        
        <div className="mt-4 text-center">
          <button
            onClick={() => setIsVisible(false)}
            className="px-4 py-2 bg-primary-600 text-white rounded hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-300"
          >
            閉じる
          </button>
        </div>
        
        <div className="mt-2 text-xs text-center text-neutral-500">
          <kbd>Ctrl/Cmd + ?</kbd> でこのヘルプを開閉
        </div>
      </div>
    </div>
  );
};

/**
 * カラーコントラストチェッカー（開発用）
 */
export const ContrastChecker: React.FC<{
  foreground: string;
  background: string;
  text: string;
  className?: string;
}> = ({ foreground, background, text, className }) => {
  const [contrastRatio, setContrastRatio] = useState<number | null>(null);

  // 輝度計算
  const getLuminance = (color: string): number => {
    // RGB値を取得（簡略化）
    const rgb = color.match(/\d+/g)?.map(Number);
    if (!rgb || rgb.length < 3) return 0;

    const [r, g, b] = rgb.map(val => {
      const s = val / 255;
      return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
    });

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  };

  useEffect(() => {
    const fgLum = getLuminance(foreground);
    const bgLum = getLuminance(background);
    
    const lightest = Math.max(fgLum, bgLum);
    const darkest = Math.min(fgLum, bgLum);
    
    const ratio = (lightest + 0.05) / (darkest + 0.05);
    setContrastRatio(ratio);
  }, [foreground, background]);

  if (process.env.NODE_ENV !== 'development' || !contrastRatio) {
    return null;
  }

  const isAACompliant = contrastRatio >= 4.5;
  const isAAACompliant = contrastRatio >= 7;

  return (
    <div className={cn('text-xs p-2 bg-neutral-100 rounded', className)}>
      <div style={{ color: foreground, backgroundColor: background }} className="p-1 rounded">
        {text}
      </div>
      <div className="mt-1">
        コントラスト比: {contrastRatio.toFixed(2)}:1
        {isAAACompliant ? ' ✅ AAA' : isAACompliant ? ' ✅ AA' : ' ❌ 基準未達成'}
      </div>
    </div>
  );
};

/**
 * 高コントラストモード検出
 */
export const useHighContrastMode = () => {
  const [isHighContrast, setIsHighContrast] = useState(false);

  useEffect(() => {
    const checkHighContrast = () => {
      // Windows高コントラストモードの検出
      if (window.matchMedia && window.matchMedia('(prefers-contrast: high)').matches) {
        setIsHighContrast(true);
        return;
      }

      // その他の方法での検出
      const testElement = document.createElement('div');
      testElement.style.position = 'absolute';
      testElement.style.top = '-9999px';
      testElement.style.backgroundColor = '#fff';
      testElement.style.color = '#000';
      document.body.appendChild(testElement);

      const computedStyle = window.getComputedStyle(testElement);
      const bgColor = computedStyle.backgroundColor;
      const textColor = computedStyle.color;

      // 期待値と異なる場合は高コントラストモードの可能性
      if (bgColor !== 'rgb(255, 255, 255)' || textColor !== 'rgb(0, 0, 0)') {
        setIsHighContrast(true);
      }

      document.body.removeChild(testElement);
    };

    checkHighContrast();

    // メディアクエリの変更を監視
    const mediaQuery = window.matchMedia('(prefers-contrast: high)');
    const handleChange = (e: MediaQueryListEvent) => {
      setIsHighContrast(e.matches);
    };

    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, []);

  return isHighContrast;
};

/**
 * 動きを減らす設定の検出
 */
export const useReducedMotion = () => {
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false);

  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReducedMotion(mediaQuery.matches);

    const handleChange = (e: MediaQueryListEvent) => {
      setPrefersReducedMotion(e.matches);
    };

    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, []);

  return prefersReducedMotion;
};

/**
 * フォーカスインジケーター強化
 */
export const FocusIndicator: React.FC<{
  children: React.ReactNode;
  className?: string;
}> = ({ children, className }) => {
  return (
    <div className={cn(
      'focus-within:ring-2 focus-within:ring-primary-500 focus-within:ring-offset-2',
      'rounded transition-all duration-200',
      className
    )}>
      {children}
    </div>
  );
};

export default {
  LiveRegion,
  SkipLink,
  FocusTrap,
  KeyboardHelp,
  ContrastChecker,
  FocusIndicator,
  useHighContrastMode,
  useReducedMotion,
};