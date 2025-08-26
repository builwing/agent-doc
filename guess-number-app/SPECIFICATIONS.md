# GuessNumber 技術仕様書

## 📋 概要

本仕様書は、GuessNumber プロジェクトの技術的実装詳細を定義します。Next.js 15、TypeScript、PWA技術を用いたモダンなWeb アプリケーションの構築指針を提供します。

## 🏗️ アーキテクチャ設計

### システム全体設計

```
┌─────────────────────────────────────────────────────────┐
│                    GuessNumber PWA                      │
├─────────────────────────────────────────────────────────┤
│  Presentation Layer (Next.js 15 App Router)            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │
│  │   Pages     │ │ Components  │ │    Hooks    │       │
│  │  (Routes)   │ │   (UI)      │ │  (Logic)    │       │
│  └─────────────┘ └─────────────┘ └─────────────┘       │
├─────────────────────────────────────────────────────────┤
│  Business Logic Layer                                   │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │
│  │ Game Engine │ │ Score Calc  │ │ State Mgmt  │       │
│  │  (Core)     │ │  (Service)  │ │ (Context)   │       │
│  └─────────────┘ └─────────────┘ └─────────────┘       │
├─────────────────────────────────────────────────────────┤
│  Data Layer                                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │
│  │ Local Store │ │ Cache Layer │ │ Service     │       │
│  │(localStorage│ │  (Memory)   │ │  Worker     │       │
│  └─────────────┘ └─────────────┘ └─────────────┘       │
└─────────────────────────────────────────────────────────┘
```

### レイヤー別責務

#### 1. Presentation Layer
- **Pages**: ルーティングとページレイアウト
- **Components**: 再利用可能なUIコンポーネント
- **Hooks**: ビジネスロジックとUIの橋渡し

#### 2. Business Logic Layer
- **Game Engine**: 数当てゲームのコアロジック
- **Score Calculator**: スコア計算とランキング
- **State Management**: アプリケーション状態の管理

#### 3. Data Layer
- **Local Storage**: 永続化データ保存
- **Cache Layer**: 一時的なデータキャッシュ
- **Service Worker**: PWA機能とオフライン対応

## 📁 プロジェクト構造

