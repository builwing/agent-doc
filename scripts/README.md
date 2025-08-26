# Agentix スクリプトガイド

## 📁 ディレクトリ構造

```
scripts/
├── setup.sh              # メインセットアップスクリプト
├── reset.sh              # プロジェクトリセット
├── integrate.sh          # 既存プロジェクトへの統合
├── install-modules.sh    # モジュール個別インストール
│
├── core/                 # コアスクリプト
│   ├── setup.sh         # 基本セットアップ
│   ├── reset.sh         # 初期状態へのリセット
│   ├── generate_agents.sh        # エージェント生成
│   ├── generate_claude_md.sh     # CLAUDE.md生成
│   ├── integrate.sh              # 統合処理
│   ├── setup_default_agents.sh   # デフォルトエージェント
│   └── setup_custom_agents.sh    # カスタムエージェント
│
├── modules/              # オプション機能モジュール
│   ├── auto_testing.sh          # 自動テストシステム
│   ├── coordination.sh          # エージェント協調
│   ├── hooks.sh                 # Git Hooks設定
│   ├── llm_router.sh           # LLMタスク振り分け
│   ├── mcp_tools.sh            # MCP連携
│   ├── metrics.sh              # メトリクス収集
│   ├── multi_llm.sh            # 複数LLM対応
│   ├── pm_prompts.sh           # PMプロンプト
│   ├── rag_system.sh           # RAGシステム
│   ├── realtime_dashboard.sh   # 監視ダッシュボード
│   └── core_scripts.sh         # コアスクリプト群
│
└── utils/                # ユーティリティ
    ├── update_requirements.sh   # 要件更新管理
    └── update_pm_context7.sh    # Context7設定更新
```

## 🚀 クイックスタート

### 1. 初期セットアップ

```bash
# 基本セットアップ（推奨）
./scripts/setup.sh --basic

# フルセットアップ（全機能）
./scripts/setup.sh --full

# エージェントのみ生成
./scripts/setup.sh --agents
```

### 2. プロジェクトリセット

```bash
# 生成されたファイルをすべて削除し、初期状態に戻す
./scripts/reset.sh

# その後、再セットアップ
./scripts/setup.sh
```

### 3. 既存プロジェクトへの統合

```bash
# 既存のプロジェクトにAgentixシステムを追加
./scripts/integrate.sh
```

## 📦 モジュール管理

### 個別インストール

```bash
# 特定のモジュールをインストール
./scripts/install-modules.sh auto-testing
./scripts/install-modules.sh hooks metrics

# すべてのモジュールをインストール
./scripts/install-modules.sh all
```

### 利用可能なモジュール

| モジュール | 説明 | コマンド |
|-----------|------|----------|
| auto-testing | 自動テスト実行システム | `install-modules.sh auto-testing` |
| coordination | エージェント間協調 | `install-modules.sh coordination` |
| hooks | Git Hooks設定 | `install-modules.sh hooks` |
| llm-router | LLMタスク振り分け | `install-modules.sh llm-router` |
| mcp-tools | MCP連携ツール | `install-modules.sh mcp-tools` |
| metrics | メトリクス収集 | `install-modules.sh metrics` |
| multi-llm | 複数LLM対応 | `install-modules.sh multi-llm` |
| pm-prompts | PMプロンプト設定 | `install-modules.sh pm-prompts` |
| rag-system | RAGシステム | `install-modules.sh rag-system` |
| dashboard | リアルタイム監視 | `install-modules.sh dashboard` |

## 🔧 高度な使用方法

### 要件定義の更新

```bash
# REQUIREMENTS.mdの変更を検出して再生成
./scripts/utils/update_requirements.sh
```

### Context7の設定

```bash
# PM及びSubAgentにContext7を使用するよう設定
./scripts/utils/update_pm_context7.sh
```

## 📝 カスタマイズ

### カスタムエージェントの作成

```bash
# 対話形式でカスタムエージェントを作成
./scripts/core/setup_custom_agents.sh
```

### エージェントの再生成

```bash
# REQUIREMENTS.mdから自動生成
./scripts/core/generate_agents.sh
```

## ⚠️ 注意事項

1. **バックアップ**: `reset.sh`を実行する前に、重要なファイルはバックアップしてください
2. **依存関係**: 一部のモジュールは他のモジュールに依存する場合があります
3. **権限**: スクリプトに実行権限が必要です: `chmod +x scripts/*.sh`

## 🆘 トラブルシューティング

### スクリプトが実行できない

```bash
# 実行権限を付与
chmod +x scripts/*.sh scripts/**/*.sh
```

### パスが見つからない

```bash
# プロジェクトルートから実行
cd /path/to/project
./scripts/setup.sh
```

### モジュールのインストールに失敗

```bash
# 基本セットアップを先に実行
./scripts/setup.sh --basic
# その後モジュールをインストール
./scripts/install-modules.sh [module-name]
```

## 📚 関連ドキュメント

- [REQUIREMENTS.md](../REQUIREMENTS.md) - プロジェクト要件定義
- [CLAUDE.md](../CLAUDE.md) - Claude用指示書（自動生成）
- [.claude/README.md](../.claude/README.md) - エージェント設定ガイド

## 🔄 更新履歴

- **v2.0.0** - スクリプト構造を整理・統合
- **v1.5.0** - モジュール化による機能分離
- **v1.0.0** - 初期リリース