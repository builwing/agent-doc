# コンテキストキャッシュ - SpecAgentX

## ドキュメント情報
- **最終更新**: [TIMESTAMP]
- **キャッシュバージョン**: 1.0.0
- **有効期限**: セッション終了まで

## プロジェクト基本情報
```yaml
project_name: SpecAgentX
version: 2.0.0
type: エージェント管理システム
status: active
base_path: .specagentx/
```

## 重要パス（高頻度参照）
```yaml
requirements: .specagentx/REQUIREMENTS.md
specifications: .specagentx/SPECIFICATIONS.md
assignments: .specagentx/pm/ASSIGNMENTS.md
progress_overview: .specagentx/pm/PROGRESS_OVERVIEW.md
workplan: .specagentx/docs/WORKPLAN.md
```

## 現在のコンテキスト

### アクティブタスク
```yaml
current_phase: [要件定義/設計/実装/テスト/デプロイ]
active_agents:
  - name: [エージェント名]
    task: [タスクID]
    status: [ステータス]
priority_tasks:
  - [P0タスクリスト]
blockers:
  - [ブロッカーリスト]
```

### 技術スタック（確定済み）
```yaml
backend: [選択された技術]
frontend: [選択された技術]
mobile: [選択された技術]
database: [選択された技術]
infrastructure: [選択された技術]
```

## 要件サマリー（変更頻度: 低）

### ビジネス要件
- **BR-001**: プロジェクト開発の完全自動化
- **BR-002**: 多言語対応
- **BR-003**: トークン効率化
- **BR-004**: 進捗保持

### 機能要件（コア）
- **FR-CORE-001**: エージェント自動生成
- **FR-CORE-002**: 多言語技術仕様対応
- **FR-PROG-001**: 進捗追跡システム
- **FR-PROG-002**: 状態復元機能

### 非機能要件
- パフォーマンス: 起動10秒以内
- 信頼性: エラー復旧95%
- トークン削減: 50%目標

## 仕様サマリー（変更頻度: 低）

### エージェント体系
```yaml
orchestrator:
  - pm: プロジェクト管理

technical:
  - api-designer: API設計
  - backend-impl: バックエンド実装
  - frontend-impl: フロントエンド実装
  - mobile-impl: モバイル実装
  - db-designer: DB設計
  - infra-architect: インフラ設計

support:
  - test-qa: テスト・品質保証
  - cicd: CI/CD構築
  - docs: ドキュメント
  - security: セキュリティ
```

### タスクID体系
```
形式: <PREFIX>-<DOMAIN>-<NUMBER>
例: TASK-API-001, REQ-CORE-001, BUG-FE-001
```

## 進捗スナップショット

### 全体進捗
```yaml
total_tasks: [N]
completed: [N] ([N]%)
in_progress: [N] ([N]%)
pending: [N] ([N]%)
blocked: [N] ([N]%)
```

### マイルストーン
| ID | 名称 | 期日 | 進捗 |
|----|------|------|------|
| M1 | 要件定義完了 | - | 0% |
| M2 | 設計完了 | - | 0% |
| M3 | MVP実装 | - | 0% |
| M4 | テスト完了 | - | 0% |
| M5 | リリース | - | 0% |

## 依存関係マップ
```yaml
api-designer:
  blocks: [backend-impl, frontend-impl, mobile-impl]
  
db-designer:
  blocks: [backend-impl]
  
backend-impl:
  blocks: [frontend-impl, mobile-impl, test-qa]
  
cicd:
  requires: [backend-impl, frontend-impl, test-qa]
```

## 頻出コマンド
```bash
# 進捗確認
cat .specagentx/pm/PROGRESS_OVERVIEW.md

# タスク確認
cat .specagentx/pm/ASSIGNMENTS.md

# エージェント進捗
cat .specagentx/agents/*/PROGRESS.md

# 要件確認
grep "FR-" .specagentx/REQUIREMENTS.md
```

## ハッシュ値（変更検知用）
```yaml
requirements_hash: [SHA256]
specifications_hash: [SHA256]
workplan_hash: [SHA256]
assignments_hash: [SHA256]
```

## キャッシュ更新ルール

### 自動更新トリガー
- フェーズ変更時
- マイルストーン達成時
- ブロッカー発生/解決時
- 技術スタック確定時

### 手動更新
```bash
# キャッシュ強制更新
update_context_cache --force

# 部分更新
update_context_cache --section progress
```

## メモリ使用状況
```yaml
cache_size: [N] KB
entries: [N]
hit_rate: [N]%
last_gc: [TIMESTAMP]
```

---
*このキャッシュはトークン効率化のため、頻繁にアクセスされる情報を保持します。*
*セッション開始時に自動ロードされ、重要な変更時に更新されます。*