```
guess-number-app/
├── src/
│   ├── app/                      # Next.js App Router
│   │   ├── globals.css          # グローバルスタイル
│   │   ├── layout.tsx           # ルートレイアウト
│   │   ├── page.tsx             # メインページ
│   │   ├── game/
│   │   │   ├── page.tsx         # ゲーム画面
│   │   │   └── layout.tsx       # ゲームレイアウト
│   │   ├── stats/
│   │   │   └── page.tsx         # 統計画面
│   │   └── settings/
│   │       └── page.tsx         # 設定画面
│   ├── components/              # 再利用可能コンポーネント
│   │   ├── ui/                  # 基本UIコンポーネント
│   │   │   ├── button.tsx
│   │   │   ├── input.tsx
│   │   │   ├── modal.tsx
│   │   │   └── progress.tsx
│   │   ├── game/                # ゲーム関連コンポーネント
│   │   │   ├── game-board.tsx
│   │   │   ├── difficulty-selector.tsx
│   │   │   ├── timer.tsx
│   │   │   ├── score-display.tsx
│   │   │   └── hint-display.tsx
│   │   ├── layout/              # レイアウトコンポーネント
│   │   │   ├── header.tsx
│   │   │   ├── footer.tsx
│   │   │   └── navigation.tsx
│   │   └── common/              # 共通コンポーネント
│   │       ├── error-boundary.tsx
│   │       ├── loading.tsx
│   │       └── accessibility.tsx
│   ├── hooks/                   # カスタムフック
│   │   ├── use-game.ts          # ゲームロジックフック
│   │   ├── use-score.ts         # スコア管理フック
│   │   ├── use-timer.ts         # タイマーフック
│   │   ├── use-local-storage.ts # ローカルストレージフック
│   │   ├── use-accessibility.ts # アクセシビリティフック
│   │   └── use-pwa.ts           # PWA機能フック
│   ├── lib/                     # ユーティリティ・ライブラリ
│   │   ├── game-engine/         # ゲームエンジン
│   │   │   ├── core.ts          # コアゲームロジック
│   │   │   ├── difficulty.ts    # 難易度管理
│   │   │   ├── score.ts         # スコア計算
│   │   │   └── hints.ts         # ヒントシステム
│   │   ├── storage/             # データストレージ
│   │   │   ├── local-storage.ts
│   │   │   ├── session-storage.ts
│   │   │   └── cache-manager.ts
│   │   ├── utils/               # ユーティリティ関数
│   │   │   ├── math.ts          # 数学関数
│   │   │   ├── validation.ts    # バリデーション
│   │   │   ├── format.ts        # フォーマット関数
│   │   │   └── accessibility.ts # アクセシビリティ
│   │   ├── constants/           # 定数定義
│   │   │   ├── game.ts          # ゲーム定数
│   │   │   ├── ui.ts            # UI定数
│   │   │   └── config.ts        # 設定定数
│   │   └── services/            # 外部サービス連携
│   │       ├── analytics.ts
│   │       └── notifications.ts
│   ├── types/                   # TypeScript型定義
│   │   ├── game.ts              # ゲーム関連型
│   │   ├── ui.ts                # UI関連型
│   │   ├── api.ts               # API関連型
│   │   └── global.d.ts          # グローバル型定義
│   ├── styles/                  # スタイル関連
│   │   ├── globals.css          # グローバルCSS
│   │   ├── components/          # コンポーネント別CSS
│   │   └── themes/              # テーマ定義
│   │       ├── light.css
│   │       └── dark.css
│   └── __tests__/               # テストファイル
│       ├── components/
│       ├── hooks/
│       ├── lib/
│       └── pages/
├── public/                      # 静的ファイル
│   ├── icons/                   # アプリアイコン
│   │   ├── icon-192x192.png
│   │   ├── icon-512x512.png
│   │   └── favicon.ico
│   ├── manifest.json            # PWAマニフェスト
│   └── sw.js                    # Service Worker
├── docs/                        # ドキュメント
│   ├── agents/                  # エージェント別要件
│   │   ├── logic/
│   │   ├── next/
│   │   ├── uiux/
│   │   ├── qa/
│   │   ├── security/
│   │   └── docs/
│   ├── api/                     # API仕様書
│   └── architecture/            # アーキテクチャ設計書
├── .vscode/                     # VS Code設定
├── .husky/                      # Git hooks
├── next.config.mjs              # Next.js設定
├── tailwind.config.ts           # Tailwind設定
├── tsconfig.json                # TypeScript設定
├── jest.config.js               # Jest設定
└── package.json                 # 依存関係定義
```

## 🎯 コア機能実装仕様

### 1. ゲームエンジン仕様

#### GameEngine クラス
```typescript
class GameEngine {
  private targetNumber: number;
  private difficulty: Difficulty;
  private attempts: number[];
  private hints: Hint[];
  private startTime: number;
  private timeLimit?: number;

  constructor(difficulty: Difficulty) {
    this.difficulty = difficulty;
    this.targetNumber = this.generateTargetNumber();
    this.attempts = [];
    this.hints = [];
    this.startTime = Date.now();
    this.timeLimit = difficulty.timeLimit;
  }

  public makeGuess(guess: number): GuessResult;
  public getHint(): Hint | null;
  public calculateScore(): Score;
  public isGameComplete(): boolean;
  private generateTargetNumber(): number;
  private validateGuess(guess: number): boolean;
}
```

#### 難易度定義
```typescript
interface Difficulty {
  id: 'easy' | 'medium' | 'hard';
  name: string;
  range: { min: number; max: number };
  maxAttempts: number;
  timeLimit?: number; // milliseconds
  maxHints: number;
  scoreMultiplier: number;
}

const DIFFICULTIES: Record<string, Difficulty> = {
  easy: {
    id: 'easy',
    name: 'かんたん',
    range: { min: 1, max: 30 },
    maxAttempts: 10,
    timeLimit: undefined,
    maxHints: 2,
    scoreMultiplier: 1.0
  },
  medium: {
    id: 'medium',
    name: 'ふつう',
    range: { min: 1, max: 50 },
    maxAttempts: 8,
    timeLimit: 60000,
    maxHints: 1,
    scoreMultiplier: 1.5
  },
  hard: {
    id: 'hard',
    name: 'むずかしい',
    range: { min: 1, max: 100 },
    maxAttempts: 7,
    timeLimit: 45000,
    maxHints: 0,
    scoreMultiplier: 2.0
  }
};
```

