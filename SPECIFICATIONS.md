了解です。
まず結論：**TypeScript**（フロントエンドは **Next.js 15**）を推奨します。理由は👇

* 型安全でバグを早期発見しやすい（学習/教材用途に最適）
* UI とロジックが 1 リポジトリで完結（**バックエンド不要のMVP**に最適）
* そのまま **PWA** 化でき、オフライン動作・モバイル導線も簡単
* 後で**ランキング用の軽いAPI**が必要になっても、同じTSで拡張しやすい

> 参考：最短で完成＝**フロントのみ（TS + Next.js 15）/ LocalStorage**。
> ランキングなどオンライン連携が必要になったら **Go または Cloud Functions(Edge Runtime) + SQLite/Firestore** を後付け。

---

# 技術仕様書（数当てゲーム / TypeScript + Next.js 版）

## 1. システムアーキテクチャ

### 1.1 アーキテクチャ概要

* **アーキテクチャパターン**: **フロントエンド単独（SPA/PWA）** + 将来拡張で「軽API」
* **API設計**: MVP は **API不要**。将来のランキングAPIは OpenAPI 3.1 に準拠予定
* **通信プロトコル**: （将来）REST(JSON)
* **認証方式**: MVP は不要（将来）匿名トークン or OAuth（任意）
* **デプロイメント**: 静的ホスティング（Vercel/Cloudflare Pages/自前Nginx）

### 1.2 システム構成

```
GuessNumber/
├── frontend/                 # Next.js 15（TypeScript）
│   ├── app/                  # App Router
│   ├── components/           # UIコンポーネント
│   ├── lib/                  # ゲームロジック/ユーティリティ
│   ├── styles/               # TailwindCSS
│   ├── public/               # PWAアイコン/manifest
│   └── service-worker.ts     # PWA（必要なら）
├── shared/                   # 型/定数（将来のAPI共有も想定）
└── (optional) backend/       # 将来のランキングAPI（TS/Go どちらでも可）
```

---

## 2. 技術スタック

### 2.1 フロントエンド

* **言語**: **TypeScript**
* **フレームワーク**: Next.js 15（App Router, Server Actionsは未使用でも可）
* **UI**: Tailwind CSS / shadcn/ui（任意）
* **状態管理**: React Hooks で十分（`useState`, `useEffect`）。履歴等はコンポーネント内状態＋`localStorage`
* **フォーム**: シンプルな input（`react-hook-form` は任意）
* **PWA**: `manifest.json` + Service Worker（静的キャッシュ）

### 2.2 将来のバックエンド（任意）

* **言語**: TypeScript（Edge Functions）または Go（高速/単一バイナリ）
* **DB**: SQLite/PlanetScale/Firestore のいずれか（ランキング用）
* **API**: OpenAPI 3.1 で `/scores` の CRUD を定義

---

## 3. OpenAPI仕様による統合（将来拡張）

MVPはAPIなし。**ランキング導入時のみ**適用。

```yaml
openapi: 3.1.0
info:
  title: GuessNumber API
  version: 1.0.0
paths:
  /scores:
    get:
      operationId: listScores
      summary: Top scores
      parameters:
        - in: query
          name: limit
          schema: { type: integer, default: 20, minimum: 1, maximum: 100 }
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Score'
    post:
      operationId: submitScore
      summary: Submit a new score
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/ScoreInput' }
      responses: { '201': { description: Created } }

components:
  schemas:
    Score:
      type: object
      required: [name, difficulty, timeMs, attempts, createdAt]
      properties:
        name: { type: string, maxLength: 20 }
        difficulty: { type: string, enum: [easy, normal, hard] }
        timeMs: { type: integer, minimum: 0 }
        attempts: { type: integer, minimum: 1 }
        createdAt: { type: string, format: date-time }
    ScoreInput:
      type: object
      required: [name, difficulty, timeMs, attempts]
      properties:
        name: { type: string, maxLength: 20 }
        difficulty: { type: string, enum: [easy, normal, hard] }
        timeMs: { type: integer, minimum: 0 }
        attempts: { type: integer, minimum: 1 }
```

---

## 4. データモデル

### 4.1 フロントエンド内モデル（TS）

