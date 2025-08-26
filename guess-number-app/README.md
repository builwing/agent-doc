# GuessNumber - 数当てゲーム

Next.js 15 + TypeScript + PWA対応で構築された数当てゲームです。

## 🎯 概要

GuessNumberは、コンピュータが選んだ数字を推測して当てる楽しいゲームです。難易度選択、ヒント機能、タイマー、スコアリングなど、充実した機能を備えています。

## 🚀 特徴

- **📱 PWA対応**: オフラインでもプレイ可能
- **🎮 3つの難易度**: かんたん・ふつう・むずかしい
- **⏱️ タイマー機能**: 制限時間内でのチャレンジ
- **💡 ヒント機能**: 適度なサポートで楽しく進行
- **📊 スコア記録**: 最高記録とプレイ履歴を保存
- **♿ アクセシビリティ対応**: キーボード操作、スクリーンリーダー対応
- **🎨 レスポンシブデザイン**: モバイル・タブレット・デスクトップ対応

## 🛠️ 技術スタック

- **フレームワーク**: Next.js 15 (App Router)
- **言語**: TypeScript
- **状態管理**: Zustand
- **スタイリング**: Tailwind CSS v4
- **UI コンポーネント**: Headless UI + CVA
- **PWA**: next-pwa
- **テスト**: Vitest + React Testing Library
- **リンター**: ESLint
- **フォーマッター**: Prettier
- **パッケージマネージャー**: pnpm
- **Git Hooks**: Husky + lint-staged

## 📦 セットアップ

### 前提条件

- Node.js 20以上
- pnpm 9以上（推奨）

### インストール

```bash
# リポジトリをクローン
git clone [repository-url]
cd guess-number-app

# 依存関係をインストール
pnpm install

# 開発サーバーを開始（デフォルトポート3000）
pnpm dev

# または、ポート3003で開始する場合
pnpm dev --port 3003
```

## 🎮 開発

### 利用可能なスクリプト

```bash
# 開発サーバー起動
pnpm dev

# プロダクションビルド
pnpm build

# プロダクションサーバー起動
pnpm start

# リンターを実行
pnpm lint

# リンターを実行（自動修正付き）
pnpm lint:fix

# TypeScript型チェック
pnpm type-check

# コードフォーマット
pnpm format

# コードフォーマットチェック
pnpm format:check

# テストを実行
pnpm test

# テストを監視モードで実行
pnpm test:watch

# テストカバレッジを確認
pnpm test:coverage

# テストUIを起動
pnpm test:ui

# 全体検証（型チェック + リンター + フォーマット + テスト）
pnpm validate

# ビルド結果をクリア
pnpm clean
```

### プロジェクト構造

```
guess-number-app/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── layout.tsx         # ルートレイアウト
│   │   ├── page.tsx           # メインページ
│   │   └── globals.css        # グローバルスタイル
│   ├── components/            # Reactコンポーネント
│   │   ├── game/              # ゲーム関連コンポーネント
│   │   └── ui/                # 汎用UIコンポーネント
│   ├── lib/                   # ユーティリティとロジック
│   │   ├── game-engine.ts     # ゲームエンジン
│   │   ├── game-store.ts      # Zustand状態管理
│   │   ├── difficulty.ts      # 難易度システム
│   │   ├── hints.ts           # ヒント機能
│   │   └── scoring.ts         # スコア計算
│   ├── styles/                # デザイントークン
│   ├── test/                  # テスト設定
│   └── types/                 # TypeScript型定義
│       └── game.ts            # ゲーム関連の型
├── public/
│   ├── manifest.json          # PWAマニフェスト
│   └── icons/                 # アプリアイコン
├── .vscode/                   # VS Code設定
├── .husky/                    # Git hooks
├── next.config.mjs            # Next.js設定
├── tailwind.config.ts         # Tailwind CSS設定
├── tsconfig.json              # TypeScript設定
└── package.json
```

## 🎲 ゲームルール

### 基本ルール
1. コンピュータが選んだ数字を推測してください
2. 推測すると「もっと大きい」「もっと小さい」のヒントが出ます
3. 制限回数・制限時間内に正解を当てるとクリアです

### 難易度

| 難易度 | 範囲 | 試行回数 | 制限時間 | ヒント |
|--------|------|----------|----------|--------|
| イージー | 1-30 | 10回 | なし | 3回 |
| ノーマル | 1-50 | 8回 | 90秒 | 2回 |
| ハード | 1-100 | 7回 | 60秒 | 1回 |

## 🔧 開発時の注意事項

### コードスタイル
- すべてのコメント・ドキュメントは日本語で記述
- TypeScriptの型安全性を重視
- 関数名・変数名は英語、コメントは日本語

### Git ワークフロー
- コミット前に自動的にlint-stagedが実行されます
- プッシュ前に型チェック・リンター・フォーマットの検証が実行されます

### PWA開発
- マニフェストファイルは `public/manifest.json`
- Service Workerは本番環境でのみ有効化
- オフライン機能のテストは `pnpm build && pnpm start` で確認

## 🌐 デプロイ

### Vercel（推奨）
```bash
# Vercel CLIでデプロイ
npx vercel

# または GitHub連携で自動デプロイ
```

### その他のプラットフォーム
- Netlify
- Cloudflare Pages
- 静的ホスティング（ビルド後の `out` ディレクトリ）

## 📱 PWA機能

### インストール
1. ブラウザでアクセス
2. 「ホーム画面に追加」をタップ/クリック
3. ネイティブアプリのように起動可能

### オフライン機能
- ゲームはオフラインでも完全にプレイ可能
- 記録はローカルストレージに保存

## 🎯 学習ポイント

このプロジェクトは以下の学習に適しています：

- **Next.js 15**: App Router、Server Components
- **TypeScript**: 型安全なReact開発
- **PWA**: Progressive Web Appの実装
- **Tailwind CSS**: ユーティリティファーストCSS
- **アクセシビリティ**: インクルーシブなUI設計
- **パフォーマンス**: Core Web Vitals最適化

## 📄 ライセンス

MIT License

## 🤝 コントリビューション

プルリクエストやイシューの報告を歓迎します！

---

**楽しいゲーム体験をお届けします！ 🎮**