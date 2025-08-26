# 🔍 Agentixプロジェクト検証レポート

## 📋 エグゼクティブサマリー

プロジェクト全体の徹底的な検証により、以下の主要な問題を特定しました：

1. **スクリプトの重複**: 29個中11個が機能重複または廃止候補
2. **パス不整合**: `.claude/pm/` vs `pm/` vs `.claude/.claude/pm/`の混在
3. **実装の不完全性**: 複数のスクリプトが未完成または簡易実装
4. **ドキュメントとの不一致**: README.mdに記載されていない機能あり

## 🚨 発見された矛盾点

### 1. ディレクトリパスの不整合

| スクリプト | 使用パス | 正しいパス |
|-----------|---------|-----------|
| `setup.sh` | `pm/` | `.claude/pm/` |
| `install_pm_prompts.sh` | `.claude/.claude/pm/` ❌ | `.claude/pm/` |
| `update_pm_context7.sh` | `.claude/pm/` ✅ | `.claude/pm/` |
| `migrate_pm_to_claude.sh` | `.claude/pm/` ✅ | `.claude/pm/` |

**影響**: PMの設定ファイルが異なる場所に作成され、エージェントが正しく動作しない

### 2. registry.json形式の不一致

**setup.sh版**:
```json
{
  "agents": [
    {"id": "api", "priority": 1}
  ]
}
```

**migrate_pm_to_claude.sh版**:
```json
{
  "agents": {
    "api": {"priority": "high"}
  }
}
```

**影響**: エージェント登録の解析エラー

### 3. エージェント生成の重複

| スクリプト | 作成場所 | 形式 |
|-----------|---------|------|
| `setup_default_agents.sh` | `.claude/agents/*.md` | YAMLフロントマター |
| `setup_agent.sh` | `docs/agents/*/` | ディレクトリ構造 |
| `generate_agents_from_requirements.sh` | 両方 | 統合形式 |

**影響**: どのスクリプトを使うべきか不明確

## 🗑️ 削除推奨スクリプト

### 即座に削除可能（重複・廃止）

1. **`fix_pm_paths.sh`**
   - 理由: `migrate_pm_to_claude.sh`と機能重複
   - 代替: `migrate_pm_to_claude.sh`

2. **`setup_agent.sh`**
   - 理由: `docs/agents/`のみ作成（不完全）
   - 代替: `generate_agents_from_requirements.sh`

3. **`pm_register_agent.sh`**
   - 理由: 実装不完全（jqコメントアウト）
   - 代替: なし（機能未使用）

4. **`create-requirements.sh`**
   - 理由: Node.js依存で複雑、未完成
   - 代替: 手動でREQUIREMENTS.md作成

5. **`setup_requirements_agent.sh`**
   - 理由: Node.jsアプローチ、メインフローと不一致
   - 代替: `generate_agents_from_requirements.sh`

### 統合推奨（機能移行後削除）

6. **`setup_default_agents.sh`**
   - 理由: `setup.sh`に統合可能
   - 移行先: `setup.sh`内で実行

7. **`migrate_pm_to_claude.sh`**
   - 理由: 一度実行すれば不要
   - 保持期間: マイグレーション完了まで

### 簡素化推奨

8. **`install_auto_testing.sh`**
   - 理由: 630行の巨大スクリプト、使用頻度低い
   - 対応: 基本機能のみに縮小

9. **`install_cordination.sh`**
   - 理由: 実装が複雑すぎる
   - 対応: 必要時に再設計

## ✅ 修正が必要な箇所

### 1. install_pm_prompts.sh の修正

```bash
# 現在（8行目）
cat > .claude/.claude/pm/prompts/pm_system.txt << 'PM_EOF'

# 修正後
cat > .claude/pm/prompts/pm_system.txt << 'PM_EOF'
```

### 2. setup.sh の修正

```bash
# 現在（17行目）
mkdir -p pm/{prompts/subagent_system,logs}

# 修正後
mkdir -p .claude/pm/{prompts/subagent_system,logs}
```

### 3. README.md に未記載の機能

以下がREADME.mdに記載されていません：
- `create-requirements.sh`
- `fix_pm_paths.sh`
- `migrate_pm_to_claude.sh`
- `pm_register_agent.sh`
- `setup_agent.sh`
- `setup_requirements_agent.sh`