```ts
export type Difficulty = 'easy'|'normal'|'hard';

export interface GameState {
  target: number;          // 正解の乱数
  upper: number;           // 上限値（難易度で可変）
  guesses: number[];       // 入力履歴
  attemptsLeft: number;    // 残り試行回数
  timeLeftSec?: number;    // 残り時間（難易度で有効/無効）
  status: 'idle'|'playing'|'won'|'lost';
  startedAt?: number;      // ms
}

export interface Settings {
  difficulty: Difficulty;
  sound: boolean;
  colorBlindMode: boolean;
}

export interface BestRecord {
  difficulty: Difficulty;
  timeMs: number;
  attempts: number;
  updatedAt: string;       // ISO
}
```

### 4.2 LocalStorage キー

* `gn_settings`：`Settings`
* `gn_best_records`：`Record<Difficulty, BestRecord>`
* `gn_last_session`：直近の `GameState`（任意）

---

## 5. 開発環境セットアップ

### 5.1 前提

* Node.js 20+
* pnpm 9+（npm でも可）
* （任意）Docker（将来のAPI用）

### 5.2 初期化

```bash
pnpm create next-app@latest guess-number --ts --app --eslint --tailwind
cd guess-number
pnpm i
```

### 5.3 スクリプト

```jsonc
// package.json（一部）
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "test": "vitest run"
  }
}
```

---

## 6. 実装ポイント

### 6.1 難易度とルール詳細仕様

#### イージーモード（Easy）
* **数値範囲**: 1〜30
* **最大試行回数**: 10回
* **制限時間**: なし（無制限）
* **ヒント回数**: 3回まで
* **ヒント種類**: 範囲縮小（「正解は15〜25の間です」）
* **スコア倍率**: 1.0倍
* **推奨対象**: 初回プレイヤー、子供、練習用

#### ノーマルモード（Normal）
* **数値範囲**: 1〜50
* **最大試行回数**: 8回
* **制限時間**: 90秒
* **ヒント回数**: 2回まで
* **ヒント種類**: 範囲縮小 + 奇数/偶数ヒント
* **スコア倍率**: 1.5倍
* **推奨対象**: 慣れたプレイヤー、標準的な挑戦

#### ハードモード（Hard）
* **数値範囲**: 1〜100
* **最大試行回数**: 7回
* **制限時間**: 60秒
* **ヒント回数**: 1回のみ
* **ヒント種類**: 範囲縮小のみ（より粗い範囲）
* **スコア倍率**: 2.0倍
* **推奨対象**: 上級プレイヤー、最高難易度への挑戦

#### エクストリームモード（Extreme）※将来実装
* **数値範囲**: 1〜500
* **最大試行回数**: 10回
* **制限時間**: 120秒
* **ヒント回数**: なし
* **スコア倍率**: 3.0倍
* **特別ルール**: 連続正解ボーナス有効

### 6.2 スコア計算システム詳細仕様

#### 基本スコア計算式
```typescript
// 基本スコア = (残り試行回数 × 100) + (残り時間秒数 × 10) + 完了ボーナス
const baseScore = {
  attemptBonus: remainingAttempts * 100,
  timeBonus: Math.max(0, remainingTimeSeconds * 10),
  completionBonus: 1000,
  difficultyMultiplier: getDifficultyMultiplier(difficulty)
};

const finalScore = Math.floor(
  (baseScore.attemptBonus + baseScore.timeBonus + baseScore.completionBonus) 
  * baseScore.difficultyMultiplier
);
```

#### ボーナスポイント詳細
* **早解きボーナス**: 残り時間の50%以上で完了時、追加500ポイント
* **少数回答ボーナス**: 残り試行回数の70%以上で完了時、追加300ポイント
* **パーフェクトボーナス**: 3回以内で正解時、追加1000ポイント
* **連続プレイボーナス**: 同セッション内で連続クリア時、2回目以降+200ポイント/回
* **ヒント未使用ボーナス**: ヒントを使わずクリア時、+500ポイント

#### ペナルティシステム
* **時間切れペナルティ**: 最終スコアの20%減点
* **試行回数超過**: ゲームオーバー（スコア記録なし）
* **無効入力**: 3回連続で無効な数値入力時、-100ポイント

### 6.3 ヒント機能詳細仕様

#### 範囲縮小ヒント
```typescript
interface RangeHint {
  type: 'range';
  message: string;
  newMin: number;
  newMax: number;
  accuracy: 'precise' | 'rough'; // 難易度により精度調整
}

// 例: "正解は25〜35の間です" (precise)
// 例: "正解は20〜40の間です" (rough)
```

