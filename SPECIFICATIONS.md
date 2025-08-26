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

### 6.1 難易度とルール例

* `easy`: 上限30 / 試行10回 / 時間制限なし / ヒント2回
* `normal`: 上限50 / 試行8回 / 60秒 / ヒント1回
* `hard`: 上限100 / 試行7回 / 45秒 / ヒント0回

### 6.2 コアロジック（擬似コード）

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

## 7. テスト戦略

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

### まとめ

* **おすすめ言語**: **TypeScript**（Next.js 15）
* **理由**: 速いMVP、型安全、PWA対応、将来の拡張が容易
* **今すること**: `pnpm create next-app` → ルール＆UI実装 → LocalStorage記録 → PWA化

