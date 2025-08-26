/**
 * NumberInput - 数値入力専用コンポーネント
 * ゲーム用の数値入力にカスタマイズされたインプットコンポーネント
 * アクセシビリティ対応とキーボードナビゲーション実装
 */

import React, { useState, useRef, useCallback, useEffect } from 'react';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import type { GameState } from '@/types/game';
import { cn, clamp } from '@/lib/utils';

export interface NumberInputProps {
  /** ゲーム状態 */
  gameState: GameState;
  /** 推測を送信する関数 */
  onGuess: (guess: number) => void;
  /** 入力無効化フラグ */
  disabled?: boolean;
  /** カスタムクラス */
  className?: string;
  /** オートフォーカス */
  autoFocus?: boolean;
  /** プレースホルダーテキスト */
  placeholder?: string;
}

export const NumberInput: React.FC<NumberInputProps> = ({
  gameState,
  onGuess,
  disabled = false,
  className,
  autoFocus = true,
  placeholder = '数字を入力',
}) => {
  // ローカル状態
  const [currentInput, setCurrentInput] = useState('');
  const [inputError, setInputError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  // 参照
  const inputRef = useRef<HTMLInputElement>(null);
  
  // フォーカス管理
  useEffect(() => {
    if (autoFocus && !disabled && gameState.status === 'playing' && inputRef.current) {
      inputRef.current.focus();
    }
  }, [autoFocus, disabled, gameState.status]);

  // 入力検証関数
  const validateInput = useCallback((value: string): string | null => {
    const num = parseInt(value, 10);
    
    // 空文字チェック
    if (!value.trim()) {
      return '数値を入力してください';
    }
    
    // 数値チェック
    if (isNaN(num) || !Number.isInteger(num)) {
      return '整数を入力してください';
    }
    
    // 範囲チェック
    if (num < 1 || num > gameState.upper) {
      return `1から${gameState.upper}の間の数値を入力してください`;
    }
    
    // 重複チェック
    if (gameState.guesses.includes(num)) {
      return 'この数値は既に推測済みです';
    }
    
    return null;
  }, [gameState.upper, gameState.guesses]);

  // 入力値変更ハンドラー
  const handleInputChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    
    // 数値のみを許可（空文字も許可）
    if (value === '' || /^\d+$/.test(value)) {
      // 数値がある場合は範囲内に制限
      if (value !== '' && !isNaN(parseInt(value, 10))) {
        const numValue = parseInt(value, 10);
        const clampedValue = clamp(numValue, 1, gameState.upper);
        
        if (numValue !== clampedValue) {
          setCurrentInput(clampedValue.toString());
          return;
        }
      }
      
      setCurrentInput(value);
      
      // リアルタイム検証
      if (value.trim()) {
        const error = validateInput(value);
        setInputError(error || '');
      } else {
        setInputError('');
      }
    }
  }, [gameState.upper, validateInput]);

  // 推測送信ハンドラー
  const handleSubmit = useCallback(async () => {
    if (isSubmitting || disabled || !currentInput.trim()) return;
    
    const error = validateInput(currentInput);
    if (error) {
      setInputError(error);
      return;
    }
    
    const guess = parseInt(currentInput, 10);
    setIsSubmitting(true);
    
    try {
      await onGuess(guess);
      // 成功時は入力をクリア
      setCurrentInput('');
      setInputError('');
      
      // フォーカスを戻す
      if (inputRef.current) {
        inputRef.current.focus();
      }
    } catch (err) {
      console.error('推測送信エラー:', err);
      setInputError('推測の送信に失敗しました');
    } finally {
      setIsSubmitting(false);
    }
  }, [currentInput, validateInput, onGuess, disabled, isSubmitting]);

  // キーボードイベントハンドラー
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !inputError && currentInput.trim() && !isSubmitting) {
      e.preventDefault();
      handleSubmit();
    }
  }, [inputError, currentInput, isSubmitting, handleSubmit]);

  // 入力クリアハンドラー
  const handleClear = useCallback(() => {
    setCurrentInput('');
    setInputError('');
    if (inputRef.current) {
      inputRef.current.focus();
    }
  }, []);

  // 送信可能状態の計算
  const canSubmit = !disabled && 
                   !isSubmitting && 
                   currentInput.trim() !== '' && 
                   !inputError &&
                   gameState.status === 'playing';

  // 範囲ヒント表示用
  const rangeHint = `${gameState.currentRange[0]}～${gameState.currentRange[1]}の間かも...`;

  return (
    <div className={cn('space-y-4', className)}>
      {/* 入力フィールド */}
      <div className="relative max-w-md mx-auto">
        <Input
          ref={inputRef}
          type="text"
          inputType="number"
          size="xl"
          value={currentInput}
          onChange={handleInputChange}
          onKeyDown={handleKeyDown}
          placeholder={placeholder}
          error={!!inputError}
          errorMessage={inputError}
          helperText={!inputError && currentInput ? rangeHint : undefined}
          disabled={disabled || isSubmitting || gameState.status !== 'playing'}
          className={cn(
            'text-center text-3xl font-bold font-mono',
            'transition-all duration-200',
            inputError && 'shake-animation'
          )}
          aria-label={`1から${gameState.upper}の間の数値を入力`}
          aria-describedby="number-input-help"
          autoComplete="off"
          inputMode="numeric"
          pattern="[0-9]*"
        />
        
        {/* クリアボタン */}
        {currentInput && (
          <button
            onClick={handleClear}
            className={cn(
              'absolute right-3 top-1/2 transform -translate-y-1/2',
              'text-neutral-400 hover:text-neutral-600',
              'transition-colors duration-200',
              'p-1 rounded-full hover:bg-neutral-100'
            )}
            aria-label="入力をクリア"
            type="button"
          >
            ✕
          </button>
        )}
      </div>

      {/* 送信ボタン */}
      <div className="text-center">
        <Button
          size="lg"
          onClick={handleSubmit}
          disabled={!canSubmit}
          loading={isSubmitting}
          className={cn(
            'min-w-[160px]',
            'transform transition-all duration-200',
            canSubmit && 'hover:scale-105',
            'disabled:transform-none'
          )}
          aria-label={`${currentInput}を推測として送信`}
        >
          {isSubmitting ? (
            <>⏳ 送信中...</>
          ) : (
            <>🎯 推測する</>
          )}
        </Button>
      </div>

      {/* 入力ヘルプ */}
      <div 
        id="number-input-help" 
        className="text-center text-sm text-neutral-600"
        aria-live="polite"
      >
        {gameState.attemptsLeft > 0 ? (
          <>
            残り{gameState.attemptsLeft}回の推測チャンス
            {gameState.timeLeftSec !== undefined && (
              <> • 残り時間: {gameState.timeLeftSec}秒</>
            )}
          </>
        ) : (
          '推測回数を使い切りました'
        )}
      </div>

      {/* キーボードショートカット説明 */}
      <div className="text-center text-xs text-neutral-400">
        <kbd className="px-2 py-1 bg-neutral-100 rounded text-xs">Enter</kbd>で送信 • 
        <kbd className="px-2 py-1 bg-neutral-100 rounded text-xs ml-2">Esc</kbd>でクリア
      </div>
    </div>
  );
};

// キーボードショートカット用の効果（Escapeキー）
export const useNumberInputShortcuts = (onClear?: () => void) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && onClear) {
        onClear();
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [onClear]);
};

export default NumberInput;