#### 奇数/偶数ヒント
```typescript
interface ParityHint {
  type: 'parity';
  message: string;
  isParity: 'odd' | 'even';
}

// 例: "正解は奇数です"
// 例: "正解は偶数です"
```

#### 大小比較ヒント
```typescript
interface ComparisonHint {
  type: 'comparison';
  message: string;
  threshold: number;
  relation: 'greater' | 'less';
}

// 例: "正解は50より大きいです"
// 例: "正解は25より小さいです"
```

### 6.4 コアロジック（詳細実装）

```ts
function startGame(diff: Difficulty) {
  const cfg = getConfig(diff);
  return <GameState>{
    target: rand(1, cfg.upper),
    upper: cfg.upper,
    guesses: [],
    attemptsLeft: cfg.attempts,
    timeLeftSec: cfg.timeLimitSec ?? undefined,
    status: 'playing',
    startedAt: Date.now()
  };
}

function judge(g: number, s: GameState) {
  if (s.status !== 'playing') return s;
  if (g < 1 || g > s.upper) throw new Error('範囲外');
  s.guesses.push(g);
  s.attemptsLeft--;
  if (g === s.target) s.status = 'won';
  else if (s.attemptsLeft <= 0 || (s.timeLeftSec!==undefined && s.timeLeftSec<=0)) s.status = 'lost';
  return s;
}

function hint(s: GameState): [number, number] {
  // 範囲縮小ヒント
  const min = Math.max(1, Math.min(...[...s.guesses, 1]));
  const max = Math.min(s.upper, Math.max(...[...s.guesses, s.upper]));
  // 単純に中央値基準など工夫可
  return [Math.min(s.target, max), Math.max(s.target, min)];
}
```

### 6.3 アクセシビリティ

* キーボード操作（Enterで送信、↑↓で前回値履歴）
* 色覚多様性モード（赤/緑に依存しない強調）
* ライブリージョンで結果を読み上げ（SR対応）

---

## 7. UI/UX仕様詳細

### 7.1 画面遷移フロー仕様

#### メイン画面遷移
```
[スプラッシュ画面] → [メニュー画面] → [難易度選択] → [ゲーム画面] → [結果画面] → [メニューに戻る]
                                    ↓
                                [設定画面] ⇄ [ヘルプ画面]
                                    ↓
                                [履歴画面] → [詳細統計画面]
```

#### 状態遷移詳細
1. **アプリ起動時**
   - スプラッシュ画面（0.5秒）→ メニュー画面へ自動遷移
   - 初回起動時のみチュートリアル画面を表示

2. **ゲーム開始フロー**
   - メニュー → 難易度選択 → カウントダウン（3秒）→ ゲーム開始
   - 中断時は確認ダイアログを表示

3. **ゲーム終了フロー**
   - 結果判定 → アニメーション表示 → 結果画面 → 新記録時は特別演出

### 7.2 アニメーション仕様

#### 画面遷移アニメーション
```typescript
const transitionConfig = {
  // ページ遷移
  pageTransition: {
    type: 'slide',
    duration: 300,
    easing: 'ease-in-out'
  },
  
  // モーダル表示
  modalTransition: {
    type: 'fade-scale',
    duration: 200,
    easing: 'ease-out'
  },
  
  // ゲーム要素
  gameElementTransition: {
    type: 'bounce',
    duration: 150,
    easing: 'ease-out'
  }
};
```

#### フィードバックアニメーション
* **正解時**: 緑色のパルスエフェクト + 拡大縮小（200ms）
* **不正解時**: 赤色の震動エフェクト（300ms）
* **ヒント表示**: フェードイン + 上からスライド（250ms）
* **スコア更新**: カウントアップアニメーション（500ms）
* **新記録達成**: 金色のパーティクルエフェクト（2秒間）

#### ロード状態アニメーション
* **ゲーム準備中**: 回転するインディケータ
* **データ保存中**: プログレスバー風インディケータ
* **結果計算中**: 数字のカウントアップ演出

### 7.3 エラーハンドリング仕様