### 2. スコアシステム仕様

#### スコア計算実装
```typescript
interface ScoreCalculation {
  baseScore: number;
  timeBonus: number;
  attemptPenalty: number;
  hintPenalty: number;
  difficultyBonus: number;
  finalScore: number;
}

class ScoreCalculator {
  private static readonly BASE_SCORE = 1000;
  private static readonly TIME_BONUS_MULTIPLIER = 10;
  private static readonly ATTEMPT_PENALTY = 50;
  private static readonly HINT_PENALTY = 100;

  public static calculate(gameState: GameState): ScoreCalculation {
    const baseScore = this.BASE_SCORE;
    const timeBonus = this.calculateTimeBonus(gameState);
    const attemptPenalty = gameState.attempts.length * this.ATTEMPT_PENALTY;
    const hintPenalty = gameState.hintsUsed * this.HINT_PENALTY;
    const difficultyBonus = baseScore * (gameState.difficulty.scoreMultiplier - 1.0);
    
    const finalScore = Math.max(0, 
      (baseScore + timeBonus - attemptPenalty - hintPenalty + difficultyBonus) 
      * gameState.difficulty.scoreMultiplier
    );

    return {
      baseScore,
      timeBonus,
      attemptPenalty,
      hintPenalty,
      difficultyBonus,
      finalScore: Math.round(finalScore)
    };
  }

  private static calculateTimeBonus(gameState: GameState): number {
    if (!gameState.difficulty.timeLimit) return 0;
    
    const remainingTime = Math.max(0, 
      gameState.difficulty.timeLimit - gameState.elapsedTime
    );
    return Math.floor(remainingTime / 1000) * this.TIME_BONUS_MULTIPLIER;
  }
}
```

### 3. 状態管理仕様

#### ゲーム状態型定義
```typescript
interface GameState {
  // ゲーム設定
  difficulty: Difficulty;
  targetNumber: number;
  
  // ゲーム進行状態
  status: 'idle' | 'playing' | 'completed' | 'failed';
  attempts: GuessAttempt[];
  hintsUsed: number;
  startTime: number;
  endTime?: number;
  elapsedTime: number;
  
  // スコア関連
  currentScore: number;
  scoreCalculation?: ScoreCalculation;
}

interface GuessAttempt {
  guess: number;
  timestamp: number;
  result: 'too_high' | 'too_low' | 'correct';
  hint?: string;
}
```

#### Context Provider実装
```typescript
const GameContext = createContext<{
  gameState: GameState;
  actions: GameActions;
} | undefined>(undefined);

interface GameActions {
  startGame: (difficulty: Difficulty) => void;
  makeGuess: (guess: number) => Promise<GuessResult>;
  requestHint: () => Promise<Hint | null>;
  resetGame: () => void;
  pauseGame: () => void;
  resumeGame: () => void;
}
```

## 📱 PWA実装仕様

### 1. Service Worker設定

#### キャッシュ戦略
```javascript
// sw.js
const CACHE_NAME = 'guess-number-v1';
const STATIC_ASSETS = [
  '/',
  '/game',
  '/stats',
  '/settings',
  '/_next/static/css/',
  '/_next/static/js/',
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png'
];

// インストール時のキャッシュ
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(STATIC_ASSETS))
  );
});

// ネットワーク優先 + フォールバック戦略
self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // 成功時はキャッシュを更新
        const responseClone = response.clone();
        caches.open(CACHE_NAME)
          .then((cache) => cache.put(event.request, responseClone));
        return response;
      })
      .catch(() => {
        // ネットワークエラー時はキャッシュから取得
        return caches.match(event.request);
      })
  );
});
```

