# 🤖 AgentDoc - AI駆動SubAgent開発システム

高度なAI駆動のSubAgentシステムで、複雑なソフトウェア開発タスクを自動化・最適化します。

## 📖 概要

AgentDocは、専門特化した複数のAIエージェントを統合管理し、効率的なソフトウェア開発を実現するフレームワークです。
PM（プロジェクトマネージャー）エージェントが中心となり、タスクを適切なエージェントに自動振り分けし、品質を保証しながら開発を進めます。

このシステムは、**Go-Zero、Next.js 15、Expo**を活用したモダンなアプリケーション開発における**AI駆動の開発システム構築**として設計されています。

📌 **最終更新**: 2025年1月25日 - PM自動振り分けシステムとContext7統合を実装

### ✨ 主な特徴

- 🎯 **12の専門エージェント** - Requirements、PM、API、Logic、Next、Expo、Infra、QA、UI/UX、Security、Docs、Setup
- 🤖 **PMによる自動タスク振り分け** - タスク内容を分析して適切なエージェントに自動委任
- 📝 **3層ドキュメント構造** - REQUIREMENTS.md（ビジネス要件）、SPECIFICATIONS.md（技術仕様）、AGENT_DEFINITIONS.md（エージェント定義）
- 🔄 **完全自動化** - エージェント生成、タスク振り分け、Context7設定まで一括実行
- 📊 **変更管理** - 要件変更の追跡と自動再生成
- 🛡️ **Context7統合** - 最新ライブラリドキュメント自動参照（Go-Zero、Next.js 15、Expo対応）
- 🌐 **日本語優先** - すべてのコミュニケーションとドキュメントが日本語対応
- 📋 **OpenAPI仕様駆動開発** - API仕様から全プラットフォームのコードを自動生成

## 🚀 クイックスタート

### 前提条件

- Bash 4.0以上
- Python 3.8以上（タスク振り分けシステム用）
- Node.js 18以上（オプション）
- Git

### インストール

```bash
# リポジトリのクローン
git clone git@github.com:builwing/agent-doc.git my-app
cd my-app
rm -rf .git  //gitの初期化
```

### 新規プロジェクト

```bash
# Step 1: プロジェクトの初期化
./scripts/setup.sh                        # 基本ディレクトリ構造を作成

# Step 2: ドキュメントの作成
vim REQUIREMENTS.md                       # ビジネス要件を記述
vim SPECIFICATIONS.md                     # 技術仕様を記述（Go-Zero、Next.js 15、Expo）
vim AGENT_DEFINITIONS.md                  # エージェント定義を記述（オプション：テンプレートあり）

# Step 3: エージェント生成とシステムセットアップ（一括実行）
./scripts/core/generate_agents.sh         # 以下を自動実行：
                                          # - 3つのドキュメントからエージェント生成
                                          # - PM自動振り分けシステムのセットアップ
                                          # - Context7最新ドキュメント参照の設定
                                          # - CLAUDE.md（整合性保証書）の生成

# Step 4: タスクの実行（PM自動振り分け）
./scripts/core/pm_auto_dispatch.sh "ユーザー認証APIを実装"
                                          # PMが自動的に：
                                          # - タスクを分析
                                          # - 適切なエージェントを選定
                                          # - 実行プロンプトを生成
# Step 5:Gitの開始
git init  #新規プロジェクトの開始
```

## 📦 システム構成

### コアスクリプト

| スクリプト | 説明 | 状態 |
|-----------|------|------|
| `scripts/setup.sh` | **基本ディレクトリ構造とPM設定を作成** | ✅ 必須 |
| `scripts/core/generate_agents.sh` | **3つのドキュメントから全エージェントを自動生成、PM/Context7セットアップ** | ✅ 統合済み |
| `scripts/core/pm_auto_dispatch.sh` | **タスクを分析して適切なエージェントに自動振り分け** | ✅ 実装済み |
| `scripts/core/setup_pm_hooks.sh` | **PM自動振り分けシステムのセットアップ** | ✅ 自動実行 |
| `scripts/core/update_pm_context7.sh` | **Context7最新ドキュメント参照システムの管理** | ✅ 自動実行 |
| `scripts/reset.sh` | **プロジェクトを初期状態に戻す（ドキュメントは保持）** | ✅ 実装済み |

### PM自動振り分けシステム

```bash
# タスクの振り分け（エージェント指定不要）
./scripts/core/pm_auto_dispatch.sh "ユーザー認証機能を実装"
→ PMが分析: api、security、qa エージェントに自動振り分け

./scripts/core/pm_auto_dispatch.sh "ログイン画面を作成"
→ PMが分析: next エージェントが直接実行

./scripts/core/pm_auto_dispatch.sh "TODOアプリを作る"
→ PMが分析: 複雑なタスクのためPMが調整（api、next、expo、qa）

# オプション
-v, --verbose    # 詳細な分析結果を表示
-d, --dry-run    # 実行計画のみ表示（実際には実行しない）
-f, --force      # 確認なしで実行
```