#### エラーの分類と対応
```typescript
interface ErrorHandling {
  // ユーザー入力エラー
  InputError: {
    invalidNumber: {
      message: "1から{max}までの数字を入力してください",
      action: "入力フィールドを赤枠で強調",
      duration: 3000
    },
    outOfRange: {
      message: "範囲外の数値です（1-{max}）",
      action: "震動エフェクト + トースト表示",
      duration: 2000
    },
    duplicateGuess: {
      message: "その数字はすでに入力済みです",
      action: "履歴をハイライト",
      duration: 2000
    }
  },
  
  // システムエラー
  SystemError: {
    saveError: {
      message: "データの保存に失敗しました",
      action: "リトライボタン表示",
      fallback: "ローカルストレージ確認"
    },
    loadError: {
      message: "データの読み込みに失敗しました",
      action: "デフォルト設定で続行",
      fallback: "設定リセット提案"
    }
  },
  
  // ネットワークエラー（将来のAPI用）
  NetworkError: {
    connectionError: {
      message: "インターネット接続を確認してください",
      action: "オフラインモード提案",
      retry: true
    }
  }
}
```

#### エラー表示UI設計
* **トーストメッセージ**: 画面上部に3秒間表示
* **インラインエラー**: 入力フィールド下に直接表示
* **モーダルエラー**: 重要なエラー時のブロッキングダイアログ
* **スナックバー**: 画面下部での軽微な通知

### 7.4 アクセシビリティ要件

#### キーボード操作サポート
```typescript
const keyboardShortcuts = {
  'Enter': '数字入力確定',
  'Escape': 'モーダル/メニューを閉じる',
  'Space': 'ゲーム開始/一時停止',
  'H': 'ヒント使用',
  'R': 'ゲームリセット',
  'ArrowUp/ArrowDown': '入力履歴のナビゲーション',
  'Tab': 'フォーカス移動',
  'Shift+Tab': '逆方向フォーカス移動'
};
```

#### スクリーンリーダー対応
* すべての入力要素にaria-labelを設定
* ゲーム状況をaria-live regionで通知
* ボタンの状態変化をaria-describedbyで説明
* 進行状況をaria-valuenowで数値化

#### 視覚的アクセシビリティ
* 色覚多様性対応：色だけでなく形状・パターンで区別
* コントラスト比：WCAG 2.1 AAレベル準拠（4.5:1以上）
* 文字サイズ：最小16px、ユーザー設定で最大24pxまで拡大可能
* ハイコントラストモード対応

### 7.5 レスポンシブデザイン仕様

#### ブレークポイント設定
```css
/* Tailwind CSS設定例 */
const breakpoints = {
  'xs': '320px',   /* 小型スマートフォン */
  'sm': '640px',   /* スマートフォン */
  'md': '768px',   /* タブレット */
  'lg': '1024px',  /* ラップトップ */
  'xl': '1280px',  /* デスクトップ */
  '2xl': '1536px'  /* 大型ディスプレイ */
};
```

#### デバイス別UI調整
* **スマートフォン（xs-sm）**: 
  - 単一カラムレイアウト
  - 大きめのタッチターゲット（44px以上）
  - スワイプジェスチャーサポート

* **タブレット（md-lg）**:
  - 2カラムレイアウト（ゲーム画面 + 情報パネル）
  - ランドスケープモード最適化
  - ドラッグ&ドロップインタラクション

* **デスクトップ（xl-2xl）**:
  - 3カラムレイアウト（メニュー + ゲーム + 統計）
  - マウスホバーエフェクト
  - キーボードショートカット表示

---

## 8. PWA仕様詳細

### 8.1 キャッシュ戦略仕様

#### Service Worker実装方針
```typescript
// キャッシュ戦略の定義
const CACHE_STRATEGIES = {
  // アプリケーションシェル: Cache First
  appShell: {
    strategy: 'CacheFirst',
    cacheName: 'app-shell-v1',
    assets: [
      '/',
      '/manifest.json',
      '/icon-*.png',
      '/app.css',
      '/app.js'
    ]
  },
  
  // ゲームデータ: Network First with Cache Fallback
  gameData: {
    strategy: 'NetworkFirst',
    cacheName: 'game-data-v1',
    timeout: 3000,
    fallbackCache: true
  },
  
  // 静的アセット: Stale While Revalidate
  staticAssets: {
    strategy: 'StaleWhileRevalidate',
    cacheName: 'static-assets-v1',
    maxAge: 86400 // 24時間
  }
};
```

