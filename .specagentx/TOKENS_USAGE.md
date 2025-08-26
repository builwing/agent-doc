# トークン使用量追跡 - SpecAgentX

## ドキュメント情報
- **追跡開始日**: [YYYY-MM-DD]
- **最終更新**: [TIMESTAMP]
- **報告頻度**: セッションごと

## 全体統計

### 累積使用量
```yaml
total_tokens: 0
total_cost_estimate: $0.00
sessions: 0
average_per_session: 0
```

### 目標と実績
| 指標 | 目標 | 実績 | 達成率 |
|------|------|------|--------|
| トークン削減率 | 50% | - | - |
| セッション平均 | <100K | - | - |
| エージェント平均 | <20K | - | - |

## エージェント別使用量

### PMエージェント
```yaml
total_tokens: 0
sessions: 0
average: 0
last_session: 0
trend: →
optimization_applied:
  - キャッシュ利用
  - 差分読み込み
```

### 技術エージェント
| エージェント | 累積トークン | セッション数 | 平均 | 最終 | トレンド |
|-------------|-------------|------------|------|------|----------|
| api-designer | 0 | 0 | 0 | 0 | → |
| backend-impl | 0 | 0 | 0 | 0 | → |
| frontend-impl | 0 | 0 | 0 | 0 | → |
| mobile-impl | 0 | 0 | 0 | 0 | → |
| db-designer | 0 | 0 | 0 | 0 | → |
| infra-architect | 0 | 0 | 0 | 0 | → |

### サポートエージェント
| エージェント | 累積トークン | セッション数 | 平均 | 最終 | トレンド |
|-------------|-------------|------------|------|------|----------|
| test-qa | 0 | 0 | 0 | 0 | → |
| cicd | 0 | 0 | 0 | 0 | → |
| docs | 0 | 0 | 0 | 0 | → |
| security | 0 | 0 | 0 | 0 | → |

## セッション履歴

### セッション: [SESSION_ID]
```yaml
date: [YYYY-MM-DD HH:MM]
duration: [N] minutes
total_tokens: [N]
agents_active: [N]
breakdown:
  input_tokens: [N]
  output_tokens: [N]
  cached_tokens: [N]
efficiency_score: [N]%
```

## トークン使用パターン分析

### 高使用量タスク（Top 5）
| タスク種別 | 平均トークン | 頻度 | 最適化提案 |
|-----------|-------------|------|-----------|
| [タスク種別] | [N] | [N]回 | [提案] |

### 時間帯別使用量
```
00-06: ████ (20%)
06-12: ████████████ (40%)
12-18: ████████ (30%)
18-24: ███ (10%)
```

## 最適化実績

### 実施済み最適化
| 日付 | 施策 | 削減量 | 削減率 |
|------|------|--------|--------|
| [DATE] | キャッシュ導入 | [N] | [N]% |
| [DATE] | 差分更新 | [N] | [N]% |
| [DATE] | サマリー活用 | [N] | [N]% |

### 最適化候補
1. **[最適化案1]**
   - 対象: [対象エージェント/処理]
   - 期待削減: [N]%
   - 実装難易度: 低/中/高

2. **[最適化案2]**
   - 対象: [対象エージェント/処理]
   - 期待削減: [N]%
   - 実装難易度: 低/中/高

## アラート設定

### 閾値設定
```yaml
warning_threshold:
  session: 100000  # 100Kトークン
  agent: 30000     # 30Kトークン
  task: 10000      # 10Kトークン

critical_threshold:
  session: 200000  # 200Kトークン
  agent: 50000     # 50Kトークン
  task: 20000      # 20Kトークン
```

### アラート履歴
| 日時 | レベル | 対象 | 使用量 | 対応 |
|------|--------|------|--------|------|
| - | - | - | - | - |

## コスト分析

### モデル別コスト
```yaml
input_token_cost: $0.015/1K
output_token_cost: $0.075/1K
cached_token_cost: $0.0075/1K
```

### 月次推計
```yaml
current_month_usage: 0
projected_monthly: 0
estimated_cost: $0.00
budget: $100.00
remaining: $100.00
```

## 効率化メトリクス

### キャッシュ効果
```yaml
cache_hit_rate: 0%
tokens_saved: 0
cost_saved: $0.00
```

### 差分更新効果
```yaml
full_reads_avoided: 0
tokens_saved: 0
time_saved: 0 minutes
```

### サマリー活用効果
```yaml
summaries_used: 0
tokens_saved: 0
quality_impact: none
```

## レポート生成

### 日次レポート
```bash
generate_token_report --daily > reports/tokens_$(date +%Y%m%d).md
```

### 週次レポート
```bash
generate_token_report --weekly > reports/tokens_week_$(date +%Y%W).md
```

### 月次レポート
```bash
generate_token_report --monthly > reports/tokens_month_$(date +%Y%m).md
```

## 最適化ガイドライン

### ベストプラクティス
1. ✅ 必ずキャッシュを確認してから読み込み
2. ✅ 差分のみを更新
3. ✅ 完了フェーズはサマリーを参照
4. ✅ 並行処理でバッチ読み込み
5. ✅ 不要な再読み込みを避ける

### アンチパターン
1. ❌ 毎回全ファイルを読み込む
2. ❌ キャッシュを無視する
3. ❌ 冗長な出力を生成
4. ❌ 不必要な反復処理
5. ❌ 大きなコンテキストの保持

---
*このドキュメントはトークン使用量を追跡し、最適化の機会を特定します。*
*目標: 従来比50%のトークン削減を実現*