#### マニフェスト設定
```json
{
  "name": "GuessNumber - 数当てゲーム",
  "short_name": "GuessNumber",
  "description": "楽しく論理的思考を鍛える数当てゲーム",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#3b82f6",
  "orientation": "portrait",
  "icons": [
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ],
  "screenshots": [
    {
      "src": "/screenshots/desktop.png",
      "sizes": "1280x720",
      "type": "image/png",
      "form_factor": "wide"
    },
    {
      "src": "/screenshots/mobile.png",
      "sizes": "375x812",
      "type": "image/png",
      "form_factor": "narrow"
    }
  ],
  "categories": ["games", "education"],
  "lang": "ja",
  "dir": "ltr"
}
```

### 2. オフライン機能

#### データ永続化
```typescript
class OfflineGameManager {
  private static readonly STORAGE_KEYS = {
    GAME_STATE: 'guess-number-game-state',
    SCORES: 'guess-number-scores',
    SETTINGS: 'guess-number-settings',
    STATISTICS: 'guess-number-statistics'
  };

  public static saveGameState(gameState: GameState): void {
    try {
      localStorage.setItem(
        this.STORAGE_KEYS.GAME_STATE,
        JSON.stringify(gameState)
      );
    } catch (error) {
      console.error('Failed to save game state:', error);
    }
  }

  public static loadGameState(): GameState | null {
    try {
      const saved = localStorage.getItem(this.STORAGE_KEYS.GAME_STATE);
      return saved ? JSON.parse(saved) : null;
    } catch (error) {
      console.error('Failed to load game state:', error);
      return null;
    }
  }

  public static saveScore(score: Score): void {
    try {
      const scores = this.loadScores();
      scores.push(score);
      
      // 最新100件のみ保持
      const recentScores = scores
        .sort((a, b) => b.timestamp - a.timestamp)
        .slice(0, 100);
      
      localStorage.setItem(
        this.STORAGE_KEYS.SCORES,
        JSON.stringify(recentScores)
      );
    } catch (error) {
      console.error('Failed to save score:', error);
    }
  }
}
```

## 🎨 UI/UXコンポーネント仕様

### 1. デザインシステム

#### カラーパレット
```typescript
const colors = {
  primary: {
    50: '#eff6ff',
    100: '#dbeafe',
    500: '#3b82f6',
    600: '#2563eb',
    900: '#1e3a8a'
  },
  success: {
    50: '#f0fdf4',
    500: '#22c55e',
    600: '#16a34a'
  },
  warning: {
    50: '#fffbeb',
    500: '#f59e0b',
    600: '#d97706'
  },
  error: {
    50: '#fef2f2',
    500: '#ef4444',
    600: '#dc2626'
  },
  gray: {
    50: '#f9fafb',
    100: '#f3f4f6',
    500: '#6b7280',
    900: '#111827'
  }
};
```

#### タイポグラフィ
```typescript
const typography = {
  fontFamily: {
    sans: ['Inter', 'Hiragino Sans', 'Yu Gothic', 'sans-serif'],
    mono: ['JetBrains Mono', 'Consolas', 'monospace']
  },
  fontSize: {
    xs: ['0.75rem', { lineHeight: '1rem' }],
    sm: ['0.875rem', { lineHeight: '1.25rem' }],
    base: ['1rem', { lineHeight: '1.5rem' }],
    lg: ['1.125rem', { lineHeight: '1.75rem' }],
    xl: ['1.25rem', { lineHeight: '1.75rem' }],
    '2xl': ['1.5rem', { lineHeight: '2rem' }],
    '3xl': ['1.875rem', { lineHeight: '2.25rem' }],
    '4xl': ['2.25rem', { lineHeight: '2.5rem' }]
  }
};
```

### 2. コンポーネント実装例

