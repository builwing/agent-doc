# 🎯 GuessNumber — 数当てゲーム (TypeScript + Next.js 15)

**GuessNumber** は 1〜N の乱数を推測するシンプルな Web ゲームです。短時間で遊べる軽量 UI、PWA によるオフライン動作、LocalStorage を用いた自己ベスト記録を備え、学習用の題材としても最適です。

* **対応ドキュメント**: 本 README は以下の要件・仕様に準拠しています。

  * [プロジェクト要件定義書（数当てゲーム版）](./PROJECT_REQUIREMENTS_GUESSNUMBER.md) ※本リポジトリでは代替として下記概要を再掲
  * [技術仕様書（本ゲーム / TS + Next.js 版）](./SPECIFICATIONS.md)
  * [初期化ガイド](./PROJECT_INITIALIZATION_GUIDE.md)

> **推奨言語**: TypeScript（Next.js 15）
>
> MVP はフロントエンド単独（API なし / LocalStorage 保存）。ランキング等のオンライン機能は将来拡張として API を追加可能な設計です。

---

## 🧭 1. プロジェクト概要（抜粋）

| 項目      | 内容                                  |
| ------- | ----------------------------------- |
| プロジェクト名 | **GuessNumber**                     |
| バージョン   | 1.0.0                               |
| 種別      | Web ゲーム（PWA 対応）                     |
| 目的      | 学習・デモ・軽量ゲームとして短期間で提供                |
| 主要機能    | 難易度選択 / 判定 / ヒント / タイマー / スコア / PWA |

### ルール概要

* 1 〜 **N**（難易度により変動）の整数をランダム生成
* プレイヤーは数値を入力 → 即時判定（**大きい / 小さい / 正解**）
* 試行回数・時間制限は難易度により異なる
* クリアタイム / 試行回数を**自己ベスト**として端末に保存（LocalStorage）

---

## 🧱 2. アーキテクチャ

* **構成**: フロント単独（Next.js 15 + TypeScript）。将来のランキング API は OpenAPI 3.1 に準拠予定
* **デプロイ**: 静的ホスティング（Vercel / Cloudflare Pages / 自前 Nginx）
* **データ保存**: LocalStorage（設定・ベスト記録・任意の直近セッション）
* **拡張点**: `/scores` API を追加し、スコア共有やランキングを実現可能

### ディレクトリ構成（例）

```
GuessNumber/
├── frontend/
│   ├── app/
│   │   ├── page.tsx           # ゲーム UI エントリ
│   │   └── layout.tsx         # レイアウト
│   ├── components/
│   │   ├── GameBoard.tsx      # 盤面 / 結果表示
│   │   ├── Controls.tsx       # 入力・操作
│   │   └── HUD.tsx            # タイマー / 試行回数 / 難易度
│   ├── lib/
│   │   ├── game.ts            # コアロジック（start/judge/hint 等）
│   │   ├── config.ts          # 難易度・定数
│   │   └── storage.ts         # LocalStorage I/O
│   ├── styles/
│   │   └── globals.css
│   ├── public/
│   │   ├── manifest.json      # PWA マニフェスト
│   │   └── icons/*            # PWA アイコン
│   └── service-worker.ts      # PWA（必要時）
└── shared/                    # 型/共通定義（将来 API 共有用）
```

---

## ⚙️ 3. 技術スタック

* 言語: **TypeScript**
* フレームワーク: **Next.js 15**（App Router）
* UI: Tailwind CSS / 任意で shadcn/ui
* 状態管理: React Hooks（`useState`, `useEffect`）
* テスト: Vitest / React Testing Library（任意）
* PWA: `manifest.json` + Service Worker（静的キャッシュ）

---

## 🚀 4. クイックスタート

### 必要条件

* Node.js 20+
* pnpm 9+（npm でも可）

### セットアップ

```bash
# 1) プロジェクト作成（未作成の場合）
pnpm create next-app@latest guess-number --ts --app --tailwind
cd guess-number

# 2) 依存のインストール
pnpm i

# 3) 開発サーバ起動
pnpm dev
# http://localhost:3000 にアクセス
```

> 既存のテンプレートを使用する場合は、この README の構成に合わせて `app/`・`components/`・`lib/` を配置してください。

---

## 🕹️ 5. ゲーム仕様（デフォルト）

| 難易度    | 上限 N | 試行回数 | 時間制限 | ヒント |
| ------ | ---: | ---: | ---: | --: |
| easy   |   30 |   10 |   なし |  2回 |
| normal |   50 |    8 |  60秒 |  1回 |
| hard   |  100 |    7 |  45秒 |  0回 |

