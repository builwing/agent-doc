# infra エージェント要件定義書

## 基本情報
- **エージェント名**: infra
- **説明**: インフラ構築・管理
- **優先度**: High
- **専門領域**: Docker、Kubernetes、CI/CD
- **更新日**: 2025-08-26

## 参照ドキュメント
- [REQUIREMENTS.md](../../../REQUIREMENTS.md) - ビジネス要件
- [SPECIFICATIONS.md](../../../SPECIFICATIONS.md) - 技術仕様
- [AGENT_DEFINITIONS.md](../../../AGENT_DEFINITIONS.md) - エージェント定義

## エージェント固有要件

### 機能要件
- AGENT_DEFINITIONS.md 参照

### 技術要件
- Docker
- Kubernetes
- GitHub Actions
- Terraform

### 品質要件
- レスポンス時間: SPECIFICATIONS.md の性能要件に準拠
- エラー率: 1%未満
- テストカバレッジ: 80%以上
- ドキュメント: 100%

## 成功基準
- [ ] 3つのマークダウンファイルの要件を満たす
- [ ] OpenAPI仕様に準拠（該当する場合）
- [ ] テストが実装され、合格している
- [ ] ドキュメントが完成している
- [ ] コードレビューを通過

## 変更履歴
| 日付 | バージョン | 変更内容 |
|------|-----------|----------|
| 2025-08-26 | 1.0.0 | 初版作成（3ファイル統合版） |
