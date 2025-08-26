/**
 * GuessNumber - DifficultySelector コンポーネント
 * ゲーム難易度選択のためのインタラクティブUI
 * カード型デザインとアクセシビリティ対応
 */

import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import type { Difficulty } from '@/types/game';
import { DIFFICULTY_CONFIGS } from '@/types/game';
import { cn, formatTime } from '@/lib/utils';

export interface DifficultySelectorProps {
  /** 現在選択されている難易度 */
  selectedDifficulty: Difficulty;
  /** 難易度変更時のコールバック */
  onDifficultyChange: (difficulty: Difficulty) => void;
  /** ゲーム開始時のコールバック */
  onStartGame: (difficulty: Difficulty) => void;
  /** カスタムクラス */
  className?: string;
}

// 難易度ごとの表示設定
const DIFFICULTY_DISPLAY = {
  easy: {
    icon: '🟢',
    title: 'かんたん',
    color: 'success',
    description: 'ゲームに慣れたい方におすすめ',
    features: ['範囲が狭い', 'たくさん試行できる', '時間制限なし'],
  },
  normal: {
    icon: '🟡',
    title: 'ふつう',
    color: 'warning',
    description: 'バランスの取れた標準的な難易度',
    features: ['適度な範囲', '程よい試行回数', '軽い時間制限'],
  },
  hard: {
    icon: '🔴',
    title: 'むずかしい',
    color: 'error',
    description: 'チャレンジャー向けの高難易度',
    features: ['広い範囲', '少ない試行回数', '厳しい時間制限'],
  },
} as const;

