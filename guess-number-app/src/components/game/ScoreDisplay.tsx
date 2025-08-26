/**
 * ScoreDisplay - スコア表示コンポーネント
 * 現在のスコア、ベストスコア、スコア詳細を表示
 * アニメーション効果とスコア分析機能付き
 */

import React, { useMemo, useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import type { GameState, Difficulty, ScoreResult, BestRecord } from '@/types/game';
import { ScoreCalculator } from '@/lib/scoring';
import { useBestRecord } from '@/lib/game-store';
import { cn, formatTime } from '@/lib/utils';

export interface ScoreDisplayProps {
  /** ゲーム状態 */
  gameState: GameState;
  /** 難易度 */
  difficulty: Difficulty;
  /** カスタムクラス */
  className?: string;
  /** コンパクト表示フラグ */
  compact?: boolean;
  /** スコア詳細表示フラグ */
  showDetails?: boolean;
  /** アニメーション無効フラグ */
  disableAnimation?: boolean;
}

export const ScoreDisplay: React.FC<ScoreDisplayProps> = ({
  gameState,
  difficulty,
  className,
  compact = false,
  showDetails = true,
  disableAnimation = false,
}) => {
  // アニメーション状態
  const [animationStep, setAnimationStep] = useState(0);
  const [showConfetti, setShowConfetti] = useState(false);
  
  // ベスト記録を取得
  const bestRecord = useBestRecord(difficulty) as BestRecord | null;
  
  // スコア計算
  const scoreResult = useMemo(() => {
    if (gameState.status !== 'won') return null;
    
    const completionTime = gameState.startedAt ? 
      Date.now() - gameState.startedAt : 0;
    
    return ScoreCalculator.calculateTotalScore(
      gameState,
      difficulty,
      completionTime,
      false // 連続プレイボーナスは別途管理
    );
  }, [gameState, difficulty]);

  // 新記録判定
  const isNewRecord = useMemo(() => {
    if (!scoreResult || !bestRecord) return false;
    return scoreResult.totalScore > bestRecord.score;
  }, [scoreResult, bestRecord]);

  // アニメーション効果
  useEffect(() => {
    if (disableAnimation || !scoreResult) return;
    
    const timer1 = setTimeout(() => setAnimationStep(1), 300);
    const timer2 = setTimeout(() => setAnimationStep(2), 800);
    const timer3 = setTimeout(() => setAnimationStep(3), 1300);
    
    if (isNewRecord) {
      const confettiTimer = setTimeout(() => setShowConfetti(true), 1000);
      const confettiClearTimer = setTimeout(() => setShowConfetti(false), 4000);
      
      return () => {
        clearTimeout(timer1);
        clearTimeout(timer2);
        clearTimeout(timer3);
        clearTimeout(confettiTimer);
        clearTimeout(confettiClearTimer);
      };
    }
    
    return () => {
      clearTimeout(timer1);
      clearTimeout(timer2);
      clearTimeout(timer3);
    };
  }, [scoreResult, isNewRecord, disableAnimation]);

  // スコアなしの場合
  if (!scoreResult) {
    return (
      <Card variant="default" className={cn('opacity-60', className)}>
        <CardContent className="text-center py-6">
          <p className="text-neutral-600">
            {gameState.status === 'lost' 
              ? '残念！ゲーム終了です' 
              : 'スコア計算中...'}
          </p>
        </CardContent>
      </Card>
    );
  }

  // コンパクト表示
  if (compact) {
    return (
      <div className={cn('flex items-center gap-4', className)}>
        <div className="text-center">
          <div className="text-2xl font-bold text-primary-600">
            {scoreResult.totalScore.toLocaleString()}
          </div>
          <div className="text-xs text-neutral-600">スコア</div>
        </div>
        {isNewRecord && (
          <div className="flex items-center gap-1 text-success-600 font-semibold">
            🏆 新記録！
          </div>
        )}
      </div>
    );
  }

  return (
    <Card 
      variant={isNewRecord ? "success" : "primary"} 
      className={cn(
        'relative overflow-hidden',
        !disableAnimation && 'animate-fade-in',
        className
      )}
    >
      {/* 紙吹雪効果 */}
      {showConfetti && (
        <div className="absolute inset-0 pointer-events-none z-10">
          <div className="confetti-animation">
            {Array.from({ length: 20 }).map((_, i) => (
              <div
                key={i}
                className="confetti-piece"
                style={{
                  left: `${Math.random() * 100}%`,
                  animationDelay: `${Math.random() * 2}s`,
                  backgroundColor: ['#f59e0b', '#10b981', '#3b82f6', '#ef4444', '#8b5cf6'][Math.floor(Math.random() * 5)],
                }}
              />
            ))}
          </div>
        </div>
      )}

      <CardHeader>
        <CardTitle level={2} className="flex items-center justify-between">
          <span>
            {isNewRecord ? '🏆 新記録達成！' : '📊 スコア結果'}
          </span>
          {gameState.status === 'won' && (
            <span className="text-success-600 font-bold">🎉 勝利！</span>
          )}
        </CardTitle>
      </CardHeader>

      <CardContent className="space-y-6">
        {/* メインスコア表示 */}
        <div className="text-center space-y-2">
          <div 
            className={cn(
              'text-5xl font-bold font-mono',
              isNewRecord ? 'text-success-600' : 'text-primary-600',
              !disableAnimation && animationStep >= 1 && 'animate-pulse-slow'
            )}
            style={{
              transform: !disableAnimation && animationStep >= 1 ? 'scale(1.1)' : 'scale(1)',
              transition: 'transform 0.5s ease-out'
            }}
          >
            {scoreResult.totalScore.toLocaleString()}
          </div>
          <div className="text-lg text-neutral-600">
            総合スコア
          </div>
          
          {/* 難易度倍率表示 */}
          <div className="text-sm text-neutral-500">
            難易度倍率: ×{scoreResult.multiplier}
          </div>
        </div>

        {/* ベスト記録との比較 */}
        {bestRecord && (
          <div 
            className={cn(
              'text-center p-3 rounded-lg border-2',
              isNewRecord 
                ? 'border-success-300 bg-success-50' 
                : 'border-neutral-300 bg-neutral-50',
              !disableAnimation && animationStep >= 2 && 'animate-slide-up'
            )}
          >
            {isNewRecord ? (
              <div className="text-success-800">
                <div className="font-bold">新記録達成！🎊</div>
                <div className="text-sm">
                  前回: {bestRecord.score.toLocaleString()} → 
                  今回: {scoreResult.totalScore.toLocaleString()}
                  <span className="font-semibold text-success-600">
                    (+{(scoreResult.totalScore - bestRecord.score).toLocaleString()})
                  </span>
                </div>
              </div>
            ) : (
              <div className="text-neutral-700">
                <div className="font-semibold">ベスト記録</div>
                <div className="text-sm">
                  {bestRecord.score.toLocaleString()}点 
                  <span className="text-neutral-500">
                    (あと{(bestRecord.score - scoreResult.totalScore).toLocaleString()}点)
                  </span>
                </div>
              </div>
            )}
          </div>
        )}

        {/* スコア詳細 */}
        {showDetails && (
          <div 
            className={cn(
              'space-y-3',
              !disableAnimation && animationStep >= 3 && 'animate-fade-in-up'
            )}
          >
            <h4 className="font-semibold text-neutral-800 border-b pb-2">
              スコア詳細
            </h4>
            
            <div className="grid grid-cols-2 gap-3 text-sm">
              {/* 基本スコア */}
              <div className="flex justify-between p-2 bg-white rounded border">
                <span>基本スコア</span>
                <span className="font-mono font-semibold">
                  +{scoreResult.baseScore.toLocaleString()}
                </span>
              </div>
              
              {/* 回数ボーナス */}
              {scoreResult.attemptBonus > 0 && (
                <div className="flex justify-between p-2 bg-success-50 rounded border">
                  <span>回数ボーナス</span>
                  <span className="font-mono font-semibold text-success-600">
                    +{scoreResult.attemptBonus.toLocaleString()}
                  </span>
                </div>
              )}
              
              {/* 時間ボーナス */}
              {scoreResult.timeBonus > 0 && (
                <div className="flex justify-between p-2 bg-info-50 rounded border">
                  <span>時間ボーナス</span>
                  <span className="font-mono font-semibold text-info-600">
                    +{scoreResult.timeBonus.toLocaleString()}
                  </span>
                </div>
              )}
              
              {/* ヒントペナルティ */}
              {scoreResult.hintPenalty > 0 && (
                <div className="flex justify-between p-2 bg-warning-50 rounded border">
                  <span>ヒントペナルティ</span>
                  <span className="font-mono font-semibold text-warning-600">
                    -{scoreResult.hintPenalty.toLocaleString()}
                  </span>
                </div>
              )}
            </div>
            
            {/* 特別ボーナス */}
            {Object.keys(scoreResult.specialBonuses).length > 0 && (
              <div className="space-y-2">
                <h5 className="font-semibold text-neutral-700">特別ボーナス</h5>
                <div className="grid gap-2">
                  {scoreResult.specialBonuses.perfect && (
                    <div className="flex justify-between p-2 bg-gradient-to-r from-yellow-50 to-orange-50 rounded border border-yellow-200">
                      <span className="flex items-center gap-1">
                        🏅 パーフェクト
                        <span className="text-xs text-neutral-500">(3回以内)</span>
                      </span>
                      <span className="font-mono font-semibold text-yellow-600">
                        +{scoreResult.specialBonuses.perfect.toLocaleString()}
                      </span>
                    </div>
                  )}
                  
                  {scoreResult.specialBonuses.speed && (
                    <div className="flex justify-between p-2 bg-gradient-to-r from-blue-50 to-indigo-50 rounded border border-blue-200">
                      <span className="flex items-center gap-1">
                        ⚡ スピード
                        <span className="text-xs text-neutral-500">(時間50%残し)</span>
                      </span>
                      <span className="font-mono font-semibold text-blue-600">
                        +{scoreResult.specialBonuses.speed.toLocaleString()}
                      </span>
                    </div>
                  )}
                  
                  {scoreResult.specialBonuses.noHint && (
                    <div className="flex justify-between p-2 bg-gradient-to-r from-green-50 to-emerald-50 rounded border border-green-200">
                      <span className="flex items-center gap-1">
                        🧠 ノーヒント
                        <span className="text-xs text-neutral-500">(ヒント未使用)</span>
                      </span>
                      <span className="font-mono font-semibold text-green-600">
                        +{scoreResult.specialBonuses.noHint.toLocaleString()}
                      </span>
                    </div>
                  )}
                  
                  {scoreResult.specialBonuses.consecutive && (
                    <div className="flex justify-between p-2 bg-gradient-to-r from-purple-50 to-pink-50 rounded border border-purple-200">
                      <span className="flex items-center gap-1">
                        🔥 連続勝利
                        <span className="text-xs text-neutral-500">(連勝ボーナス)</span>
                      </span>
                      <span className="font-mono font-semibold text-purple-600">
                        +{scoreResult.specialBonuses.consecutive.toLocaleString()}
                      </span>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        )}

        {/* ゲーム統計 */}
        <div className="pt-4 border-t border-neutral-200">
          <div className="grid grid-cols-3 gap-4 text-center text-sm">
            <div>
              <div className="font-mono font-bold text-lg">
                {gameState.guesses.length}
              </div>
              <div className="text-neutral-600">推測回数</div>
            </div>
            <div>
              <div className="font-mono font-bold text-lg">
                {gameState.hintsUsed}
              </div>
              <div className="text-neutral-600">ヒント使用</div>
            </div>
            <div>
              <div className="font-mono font-bold text-lg">
                {formatTime(gameState.startedAt ? 
                  Math.floor((Date.now() - gameState.startedAt) / 1000) : 0)}
              </div>
              <div className="text-neutral-600">クリア時間</div>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default ScoreDisplay;