#### オフライン対応仕様
```typescript
interface OfflineCapabilities {
  // フル機能（オフライン可能）
  core: {
    gamePlay: true,        // ゲームプレイ
    scoreTracking: true,   // スコア記録
    settings: true,        // 設定変更
    statistics: true       // 統計表示
  },
  
  // 制限機能（オンライン必須）
  online: {
    leaderboard: false,    // リーダーボード
    socialShare: false,    // SNSシェア
    cloudSync: false       // クラウド同期
  },
  
  // オフライン時のフォールバック
  fallback: {
    leaderboard: "ローカル記録のみ表示",
    socialShare: "オンライン時に再試行を提案",
    cloudSync: "ローカル保存のみで継続"
  }
}
```

### 8.2 manifest.json詳細設定
```json
{
  "name": "GuessNumber - 数当てゲーム",
  "short_name": "GuessNumber",
  "description": "楽しい数当てゲームで暇つぶし",
  "start_url": "/",
  "display": "standalone",
  "orientation": "portrait-primary",
  "theme_color": "#3B82F6",
  "background_color": "#FFFFFF",
  "categories": ["games", "education", "entertainment"],
  "lang": "ja",
  "icons": [
    {
      "src": "/icons/icon-72x72.png",
      "sizes": "72x72",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable any"
    }
  ],
  "shortcuts": [
    {
      "name": "新しいゲーム",
      "url": "/game/new",
      "description": "すぐに新しいゲームを開始"
    },
    {
      "name": "統計を見る",
      "url": "/stats",
      "description": "プレイ統計とベストスコア"
    }
  ],
  "screenshots": [
    {
      "src": "/screenshots/gameplay.png",
      "sizes": "540x720",
      "type": "image/png",
      "platform": "narrow",
      "label": "ゲームプレイ画面"
    }
  ]
}
```

---

## 9. テスト戦略

* **ユニット**：乱数範囲、判定、スコア計算、難易度設定
* **UI スナップショット**：結果表示、勝敗モーダル
* **E2E（任意）**：Playwright で基本フロー（開始→数回入力→勝利）

---

## 8. デプロイメント

* **Vercel/Cloudflare Pages** にそのままデプロイ（環境変数不要）
* PWA を有効化する場合は `manifest.json` と SW を追加
* Nginx 配信時は `Cache-Control`（静的アセット）を設定

---

## 9. モニタリング・ロギング

* MVP：ブラウザコンソールログのみ
* 将来：Simple Analytics / Umami 等で「開始率」「クリア率」「平均時間」を計測

---

## 10. セキュリティ

* MVP は外部送信なし（XSS/CSRFのリスク低）
* 将来API導入時：

  * `POST /scores` は rate limit（IP/指紋）
  * 署名付きスコア or Bot判定（hCaptcha）

---

## 11. パフォーマンス最適化

* 依存最小（画像・音声を極力使わない）
* クリティカルCSS（Tailwind + 事前生成）
* PWA キャッシュ（app shell + 静的アセット）

---

## 12. CI/CD（任意）

* GitHub Actions：`lint` → `test` → `build` → `deploy`（Vercel 自動連携でも可）
* 例：

```yaml
name: CI
on: [push, pull_request]
jobs:
  web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
      - run: pnpm i
      - run: pnpm lint && pnpm test && pnpm build
```

---

## 13. データフロー図と状態遷移

### 13.1 システムアーキテクチャ図

```
┌─────────────────────────────────────────────────────────────────┐
│                        GuessNumber PWA                          │
│                     (Next.js 15 + TypeScript)                  │
├─────────────────────────────────────────────────────────────────┤
│  Frontend Layer (Presentation)                                 │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
│  │   UI Components │ │   Layout System │ │  Animation Engine│   │
│  │                 │ │                 │ │                 │   │
│  │ • GameBoard     │ │ • Responsive    │ │ • Framer Motion │   │
│  │ • InputField    │ │ • Mobile First  │ │ • Transitions   │   │
│  │ • ScoreDisplay  │ │ • Accessibility │ │ • Feedback      │   │
│  │ • HintDisplay   │ │ • PWA Shell     │ │ • Micro-interact│   │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│  Application Layer (Business Logic)                            │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
│  │  Game Engine    │ │  State Manager  │ │  Storage Service│   │
│  │                 │ │                 │ │                 │   │
│  │ • Game Logic    │ │ • Zustand Store │ │ • localStorage  │   │
│  │ • Score Calc    │ │ • Game State    │ │ • Data Persist  │   │
│  │ • Hint Generator│ │ • User Settings │ │ • Cache Strategy│   │
│  │ • Input Validator│ │ • History      │ │ • Sync Logic    │   │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│  Infrastructure Layer                                          │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
│  │  PWA Services   │ │  Browser APIs   │ │  Build System   │   │
│  │                 │ │                 │ │                 │   │
│  │ • Service Worker│ │ • Web Storage   │ │ • Next.js       │   │
│  │ • Cache Strategy│ │ • Notifications │ │ • Webpack       │   │
│  │ • Offline Mode  │ │ • Visibility API│ │ • TypeScript    │   │
│  │ • App Install   │ │ • Performance   │ │ • Tailwind CSS  │   │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 13.2 LocalStorage APIインターフェース仕様

```typescript
// LocalStorage データ構造とインターフェース定義
interface StorageInterface {
  // ゲーム状態データ
  gameState: {
    key: 'gn_current_game',
    schema: GameState,
    expiry: '24h',        // 24時間でタイムアウト
    encryption: false,    // MVP版では平文
    compression: true     // JSON圧縮
  },
  
