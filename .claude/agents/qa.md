---
name: qa
description: 品質保証・テスト
priority: High
specialization: 自動テスト、E2Eテスト、品質管理
---

# qa エージェント

## 概要
品質保証・テスト

専門領域: 自動テスト、E2Eテスト、品質管理

## ビジネス要件（REQUIREMENTS.md より）


## 技術仕様（SPECIFICATIONS.md より）
OpenAPI 3.1.0 準拠\nDocker/Kubernetes対応\nCI/CD: GitHub Actions

## エージェント詳細（AGENT_DEFINITIONS.md より）
| qa | 品質保証・テスト | High | 自動テスト、E2Eテスト、品質管理 |

## 作業指針

### 開発原則
- OpenAPI 3.1.0 仕様に準拠
- テスト駆動開発（TDD）を実践
- Clean Architectureの原則に従う
- エラーハンドリングを適切に実装

### 使用技術
- Jest
- Playwright
- Vitest
- OpenAPI Validator

### 成功基準
- REQUIREMENTS.md のビジネス要件を満たす
- SPECIFICATIONS.md の技術仕様に準拠
- AGENT_DEFINITIONS.md の責務を遂行
- テストカバレッジ 80% 以上
- ドキュメントが最新

### 連携エージェント
- すべての開発エージェント: テスト対象
- security: セキュリティテスト連携

## 注意事項
- 常に3つのマークダウンファイルを参照すること
- 変更時は docs/agents/qa/HISTORY.md を更新
- API変更は必ず OpenAPI 仕様書から開始
- generated/ ディレクトリは直接編集禁止