### Context7 最新ドキュメント参照

```bash
# Context7の管理コマンド
./scripts/core/update_pm_context7.sh setup     # 初期セットアップ（自動実行済み）
./scripts/core/update_pm_context7.sh update    # ライブラリドキュメントを更新
./scripts/core/update_pm_context7.sh check nextjs  # 特定ライブラリのバージョン確認
./scripts/core/update_pm_context7.sh agent api     # 特定エージェントのContext7設定更新
```

**管理対象ライブラリ:**
- Go-Zero v1.7.0（APIエージェント）
- Next.js 15.0.0（Nextエージェント）
- Expo SDK 51（Expoエージェント）
- PostgreSQL 16、Redis 7.2（データストア）
- Docker/Kubernetes（インフラ）
- Jest/Playwright（テスト）

## 🏗️ アーキテクチャ

```
        ユーザー入力（タスク説明のみ）
                ↓
┌─────────────────────────────────────┐
│   タスクディスパッチャー (Python)      │
│   • キーワードベース分析             │
│   • 複雑度推定                      │
│   • エージェント選定                 │
└─────────────┬───────────────────────┘
              │
              ↓ 複雑度による分岐
              │
    ┌─────────┴─────────────────┐
    ▼                           ▼
┌──────────┐            ┌──────────┐
│   PM     │            │  直接    │
│ 調整実行  │            │  実行    │
└──────────┘            └──────────┘
    │                          │
    │ 複数エージェント          │ 単一エージェント
    ▼                          ▼
┌──────────┐            ┌──────────┐
│ 各Agent  │            │  Agent   │
│ 協調実行  │            │  実行    │
└──────────┘            └──────────┘
```

## 📋 エージェント一覧

| Agent | 役割 | 主要技術 | Context7対応 |
|-------|------|----------|-------------|
| **pm** | プロジェクト管理・タスク調整 | タスク分析、進捗管理 | - |
| **requirements** | 要件定義管理 | 要件分析、変更管理 | - |
| **api** | バックエンドAPI開発 | Go-Zero v1.7.0、PostgreSQL、Redis | ✅ |
| **logic** | ビジネスロジック設計 | ドメイン駆動設計、アルゴリズム | - |
| **next** | Webフロントエンド | Next.js 15、React 19、TypeScript | ✅ |
| **expo** | モバイルアプリ | Expo SDK 51、React Native 0.74 | ✅ |
| **infra** | インフラ・DevOps | Docker、Kubernetes、GitHub Actions | ✅ |
| **qa** | 品質保証・テスト | Jest、Playwright、Vitest | ✅ |
| **uiux** | UI/UXデザイン | デザインシステム、アクセシビリティ | - |
| **security** | セキュリティ | JWT、OAuth、暗号化 | - |
| **docs** | ドキュメント管理 | Markdown、OpenAPI | - |
| **setup** | 環境構築・初期設定 | プロジェクト構造、依存関係 | - |

## 📊 ドキュメント構成

### 3層ドキュメント構造

```
プロジェクトルート/
├── REQUIREMENTS.md          # ビジネス要件（何を作るか）
├── SPECIFICATIONS.md        # 技術仕様（どう作るか）
├── AGENT_DEFINITIONS.md     # エージェント定義（誰が作るか）
└── CLAUDE.md               # 整合性保証設定（自動生成）

.claude/
├── agents/                 # 各エージェントファイル（自動生成）
│   ├── pm.md
│   ├── api.md
│   ├── next.md
│   └── ...
├── hooks/                  # タスク振り分けシステム
│   ├── task-dispatcher.py  # タスク解析エンジン
│   └── last_dispatch.json  # 最後の振り分け結果
├── context7/              # Context7設定
│   ├── library_mapping.json
│   └── library_cache/
└── pm/                    # PM設定とプロンプト

docs/agents/               # 各エージェントのドキュメント
├── api/
│   ├── REQUIREMENTS.md   # エージェント固有要件
│   ├── CHECKLIST.md      # 作業チェックリスト
│   └── HISTORY.md        # 作業履歴
└── ...
```

## 🔄 基本的な使い方

### 1. 3つのドキュメントを編集

```bash
# ビジネス要件の記述
vim REQUIREMENTS.md
- プロジェクト概要
- ビジネス要件
- 機能要件

# 技術仕様の記述
vim SPECIFICATIONS.md
- 技術スタック（Go-Zero、Next.js 15、Expo）
- アーキテクチャ
- API仕様

# エージェント定義（オプション）
vim AGENT_DEFINITIONS.md
- エージェントの責務
- 優先度
- 協調フロー
```

### 2. エージェント生成（全自動）

```bash
# 3つのドキュメントから全エージェントを生成
./scripts/core/generate_agents.sh

# 実行内容：
# 1. ドキュメント検証
# 2. エージェントファイル生成
# 3. CLAUDE.md生成
# 4. PM自動振り分けシステムセットアップ
# 5. Context7最新ドキュメント参照設定
```

### 3. タスク実行（PM自動振り分け）

