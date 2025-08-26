# Agenix → SpecAgentX 移行計画

## 移行概要
- **移行元**: Agenix v1.0
- **移行先**: SpecAgentX v2.0
- **移行期間**: [開始日] ～ [終了日]
- **移行方式**: 段階的移行（既存機能を維持しながら拡張）

## 既存Agenixスクリプト分析

### 利用可能なスクリプト（そのまま活用）
| スクリプト名 | 機能 | 移行先 | 優先度 |
|------------|------|--------|--------|
| requirements.sh | 要件定義生成 | .specagentx/scripts/ | 高 |
| pm.sh | プロジェクト管理 | .specagentx/scripts/ | 高 |
| api.sh | API開発支援 | .specagentx/scripts/ | 高 |
| logic.sh | ビジネスロジック生成 | .specagentx/scripts/ | 中 |
| next.sh | Next.js開発 | .specagentx/scripts/ | 中 |
| expo.sh | Expo開発 | .specagentx/scripts/ | 中 |
| infra.sh | インフラ構築 | .specagentx/scripts/ | 高 |
| qa.sh | 品質保証 | .specagentx/scripts/ | 高 |

### 修正が必要なスクリプト
| スクリプト名 | 修正内容 | 工数 |
|------------|---------|------|
| init.sh | 隠しディレクトリ対応 | 1h |
| config.sh | 多言語対応追加 | 2h |
| agent-generator.sh | テンプレート更新 | 3h |

### 新規作成が必要な機能
1. **言語別テンプレート管理**
   - Go, JavaScript, Python, Java, Rust対応
   - プラグイン形式での追加

2. **トークン最適化機能**
   - コンテキストキャッシュ
   - 差分更新メカニズム

3. **進捗復元機能**
   - セッション間の状態保持
   - 自動復元メカニズム

## 移行手順

### Phase 1: 環境準備（Day 1）
```bash
# 1. バックアップ作成
cp -r . ../Agenix_backup_$(date +%Y%m%d)

# 2. SpecAgentX構造作成
mkdir -p .specagentx/{docs,pm,agents,specifications,scripts}
mkdir -p .claude/agents

# 3. 既存ファイルの移動
mv REQUIREMENTS.md .specagentx/
mv agents/*.sh .specagentx/scripts/
```

### Phase 2: スクリプト移行（Day 2-3）
```bash
# 1. スクリプトのパス更新
for script in .specagentx/scripts/*.sh; do
  sed -i 's|agents/|.specagentx/agents/|g' "$script"
  sed -i 's|docs/|.specagentx/docs/|g' "$script"
done

# 2. 隠しディレクトリ対応
update_paths() {
  local file=$1
  sed -i 's|^\./|./.specagentx/|g' "$file"
}

# 3. 権限設定
chmod +x .specagentx/scripts/*.sh
```

### Phase 3: テンプレート移行（Day 4）
```bash
# 1. 既存テンプレートの変換
convert_templates() {
  # 要件定義テンプレート
  cp templates/requirements.md .specagentx/REQUIREMENTS.md
  
  # エージェント定義テンプレート
  for agent in api backend frontend mobile; do
    create_agent_template "$agent"
  done
}

# 2. 多言語テンプレート追加
for lang in go javascript python java rust; do
  mkdir -p .specagentx/specifications/languages/$lang
  cp templates/${lang}_template.md .specagentx/specifications/languages/$lang/
done
```

### Phase 4: データ移行（Day 5）
```bash
# 1. 既存プロジェクトデータの変換
migrate_project_data() {
  # 進捗データの移行
  if [ -f progress.json ]; then
    convert_progress_to_md progress.json > .specagentx/pm/PROGRESS_OVERVIEW.md
  fi
  
  # タスクデータの移行
  if [ -f tasks.json ]; then
    convert_tasks_to_md tasks.json > .specagentx/pm/ASSIGNMENTS.md
  fi
}

# 2. Git履歴の保持
git add .specagentx/
git commit -m "chore: Migrate from Agenix to SpecAgentX"
```

### Phase 5: 検証（Day 6）
```bash
# 1. 基本機能テスト
test_core_functions() {
  # PMエージェントテスト
  .specagentx/scripts/pm.sh test
  
  # APIエージェントテスト
  .specagentx/scripts/api.sh test
  
  # 進捗管理テスト
  check_progress_tracking
}

# 2. 互換性テスト
verify_compatibility() {
  # 既存コマンドの動作確認
  for cmd in init generate deploy; do
    test_command "$cmd"
  done
}
```

### Phase 6: 切り替え（Day 7）
```bash
# 1. エイリアス設定
setup_aliases() {
  echo "alias agenix='specagentx'" >> ~/.bashrc
  echo "alias agx='sax'" >> ~/.bashrc
}

# 2. 環境変数更新
export SPECAGENTX_HOME=".specagentx"
export SPECAGENTX_VERSION="2.0.0"

# 3. 完了通知
echo "Migration completed successfully!"
```

## 互換性レイヤー

### 後方互換性の維持
```bash
# compatibility.sh
#!/bin/bash

# 旧コマンドから新コマンドへのマッピング
case "$1" in
  "agent")
    shift
    .specagentx/scripts/agent-manager.sh "$@"
    ;;
  "init")
    .specagentx/scripts/init.sh "$@"
    ;;
  "generate")
    .specagentx/scripts/generate.sh "$@"
    ;;
  *)
    echo "Unknown command: $1"
    exit 1
    ;;
esac
```

## リスクと対策

| リスク | 影響 | 対策 |
|--------|------|------|
| データ損失 | 高 | 完全バックアップ実施 |
| 機能不全 | 中 | 段階的移行・ロールバック準備 |
| 学習コスト | 低 | ドキュメント整備・トレーニング |

## 成功基準
- [ ] 全既存機能が正常動作
- [ ] 新機能（多言語対応）が動作
- [ ] トークン使用量30%削減確認
- [ ] 進捗復元機能の動作確認
- [ ] ドキュメント完備

## ロールバック計画
```bash
# rollback.sh
#!/bin/bash

if [ -d "../Agenix_backup_*" ]; then
  echo "Rolling back to Agenix..."
  rm -rf .specagentx
  cp -r ../Agenix_backup_*/* .
  echo "Rollback completed"
else
  echo "No backup found!"
  exit 1
fi
```

## 移行後のサポート
- 移行ガイドの作成
- FAQドキュメント
- トラブルシューティングガイド
- コミュニティサポート

---
*この移行計画に従って、Agenixの既存資産を活かしながらSpecAgentXへスムーズに移行します。*