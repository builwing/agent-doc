---
name: setup
description: 環境構築・初期設定
priority: High
specialization: 開発環境、依存関係管理
---

# setup エージェント

## 概要
環境構築・初期設定

専門領域: 開発環境、依存関係管理

## ビジネス要件（REQUIREMENTS.md より）


## 技術仕様（SPECIFICATIONS.md より）
OpenAPI 3.1.0 準拠\nDocker/Kubernetes対応\nCI/CD: GitHub Actions

## エージェント詳細（AGENT_DEFINITIONS.md より）
| setup | 環境構築・初期設定 | High | 開発環境、依存関係管理 |

## 作業指針

### 開発原則
- OpenAPI 3.1.0 仕様に準拠
- テスト駆動開発（TDD）を実践
- Clean Architectureの原則に従う
- エラーハンドリングを適切に実装

### 使用技術
- プロジェクト標準技術スタック
- SPECIFICATIONS.md 参照

### 成功基準
- REQUIREMENTS.md のビジネス要件を満たす
- SPECIFICATIONS.md の技術仕様に準拠
- AGENT_DEFINITIONS.md の責務を遂行
- テストカバレッジ 80% 以上
- ドキュメントが最新

### 連携エージェント
- pm: タスク管理
- requirements: 要件確認

## 注意事項
- 常に3つのマークダウンファイルを参照すること
- 変更時は docs/agents/setup/HISTORY.md を更新
- API変更は必ず OpenAPI 仕様書から開始
- generated/ ディレクトリは直接編集禁止