```bash
# シンプルなタスク（直接実行）
./scripts/core/pm_auto_dispatch.sh "READMEを更新"
→ docs エージェントが直接実行

# API開発タスク（直接実行）
./scripts/core/pm_auto_dispatch.sh "ユーザー検索APIを実装"
→ api エージェントが直接実行（Go-Zero最新ドキュメント参照）

# 複雑なタスク（PM調整）
./scripts/core/pm_auto_dispatch.sh "ユーザー管理機能を実装（API、画面、テスト含む）"
→ PMエージェントが調整、api、next、qa に振り分け
```

### 4. Context7でライブラリ最新化

```bash
# すべてのライブラリドキュメントを更新
./scripts/core/update_pm_context7.sh update

# 特定ライブラリのバージョン確認
./scripts/core/update_pm_context7.sh check go-zero
./scripts/core/update_pm_context7.sh check nextjs
./scripts/core/update_pm_context7.sh check expo

# レポート表示
./scripts/core/update_pm_context7.sh all
```

### 5. プロジェクトのリセット（初期状態に戻す）

```bash
# プロジェクトを初期状態に戻す
./scripts/reset.sh
# または
./scripts/core/reset.sh

# 実行内容：
# - 自動生成されたファイル・ディレクトリをすべて削除
# - 3つのドキュメントは保持（REQUIREMENTS.md、SPECIFICATIONS.md、AGENT_DEFINITIONS.md）
# - スクリプトファイルは保持

# 削除対象：
# • .claude/              - エージェント定義とPM設定
# • docs/agents/          - エージェントドキュメント
# • generated/            - 自動生成コード
# • CLAUDE.md             - 整合性保証設定書
# • .agent-cache/         - キャッシュ
# • .git/hooks/*          - Gitフック
# • その他の自動生成ファイル

# リセット後の再セットアップ：
./scripts/setup.sh                 # 基本構造作成
./scripts/core/generate_agents.sh  # エージェント再生成（PM/Context7も自動設定）
```

## 🎯 ベストプラクティス

### 1. ドキュメント駆動開発
- **REQUIREMENTS.md** - ビジネス要件を明確に記述
- **SPECIFICATIONS.md** - 技術選定と仕様を詳細に定義
- **AGENT_DEFINITIONS.md** - エージェントの役割を明確化

### 2. PM自動振り分けの活用
- エージェント名を指定せず、タスク内容だけを記述
- PMが最適なエージェントを自動選定
- 複雑なタスクは自動的にPMが調整

### 3. Context7による最新化
- 実装前に必ず最新ドキュメントを参照
- 定期的に `update` コマンドで最新化
- バージョン固有の機能に注意

### 4. OpenAPI仕様の活用
- API開発はOpenAPI仕様から開始
- generated/ディレクトリは直接編集禁止
- バックエンド・フロントエンド・モバイル間の整合性を保証

## 🛠️ メンテナンス

### プロジェクトのクリーンアップ

開発中に自動生成されたファイルが多くなった場合や、設定をやり直したい場合は、リセット機能を使用してプロジェクトを初期状態に戻せます。

```bash
# プロジェクトリセットの流れ
1. ./scripts/reset.sh          # 自動生成ファイルを削除
2. vim REQUIREMENTS.md          # 必要に応じて要件を修正
3. vim SPECIFICATIONS.md        # 必要に応じて技術仕様を修正
4. ./scripts/setup.sh           # 基本構造を再作成
5. ./scripts/core/generate_agents.sh  # エージェントを再生成
```

**リセット時の注意事項:**
- カスタマイズしたエージェントファイルは削除されます
- 3つのドキュメント（REQUIREMENTS.md、SPECIFICATIONS.md、AGENT_DEFINITIONS.md）は保持されます
- プロジェクト固有の実装コードがある場合は事前にバックアップしてください

## 🔧 トラブルシューティング

### Python3が見つからない場合
```bash
# macOS
brew install python3

# Ubuntu/Debian
sudo apt-get install python3

# 確認
python3 --version
```

### タスクディスパッチャーが動作しない場合
```bash
# 手動セットアップ
./scripts/core/setup_pm_hooks.sh

# 動作確認
python3 .claude/hooks/task-dispatcher.py "テストタスク"
```

### Context7が機能しない場合
```bash
# 手動セットアップ
./scripts/core/update_pm_context7.sh setup

# 設定確認
ls -la .claude/context7/
```

### エージェントが生成されない場合
```bash
# ドキュメントの検証
./scripts/core/generate_agents.sh -v

# 個別エージェント生成
./scripts/core/generate_agents.sh -a api
```

## 🙏 謝辞

このプロジェクトは以下の技術に支えられています：
- Claude (Anthropic) - AI エージェント基盤
- Go-Zero - マイクロサービスフレームワーク
- Next.js 15 - Reactフルスタックフレームワーク
- Expo SDK 51 - React Native開発プラットフォーム
- Context7 - 最新ドキュメント参照システム

---

**Made with ❤️ by the AgentDoc Team**