#### ゲームボードコンポーネント
```typescript
interface GameBoardProps {
  gameState: GameState;
  onGuess: (guess: number) => void;
  onHint: () => void;
  onReset: () => void;
}

export const GameBoard: React.FC<GameBoardProps> = ({
  gameState,
  onGuess,
  onHint,
  onReset
}) => {
  const [inputValue, setInputValue] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = useCallback((e: FormEvent) => {
    e.preventDefault();
    
    const guess = parseInt(inputValue, 10);
    if (isNaN(guess)) {
      setError('有効な数値を入力してください');
      return;
    }
    
    if (guess < gameState.difficulty.range.min || 
        guess > gameState.difficulty.range.max) {
      setError(`${gameState.difficulty.range.min}から${gameState.difficulty.range.max}の間で入力してください`);
      return;
    }
    
    setError(null);
    setInputValue('');
    onGuess(guess);
  }, [inputValue, gameState.difficulty, onGuess]);

  return (
    <div className="game-board" role="main" aria-label="数当てゲーム">
      <DifficultyDisplay difficulty={gameState.difficulty} />
      <TimerDisplay 
        elapsedTime={gameState.elapsedTime}
        timeLimit={gameState.difficulty.timeLimit}
      />
      <ScoreDisplay score={gameState.currentScore} />
      
      <form onSubmit={handleSubmit} className="guess-form">
        <label htmlFor="guess-input" className="sr-only">
          数値を推測してください（{gameState.difficulty.range.min}〜{gameState.difficulty.range.max}）
        </label>
        <Input
          id="guess-input"
          type="number"
          min={gameState.difficulty.range.min}
          max={gameState.difficulty.range.max}
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          placeholder={`${gameState.difficulty.range.min}〜${gameState.difficulty.range.max}`}
          autoFocus
          disabled={gameState.status !== 'playing'}
          aria-describedby={error ? 'guess-error' : undefined}
        />
        {error && (
          <div id="guess-error" role="alert" className="error-message">
            {error}
          </div>
        )}
        <Button 
          type="submit" 
          disabled={gameState.status !== 'playing' || !inputValue}
        >
          推測する
        </Button>
      </form>

      <AttemptsHistory attempts={gameState.attempts} />
      
      <div className="game-actions">
        {gameState.difficulty.maxHints > gameState.hintsUsed && (
          <Button 
            variant="secondary" 
            onClick={onHint}
            disabled={gameState.status !== 'playing'}
          >
            ヒント ({gameState.difficulty.maxHints - gameState.hintsUsed}回)
          </Button>
        )}
        <Button 
          variant="outline" 
          onClick={onReset}
        >
          リセット
        </Button>
      </div>
    </div>
  );
};
```

## ♿ アクセシビリティ仕様

### 1. ARIA属性とセマンティクス

#### ゲーム状態の音声読み上げ
```typescript
const useGameAnnouncements = (gameState: GameState) => {
  const [announcements, setAnnouncements] = useState<string[]>([]);

  useEffect(() => {
    if (gameState.attempts.length > 0) {
      const lastAttempt = gameState.attempts[gameState.attempts.length - 1];
      let message = '';
      
      switch (lastAttempt.result) {
        case 'too_high':
          message = `${lastAttempt.guess}は正解より大きいです。`;
          break;
        case 'too_low':
          message = `${lastAttempt.guess}は正解より小さいです。`;
          break;
        case 'correct':
          message = `正解です！${lastAttempt.guess}が答えでした。`;
          break;
      }
      
      if (lastAttempt.hint) {
        message += ` ヒント: ${lastAttempt.hint}`;
      }
      
      setAnnouncements(prev => [...prev, message]);
    }
  }, [gameState.attempts]);

  return announcements;
};
```

#### キーボードナビゲーション
```typescript
const useKeyboardNavigation = () => {
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      // ESCキーでゲームリセット
      if (event.key === 'Escape') {
        event.preventDefault();
        // リセット処理
      }
      
      // Enterキーで推測送信（フォーカスが入力欄にある時）
      if (event.key === 'Enter' && event.target instanceof HTMLInputElement) {
        event.preventDefault();
        // 推測送信処理
      }
      
      // ?キーでヒント要求
      if (event.key === '?' && !event.ctrlKey && !event.metaKey) {
        event.preventDefault();
        // ヒント要求処理
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, []);
};
```

### 2. スクリーンリーダー対応

#### ライブリージョン設定
```typescript
export const GameStatusAnnouncer: React.FC<{ gameState: GameState }> = ({ gameState }) => {
  const announcements = useGameAnnouncements(gameState);
  
  return (
    <>
      {/* 重要な状態変更を即座に読み上げ */}
      <div 
        aria-live="assertive" 
        aria-atomic="true"
        className="sr-only"
      >
        {announcements[announcements.length - 1]}
      </div>
      
      {/* 一般的な状態更新を読み上げ */}
      <div 
        aria-live="polite" 
        aria-atomic="false"
        className="sr-only"
      >
        残り{gameState.difficulty.maxAttempts - gameState.attempts.length}回の推測が可能です。
      </div>
    </>
  );
};
```

