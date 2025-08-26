/**
 * GuessNumber メインゲーム画面
 * Next.js 15 App Router対応
 * Zustand状態管理とGameEngineを統合
 */
'use client';

import React, { useEffect, useState, useCallback, useMemo } from 'react';
import { GameBoard } from '@/components/game/GameBoard';
import { DifficultySelector } from '@/components/game/DifficultySelector';
import { useGameStore } from '@/lib/game-store';
import type { Difficulty, HintType } from '@/types/game';
import { DIFFICULTY_CONFIGS } from '@/types/game';
import { cn } from '@/lib/utils';

// 追加コンポーネントの動的インポート（パフォーマンス最適化）
const NumberInput = React.lazy(() => import('@/components/game/NumberInput').then(module => ({ default: module.NumberInput })));
const GameStatus = React.lazy(() => import('@/components/game/GameStatus').then(module => ({ default: module.GameStatus })));
const ScoreDisplay = React.lazy(() => import('@/components/game/ScoreDisplay').then(module => ({ default: module.ScoreDisplay })));
const GameOverModal = React.lazy(() => import('@/components/game/GameOverModal').then(module => ({ default: module.GameOverModal })));

// Suspenseラッパー
import { GameSuspenseWrapper } from '@/components/SuspenseWrapper';

export default function HomePage() {
  // Zustand storeから状態と関数を取得
  const {
    gameState,
    currentDifficulty,
    isPlaying,
    startNewGame,
    makeGuess,
    useHint,
    resetGame,
    pauseGame,
    resumeGame,
    setDifficulty,
  } = useGameStore();

  // ローカル状態（UI関連）
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [hintMessage, setHintMessage] = useState<string | null>(null);

  // ストア初期化（初回マウント時のみ）
  useEffect(() => {
    const store = useGameStore.getState();
    store.loadFromStorage();
  }, []);

  // 新しいゲームを開始
  const handleStartNewGame = useCallback(async (difficulty: Difficulty) => {
    setIsLoading(true);
    setError(null);
    
    try {
      startNewGame(difficulty);
      console.log(`新規ゲーム開始: 難易度=${difficulty}`);
    } catch (err) {
      console.error('ゲーム開始エラー:', err);
      setError('ゲームの開始に失敗しました。再度お試しください。');
    } finally {
      setIsLoading(false);
    }
  }, [startNewGame]);

  // 推測処理
  const handleGuess = useCallback(async (guess: number) => {
    if (!gameState || isLoading) return;
    
    setIsLoading(true);
    setError(null);
    
    try {
      const result = await makeGuess(guess);
      console.log('推測結果:', result);
      
      // 結果に応じてフィードバックを表示
      if (result.result.won) {
        // 勝利時の処理は GameOverModal で処理
      } else if (result.result.gameEnded && !result.result.won) {
        // 敗北時の処理は GameOverModal で処理
      }
    } catch (err) {
      console.error('推測エラー:', err);
      setError(err instanceof Error ? err.message : '推測の処理に失敗しました');
    } finally {
      setIsLoading(false);
    }
  }, [gameState, makeGuess, isLoading]);

  // ヒント使用
  const handleUseHint = useCallback(() => {
    if (!gameState || isLoading) return;
    
    setIsLoading(true);
    setError(null);
    
    try {
      // まずは範囲ヒントを使用（後で種類選択機能を追加予定）
      const hint = useHint('range');
      setHintMessage(hint.message);
      
      // 3秒後にヒントメッセージを非表示
      setTimeout(() => setHintMessage(null), 3000);
    } catch (err) {
      console.error('ヒント使用エラー:', err);
      setError(err instanceof Error ? err.message : 'ヒントの取得に失敗しました');
    } finally {
      setIsLoading(false);
    }
  }, [gameState, useHint, isLoading]);

  // ゲームリセット
  const handleResetGame = useCallback(() => {
    resetGame();
    setError(null);
    setHintMessage(null);
  }, [resetGame]);

  // 難易度設定
  const handleDifficultyChange = useCallback((difficulty: Difficulty) => {
    setDifficulty(difficulty);
  }, [setDifficulty]);

  // 現在の統計を計算
  const gameStats = useMemo(() => {
    if (!gameState) {
      return null;
    }
    
    const timeElapsed = gameState.startedAt ? 
      Math.floor((Date.now() - gameState.startedAt) / 1000) : 0;
    const attemptsUsed = gameState.guesses.length;
    
    return {
      timeElapsed,
      attemptsUsed,
      hintsUsed: gameState.hintsUsed,
      currentRange: gameState.currentRange,
    };
  }, [gameState]);

  // ゲーム未開始時は難易度選択画面を表示
  if (!gameState || gameState.status === 'idle' || !isPlaying) {
    return (
      <main className={cn(
        'min-h-screen bg-gradient-to-br from-primary-50 via-white to-primary-100',
        'px-4 py-8 sm:px-6 lg:px-8'
      )}>
        <div className="mx-auto max-w-4xl space-y-6">
          {/* メインタイトル */}
          <header className="text-center animate-fade-in">
            <h1 className="text-4xl font-bold text-primary-900 mb-2">
              🎯 GuessNumber
            </h1>
            <p className="text-lg text-neutral-600 max-w-2xl mx-auto">
              数を推測して正解を当てるゲームです。<br />
              難易度を選んでスタートしてください！
            </p>
          </header>

          {/* エラー表示 */}
          {error && (
            <div className="card variant-error animate-fade-in" role="alert">
              <div className="card-body">
                <h3 className="font-semibold text-error-800 mb-1">エラー</h3>
                <p className="text-error-700">{error}</p>
              </div>
            </div>
          )}

          {/* 難易度選択 */}
          <div className="animate-fade-in" style={{ animationDelay: '0.1s' }}>
            <DifficultySelector
              selectedDifficulty={currentDifficulty}
              onDifficultyChange={handleDifficultyChange}
              onStartGame={handleStartNewGame}
            />
          </div>

          {/* スタートボタン */}
          <div className="text-center animate-fade-in" style={{ animationDelay: '0.2s' }}>
            <button
              onClick={() => handleStartNewGame(currentDifficulty)}
              disabled={isLoading}
              className={cn(
                'btn-primary text-xl px-8 py-4 min-w-[200px]',
                'disabled:opacity-50 disabled:cursor-not-allowed',
                'transform transition-transform hover:scale-105'
              )}
              aria-label={`${DIFFICULTY_CONFIGS[currentDifficulty].upper}まで範囲でゲームを開始`}
            >
              {isLoading ? (
                <>⏳ 準備中...</>
              ) : (
                <>🎮 ゲームスタート</>
              )}
            </button>
          </div>

          {/* ゲームルール説明 */}
          <div className="card animate-fade-in" style={{ animationDelay: '0.3s' }}>
            <div className="card-body">
              <h2 className="text-xl font-semibold mb-4 text-primary-800">
                📋 ゲームのルール
              </h2>
              <div className="grid md:grid-cols-2 gap-6">
                <div>
                  <h3 className="font-semibold mb-2 text-neutral-800">基本ルール</h3>
                  <ul className="text-sm text-neutral-600 space-y-1">
                    <li>• コンピュータが選んだ数字を推測</li>
                    <li>• 「もっと大きい」「もっと小さい」のヒント</li>
                    <li>• 制限回数内に正解を目指そう</li>
                    <li>• ヒント機能で推測をサポート</li>
                  </ul>
                </div>
                <div>
                  <h3 className="font-semibold mb-2 text-neutral-800">スコアシステム</h3>
                  <ul className="text-sm text-neutral-600 space-y-1">
                    <li>• 残り試行回数でボーナス</li>
                    <li>• 残り時間でタイムボーナス</li>
                    <li>• 3回以内クリアでパーフェクトボーナス</li>
                    <li>• 難易度が高いほど高得点</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    );
  }

  // ゲーム進行中の画面
  return (
    <main className={cn(
      'min-h-screen bg-gradient-to-br from-primary-50 via-white to-secondary-50',
      'px-4 py-8 sm:px-6 lg:px-8'
    )}>
      <div className="mx-auto max-w-4xl space-y-6">
        {/* エラー表示 */}
        {error && (
          <div className="card variant-error animate-fade-in" role="alert">
            <div className="card-body">
              <h3 className="font-semibold text-error-800 mb-1">エラー</h3>
              <p className="text-error-700">{error}</p>
            </div>
          </div>
        )}

        {/* ヒントメッセージ表示 */}
        {hintMessage && (
          <div className="card variant-success animate-bounce-in" role="status" aria-live="polite">
            <div className="card-body">
              <h3 className="font-semibold text-success-800 mb-1">💡 ヒント</h3>
              <p className="text-success-700">{hintMessage}</p>
            </div>
          </div>
        )}

        {/* ゲーム状況表示 */}
        <GameSuspenseWrapper loadingText="ゲーム情報読み込み中...">
          <GameStatus
            gameState={gameState}
            difficulty={currentDifficulty}
            stats={gameStats}
          />
        </GameSuspenseWrapper>

        {/* メインゲームボード */}
        <GameBoard
          gameState={gameState}
          onGuess={handleGuess}
          onUseHint={handleUseHint}
          onPause={pauseGame}
          onQuit={handleResetGame}
          className="animate-fade-in"
        />

        {/* スコア表示（ゲーム終了時） */}
        {(gameState.status === 'won' || gameState.status === 'lost') && (
          <GameSuspenseWrapper loadingText="スコア計算中...">
            <ScoreDisplay
              gameState={gameState}
              difficulty={currentDifficulty}
            />
          </GameSuspenseWrapper>
        )}

        {/* ゲーム終了モーダル */}
        {(gameState.status === 'won' || gameState.status === 'lost') && (
          <GameSuspenseWrapper loadingText="結果表示準備中...">
            <GameOverModal
              gameState={gameState}
              difficulty={currentDifficulty}
              onPlayAgain={() => handleStartNewGame(currentDifficulty)}
              onChangeDifficulty={handleResetGame}
            />
          </GameSuspenseWrapper>
        )}
      </div>
    </main>
  );
}