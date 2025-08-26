/**
 * GuessNumberゲーム用の型定義
 * SPECIFICATIONS.mdに基づく型定義
 */

// ゲームの難易度
export type Difficulty = 'easy' | 'normal' | 'hard';

// 推測結果
export interface GuessResult {
  guess: number;
  result: 'correct' | 'too_high' | 'too_low';
  attemptsLeft: number;
  timeLeft?: number;
  gameEnded: boolean;
  won: boolean;
}

// ゲームアクション
export type GameAction = 
  | { type: 'MAKE_GUESS'; payload: { guess: number } }
  | { type: 'USE_HINT'; payload: { hintType: HintType } }
  | { type: 'RESET_GAME' }
  | { type: 'TICK_TIMER' };

// ヒントの種類
export type HintType = 'range' | 'parity' | 'digit';

// スコア結果
export interface ScoreResult {
  baseScore: number;
  timeBonus: number;
  attemptBonus: number;
  hintPenalty: number;
  specialBonuses: {
    perfect?: number;
    speed?: number;
    noHint?: number;
    consecutive?: number;
  };
  totalScore: number;
  multiplier: number;
}

// エラータイプ
export enum GameError {
  INVALID_INPUT = 'INVALID_INPUT',
  OUT_OF_RANGE = 'OUT_OF_RANGE',
  DUPLICATE_GUESS = 'DUPLICATE_GUESS',
  GAME_ALREADY_FINISHED = 'GAME_ALREADY_FINISHED',
  HINT_NOT_AVAILABLE = 'HINT_NOT_AVAILABLE',
  TIME_LIMIT_EXCEEDED = 'TIME_LIMIT_EXCEEDED'
}

// 検証結果
export interface ValidationResult {
  isValid: boolean;
  error?: GameError;
  message?: string;
}

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
  type: HintType;  // 範囲、奇遇、桁数
  message: string;
  used: boolean;
}

// 範囲ヒント
export interface RangeHint extends Hint {
  type: 'range';
  range: [number, number];
  accuracy: 'precise' | 'rough';
}

// パリティヒント
export interface ParityHint extends Hint {
  type: 'parity';
  isEven: boolean;
}

// 桁数ヒント
export interface DigitHint extends Hint {
  type: 'digit';
  digitCount: number;
}

// 難易度別設定マップ（要件仕様書に基づく更新）
export const DIFFICULTY_CONFIGS: Record<Difficulty, GameConfig> = {
  easy: {
    upper: 30,
    attempts: 10,
    timeLimitSec: undefined, // 時間制限なし
    hintsAllowed: 3,
  },
  normal: {
    upper: 50,
    attempts: 8,
    timeLimitSec: 90, // 90秒
    hintsAllowed: 2,
  },
  hard: {
    upper: 100,
    attempts: 7,
    timeLimitSec: 60, // 60秒
    hintsAllowed: 1,
  },
};

// スコア計算定数
export const SCORE_CONFIG = {
  baseCompletionBonus: 1000,
  attemptBonusRate: 100,
  timeBonusRate: 10,
  hintPenalty: 150,
  specialBonuses: {
    perfect: 1000,    // 3回以内クリア
    speed: 500,       // 残り時間50%以上
    noHint: 500,      // ヒント未使用
    consecutive: 200  // 連続クリア
  },
  difficultyMultipliers: {
    easy: 1.0,
    normal: 1.5,
    hard: 2.0,
  }
} as const;

// LocalStorageキー定数
export const STORAGE_KEYS = {
  SETTINGS: 'gn_settings',
  BEST_RECORDS: 'gn_best_records', 
  GAME_HISTORY: 'gn_game_history',
  LAST_SESSION: 'gn_last_session',
} as const;