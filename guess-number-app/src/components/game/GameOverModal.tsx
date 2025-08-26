/**
 * GameOverModal - ゲーム終了モーダルコンポーネント
 * 勝利・敗北時の結果表示とリプレイ機能
 * アクセシビリティ対応とキーボードナビゲーション実装
 */

import React, { useEffect, useCallback, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { ScoreDisplay } from './ScoreDisplay';
import type { GameState, Difficulty } from '@/types/game';
import { DIFFICULTY_CONFIGS } from '@/types/game';
import { cn, formatTime } from '@/lib/utils';

export interface GameOverModalProps {
  /** ゲーム状態 */
  gameState: GameState;
  /** 難易度 */
  difficulty: Difficulty;
  /** 同じ難易度でもう一度プレイする関数 */
  onPlayAgain: () => void;
  /** 難易度を変更して戻る関数 */
  onChangeDifficulty: () => void;
  /** 統計表示を開く関数 */
  onShowStats?: () => void;
  /** カスタムクラス */
  className?: string;
  /** モーダル閉じる関数（オプション） */
  onClose?: () => void;
}

export const GameOverModal: React.FC<GameOverModalProps> = ({
  gameState,
  difficulty,
  onPlayAgain,
  onChangeDifficulty,
  onShowStats,
  className,
  onClose,
}) => {
  // モーダル表示状態
  const [isVisible, setIsVisible] = useState(false);
  const [animationPhase, setAnimationPhase] = useState<'enter' | 'show' | 'exit'>('enter');

  // 勝利・敗北判定
  const isWin = gameState.status === 'won';
  const isLose = gameState.status === 'lost';

  // 表示アニメーション
  useEffect(() => {
    if (isWin || isLose) {
      // 少し遅延させてからモーダルを表示
      const timer1 = setTimeout(() => {
        setIsVisible(true);
        setAnimationPhase('show');
      }, 500);

      return () => clearTimeout(timer1);
    }
  }, [isWin, isLose]);

  // キーボードイベント処理
  const handleKeyDown = useCallback((e: KeyboardEvent) => {
    switch (e.key) {
      case 'Enter':
      case ' ':
        e.preventDefault();
        onPlayAgain();
        break;
      case 'Escape':
        e.preventDefault();
        if (onClose) {
          onClose();
        } else {
          onChangeDifficulty();
        }
        break;
      case 'Tab':
        // タブフォーカスをモーダル内に制限
        const focusableElements = document.querySelectorAll(
          '.game-over-modal button, .game-over-modal [tabindex="0"]'
        );
        if (focusableElements.length > 0) {
          const firstElement = focusableElements[0] as HTMLElement;
          const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement;
          
          if (e.shiftKey && e.target === firstElement) {
            e.preventDefault();
            lastElement.focus();
          } else if (!e.shiftKey && e.target === lastElement) {
            e.preventDefault();
            firstElement.focus();
          }
        }
        break;
    }
  }, [onPlayAgain, onChangeDifficulty, onClose]);

  // キーボードイベント登録
  useEffect(() => {
    if (isVisible) {
      document.addEventListener('keydown', handleKeyDown);
      // フォーカスをモーダル内に移動
      const playAgainButton = document.querySelector('.play-again-button') as HTMLElement;
      if (playAgainButton) {
        playAgainButton.focus();
      }
    }

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [isVisible, handleKeyDown]);

  // モーダルクローズ処理
  const handleClose = useCallback(() => {
    setAnimationPhase('exit');
    setTimeout(() => {
      setIsVisible(false);
      if (onClose) {
        onClose();
      } else {
        onChangeDifficulty();
      }
    }, 300);
  }, [onClose, onChangeDifficulty]);

  // ゲーム統計の計算
  const gameStats = {
    playTime: gameState.startedAt ? 
      Math.floor((Date.now() - gameState.startedAt) / 1000) : 0,
    attempts: gameState.guesses.length,
    hintsUsed: gameState.hintsUsed,
    target: gameState.target,
    difficulty,
  };

  // モーダルが表示されない場合
  if (!isVisible) {
    return null;
  }

  return (
    <>
      {/* バックドロップ */}
      <div
        className={cn(
          'fixed inset-0 z-50 bg-black/60 backdrop-blur-sm',
          'flex items-center justify-center p-4',
          animationPhase === 'enter' && 'animate-fade-in',
          animationPhase === 'exit' && 'animate-fade-out'
        )}
        onClick={handleClose}
        role="dialog"
        aria-modal="true"
        aria-labelledby="game-over-title"
      >
        {/* モーダルコンテンツ */}
        <div
          className={cn(
            'game-over-modal w-full max-w-lg mx-auto',
            animationPhase === 'enter' && 'animate-scale-in',
            animationPhase === 'exit' && 'animate-scale-out',
            className
          )}
          onClick={(e) => e.stopPropagation()}
        >
          <Card 
            variant={isWin ? "success" : "error"}
            className="shadow-2xl border-2"
          >
            <CardHeader className="text-center">
              <CardTitle 
                id="game-over-title"
                level={1} 
                className={cn(
                  'text-3xl font-bold',
                  isWin ? 'text-success-700' : 'text-error-700'
                )}
              >
                {isWin ? (
                  <>🎉 おめでとうございます！</>
                ) : (
                  <>😢 ゲームオーバー</>
                )}
              </CardTitle>
              
              <div className={cn(
                'text-lg mt-2',
                isWin ? 'text-success-600' : 'text-error-600'
              )}>
                {isWin ? (
                  <>正解は <strong className="text-2xl font-mono">{gameStats.target}</strong> でした！</>
                ) : (
                  <>正解は <strong className="text-2xl font-mono">{gameStats.target}</strong> でした</>
                )}
              </div>
            </CardHeader>

            <CardContent className="space-y-6">
              {/* 勝利時のスコア表示 */}
              {isWin && (
                <ScoreDisplay
                  gameState={gameState}
                  difficulty={difficulty}
                  showDetails={false}
                  compact={true}
                />
              )}

              {/* ゲーム統計 */}
              <div className="grid grid-cols-3 gap-4 text-center text-sm">
                <div className="p-3 bg-white rounded-lg border">
                  <div className="font-mono text-xl font-bold text-neutral-900">
                    {gameStats.attempts}
                  </div>
                  <div className="text-neutral-600 text-xs">推測回数</div>
                </div>
                <div className="p-3 bg-white rounded-lg border">
                  <div className="font-mono text-xl font-bold text-neutral-900">
                    {formatTime(gameStats.playTime)}
                  </div>
                  <div className="text-neutral-600 text-xs">プレイ時間</div>
                </div>
                <div className="p-3 bg-white rounded-lg border">
                  <div className="font-mono text-xl font-bold text-neutral-900">
                    {gameStats.hintsUsed}
                  </div>
                  <div className="text-neutral-600 text-xs">ヒント使用</div>
                </div>
              </div>

              {/* 推測履歴表示（最後の5回） */}
              {gameState.guesses.length > 0 && (
                <div className="space-y-2">
                  <h4 className="font-semibold text-neutral-800 text-center">
                    推測履歴
                    {gameState.guesses.length > 5 && (
                      <span className="text-sm font-normal text-neutral-600">
                        （最後の5回）
                      </span>
                    )}
                  </h4>
                  <div className="flex justify-center gap-2">
                    {gameState.guesses.slice(-5).map((guess, index) => (
                      <div
                        key={`final-guess-${index}-${guess}`}
                        className={cn(
                          'w-12 h-12 flex items-center justify-center rounded-lg text-sm font-bold border-2',
                          guess === gameStats.target
                            ? 'bg-success-100 border-success-300 text-success-800'
                            : guess < gameStats.target
                              ? 'bg-warning-100 border-warning-300 text-warning-800'
                              : 'bg-error-100 border-error-300 text-error-800'
                        )}
                        title={
                          guess === gameStats.target
                            ? '正解！'
                            : guess < gameStats.target
                              ? 'もっと大きい'
                              : 'もっと小さい'
                        }
                      >
                        {guess}
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* 励ましメッセージ */}
              <div className="text-center p-4 bg-neutral-50 rounded-lg">
                <p className={cn(
                  'text-sm',
                  isWin ? 'text-success-700' : 'text-neutral-700'
                )}>
                  {isWin ? (
                    gameStats.attempts <= 3 
                      ? '🌟 素晴らしい推測力です！パーフェクトクリア！'
                      : gameStats.attempts <= 5
                        ? '👏 とても良い結果です！'
                        : '🎯 クリアおめでとうございます！'
                  ) : (
                    gameStats.attempts >= DIFFICULTY_CONFIGS[difficulty].attempts - 2
                      ? '💪 最後まで粘り強く頑張りました！'
                      : '🎲 また挑戦してみてください！'
                  )}
                </p>
              </div>

              {/* アクションボタン */}
              <div className="flex gap-3">
                <Button
                  variant="primary"
                  size="lg"
                  onClick={onPlayAgain}
                  className="play-again-button flex-1"
                  aria-label="同じ難易度でもう一度プレイ"
                >
                  🔄 もう一度
                </Button>
                
                <Button
                  variant="secondary"
                  size="lg"
                  onClick={onChangeDifficulty}
                  className="flex-1"
                  aria-label="難易度選択画面に戻る"
                >
                  🎯 難易度変更
                </Button>
              </div>

              {/* 統計表示ボタン（オプション） */}
              {onShowStats && (
                <div className="text-center">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={onShowStats}
                    aria-label="詳細統計を表示"
                  >
                    📊 詳細統計を見る
                  </Button>
                </div>
              )}

              {/* キーボードショートカット説明 */}
              <div className="text-center text-xs text-neutral-500 space-x-4">
                <span>
                  <kbd className="px-2 py-1 bg-neutral-200 rounded text-xs">Enter</kbd>
                  もう一度
                </span>
                <span>
                  <kbd className="px-2 py-1 bg-neutral-200 rounded text-xs">Esc</kbd>
                  難易度変更
                </span>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </>
  );
};

export default GameOverModal;