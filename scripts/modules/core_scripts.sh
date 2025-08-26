#!/usr/bin/env bash
# SubAgentシステムのコアスクリプト群をインストール
set -euo pipefail

echo "📦 コアスクリプト群をインストール中..."

# 1. agent_scaffold.sh - 新規Agent作成用
cat > scripts/agent_scaffold.sh << 'SCAFFOLD_EOF'
#!/usr/bin/env bash
# 新しいAgentの雛形を作成
set -euo pipefail

AGENT="${1:-}"
[[ -z "$AGENT" ]] && {
    echo "使用方法: $0 <agent-name>"
    echo "利用可能: api, logic, next, expo, infra, qa, uiux, security, docs"
    exit 1
}

DIR="docs/agents/$AGENT"

if [[ -d "$DIR" ]]; then
    echo "⚠️  $DIR は既に存在します"
    read -p "上書きしますか? (y/N): " confirm
    [[ "$confirm" != "y" ]] && exit 0
fi

mkdir -p "$DIR"
echo "📁 $DIR を作成中..."

# テンプレートファイルを作成
cp docs/agents/api/REQUIREMENTS.md "$DIR/REQUIREMENTS.md" 2>/dev/null || {
    echo "エラー: テンプレートが見つかりません。先に scripts/setup.sh を実行してください"
    exit 1
}

# agent名を更新
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/agent: api/agent: $AGENT/g" "$DIR/REQUIREMENTS.md"
else
    sed -i "s/agent: api/agent: $AGENT/g" "$DIR/REQUIREMENTS.md"
fi

echo "✅ $AGENT Agent の雛形を作成しました"
echo "📝 次のファイルを編集してください:"
echo "   - $DIR/REQUIREMENTS.md"
echo "   - $DIR/CHECKLIST.md"
SCAFFOLD_EOF

# 2. agent_start.sh - Agent実行前の要件確認
cat > scripts/agent_start.sh << 'START_EOF'
#!/usr/bin/env bash
# Agentの実行前に要件を確認
set -euo pipefail

AGENT="${1:-}"
TASK="${2:-}"

[[ -z "$AGENT" || -z "$TASK" ]] && {
    echo "使用方法: $0 <agent> <task-summary>"
    exit 1
}

REQ="docs/agents/$AGENT/REQUIREMENTS.md"
CHK="docs/agents/$AGENT/CHECKLIST.md"

