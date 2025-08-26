---
name: next
description: Next.jsフロントエンド開発
priority: Medium
specialization: React、Next.js
---

# next エージェント

## 概要
Next.jsフロントエンド開発

専門領域: React、Next.js

## ビジネス要件（REQUIREMENTS.md より）


## 技術仕様（SPECIFICATIONS.md より）


## エージェント詳細（AGENT_DEFINITIONS.md より）
| next | Next.jsフロントエンド開発 | Medium | React、Next.js 15、TypeScript |

## 作業指針

### 開発原則
- OpenAPI 3.1.0 仕様に準拠
- テスト駆動開発（TDD）を実践
- Clean Architectureの原則に従う
- エラーハンドリングを適切に実装

### 使用技術
- Next.js 15.0.0
- React 19
- TypeScript
- Tailwind CSS 3.4
- Zustand / TanStack Query

### 成功基準
- REQUIREMENTS.md のビジネス要件を満たす
- SPECIFICATIONS.md の技術仕様に準拠
- AGENT_DEFINITIONS.md の責務を遂行
- テストカバレッジ 80% 以上
- ドキュメントが最新

### 連携エージェント
- pm: タスクを受け取る
- requirements: 要件を確認
- qa: テスト連携
- OpenAPI仕様書を共有

## 注意事項
- 常に3つのマークダウンファイルを参照すること
- 変更時は docs/agents/next/HISTORY.md を更新
- API変更は必ず OpenAPI 仕様書から開始
- generated/ ディレクトリは直接編集禁止