## 🧪 テスト仕様

### 1. テスト戦略

#### テストピラミッド
```
                🔺
               /   \
              /     \
             /  E2E   \    <- 10件（主要ユーザーフロー）
            /_________\
           /           \
          / Integration  \   <- 30件（コンポーネント統合）
         /_____________\
        /               \
       /  Unit Tests     \    <- 100件以上（関数・ロジック）
      /___________________\
```

#### 単体テスト例
```typescript
// __tests__/lib/game-engine/core.test.ts
describe('GameEngine', () => {
  describe('makeGuess', () => {
    it('正解の場合、正しい結果を返す', () => {
      const engine = new GameEngine(DIFFICULTIES.easy);
      engine['targetNumber'] = 15; // プライベートプロパティをテスト用に設定
      
      const result = engine.makeGuess(15);
      
      expect(result.isCorrect).toBe(true);
      expect(result.feedback).toBe('correct');
      expect(engine.isGameComplete()).toBe(true);
    });

    it('推測が大きすぎる場合、適切なヒントを返す', () => {
      const engine = new GameEngine(DIFFICULTIES.easy);
      engine['targetNumber'] = 15;
      
      const result = engine.makeGuess(20);
      
      expect(result.isCorrect).toBe(false);
      expect(result.feedback).toBe('too_high');
      expect(result.hint).toContain('小さい');
    });
  });

  describe('calculateScore', () => {
    it('最小試行回数でクリアした場合、高スコアを返す', () => {
      const engine = new GameEngine(DIFFICULTIES.medium);
      engine['targetNumber'] = 25;
      engine['startTime'] = Date.now() - 10000; // 10秒経過
      
      engine.makeGuess(25); // 1回でクリア
      
      const score = engine.calculateScore();
      
      expect(score.finalScore).toBeGreaterThan(1400); // 高スコア期待
      expect(score.timeBonus).toBeGreaterThan(0);
      expect(score.attemptPenalty).toBe(50); // 1回分のペナルティ
    });
  });
});
```

### 2. 統合テスト例

```typescript
// __tests__/components/game/game-board.test.tsx
describe('GameBoard', () => {
  const mockGameState: GameState = {
    difficulty: DIFFICULTIES.easy,
    targetNumber: 15,
    status: 'playing',
    attempts: [],
    hintsUsed: 0,
    startTime: Date.now(),
    elapsedTime: 0,
    currentScore: 0
  };

  it('有効な推測を送信できる', async () => {
    const onGuess = jest.fn();
    
    render(
      <GameBoard 
        gameState={mockGameState}
        onGuess={onGuess}
        onHint={jest.fn()}
        onReset={jest.fn()}
      />
    );

    const input = screen.getByLabelText(/数値を推測してください/);
    const submitButton = screen.getByRole('button', { name: '推測する' });

    await user.type(input, '10');
    await user.click(submitButton);

    expect(onGuess).toHaveBeenCalledWith(10);
  });

  it('範囲外の値でエラーメッセージを表示する', async () => {
    render(
      <GameBoard 
        gameState={mockGameState}
        onGuess={jest.fn()}
        onHint={jest.fn()}
        onReset={jest.fn()}
      />
    );

    const input = screen.getByLabelText(/数値を推測してください/);
    const submitButton = screen.getByRole('button', { name: '推測する' });

    await user.type(input, '50'); // 範囲外（1-30）
    await user.click(submitButton);

    expect(screen.getByRole('alert')).toHaveTextContent('1から30の間で入力してください');
  });
});
```

### 3. E2Eテスト例