## 📊 推奨アクション

### Phase 1: 即座の対応（優先度: 高）

1. **パス統一**
   ```bash
   # 修正スクリプトの作成
   ./scripts/fix_all_paths.sh
   ```

2. **重複スクリプトの削除**
   ```bash
   rm scripts/fix_pm_paths.sh
   rm scripts/setup_agent.sh
   rm scripts/pm_register_agent.sh
   rm scripts/create-requirements.sh
   rm scripts/setup_requirements_agent.sh
   ```

3. **install_pm_prompts.sh の修正**
   - `.claude/.claude/` → `.claude/` に統一

### Phase 2: 統合と簡素化（優先度: 中）

1. **setup系の統合**
   - `setup.sh`に`setup_default_agents.sh`を統合

2. **install系の整理**
   - 基本的な4つのみ保持
   - 高度な機能は別リポジトリへ

### Phase 3: ドキュメント更新（優先度: 低）

1. **README.md の更新**
   - 削除したスクリプトの記載を削除
   - 実際の構造と一致させる

2. **MIGRATION_GUIDE.md の作成**
   - 古いバージョンからの移行手順

## 🎯 最終的なスクリプト構成（推奨）

### コアスクリプト（必須）
- `setup.sh` - 初期セットアップ（統合版）
- `generate_agents_from_requirements.sh` - エージェント生成
- `update_requirements.sh` - 要件管理
- `update_pm_context7.sh` - Context7設定
- `integrate_to_existing.sh` - 既存プロジェクト統合
- `reset_to_initial.sh` - リセット

### カスタマイズ（オプション）
- `setup_custom_agents.sh` - カスタムエージェント
- `generate_claude_md.sh` - CLAUDE.md生成
- `setup_project_structure.sh` - プロジェクト構造

### 基本拡張（オプション）
- `install_scripts.sh` - PMスクリプト
- `install_pm_prompts.sh` - プロンプト設定（修正版）
- `install_hooks.sh` - Git Hooks
- `install_mcp_tools.sh` - MCPツール

### 高度な拡張（別管理推奨）
- `install_llm_router.sh`
- `install_metrics.sh`
- `install_multi_llm.sh`
- `install_rag_system.sh`
- `install_realtime_dashboard.sh`

## 🔧 修正スクリプトの提案

```bash
#!/usr/bin/env bash
# cleanup_and_fix.sh - プロジェクトのクリーンアップと修正

echo "🧹 Agentixプロジェクトのクリーンアップを開始..."

# 1. 不要なスクリプトの削除
SCRIPTS_TO_DELETE=(
    "scripts/fix_pm_paths.sh"
    "scripts/setup_agent.sh"
    "scripts/pm_register_agent.sh"
    "scripts/create-requirements.sh"
    "scripts/setup_requirements_agent.sh"
)

for script in "${SCRIPTS_TO_DELETE[@]}"; do
    if [ -f "$script" ]; then
        rm "$script"
        echo "✅ 削除: $script"
    fi
done

# 2. パスの修正
if [ -f "scripts/install_pm_prompts.sh" ]; then
    sed -i.bak 's|\.claude/\.claude/|.claude/|g' scripts/install_pm_prompts.sh
    echo "✅ install_pm_prompts.sh のパスを修正"
fi

if [ -f "scripts/setup.sh" ]; then
    sed -i.bak 's|mkdir -p pm/|mkdir -p .claude/pm/|g' scripts/setup.sh
    echo "✅ setup.sh のパスを修正"
fi

# 3. pmディレクトリの統合
if [ -d "pm" ] && [ ! -d ".claude/pm" ]; then
    mkdir -p .claude
    mv pm .claude/
    echo "✅ pm/ を .claude/pm/ に移動"
fi

echo "🎉 クリーンアップ完了！"
```

## 結論

現在のプロジェクトは機能的ですが、以下の改善により更に堅牢になります：

1. **29個 → 18個**のスクリプトに削減
2. **パス統一**により設定の一貫性確保
3. **重複排除**により保守性向上
4. **ドキュメント更新**により透明性確保

これらの対応により、Agentixはよりクリーンで保守しやすいシステムになります。