/**
 * GameStatus - ゲーム状態表示コンポーネント
 * タイマー、進行状況、統計情報を表示
 * リアルタイム更新とアニメーション実装
 */

import React, { useEffect, useState, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import type { GameState, Difficulty } from '@/types/game';
import { DIFFICULTY_CONFIGS } from '@/types/game';
import { cn, formatTime } from '@/lib/utils';

export interface GameStatusProps {
  /** ゲーム状態 */
  gameState: GameState;
  /** 難易度 */
  difficulty: Difficulty;
  /** 統計情報 */
  stats?: {
    timeElapsed: number;
    attemptsUsed: number;
    hintsUsed: number;
    currentRange: [number, number];
  } | null;
  /** カスタムクラス */
  className?: string;
  /** コンパクト表示フラグ */
  compact?: boolean;
}

export const GameStatus: React.FC<GameStatusProps> = ({
  gameState,
  difficulty,
  stats,
  className,
  compact = false,
}) => {
  // リアルタイム時間更新用
  const [currentTime, setCurrentTime] = useState(Date.now());
  
  // 1秒ごとに時間を更新
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTime(Date.now());
    }, 1000);
    
    return () => clearInterval(interval);
  }, []);

  // 難易度設定を取得
  const difficultyConfig = DIFFICULTY_CONFIGS[difficulty];

  // 時間関連の計算
  const timeStats = useMemo(() => {
    const elapsed = gameState.startedAt ? 
      Math.floor((currentTime - gameState.startedAt) / 1000) : 0;
    
    const timeLimit = difficultyConfig.timeLimitSec;
    const timeLeft = timeLimit ? Math.max(0, timeLimit - elapsed) : undefined;
    const timeProgress = timeLimit ? ((timeLimit - elapsed) / timeLimit) * 100 : 100;
    
    return {
      elapsed,
      timeLeft,
      timeProgress: Math.max(0, Math.min(100, timeProgress)),
      hasTimeLimit: !!timeLimit,
    };
  }, [currentTime, gameState.startedAt, difficultyConfig.timeLimitSec]);

  // 進行状況の計算
  const progress = useMemo(() => {
    const totalAttempts = difficultyConfig.attempts;
    const usedAttempts = gameState.guesses.length;
    const remainingAttempts = gameState.attemptsLeft;
    const progressPercent = (usedAttempts / totalAttempts) * 100;
    
    return {
      totalAttempts,
      usedAttempts,
      remainingAttempts,
      progressPercent: Math.min(100, progressPercent),
    };
  }, [gameState.guesses.length, gameState.attemptsLeft, difficultyConfig.attempts]);

  // ヒント残数
  const hintsRemaining = Math.max(0, difficultyConfig.hintsAllowed - gameState.hintsUsed);

  // 状態に応じたカラーテーマ
  const getStatusColor = () => {
    if (gameState.status === 'won') return 'text-success-600';
    if (gameState.status === 'lost') return 'text-error-600';
    if (progress.remainingAttempts <= 2) return 'text-warning-600';
    return 'text-primary-600';
  };

  // 時間警告の色
  const getTimeColor = () => {
    if (!timeStats.hasTimeLimit) return 'text-neutral-600';
    if (timeStats.timeProgress > 50) return 'text-success-600';
    if (timeStats.timeProgress > 20) return 'text-warning-600';
    return 'text-error-600';
  };

  if (compact) {
    // コンパクト表示版
    return (
      <div className={cn('flex items-center gap-4 text-sm', className)}>
        <div className="flex items-center gap-2">
          <span className="text-neutral-500">範囲:</span>
          <span className="font-mono font-bold">1-{gameState.upper}</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-neutral-500">残り:</span>
          <span className={cn('font-mono font-bold', getStatusColor())}>
            {progress.remainingAttempts}回
          </span>
        </div>
        {timeStats.hasTimeLimit && (
          <div className="flex items-center gap-2">
            <span className="text-neutral-500">時間:</span>
            <span className={cn('font-mono font-bold', getTimeColor())}>
              {formatTime(timeStats.timeLeft || 0)}
            </span>
          </div>
        )}
      </div>
    );
  }

  return (
    <Card variant="primary" className={cn('animate-fade-in', className)}>
      <CardHeader className="pb-3">
        <CardTitle level={3} className="flex items-center justify-between">
          <span>ゲーム状況</span>
          <div className="flex items-center gap-2 text-sm text-neutral-600">
            <span>難易度:</span>
            <span className={cn('font-semibold', getStatusColor())}>
              {difficulty === 'easy' && '🟢 かんたん'}
              {difficulty === 'normal' && '🟡 ふつう'}
              {difficulty === 'hard' && '🔴 むずかしい'}
            </span>
          </div>
        </CardTitle>
      </CardHeader>
      
      <CardContent className="space-y-6">
        {/* 基本統計グリッド */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {/* 範囲表示 */}
          <div className="text-center p-4 bg-white rounded-lg border">
            <div className="font-mono text-2xl font-bold text-neutral-900">
              1-{gameState.upper}
            </div>
            <div className="text-sm text-neutral-600 mt-1">範囲</div>
          </div>
          
          {/* 残り回数 */}
          <div className="text-center p-4 bg-white rounded-lg border">
            <div className={cn('font-mono text-2xl font-bold', getStatusColor())}>
              {progress.remainingAttempts}
            </div>
            <div className="text-sm text-neutral-600 mt-1">残り回数</div>
          </div>
          
          {/* 推測済み */}
          <div className="text-center p-4 bg-white rounded-lg border">
            <div className="font-mono text-2xl font-bold text-info-600">
              {progress.usedAttempts}
            </div>
            <div className="text-sm text-neutral-600 mt-1">推測済み</div>
          </div>
          
          {/* ヒント残数 */}
          <div className="text-center p-4 bg-white rounded-lg border">
            <div className="font-mono text-2xl font-bold text-warning-600">
              {hintsRemaining}
            </div>
            <div className="text-sm text-neutral-600 mt-1">ヒント残</div>
          </div>
        </div>

        {/* 推測範囲表示 */}
        {gameState.currentRange[0] !== 1 || gameState.currentRange[1] !== gameState.upper ? (
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span>推測可能範囲</span>
              <span className="font-mono font-bold">
                {gameState.currentRange[0]} ～ {gameState.currentRange[1]}
              </span>
            </div>
            <div className="relative h-3 bg-neutral-200 rounded-full overflow-hidden">
              <div
                className="absolute h-full bg-gradient-to-r from-primary-400 to-primary-600 rounded-full transition-all duration-500"
                style={{
                  left: `${((gameState.currentRange[0] - 1) / (gameState.upper - 1)) * 100}%`,
                  width: `${((gameState.currentRange[1] - gameState.currentRange[0] + 1) / gameState.upper) * 100}%`,
                }}
              />
            </div>
            <div className="text-xs text-center text-neutral-500">
              範囲が{gameState.upper}から{gameState.currentRange[1] - gameState.currentRange[0] + 1}に絞り込まれました
            </div>
          </div>
        ) : null}

        {/* 進行状況バー */}
        <div className="space-y-2">
          <div className="flex justify-between text-sm">
            <span>ゲーム進行状況</span>
            <span>{Math.round(progress.progressPercent)}%</span>
          </div>
          <div className="relative h-3 bg-neutral-200 rounded-full overflow-hidden">
            <div
              className={cn(
                'h-full rounded-full transition-all duration-500',
                'bg-gradient-to-r',
                progress.progressPercent < 50 
                  ? 'from-success-400 to-success-600'
                  : progress.progressPercent < 80
                    ? 'from-warning-400 to-warning-600'
                    : 'from-error-400 to-error-600'
              )}
              style={{ width: `${progress.progressPercent}%` }}
              role="progressbar"
              aria-valuenow={progress.progressPercent}
              aria-valuemin={0}
              aria-valuemax={100}
              aria-label="ゲーム進行状況"
            />
          </div>
        </div>

        {/* タイマー（制限時間がある場合） */}
        {timeStats.hasTimeLimit && (
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span>残り時間</span>
              <span className={cn('font-mono font-bold', getTimeColor())}>
                {formatTime(timeStats.timeLeft || 0)}
              </span>
            </div>
            <div className="relative h-3 bg-neutral-200 rounded-full overflow-hidden">
              <div
                className={cn(
                  'h-full rounded-full transition-all duration-1000',
                  'bg-gradient-to-r',
                  timeStats.timeProgress > 50
                    ? 'from-success-400 to-success-600'
                    : timeStats.timeProgress > 20
                      ? 'from-warning-400 to-warning-600'
                      : 'from-error-400 to-error-600'
                )}
                style={{ width: `${timeStats.timeProgress}%` }}
                role="progressbar"
                aria-valuenow={timeStats.timeLeft}
                aria-valuemin={0}
                aria-valuemax={difficultyConfig.timeLimitSec}
                aria-label="残り時間"
              />
            </div>
            {timeStats.timeProgress <= 20 && (
              <div className="text-xs text-center text-error-600 font-semibold animate-pulse">
                ⚠️ 時間が少なくなってきました！
              </div>
            )}
          </div>
        )}

        {/* 経過時間表示 */}
        <div className="text-center text-sm text-neutral-600">
          経過時間: <span className="font-mono font-semibold">{formatTime(timeStats.elapsed)}</span>
        </div>
      </CardContent>
    </Card>
  );
};

export default GameStatus;