```typescript
// e2e/game-flow.spec.ts
import { test, expect } from '@playwright/test';

test('完全なゲームフロー', async ({ page }) => {
  await page.goto('/');

  // 難易度選択
  await page.click('text=ふつう');
  await page.click('text=ゲームを開始');

  // ゲーム画面に遷移
  await expect(page).toHaveURL('/game');
  
  // 推測を行う
  await page.fill('[data-testid=guess-input]', '25');
  await page.click('text=推測する');

  // フィードバックを確認
  await expect(page.locator('[data-testid=feedback]')).toBeVisible();
  
  // スコアが表示されることを確認
  await expect(page.locator('[data-testid=score]')).toContainText('スコア:');
});

test('アクセシビリティ: キーボードナビゲーション', async ({ page }) => {
  await page.goto('/game');

  // Tabキーでナビゲーション
  await page.keyboard.press('Tab'); // 入力欄
  await expect(page.locator('[data-testid=guess-input]')).toBeFocused();

  await page.keyboard.press('Tab'); // 推測ボタン
  await expect(page.locator('text=推測する')).toBeFocused();

  // Escキーでリセット
  await page.keyboard.press('Escape');
  await expect(page.locator('[data-testid=reset-confirm]')).toBeVisible();
});
```

## 🔒 セキュリティ仕様

### 1. Content Security Policy

```javascript
// next.config.mjs
const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-eval'", // Next.js開発時に必要
      "style-src 'self' 'unsafe-inline'", // Tailwindに必要
      "img-src 'self' data: blob:",
      "font-src 'self'",
      "object-src 'none'",
      "base-uri 'self'",
      "form-action 'self'",
      "frame-ancestors 'none'",
      "upgrade-insecure-requests"
    ].join('; ')
  },
  {
    key: 'X-Frame-Options',
    value: 'DENY'
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff'
  },
  {
    key: 'Referrer-Policy',
    value: 'strict-origin-when-cross-origin'
  }
];
```

### 2. 入力値検証

```typescript
class InputValidator {
  public static validateGuess(
    guess: number, 
    difficulty: Difficulty
  ): ValidationResult {
    // 型チェック
    if (typeof guess !== 'number' || isNaN(guess)) {
      return {
        isValid: false,
        error: '有効な数値を入力してください'
      };
    }

    // 範囲チェック
    if (guess < difficulty.range.min || guess > difficulty.range.max) {
      return {
        isValid: false,
        error: `${difficulty.range.min}から${difficulty.range.max}の間で入力してください`
      };
    }

    // 整数チェック
    if (!Number.isInteger(guess)) {
      return {
        isValid: false,
        error: '整数を入力してください'
      };
    }

    return { isValid: true };
  }

  public static sanitizeString(input: string): string {
    return input
      .replace(/[<>\"'&]/g, (match) => {
        const entityMap: Record<string, string> = {
          '<': '&lt;',
          '>': '&gt;',
          '"': '&quot;',
          "'": '&#x27;',
          '&': '&amp;'
        };
        return entityMap[match];
      })
      .slice(0, 1000); // 長さ制限
  }
}
```

## 📊 パフォーマンス仕様

### 1. バンドル最適化

#### 動的インポート
```typescript
// 統計画面は必要時のみロード
const StatsPage = dynamic(() => import('../components/stats/stats-page'), {
  loading: () => <Loading />,
  ssr: false // クライアントサイドのみ
});

// 大きなライブラリは条件付きロード
const useChartLibrary = () => {
  const [chartLib, setChartLib] = useState(null);

  const loadChart = useCallback(async () => {
    if (!chartLib) {
      const { Chart } = await import('chart.js');
      setChartLib(Chart);
    }
  }, [chartLib]);

  return { chartLib, loadChart };
};
```

#### Tree Shaking設定
```javascript
// next.config.mjs
const config = {
  experimental: {
    optimizeCss: true,
    optimizePackageImports: ['lucide-react', 'date-fns']
  },
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production'
  }
};
```

### 2. 画像最適化

```typescript
// アイコン最適化
const GameIcon: React.FC<{ size?: number }> = ({ size = 24 }) => (
  <Image
    src="/icons/game-icon.svg"
    alt="ゲームアイコン"
    width={size}
    height={size}
    priority={size > 32} // 大きなアイコンは優先ロード
  />
);

// レスポンシブ画像
const HeroImage: React.FC = () => (
  <Image
    src="/images/hero.jpg"
    alt="数当てゲーム"
    fill
    sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
    className="object-cover"
  />
);
```