* 入力は 1〜N の整数。範囲外はエラー表示
* **判定**: 入力 < 目標 →「小さい」 / 入力 > 目標 →「大きい」 / 一致 →「正解」
* **クリア**: クリアタイム & 試行回数を保存（難易度別のベスト記録を更新）
* **アクセシビリティ**: キーボード操作（Enter送信）・視認性配色・SR への簡易読み上げ対応

---

## 🧩 6. 実装要点

### コアロジック（擬似コード）

```ts
export type Difficulty = 'easy'|'normal'|'hard';

export interface GameState {
  target: number;       // 正解
  upper: number;        // 上限
  guesses: number[];    // 履歴
  attemptsLeft: number; // 残り試行
  timeLeftSec?: number; // 残り時間（任意）
  status: 'idle'|'playing'|'won'|'lost';
  startedAt?: number;   // ms
}

export function startGame(diff: Difficulty): GameState { /* ... */ }
export function judge(guess: number, s: GameState): GameState { /* ... */ }
export function hint(s: GameState): [number, number] { /* ... */ }
```

### LocalStorage キー（推奨）

* `gn_settings`：設定（難易度/サウンド等）
* `gn_best_records`：難易度別ベスト記録
* `gn_last_session`：直近セッション（任意）

---

## 🧪 7. テスト

* **ユニット**: 乱数範囲、判定、スコア計算、難易度設定
* **UI**: 結果表示、勝敗モーダルのスナップショット
* **E2E（任意）**: Playwright で基本フロー（開始→数回入力→勝利）

例（Vitest）:

```bash
pnpm test
```

---

## 📦 8. スクリプト

```jsonc
// package.json（例）
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

## 📱 9. PWA 対応

* `public/manifest.json` を配置（name, icons, theme\_color など）
* `service-worker.ts` で静的アセットと App Shell をキャッシュ
* インストールプロンプトはブラウザの条件に依存

> 注: PWA は開発サーバでは挙動が限定されます。本番で `next start` またはホスティング上で確認してください。

---

## 🚢 10. デプロイ

### Vercel（推奨・最短）

1. GitHub にプッシュ
2. Vercel で Import → Framework: **Next.js** → 自動デプロイ

### Cloudflare Pages

* `npm run build` / `npm run start` を指定、Node v20 を選択

### Nginx（自前）

* `next build` → `next start` を systemd などで常駐
* 逆プロキシで 3000 → 80/443 を中継

---

## 🔁 11. CI/CD（任意）

GitHub Actions の最小例:

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

## 🔒 12. セキュリティ

* MVP は外部送信なし（XSS/CSRF のリスク低）
* 将来 `/scores` API を導入する場合:

  * Rate Limit / Bot 対策（hCaptcha 等）
  * 入力バリデーション（Zod など）
  * OpenAPI 3.1 でスキーマ統一

---

## 📈 13. モニタリング / 指標（任意）

* 開始率（トップ→「開始」クリック率）
* クリア率 / 平均クリア時間
* 難易度別の離脱率

> プライバシーに配慮するため、サーバレス分析（Umami / Simple Analytics 等）を推奨。

---

## 🗺️ 14. ロードマップ

* [ ] ゲーム本体（MVP）
* [ ] PWA 化（オフライン動作）
* [ ] ベスト記録 UI 改善（難易度別に切替）
* [ ] ヒントのバリエーション（偶奇 / 桁）
* [ ] ランキング API（OpenAPI 3.1 / TypeScript or Go）
* [ ] i18n（日本語/英語）

---

## 🧰 15. トラブルシューティング

* **PWA が更新されない**: キャッシュ消去 → 再読み込み（ハードリロード）
* **音が鳴らない**: モバイルはユーザー操作なし再生不可な場合あり → 初回タップで解消
* **ビルド失敗**: Node バージョンを 20+ に更新 / Lockfile を再生成（`rm -rf node_modules && pnpm i`）

---

## 🤝 16. コントリビュート

Issues / PR 歓迎です。コード規約は ESLint + Prettier に準拠。テストがある変更は極力テストも添付してください。

---

## 📄 17. ライセンス

* 本プロジェクトは **オープンソース** を前提（例: MIT ライセンス）。
* 組織ポリシーに合わせて `LICENSE` を配置してください。

---

### 参考リンク

* [Next.js ドキュメント](https://nextjs.org/docs)
* [TypeScript ハンドブック](https://www.typescriptlang.org/docs/)
* [PWA（Web.dev）](https://web.dev/learn/pwa/)

> ドキュメント整備の都合で、`SPECIFICATIONS.md` と本 README の重複は最小限に抑えています。実装詳細は `SPECIFICATIONS.md` を一次情報として更新してください。
