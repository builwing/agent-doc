/**
 * GuessNumberゲーム用の型定義
 * SPECIFICATIONS.mdに基づく型定義
 */

// ゲームの難易度
export type Difficulty = 'easy' | 'normal' | 'hard';

// ゲームの状態
export type GameStatus = 'idle' | 'playing' | 'won' | 'lost';

// ゲームの設定
export interface GameConfig {
  upper: number;        // 数値の上限
  attempts: number;     // 試行回数上限
  timeLimitSec?: number; // 制限時間（秒）、undefinedは時間制限なし
  hintsAllowed: number; // 使用可能ヒント数
}

// ゲームの状態
export interface GameState {
  target: number;          // 正解の乱数
  upper: number;           // 上限値（難易度で可変）
  guesses: number[];       // 入力履歴
  attemptsLeft: number;    // 残り試行回数
  timeLeftSec?: number;    // 残り時間（難易度で有効/無効）
  status: GameStatus;      // ゲーム状態
  startedAt?: number;      // 開始時刻（ms）
  hintsUsed: number;       // 使用済みヒント数
  currentRange: [number, number]; // 現在の推測範囲
}

// プレイヤー設定
export interface Settings {
  difficulty: Difficulty;
  sound: boolean;
  colorBlindMode: boolean;
  theme: 'light' | 'dark' | 'auto';
}

// 最高記録
export interface BestRecord {
  difficulty: Difficulty;
  timeMs: number;         // クリア時間（ミリ秒）
  attempts: number;       // 試行回数
  updatedAt: string;      // 記録日時（ISO string）
  score: number;          // スコア（時間と試行回数から算出）
}

// プレイ履歴
export interface GameHistory {
  id: string;
  difficulty: Difficulty;
  target: number;
  guesses: number[];
  timeMs: number;
  won: boolean;
  playedAt: string;       // ISO string
  score?: number;
}

// ヒントの種類
export interface Hint {
  type: 'range' | 'parity' | 'digit';  // 範囲、奇遇、桁数
  message: string;
  used: boolean;
}

// 難易度別設定マップ
export const DIFFICULTY_CONFIGS: Record<Difficulty, GameConfig> = {
  easy: {
    upper: 30,
    attempts: 10,
    timeLimitSec: undefined, // 時間制限なし
    hintsAllowed: 2,
  },
  normal: {
    upper: 50,
    attempts: 8,
    timeLimitSec: 60,
    hintsAllowed: 1,
  },
  hard: {
    upper: 100,
    attempts: 7,
    timeLimitSec: 45,
    hintsAllowed: 0,
  },
};

// LocalStorageキー定数
export const STORAGE_KEYS = {
  SETTINGS: 'gn_settings',
  BEST_RECORDS: 'gn_best_records', 
  GAME_HISTORY: 'gn_game_history',
  LAST_SESSION: 'gn_last_session',
} as const;