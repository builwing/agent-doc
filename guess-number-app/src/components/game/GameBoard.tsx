/**
 * GuessNumber - GameBoardコンポーネント
 * メインゲーム画面の表示とインタラクション
 * アクセシビリティ対応とキーボードナビゲーション実装
 */

import React, { useState, useEffect, useRef } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import type { GameState } from '@/types/game';
import { cn, formatTime, clamp } from '@/lib/utils';

export interface GameBoardProps {
  /** ゲーム状態 */
  gameState: GameState;
  /** 推測を送信する関数 */
  onGuess: (guess: number) => void;
  /** ヒントを使用する関数 */
  onUseHint: () => void;
  /** ゲームを一時停止する関数 */
  onPause?: () => void;
  /** ゲームを終了する関数 */
  onQuit?: () => void;
  /** カスタムクラス */
  className?: string;
}

export const GameBoard: React.FC<GameBoardProps> = ({
  gameState,
  onGuess,
  onUseHint,
  onPause,
  onQuit,
  className,
}) => {
  const [currentGuess, setCurrentGuess] = useState('');
  const [inputError, setInputError] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);

  // 入力フィールドにフォーカスを設定
  useEffect(() => {
    if (gameState.status === 'playing' && inputRef.current) {
      inputRef.current.focus();
    }
  }, [gameState.status]);

  // 推測の送信処理
  const handleSubmitGuess = () => {
    const guess = parseInt(currentGuess, 10);
    
    // バリデーション
    if (isNaN(guess)) {
      setInputError('数値を入力してください');
      return;
    }
    
    if (guess < 1 || guess > gameState.upper) {
      setInputError(`1から${gameState.upper}の間の数値を入力してください`);
      return;
    }
    
    // 既に推測済みかチェック
    if (gameState.guesses.includes(guess)) {
      setInputError('この数値は既に推測済みです');
      return;
    }
    
    // エラーをクリア
    setInputError('');
    setCurrentGuess('');
    
    // 推測を送信
    onGuess(guess);
  };

  // Enter キーでの送信
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !inputError && currentGuess) {
      handleSubmitGuess();
    }
  };

  // 入力値の変更処理
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    
    // 数値のみを許可
    if (value === '' || /^\d+$/.test(value)) {
      const numValue = parseInt(value, 10);
      
      // 範囲チェック（リアルタイム）
      if (!isNaN(numValue)) {
        const clampedValue = clamp(numValue, 1, gameState.upper);
        if (numValue !== clampedValue) {
          setCurrentGuess(clampedValue.toString());
          return;
        }
      }
      
      setCurrentGuess(value);
      setInputError(''); // エラーをクリア
    }
  };

  // 進行状況の計算
  const progressPercentage = Math.max(0, 
    ((gameState.guesses.length + 1) / (gameState.attemptsLeft + gameState.guesses.length)) * 100
  );

  // 時間の進行状況（制限時間がある場合）
  const timeProgressPercentage = gameState.timeLeftSec !== undefined 
    ? Math.max(0, (gameState.timeLeftSec / (gameState.timeLeftSec + 1)) * 100)
    : 100;

  // 最後の推測結果を取得
  const lastGuess = gameState.guesses[gameState.guesses.length - 1];
  const lastResult = lastGuess ? (
    lastGuess < gameState.target ? 'もっと大きい数です' : 'もっと小さい数です'
  ) : '';

  // ヒント残数
  const hintsRemaining = Math.max(0, 3 - gameState.hintsUsed); // 仮定：最大3回のヒント

  return (
    <div className={cn('space-y-6', className)}>
      {/* ゲーム情報パネル */}
      <Card variant="primary" className="animate-fade-in">
        <CardHeader>
          <CardTitle level={2} className="flex items-center justify-between">
            <span>数当てゲーム</span>
            <div className="flex gap-2">
              {onPause && (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={onPause}
                  aria-label="ゲームを一時停止"
                >
                  ⏸️
                </Button>
              )}
              {onQuit && (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={onQuit}
                  aria-label="ゲームを終了"
                >
                  ❌
                </Button>
              )}
            </div>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* ゲーム統計 */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
            <div className="text-center p-3 bg-white rounded-lg">
              <div className="font-mono text-xl font-bold text-neutral-900">
                1-{gameState.upper}
              </div>
              <div className="text-neutral-600">範囲</div>
            </div>
            
            <div className="text-center p-3 bg-white rounded-lg">
              <div className="font-mono text-xl font-bold text-warning-600">
                {gameState.attemptsLeft}
              </div>
              <div className="text-neutral-600">残り回数</div>
            </div>
            
            <div className="text-center p-3 bg-white rounded-lg">
              <div className="font-mono text-xl font-bold text-info-600">
                {gameState.guesses.length}
              </div>
              <div className="text-neutral-600">推測済み</div>
            </div>
            
            <div className="text-center p-3 bg-white rounded-lg">
              <div className="font-mono text-xl font-bold text-success-600">
                {hintsRemaining}
              </div>
              <div className="text-neutral-600">ヒント残</div>
            </div>
          </div>

          {/* 時間制限があるゲームの場合のタイマー */}
          {gameState.timeLeftSec !== undefined && (
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>残り時間</span>
                <span className="font-mono font-bold">
                  {formatTime(gameState.timeLeftSec)}
                </span>
              </div>
              <div className="w-full bg-neutral-200 rounded-full h-2">
                <div
                  className={cn(
                    'h-2 rounded-full transition-all duration-1000',
                    timeProgressPercentage > 30 
                      ? 'bg-success-500' 
                      : timeProgressPercentage > 10 
                        ? 'bg-warning-500' 
                        : 'bg-error-500'
                  )}
                  style={{ width: `${timeProgressPercentage}%` }}
                  role="progressbar"
                  aria-valuenow={gameState.timeLeftSec}
                  aria-valuemin={0}
                  aria-valuemax={300} // 仮定：最大5分
                  aria-label="残り時間"
                />
              </div>
            </div>
          )}

          {/* 進行状況バー */}
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span>ゲーム進行状況</span>
              <span>{Math.round(progressPercentage)}%</span>
            </div>
            <div className="w-full bg-neutral-200 rounded-full h-2">
              <div
                className="bg-primary-500 h-2 rounded-full transition-all duration-500"
                style={{ width: `${progressPercentage}%` }}
                role="progressbar"
                aria-valuenow={progressPercentage}
                aria-valuemin={0}
                aria-valuemax={100}
                aria-label="ゲーム進行状況"
              />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* 推測入力エリア */}
      <Card className="animate-fade-in" style={{ animationDelay: '0.1s' }}>
        <CardContent className="space-y-6">
          <div className="text-center">
            <h3 className="text-lg font-semibold mb-2 text-neutral-900">
              数字を推測してください
            </h3>
            <p className="text-neutral-600 text-sm">
              1から{gameState.upper}の間の数値を入力してください
            </p>
          </div>

          {/* 最後の結果表示 */}
          {lastGuess && (
            <div
              className={cn(
                'game-feedback border-2 animate-bounce-in',
                lastGuess < gameState.target
                  ? 'border-warning-300 bg-warning-50 text-warning-800'
                  : 'border-error-300 bg-error-50 text-error-800'
              )}
              role="status"
              aria-live="polite"
            >
              <div className="font-semibold">前回の推測: {lastGuess}</div>
              <div className="text-sm">{lastResult}</div>
            </div>
          )}

          {/* 入力フィールド */}
          <div className="max-w-md mx-auto">
            <Input
              ref={inputRef}
              type="number"
              inputType="number"
              size="xl"
              value={currentGuess}
              onChange={handleInputChange}
              onKeyDown={handleKeyDown}
              placeholder="数字を入力"
              min={1}
              max={gameState.upper}
              error={!!inputError}
              errorMessage={inputError}
              helperText={`ヒント: ${gameState.currentRange[0]}から${gameState.currentRange[1]}の間かも...`}
              className="text-center text-3xl font-bold"
              aria-label={`1から${gameState.upper}の間の数値を入力`}
            />
          </div>

          {/* アクションボタン */}
          <div className="flex gap-4 justify-center">
            <Button
              size="lg"
              onClick={handleSubmitGuess}
              disabled={!currentGuess || !!inputError}
              className="min-w-[120px]"
            >
              推測する
            </Button>
            
            <Button
              variant="warning"
              size="lg"
              onClick={onUseHint}
              disabled={hintsRemaining === 0}
              className="min-w-[120px]"
            >
              ヒント ({hintsRemaining})
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* 推測履歴 */}
      {gameState.guesses.length > 0 && (
        <Card className="animate-fade-in" style={{ animationDelay: '0.2s' }}>
          <CardHeader>
            <CardTitle level={3}>推測履歴</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-4 md:grid-cols-6 lg:grid-cols-8 gap-2">
              {gameState.guesses.map((guess, index) => (
                <div
                  key={`guess-${index}-${guess}`}
                  className={cn(
                    'aspect-square flex items-center justify-center rounded-lg text-sm font-bold border-2',
                    guess < gameState.target
                      ? 'bg-warning-100 border-warning-300 text-warning-800'
                      : 'bg-error-100 border-error-300 text-error-800'
                  )}
                  title={`推測 ${index + 1}: ${guess} (${guess < gameState.target ? '小さい' : '大きい'})`}
                >
                  {guess}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
};