# 技術仕様書 - SpecAgentX

## ドキュメント情報
- **バージョン**: 2.0.0
- **最終更新日**: 2025-08-25
- **ステータス**: アクティブ
- **管理者**: PMエージェント
- **参照**: REQUIREMENTS.md v2.0.0

## 1. アーキテクチャ概要

### 1.1 システム構成
```
┌─────────────────────────────────────────────┐
│           ClaudeCode Interface              │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│            PM Agent (統括)                   │
├──────────────────────────────────────────────┤
│  - タスク分解・割り当て                        │
│  - 進捗管理・集約                             │
│  - エージェント間調整                          │
└────────┬───────────────────────┬────────────┘
         │                       │
┌────────▼──────┐       ┌───────▼──────────┐
│ Technical     │       │ Support          │
│ Agents        │       │ Agents           │
├───────────────┤       ├──────────────────┤
│ - api-designer│       │ - test-qa        │
│ - backend-impl│       │ - cicd           │
│ - frontend    │       │ - docs           │
│ - mobile      │       │ - security       │
│ - db-designer │       └──────────────────┘
│ - infra       │
└───────────────┘
```

### 1.2 データフロー
1. **要件定義** → PMエージェントが解析
2. **タスク分解** → WBS作成、エージェント割り当て
3. **実装** → 各専門エージェントが並行作業
4. **統合** → PMエージェントが成果物を集約
5. **検証** → QAエージェントがテスト実行

## 2. 技術スタック（言語非依存）

### 2.1 システム基盤
- **エージェント実行環境**: ClaudeCode
- **ドキュメント形式**: Markdown
- **バージョン管理**: Git
- **スクリプト**: Bash / Node.js

### 2.2 対応言語・フレームワーク
プロジェクトごとに以下から選択：

| カテゴリ | 選択肢 |
|---------|--------|
| **バックエンド** | Go (go-zero), Node.js (Express/Fastify), Python (FastAPI/Django), Java (Spring Boot), Rust (Actix) |
| **フロントエンド** | Next.js 15, React, Vue 3, Angular, Svelte |
| **モバイル** | Expo (React Native), Flutter, Swift, Kotlin |
| **データベース** | PostgreSQL, MySQL, MongoDB, Redis, DynamoDB |
| **インフラ** | Docker, Kubernetes, AWS, GCP, Azure |

## 3. 言語別仕様テンプレート構造

### 3.1 共通仕様 (common/)
```yaml
api:
  authentication: JWT / OAuth2 / API Key
  rate_limiting: true
  versioning: /v1, /v2
  error_format: 
    code: string
    message: string
    details: object

database:
  connection_pooling: true
  migration_tool: required
  backup_strategy: daily

security:
  encryption: AES-256
  hashing: bcrypt / argon2
  cors: configurable
  csp: enabled
```

### 3.2 言語固有仕様
各言語ディレクトリに以下を配置：
- `template.md`: プロジェクト構造テンプレート
- `conventions.md`: コーディング規約
- `dependencies.md`: 標準ライブラリリスト
- `testing.md`: テスト戦略

## 4. エージェント仕様

### 4.1 PMエージェント
```yaml
role: プロジェクトマネージャー
responsibilities:
  - 要件分析
  - タスク分解（WBS作成）
  - エージェント割り当て
  - 進捗管理
  - リスク管理
inputs:
  - REQUIREMENTS.md
  - SPECIFICATIONS.md
outputs:
  - ASSIGNMENTS.md
  - PROGRESS_OVERVIEW.md
  - リスクレポート
```

### 4.2 技術エージェント共通仕様
```yaml
structure:
  definition: DEFINITION.md
  plan: PLAN.md
  progress: PROGRESS.md
  outcome: OUTCOME.md

workflow:
  1. タスク受領（ASSIGNMENTS.md参照）
  2. 計画作成（PLAN.md更新）
  3. 実装/設計
  4. 進捗報告（PROGRESS.md更新）
  5. 成果物提出（OUTCOME.md作成）
```

## 5. コンテキスト最適化仕様

### 5.1 キャッシュ戦略
```yaml
context_cache:
  format: key-value pairs
  update_frequency: per_session
  priority_levels:
    high: 要件定義、現在のタスク
    medium: 依存関係、API仕様
    low: 過去の成果物、参考資料

token_tracking:
  per_agent: true
  alert_threshold: 80%
  optimization_trigger: 90%
```

### 5.2 差分管理
```yaml
change_detection:
  method: hash_comparison
  granularity: section_level
  update_strategy: incremental

summary_generation:
  trigger: phase_completion
  max_size: 500_tokens
  retention: permanent
```

## 6. 進捗管理仕様

### 6.1 タスクID体系
```
形式: <PREFIX>-<DOMAIN>-<NUMBER>
例: 
  - REQ-CORE-001 (要件)
  - TASK-API-001 (APIタスク)
  - BUG-FE-001 (フロントエンドバグ)
```

### 6.2 ステータス定義
| ステータス | 説明 | 次のアクション |
|-----------|------|---------------|
| pending | 未着手 | 計画作成 |
| in_progress | 作業中 | 進捗更新 |
| blocked | ブロック中 | 課題解決 |
| review | レビュー中 | フィードバック対応 |
| completed | 完了 | 成果物確定 |

## 7. 品質基準

### 7.1 コード品質
- **カバレッジ**: 80%以上
- **複雑度**: 循環的複雑度10以下
- **重複**: 5%以下
- **リンター**: エラー0

### 7.2 ドキュメント品質
- **完全性**: 全機能の説明
- **正確性**: コードとの一致
- **可読性**: 明確な構造
- **更新性**: 変更履歴の記録

## 8. セキュリティ仕様

### 8.1 認証・認可
- **認証方式**: JWT推奨
- **トークン有効期限**: アクセス24h、リフレッシュ30d
- **権限管理**: RBAC実装

### 8.2 データ保護
- **暗号化**: 保存時・通信時
- **個人情報**: GDPR/CCPA準拠
- **監査ログ**: 全操作記録

## 9. デプロイメント仕様

### 9.1 環境
| 環境 | 用途 | 自動化 |
|------|------|--------|
| development | 開発 | - |
| staging | 検証 | CI/CD |
| production | 本番 | CI/CD |

### 9.2 CI/CDパイプライン
```yaml
stages:
  - lint: コード品質チェック
  - test: 自動テスト実行
  - build: ビルド
  - security: セキュリティスキャン
  - deploy: デプロイ
  - verify: 動作確認
```

## 10. 移行戦略

### 10.1 既存システムからの移行
1. **評価フェーズ**: 現状分析
2. **計画フェーズ**: 移行計画作成
3. **準備フェーズ**: 環境構築
4. **移行フェーズ**: データ・コード移行
5. **検証フェーズ**: 動作確認
6. **切替フェーズ**: 本番切替

## 11. 付録

### 11.1 用語定義
- **エージェント**: 特定の役割を持つ自動化された実行単位
- **コンテキスト**: LLMが処理する情報の文脈
- **トークン**: LLMの処理単位
- **WBS**: Work Breakdown Structure（作業分解構造）

### 11.2 参照ドキュメント
- REQUIREMENTS.md: ビジネス要件
- WORKPLAN.md: 詳細作業計画
- 各言語別template.md: 実装詳細

---
*この仕様書は技術的な実装ガイドラインを提供し、要件定義書と連携して使用されます。*