[[ -f "$REQ" ]] || {
    echo "❌ $REQ が見つかりません"
    echo "先に scripts/agent_scaffold.sh $AGENT を実行してください"
    exit 1
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 $AGENT Agent 起動準備"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 タスク: $TASK"
echo ""
echo "📄 要件定義の要約:"
echo "---"
# YAMLヘッダーの後から要約を表示
awk '/^---$/,/^---$/{next} /^#/{print} /^- /{print}' "$REQ" | head -20
echo "---"
echo ""

if [[ -f "$CHK" ]]; then
    echo "✅ チェックリスト確認:"
    echo "---"
    grep "^- \[" "$CHK" | head -5
    echo "---"
    echo ""
fi

echo "⚠️  重要: 上記の要件を確認してから作業を開始してください"
echo ""
echo "🚀 実行計画:"
echo "1. 要件定義（$REQ）を完全に読む"
echo "2. チェックリスト（$CHK）の前提条件を確認"
echo "3. 実装計画を作成（根拠を明記）"
echo "4. 実装/提案を行う"
echo "5. HISTORY.mdに記録する"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
START_EOF

# 3. agent_log.sh - 作業履歴の記録
cat > scripts/agent_log.sh << 'LOG_EOF'
#!/usr/bin/env bash
# Agent作業履歴を記録
set -euo pipefail

AGENT="${1:-}"
TASK="${2:-}"
REFS="${3:-}"
COMMITS="${4:-}"
NOTES="${5:-}"

[[ -z "$AGENT" || -z "$TASK" ]] && {
    echo "使用方法: $0 <agent> <task> [refs] [commits] [notes]"
    echo "例: $0 api \"ユーザー検索API追加\" \"REQUIREMENTS.md#L30\" \"abc123,def456\" \"p95<200ms達成\""
    exit 1
}

HISTORY="docs/agents/$AGENT/HISTORY.md"
[[ -f "$HISTORY" ]] || {
    echo "❌ $HISTORY が見つかりません"
    exit 1
}

TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S%z")
USER="${USER:-unknown}"

# 履歴エントリを追加
{
    echo ""
    echo "## $TIMESTAMP by $AGENT"
    echo "- task: \"$TASK\""
    [[ -n "$REFS" ]] && {
        echo "- refs:"
        IFS=',' read -ra REF_ARRAY <<< "$REFS"
        for ref in "${REF_ARRAY[@]}"; do
            echo "  - $ref"
        done
    }
    [[ -n "$COMMITS" ]] && {
        echo "- commits:"
        IFS=',' read -ra COMMIT_ARRAY <<< "$COMMITS"
        for commit in "${COMMIT_ARRAY[@]}"; do
            echo "  - $commit"
        done
    }
    [[ -n "$NOTES" ]] && {
        echo "- notes:"
        echo "  - $NOTES"
    }
    echo ""
} >> "$HISTORY"

echo "✅ 履歴を記録しました: $HISTORY"
echo "📝 記録内容:"
tail -15 "$HISTORY"
LOG_EOF

# 4. pm_dispatch.sh - PM経由でタスクを振り分け
cat > scripts/pm_dispatch.sh << 'DISPATCH_EOF'
#!/usr/bin/env bash
# PMによるタスク振り分け
set -euo pipefail

MESSAGE="${1:-}"
[[ -z "$MESSAGE" ]] && {
    echo "使用方法: $0 \"<タスク内容>\""
    echo "例: $0 \"ユーザー検索APIにページング機能を追加\""
    exit 1
}

echo "🎯 PM: タスク分析中..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 簡易的なキーワードマッチング（実際はLLMを使用）
ROUTE=""
CONFIDENCE=0.8

# registry.jsonからキーワードを読み込んで判定
if echo "$MESSAGE" | grep -iE "API|Go-Zero|endpoint|REST" >/dev/null; then
    ROUTE="api"
elif echo "$MESSAGE" | grep -iE "Next\.js|SSR|React|web|frontend" >/dev/null; then
    ROUTE="next"
elif echo "$MESSAGE" | grep -iE "Expo|React Native|mobile|iOS|Android" >/dev/null; then
    ROUTE="expo"
elif echo "$MESSAGE" | grep -iE "test|テスト|E2E|unit" >/dev/null; then
    ROUTE="qa"
elif echo "$MESSAGE" | grep -iE "security|JWT|auth|認証" >/dev/null; then
    ROUTE="security"
elif echo "$MESSAGE" | grep -iE "nginx|docker|CI/CD|deploy" >/dev/null; then
    ROUTE="infra"
elif echo "$MESSAGE" | grep -iE "UI|UX|design|デザイン" >/dev/null; then
    ROUTE="uiux"
elif echo "$MESSAGE" | grep -iE "document|ドキュメント|README" >/dev/null; then
    ROUTE="docs"
elif echo "$MESSAGE" | grep -iE "ビジネス|業務|ドメイン" >/dev/null; then
    ROUTE="logic"
else
    ROUTE="human_review"
    CONFIDENCE=0.3
fi

# 結果をJSON形式で出力
RESULT=$(cat << JSON
{
  "route": "$ROUTE",
  "reason": "キーワードマッチングによる判定",
  "confidence": $CONFIDENCE,
  "normalized_task": "$MESSAGE",
  "required_docs": [
    "docs/agents/$ROUTE/REQUIREMENTS.md",
    "docs/agents/$ROUTE/CHECKLIST.md"
  ],
  "timestamp": "$(date -Iseconds)"
}
JSON
)

echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ログに記録
LOG_FILE=".claude/.claude/pm/logs/$(date +%Y%m%d).json"
mkdir -p .claude/.claude/pm/logs
echo "$RESULT" >> "$LOG_FILE"

# 判定結果に基づくアクション
if [[ "$ROUTE" == "human_review" ]]; then
    echo "⚠️  人間によるレビューが必要です"
    echo "理由: 信頼度が低い ($CONFIDENCE < 0.6)"
else
    echo "✅ 振り分け先: $ROUTE Agent"
    echo ""
    echo "次のコマンドを実行してください:"
    echo "  ./scripts/agent_start.sh $ROUTE \"$MESSAGE\""
fi
DISPATCH_EOF

# 5. pm_validate.sh - 要件と履歴の整合性チェック
cat > scripts/pm_validate.sh << 'VALIDATE_EOF'
#!/usr/bin/env bash
# 要件定義と履歴の整合性をチェック
set -euo pipefail

echo "🔍 SubAgentシステムの検証を開始..."
echo ""

ERRORS=0
WARNINGS=0

# 各Agentをチェック
for agent in api logic next expo infra qa uiux security docs; do
    DIR="docs/agents/$agent"
    
    if [[ ! -d "$DIR" ]]; then
        echo "⚠️  WARNING: $DIR が存在しません"
        ((WARNINGS++))
        continue
    fi
    
    # 必須ファイルの確認
    for file in REQUIREMENTS.md CHECKLIST.md HISTORY.md; do
        if [[ ! -f "$DIR/$file" ]]; then
            echo "❌ ERROR: $DIR/$file が見つかりません"
            ((ERRORS++))
        fi
    done
    
    # REQUIREMENTS.mdの更新日確認
    if [[ -f "$DIR/REQUIREMENTS.md" ]]; then
        LAST_UPDATE=$(grep "last_updated:" "$DIR/REQUIREMENTS.md" 2>/dev/null | cut -d: -f2 | xargs)
        if [[ -n "$LAST_UPDATE" ]]; then
            # 30日以上前なら警告
            if [[ "$OSTYPE" == "darwin"* ]]; then
                DAYS_AGO=$(( ($(date +%s) - $(date -j -f "%Y-%m-%d" "$LAST_UPDATE" +%s)) / 86400 ))
            else
                DAYS_AGO=$(( ($(date +%s) - $(date -d "$LAST_UPDATE" +%s)) / 86400 ))
            fi
            
            if [[ $DAYS_AGO -gt 30 ]]; then
                echo "⚠️  WARNING: $agent の要件定義が $DAYS_AGO 日前から更新されていません"
                ((WARNINGS++))
            fi
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "検証結果:"
echo "  エラー: $ERRORS"
echo "  警告: $WARNINGS"

if [[ $ERRORS -gt 0 ]]; then
    echo "❌ エラーを修正してください"
    exit 1
else
    echo "✅ 検証完了"
fi
VALIDATE_EOF

# スクリプトに実行権限を付与
chmod +x scripts/*.sh

echo "✅ コアスクリプトのインストールが完了しました！"
echo ""
echo "📝 作成されたスクリプト:"
echo "  - scripts/agent_scaffold.sh  : 新規Agent作成"
echo "  - scripts/agent_start.sh      : Agent実行前確認"
echo "  - scripts/agent_log.sh        : 履歴記録"
echo "  - scripts/pm_dispatch.sh      : タスク振り分け"
echo "  - scripts/pm_validate.sh      : システム検証"
echo ""
echo "次のステップ: ./scripts/install_pm_prompts.sh を実行してください"