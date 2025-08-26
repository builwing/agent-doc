/**
 * GuessNumber メインゲーム画面
 * Next.js 15 App Router対応
 */
'use client';

import { useState } from 'react';
import type { Difficulty, GameState } from '@/types/game';
import { DIFFICULTY_CONFIGS } from '@/types/game';

export default function HomePage() {
  // 初期状態: ゲーム選択画面
  const [gameState, setGameState] = useState<GameState | null>(null);
  const [selectedDifficulty, setSelectedDifficulty] = useState<Difficulty>('normal');

  // 新しいゲームを開始する関数
  const startNewGame = (difficulty: Difficulty) => {
    const config = DIFFICULTY_CONFIGS[difficulty];
    const target = Math.floor(Math.random() * config.upper) + 1;
    
    const newGameState: GameState = {
      target,
      upper: config.upper,
      guesses: [],
      attemptsLeft: config.attempts,
      timeLeftSec: config.timeLimitSec,
      status: 'playing',
      startedAt: Date.now(),
      hintsUsed: 0,
      currentRange: [1, config.upper],
    };
    
    setGameState(newGameState);
    console.log(`ゲーム開始: 難易度=${difficulty}, 正解=${target}`); // デバッグ用
  };

  // ゲームリセット
  const resetGame = () => {
    setGameState(null);
  };

  // ゲーム中でない場合は、難易度選択画面を表示
  if (!gameState || gameState.status === 'idle') {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="card">
          <div className="card-body text-center">
            <h2 className="text-2xl font-bold mb-4 text-slate-800">
              ゲームを始めよう！
            </h2>
            <p className="text-slate-600 mb-6">
              数を推測して正解を当てるゲームです。<br />
              難易度を選んでスタートしてください。
            </p>
            
            {/* 難易度選択 */}
            <div className="space-y-4 mb-6">
              {(Object.keys(DIFFICULTY_CONFIGS) as Difficulty[]).map((difficulty) => {
                const config = DIFFICULTY_CONFIGS[difficulty];
                const isSelected = selectedDifficulty === difficulty;
                
                return (
                  <button
                    key={difficulty}
                    onClick={() => setSelectedDifficulty(difficulty)}
                    className={`w-full p-4 rounded-lg border-2 transition-all ${
                      isSelected
                        ? 'border-primary-500 bg-primary-50 text-primary-700'
                        : 'border-slate-200 bg-white hover:border-slate-300'
                    }`}
                  >
                    <div className="text-left">
                      <div className="font-semibold text-lg capitalize">
                        {difficulty === 'easy' && '🟢 かんたん'}
                        {difficulty === 'normal' && '🟡 ふつう'}
                        {difficulty === 'hard' && '🔴 むずかしい'}
                      </div>
                      <div className="text-sm text-slate-600 mt-1">
                        範囲: 1-{config.upper} | 
                        試行回数: {config.attempts}回 | 
                        {config.timeLimitSec ? `制限時間: ${config.timeLimitSec}秒` : '時間制限なし'}
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
            
            {/* スタートボタン */}
            <button
              onClick={() => startNewGame(selectedDifficulty)}
              className="btn-primary text-xl px-8 py-4 w-full"
            >
              🎮 ゲームスタート
            </button>
          </div>
        </div>
        
        {/* ゲームルール説明 */}
        <div className="card">
          <div className="card-body">
            <h3 className="font-semibold mb-3">📋 ゲームのルール</h3>
            <ul className="text-sm text-slate-600 space-y-2">
              <li>• コンピュータが選んだ数字を推測してください</li>
              <li>• 推測すると「もっと大きい」「もっと小さい」のヒントが出ます</li>
              <li>• 制限回数内に正解を当てるとクリアです</li>
              <li>• 難易度が高いほど範囲が広く、制限が厳しくなります</li>
            </ul>
          </div>
        </div>
      </div>
    );
  }

  // ゲーム進行中の画面
  return (
    <div className="space-y-6 animate-fade-in">
      {/* ゲーム状況表示 */}
      <div className="card">
        <div className="card-body">
          <div className="flex justify-between items-center mb-4">
            <div className="text-sm text-slate-600">
              範囲: 1-{gameState.upper}
            </div>
            <div className="text-sm text-slate-600">
              残り: {gameState.attemptsLeft}回
            </div>
          </div>
          
          {gameState.timeLeftSec !== undefined && (
            <div className="mb-4">
              <div className="text-center text-sm text-slate-600">
                残り時間: {gameState.timeLeftSec}秒
              </div>
              <div className="w-full bg-slate-200 rounded-full h-2 mt-2">
                <div 
                  className="bg-primary-600 h-2 rounded-full transition-all duration-1000"
                  style={{
                    width: `${(gameState.timeLeftSec / (DIFFICULTY_CONFIGS[selectedDifficulty].timeLimitSec || 60)) * 100}%`
                  }}
                />
              </div>
            </div>
          )}
          
          <div className="text-center">
            <p className="text-lg text-slate-700 mb-4">
              1から{gameState.upper}の間で数字を推測してください
            </p>
            
            {/* 入力フィールド（実装は次回） */}
            <div className="mb-4">
              <input
                type="number"
                min="1"
                max={gameState.upper}
                className="input text-center text-2xl font-mono"
                placeholder="数字を入力"
                disabled
              />
            </div>
            
            <button className="btn-primary" disabled>
              推測する
            </button>
            
            <p className="text-sm text-slate-500 mt-4">
              ※ ゲームロジックは次回実装予定
            </p>
          </div>
        </div>
      </div>
      
      {/* 推測履歴（実装は次回） */}
      <div className="card">
        <div className="card-body">
          <h3 className="font-semibold mb-3">📝 推測履歴</h3>
          <p className="text-slate-500 text-center py-4">
            まだ推測していません
          </p>
        </div>
      </div>
      
      {/* リセットボタン */}
      <button
        onClick={resetGame}
        className="btn-secondary w-full"
      >
        ゲームをやり直す
      </button>
    </div>
  );
}