  // ユーザー設定
  userSettings: {
    key: 'gn_settings',
    schema: UserSettings,
    expiry: 'never',      // 永続保存
    encryption: false,
    compression: false,
    migration: true       // バージョン間移行対応
  },
  
  // ベストスコア記録
  bestRecords: {
    key: 'gn_best_records',
    schema: Record<Difficulty, BestRecord>,
    expiry: 'never',
    encryption: false,
    compression: true
  },
  
  // プレイ統計
  playStatistics: {
    key: 'gn_statistics',
    schema: PlayStatistics,
    expiry: '30d',        // 30日間保存
    encryption: false,
    compression: true,
    aggregation: true     // 統計データの集約
  }
}

// StorageService実装インターフェース
interface IStorageService {
  // 基本操作
  get<T>(key: string, schema: any): Promise<T | null>;
  set<T>(key: string, data: T, options?: StorageOptions): Promise<void>;
  remove(key: string): Promise<void>;
  clear(): Promise<void>;
  
  // 高度な操作
  exists(key: string): Promise<boolean>;
  getSize(key?: string): Promise<number>;
  
  // データ検証
  validate<T>(data: any, schema: any): T;
  migrate(key: string, oldVersion: string, newVersion: string): Promise<void>;
  
  // エラーハンドリング
  handleQuotaExceeded(): Promise<void>;
  handleCorruption(key: string): Promise<void>;
}
```

---

## 14. KPI定義と成功指標

### 14.1 定量的KPI

#### ユーザーエンゲージメントKPI
```typescript
const ENGAGEMENT_KPIS = {
  // 基本エンゲージメント
  dailyActiveUsers: {
    target: '100+ DAU',
    measurement: 'unique localStorage identifiers per day',
    tracking: 'client-side analytics'
  },
  
  sessionDuration: {
    target: '平均3分以上',
    measurement: 'time from app start to close',
    benchmark: '短時間ゲームとしては理想的'
  },
  
  gameCompletionRate: {
    target: '85%以上',
    measurement: 'games finished / games started',
    segmentation: '難易度別に分析'
  },
  
  retentionRate: {
    target: 'Day1: 60%, Day7: 30%',
    measurement: 'returning users with localStorage data',
    importance: '習慣化の指標'
  }
};

