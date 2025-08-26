# SpecAgentX ディレクトリ構造

## プロジェクト構成

```
SpecAgentX/
├── .specagentx/                    # SpecAgentXシステムファイル（隠しディレクトリ）
│   ├── REQUIREMENTS.md             # 要件定義書（マスター）
│   ├── SPECIFICATIONS.md           # 技術仕様書（マスター）
│   ├── CONTEXT_CACHE.md           # コンテキストキャッシュ
│   ├── TOKENS_USAGE.md            # トークン使用量追跡
│   │
│   ├── docs/                       # プロジェクトドキュメント
│   │   ├── WORKPLAN.md            # 作業計画書（WBS）
│   │   ├── CHANGELOG.md           # 変更履歴
│   │   └── DECISIONS.md           # 意思決定記録
│   │
│   ├── pm/                         # PMエージェント管理領域
│   │   ├── OVERVIEW.md            # プロジェクト概要
│   │   ├── ASSIGNMENTS.md         # タスク割り当て
│   │   ├── PROGRESS_OVERVIEW.md   # 全体進捗ダッシュボード
│   │   ├── TEMPLATES/             # 各種テンプレート
│   │   │   ├── PLAN.template.md
│   │   │   ├── PROGRESS.template.md
│   │   │   └── OUTCOME.template.md
│   │   └── SUMMARY/               # フェーズ完了時の要約
│   │       └── phase-*.md
│   │
│   ├── agents/                     # 専門エージェント定義
│   │   ├── api-designer/          # API設計エージェント
│   │   ├── backend-impl/          # バックエンド実装エージェント
│   │   ├── frontend-impl/         # フロントエンド実装エージェント
│   │   ├── mobile-impl/           # モバイル実装エージェント
│   │   ├── db-designer/           # DB設計エージェント
│   │   ├── infra-architect/       # インフラ設計エージェント
│   │   ├── test-qa/               # テスト・QAエージェント
│   │   └── cicd/                  # CI/CDエージェント
│   │       （各エージェントディレクトリ内）
│   │       ├── DEFINITION.md      # エージェント定義
│   │       ├── PLAN.md           # 作業計画
│   │       ├── PROGRESS.md       # 進捗記録
│   │       └── OUTCOME.md        # 成果物
│   │
│   └── specifications/             # 技術仕様テンプレート
│       ├── common/                # 共通仕様
│       │   ├── api.md
│       │   ├── database.md
│       │   └── security.md
│       └── languages/             # 言語別仕様
│           ├── go/
│           │   ├── template.md
│           │   └── conventions.md
│           ├── javascript/
│           │   ├── template.md
│           │   └── conventions.md
│           ├── python/
│           │   ├── template.md
│           │   └── conventions.md
│           ├── java/
│           │   ├── template.md
│           │   └── conventions.md
│           └── rust/
│               ├── template.md
│               └── conventions.md
│
├── .claude/                        # ClaudeCode設定
│   └── agents/                     # エージェント定義
│       ├── pm.agent.md
│       ├── api-designer.agent.md
│       ├── backend-impl.agent.md
│       ├── frontend-impl.agent.md
│       ├── mobile-impl.agent.md
│       ├── test-qa.agent.md
│       └── cicd.agent.md
│
└── [プロジェクトファイル]            # 実際のプロジェクトコード
    ├── src/                        # ソースコード
    ├── tests/                      # テストコード
    ├── docs/                       # プロジェクトドキュメント
    └── ...                         # その他のプロジェクトファイル
```

## 特徴

### 1. 隠しディレクトリ構造
- `.specagentx/` 配下にすべてのシステムファイルを配置
- 実際のプロジェクト開発の邪魔にならない
- システムファイルと開発ファイルの明確な分離

### 2. コンテキスト効率化
- `CONTEXT_CACHE.md`: 頻繁に参照される情報のキャッシュ
- `TOKENS_USAGE.md`: 各エージェントのトークン使用量追跡
- `SUMMARY/`: 各フェーズ完了時の要約保存

### 3. 多言語対応
- `specifications/languages/`: 言語別の仕様テンプレート
- 新言語はプラグイン形式で追加可能
- 共通仕様と言語固有仕様の分離

### 4. 進捗管理
- 各エージェントが独自の `PROGRESS.md` を持つ
- PMが `PROGRESS_OVERVIEW.md` で全体を統括
- 中断・再開時の状態完全保持

## 運用ルール

1. **システムファイルは `.specagentx/` 内のみ**
2. **プロジェクトコードはルートディレクトリに自由に配置**
3. **エージェント定義は `.claude/agents/` に配置**
4. **すべての変更は `CHANGELOG.md` に記録**
5. **重要な意思決定は `DECISIONS.md` に記録**

---
*このドキュメントは SpecAgentX のディレクトリ構造を定義します。*