export const DifficultySelector: React.FC<DifficultySelectorProps> = ({
  selectedDifficulty,
  onDifficultyChange,
  onStartGame,
  className,
}) => {
  const [hoveredDifficulty, setHoveredDifficulty] = useState<Difficulty | null>(null);

  // 難易度カードのクリック処理
  const handleCardClick = (difficulty: Difficulty) => {
    onDifficultyChange(difficulty);
  };

  // キーボードでの難易度選択
  const handleCardKeyDown = (e: React.KeyboardEvent, difficulty: Difficulty) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onDifficultyChange(difficulty);
    }
  };

  return (
    <div className={cn('space-y-8', className)}>
      {/* ヘッダー */}
      <div className="text-center space-y-4">
        <h2 className="text-3xl font-bold text-neutral-900">
          難易度を選択してください
        </h2>
        <p className="text-neutral-600 max-w-2xl mx-auto leading-relaxed">
          あなたのスキルレベルに合った難易度を選んで、数当てゲームを楽しみましょう。
          いつでも変更できますので、お気軽にお選びください。
        </p>
      </div>

      {/* 難易度カード一覧 */}
      <div className="grid md:grid-cols-3 gap-6 max-w-6xl mx-auto">
        {(Object.keys(DIFFICULTY_CONFIGS) as Difficulty[]).map((difficulty) => {
          const config = DIFFICULTY_CONFIGS[difficulty];
          const display = DIFFICULTY_DISPLAY[difficulty];
          const isSelected = selectedDifficulty === difficulty;
          const isHovered = hoveredDifficulty === difficulty;

          return (
            <Card
              key={difficulty}
              interactive
              variant='default'
              className={cn(
                'cursor-pointer transition-all duration-300',
                'hover:scale-105 hover:shadow-xl',
                isSelected && 'ring-4 ring-offset-2 ring-primary-500 bg-primary-50 border-primary-300',
                isHovered && !isSelected && 'scale-102 shadow-lg'
              )}
              onClick={() => handleCardClick(difficulty)}
              onKeyDown={(e) => handleCardKeyDown(e, difficulty)}
              onMouseEnter={() => setHoveredDifficulty(difficulty)}
              onMouseLeave={() => setHoveredDifficulty(null)}
              role="button"
              tabIndex={0}
              aria-pressed={isSelected}
              aria-label={`${display.title}難易度を選択`}
            >
              <CardHeader className="text-center pb-4">
                {/* 難易度アイコンとタイトル */}
                <div className="space-y-2">
                  <div className="text-4xl" role="img" aria-label={display.title}>
                    {display.icon}
                  </div>
                  <CardTitle 
                    level={3} 
                    className={cn(
                      'text-xl font-bold',
                      isSelected ? 'text-gray-900' : 'text-neutral-900'
                    )}
                  >
                    {display.title}
                  </CardTitle>
                </div>

                {/* 選択インジケーター */}
                {isSelected && (
                  <div 
                    className="mt-2 animate-bounce-in"
                    role="img" 
                    aria-label="選択済み"
                  >
                    ✅
                  </div>
                )}
              </CardHeader>

              <CardContent className="space-y-4">
                {/* 説明テキスト */}
                <p className={cn(
                  'text-sm text-center leading-relaxed',
                  isSelected ? 'text-gray-800' : 'text-neutral-600'
                )}>
                  {display.description}
                </p>

                {/* ゲーム設定詳細 */}
                <div className="space-y-3">
                  <div className={cn(
                    'grid grid-cols-1 gap-2 text-xs',
                    isSelected ? 'text-gray-700' : 'text-neutral-500'
                  )}>
                    <div className="flex justify-between">
                      <span>数値範囲:</span>
                      <span className="font-mono font-bold">1-{config.upper}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>試行回数:</span>
                      <span className="font-mono font-bold">{config.attempts}回</span>
                    </div>
                    <div className="flex justify-between">
                      <span>制限時間:</span>
                      <span className="font-mono font-bold">
                        {config.timeLimitSec ? formatTime(config.timeLimitSec) : '無制限'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* 特徴一覧 */}
                <div className="space-y-2">
                  <h4 className={cn(
                    'text-xs font-semibold',
                    isSelected ? 'text-gray-800' : 'text-neutral-700'
                  )}>
                    特徴:
                  </h4>
                  <ul className="space-y-1">
                    {display.features.map((feature, index) => (
                      <li
                        key={index}
                        className={cn(
                          'text-xs flex items-center',
                          isSelected ? 'text-gray-700' : 'text-neutral-600'
                        )}
                      >
                        <span className="mr-2 text-xs">•</span>
                        {feature}
                      </li>
                    ))}
                  </ul>
                </div>

                {/* 選択ボタン（選択状態でのみ表示） */}
                {isSelected && (
                  <div className="pt-2">
                    <Button
                      size="sm"
                      variant="secondary"
                      fullWidth
                      onClick={(e) => {
                        e.stopPropagation();
                        onStartGame(difficulty);
                      }}
                      className="animate-fade-in"
                    >
                      この難易度で開始
                    </Button>
                  </div>
                )}
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* ゲーム開始ボタン */}
      <div className="text-center">
        <Button
          size="xl"
          onClick={() => onStartGame(selectedDifficulty)}
          className="px-12 py-4 text-lg font-bold animate-pulse-slow"
          leftIcon={<span className="text-xl">🎮</span>}
        >
          ゲームスタート
        </Button>
        
        <p className="mt-4 text-xs text-neutral-500">
          選択中: <strong>{DIFFICULTY_DISPLAY[selectedDifficulty].title}</strong> 
          ({DIFFICULTY_CONFIGS[selectedDifficulty].upper}まで, {DIFFICULTY_CONFIGS[selectedDifficulty].attempts}回)
        </p>
      </div>

      {/* ヘルプセクション */}
      <Card variant="filled" className="max-w-4xl mx-auto">
        <CardHeader>
          <CardTitle level={3} className="flex items-center">
            <span className="mr-2">💡</span>
            ゲームのルール
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid md:grid-cols-2 gap-6 text-sm">
            <div>
              <h4 className="font-semibold mb-2">基本ルール</h4>
              <ul className="space-y-1 text-neutral-600">
                <li>• コンピュータが選んだ数字を推測します</li>
                <li>• 推測すると「大きい」「小さい」のヒントが出ます</li>
                <li>• 制限回数内に正解を当てるとクリアです</li>
                <li>• より少ない回数でクリアするとスコアが上がります</li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-2">攻略のコツ</h4>
              <ul className="space-y-1 text-neutral-600">
                <li>• 二分探索で効率よく絞り込みましょう</li>
                <li>• ヒント機能を活用して範囲を狭めます</li>
                <li>• 時間制限がある場合は素早い判断が重要です</li>
                <li>• 過去の推測を覚えて重複を避けましょう</li>
              </ul>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};