const PERFORMANCE_KPIS = {
  // テクニカルパフォーマンス
  loadTime: {
    target: 'FCP < 2秒、LCP < 2.5秒',
    measurement: 'Core Web Vitals',
    tools: 'Lighthouse、RUM'
  },
  
  errorRate: {
    target: '<0.1%',
    measurement: 'JavaScript errors / total sessions',
    monitoring: 'browser console + error boundary'
  },
  
  offlineUsability: {
    target: '機能制限なし100%',
    measurement: 'offline game completion rate',
    verification: 'PWA offline testing'
  },
  
  crossBrowserCompatibility: {
    target: '主要ブラウザ95%+',
    measurement: 'feature compatibility matrix',
    browsers: 'Chrome, Firefox, Safari, Edge'
  }
};
```

#### ビジネス価値KPI
```typescript
const BUSINESS_KPIS = {
  // プロダクト成功指標
  userSatisfaction: {
    target: '4.5/5.0以上',
    measurement: 'in-app feedback + usage patterns',
    factors: 'ease of use, entertainment value, performance'
  },
  
  organicGrowth: {
    target: '月次10%成長',
    measurement: 'new user acquisition without paid advertising',
    channels: 'word of mouth, social sharing, SEO'
  },
  
  technicalDebt: {
    target: '<5%',
    measurement: 'code complexity, dependency updates, bug count',
    maintenance: 'sustainable long-term development'
  },
  
  educationalValue: {
    target: '学習リソースとして80%満足度',
    measurement: 'developer feedback, code reuse, teaching adoption',
    audience: 'programming learners, instructors'
  }
};
```

### 14.2 定性的成功基準

#### ユーザー体験品質
```typescript
const UX_QUALITY_CRITERIA = {
  // 直感性・学習容易性
  learnability: {
    criteria: 'チュートリアルなしで60秒以内にゲーム完了',
    validation: '初回ユーザーテスト',
    acceptance: '90%のユーザーが直感的操作可能'
  },
  
  // アクセシビリティ
  accessibility: {
    criteria: 'WCAG 2.1 AA準拠',
    validation: 'axe-core, manual testing',
    acceptance: '障害のあるユーザーも独立してプレイ可能'
  },
  
  // デザイン品質
  designQuality: {
    criteria: '視覚的に魅力的で現代的',
    validation: 'design review, user feedback',
    acceptance: '競合ゲームと比較して劣らない品質'
  }
};

const TECHNICAL_QUALITY_CRITERIA = {
  // コード品質
  codeQuality: {
    criteria: 'TypeScript strict mode, ESLint clean, 85%+ test coverage',
    validation: 'automated CI/CD checks',
    acceptance: '新規開発者が1週間以内に貢献可能'
  },
  
  // アーキテクチャ品質
  architectureQuality: {
    criteria: 'モジュール分離、依存性注入、テスタブル設計',
    validation: 'code review, architecture documentation',
    acceptance: '将来機能追加時の影響範囲最小化'
  },
  
  // セキュリティ
  security: {
    criteria: 'OWASP Top 10対応、データ保護適切',
    validation: 'security audit, penetration testing',
    acceptance: 'ユーザーデータの安全性保証'
  }
};
```

### 14.3 リリース判定基準

#### MVP リリース基準（必須条件）
```markdown
## 機能完成度
- [ ] 全ての基本ゲーム機能が動作（easy/normal/hardの3難易度）
- [ ] スコア計算システムが正確に動作
- [ ] ローカルデータ保存・復元が安定動作
- [ ] PWA として適切にインストール・オフライン動作可能
- [ ] レスポンシブデザインで主要デバイスサイズに対応

## 品質基準
- [ ] 単体テスト85%以上、E2Eテスト主要フロー100%カバー
- [ ] Lighthouse Score 90点以上（全項目）
- [ ] 主要ブラウザ（Chrome, Firefox, Safari, Edge）で動作確認
- [ ] アクセシビリティ基準（axe-core violations = 0）クリア
- [ ] 1週間の連続稼働テストで重大エラーなし

## パフォーマンス基準
- [ ] 初期ロード時間2秒以内（3G slowネットワーク）
- [ ] ゲーム操作レスポンス100ms以内
- [ ] メモリリークなし（24時間連続プレイテスト）
- [ ] PWA キャッシュサイズ1MB未満

## ドキュメント完成度
- [ ] README.md（セットアップ・使用方法・拡張ガイド）
- [ ] APIドキュメント（TypeScript型定義を含む）
- [ ] デプロイメントガイド
- [ ] 学習者向けチュートリアル
```

#### 継続改善KPI（月次評価）
```typescript
const CONTINUOUS_IMPROVEMENT_KPIS = {
  // ユーザー行動分析
  userBehaviorInsights: {
    metrics: [
      '難易度別プレイ時間分析',
      'ヒント使用パターン分析', 
      'ドロップオフポイント特定',
      'リピート利用パターン'
    ],
    actionItems: '分析結果に基づくUX改善'
  },
  
  // 技術負債管理
  technicalHealth: {
    metrics: [
      '依存関係の最新化状況',
      'セキュリティ脆弱性スキャン結果',
      'パフォーマンス劣化の検出',
      'コード複雑度の監視'
    ],
    actionItems: '予防的メンテナンス実行'
  }
};
```

---

### まとめ

* **おすすめ言語**: **TypeScript**（Next.js 15）
* **理由**: 速いMVP、型安全、PWA対応、将来の拡張が容易
* **今すること**: `pnpm create next-app` → ルール＆UI実装 → LocalStorage記録 → PWA化