## 📈 監視・分析仕様

### 1. エラー監視

```typescript
class ErrorReporter {
  public static reportError(error: Error, context: ErrorContext): void {
    // 開発環境ではコンソールに出力
    if (process.env.NODE_ENV === 'development') {
      console.error('Application Error:', {
        message: error.message,
        stack: error.stack,
        context
      });
    }

    // 本番環境では外部サービスに送信（将来実装）
    if (process.env.NODE_ENV === 'production') {
      // Sentry, LogRocket等のサービス連携
      // this.sendToExternalService(error, context);
    }

    // ユーザーフレンドリーなエラー表示
    this.showUserError(this.getUserMessage(error));
  }

  private static getUserMessage(error: Error): string {
    // エラーの種類に応じてユーザー向けメッセージを返す
    if (error.name === 'NetworkError') {
      return 'ネットワークエラーが発生しました。インターネット接続を確認してください。';
    }
    
    if (error.name === 'StorageError') {
      return 'データの保存に失敗しました。ブラウザの容量を確認してください。';
    }

    return '予期しないエラーが発生しました。ページを再読み込みしてください。';
  }
}
```

### 2. パフォーマンス測定

```typescript
class PerformanceMonitor {
  public static measureGameStart(): void {
    performance.mark('game-start');
  }

  public static measureGameEnd(): void {
    performance.mark('game-end');
    performance.measure('game-duration', 'game-start', 'game-end');
    
    const measure = performance.getEntriesByName('game-duration')[0];
    this.reportMetric('game-duration', measure.duration);
  }

  public static measurePageLoad(): void {
    window.addEventListener('load', () => {
      const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
      
      const metrics = {
        'load-time': navigation.loadEventEnd - navigation.fetchStart,
        'dom-ready': navigation.domContentLoadedEventEnd - navigation.fetchStart,
        'first-paint': this.getFirstPaint()
      };

      Object.entries(metrics).forEach(([name, value]) => {
        this.reportMetric(name, value);
      });
    });
  }

  private static getFirstPaint(): number {
    const paintEntries = performance.getEntriesByType('paint');
    const firstPaint = paintEntries.find(entry => entry.name === 'first-paint');
    return firstPaint ? firstPaint.startTime : 0;
  }

  private static reportMetric(name: string, value: number): void {
    // 開発環境での監視
    if (process.env.NODE_ENV === 'development') {
      console.log(`Performance Metric - ${name}:`, value);
    }

    // 将来的な分析サービス連携
    // analytics.track('performance', { metric: name, value });
  }
}
```

## 🔄 CI/CD設定仕様

### GitHub Actions ワークフロー

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
      
      - name: Install dependencies
        run: pnpm install

      - name: Type check
        run: pnpm type-check

      - name: Lint
        run: pnpm lint

      - name: Unit tests
        run: pnpm test --coverage

      - name: Build
        run: pnpm build

      - name: E2E tests
        run: pnpm playwright test

      - name: Upload coverage
        uses: codecov/codecov-action@v3

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: vercel/action@v1
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
```

## 🎯 品質基準

### Definition of Done
- [ ] 機能要件を満たしている
- [ ] 単体テスト・統合テストが通過
- [ ] E2Eテストが通過
- [ ] アクセシビリティテストが通過（axe-core）
- [ ] パフォーマンステストが基準をクリア
- [ ] セキュリティスキャンが通過
- [ ] TypeScriptエラーが0件
- [ ] ESLintエラーが0件
- [ ] コードレビューが完了
- [ ] ドキュメントが更新済み

### 品質メトリクス目標値
- **テストカバレッジ**: 80%以上
- **TypeScript strict**: 100%
- **Lighthouse Performance**: 90点以上
- **Lighthouse Accessibility**: 95点以上
- **Lighthouse PWA**: 90点以上
- **Bundle Size**: 500KB以下（gzip）
- **初回ロード時間**: 2秒以内（3G）

---

この技術仕様書は、GuessNumberプロジェクトの技術的実装指針として機能し、開発チーム全体の技術的な統一性を保証します。定期的な見直しと最新技術動向の反映を通じて、高品質なアプリケーションの構築を支援します。