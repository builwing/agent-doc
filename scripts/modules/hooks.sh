#!/usr/bin/env bash
# Git Hooks と GitHub Actions の設定
set -euo pipefail

echo "🔧 Git Hooks と CI/CD を設定中..."

# 1. pre-commit hook - 履歴追記の確認
cat > .git/hooks/pre-commit << 'PRECOMMIT_EOF'
#!/usr/bin/env bash
# 変更されたファイルに対応するAgent履歴の更新を確認
set -euo pipefail

# 変更されたファイルを取得
CHANGED=$(git diff --cached --name-only || true)

if [[ -z "$CHANGED" ]]; then
    exit 0
fi

# 影響を受けるAgentを特定
AFFECTED_AGENTS=""

# API関連の変更
echo "$CHANGED" | grep -E '^(api/|internal/|cmd/|.*\.go$)' >/dev/null 2>&1 && {
    AFFECTED_AGENTS="$AFFECTED_AGENTS api"
}

# Next.js関連の変更
echo "$CHANGED" | grep -E '^(app/|pages/|components/|.*\.(tsx|jsx)$)' >/dev/null 2>&1 && {
    AFFECTED_AGENTS="$AFFECTED_AGENTS next"
}

# Expo関連の変更
echo "$CHANGED" | grep -E '^(mobile/|.*\.native\.|app\.json|app\.config\.)' >/dev/null 2>&1 && {
    AFFECTED_AGENTS="$AFFECTED_AGENTS expo"
}

# インフラ関連の変更
echo "$CHANGED" | grep -E '^(\.github/|docker|nginx/|deploy/)' >/dev/null 2>&1 && {
    AFFECTED_AGENTS="$AFFECTED_AGENTS infra"
}

# テスト関連の変更
echo "$CHANGED" | grep -E '^(test/|spec/|e2e/|.*\.(test|spec)\.)' >/dev/null 2>&1 && {
    AFFECTED_AGENTS="$AFFECTED_AGENTS qa"
}

if [[ -n "$AFFECTED_AGENTS" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 以下のAgentの履歴更新が必要かもしれません:"
    for agent in $AFFECTED_AGENTS; do
        echo "  - $agent"
        HISTORY="docs/agents/$agent/HISTORY.md"
        if [[ -f "$HISTORY" ]]; then
            # 今日の日付が履歴にあるかチェック
            TODAY=$(date +%Y-%m-%d)
            if ! grep -q "$TODAY" "$HISTORY" 2>/dev/null; then
                echo "    ⚠️  今日の作業履歴がありません"
            fi
        fi
    done
    echo ""
    echo "履歴を追加する場合:"
    echo "  ./scripts/agent_log.sh <agent> \"<task>\" \"<refs>\""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    read -p "このまま続行しますか? (y/N): " CONTINUE
    if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
        echo "コミットを中断しました"
        exit 1
    fi
fi

# コミットメッセージに要件への参照があるか確認（推奨）
if [[ -f ".git/COMMIT_EDITMSG" ]]; then
    if ! grep -q "refs docs/agents/" ".git/COMMIT_EDITMSG" 2>/dev/null; then
        echo ""
        echo "💡 ヒント: コミットメッセージに要件への参照を含めることを推奨します"
        echo "  例: refs docs/agents/api/REQUIREMENTS.md#受け入れ基準"
    fi
fi

exit 0
PRECOMMIT_EOF

chmod +x .git/hooks/pre-commit

# 2. commit-msg hook - コミットメッセージの検証
cat > .git/hooks/commit-msg << 'COMMITMSG_EOF'
#!/usr/bin/env bash
# コミットメッセージの形式を検証
set -euo pipefail

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# 基本的なコミットメッセージ形式をチェック
# format: <type>(<scope>): <subject>
# 例: feat(api): add user search endpoint

PATTERN="^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\([a-z]+\))?: .{3,}"

if ! echo "$COMMIT_MSG" | grep -qE "$PATTERN"; then
    echo "❌ コミットメッセージの形式が正しくありません"
    echo ""
    echo "正しい形式:"
    echo "  <type>(<scope>): <subject>"
    echo ""
    echo "type:"
    echo "  feat     : 新機能"
    echo "  fix      : バグ修正"
    echo "  docs     : ドキュメント"
    echo "  style    : フォーマット"
    echo "  refactor : リファクタリング"
    echo "  test     : テスト"
    echo "  chore    : ビルド・補助ツール"
    echo "  perf     : パフォーマンス改善"
    echo ""
    echo "scope: api, next, expo, infra, qa, etc."
    echo ""
    echo "例:"
    echo "  feat(api): add pagination to user search API"
    echo "  fix(next): resolve SSR hydration issue"
    echo "  docs(expo): update push notification setup guide"
    exit 1
fi

# refs docs/agents/ の推奨
if ! echo "$COMMIT_MSG" | grep -q "refs docs/agents/" 2>/dev/null; then
    echo "💡 要件への参照を追加することを推奨します"
    echo "  例: refs docs/agents/api/REQUIREMENTS.md#L30"
fi

exit 0
COMMITMSG_EOF

chmod +x .git/hooks/commit-msg

# 3. GitHub Actions - agent-guard.yml
cat > .github/workflows/agent-guard.yml << 'GITHUB_EOF'
name: SubAgent System Guard

on:
  pull_request:
    branches: [ main, develop ]
  push:
    branches: [ main ]

jobs:
  validate-structure:
    name: Validate SubAgent Structure
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check required files
        run: |
          set -e
          echo "🔍 SubAgent構造を検証中..."
          
          AGENTS="api logic next expo infra qa uiux security docs"
          ERRORS=0
          
          for agent in $AGENTS; do
            echo "Checking $agent..."
            
            # 必須ファイルの確認
            for file in REQUIREMENTS.md CHECKLIST.md HISTORY.md; do
              if [[ ! -f "docs/agents/$agent/$file" ]]; then
                echo "❌ Missing: docs/agents/$agent/$file"
                ERRORS=$((ERRORS + 1))
              fi
            done
          done
          
          if [[ $ERRORS -gt 0 ]]; then
            echo "❌ $ERRORS 個のファイルが不足しています"
            exit 1
          fi
          
          echo "✅ 構造検証完了"

      - name: Check REQUIREMENTS.md format
        run: |
          set -e
          echo "📋 要件定義の形式を確認中..."
          
          for agent in api logic next expo infra qa uiux security docs; do
            REQ="docs/agents/$agent/REQUIREMENTS.md"
            
            # YAMLヘッダーの確認
            if ! grep -q "^agent: $agent" "$REQ"; then
              echo "❌ $REQ: agent フィールドが正しくありません"
              exit 1
            fi
            
            # 必須セクションの確認
            for section in "# 目的" "# スコープ" "# 受け入れ基準"; do
              if ! grep -q "^$section" "$REQ"; then
                echo "❌ $REQ: '$section' セクションがありません"
                exit 1
              fi
            done
          done
          
          echo "✅ 要件定義の形式確認完了"

  check-history-update:
    name: Check History Updates
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    
    steps:
      - name: Checkout PR branch
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get changed files
        id: changed-files
        run: |
          echo "📝 変更されたファイルを取得中..."
          CHANGED=$(git diff --name-only origin/${{ github.base_ref }}...HEAD)
          echo "CHANGED<<EOF" >> $GITHUB_ENV
          echo "$CHANGED" >> $GITHUB_ENV
          echo "EOF" >> $GITHUB_ENV

      - name: Check if history needs update
        run: |
          set -e
          AFFECTED=""
          
          # 各Agentの領域をチェック
          echo "$CHANGED" | grep -E '^(api/|internal/|cmd/)' && AFFECTED="$AFFECTED api" || true
          echo "$CHANGED" | grep -E '^(app/|pages/|components/)' && AFFECTED="$AFFECTED next" || true
          echo "$CHANGED" | grep -E '^(mobile/|.*\.native\.)' && AFFECTED="$AFFECTED expo" || true
          echo "$CHANGED" | grep -E '^(infra/|deploy/|\.github/)' && AFFECTED="$AFFECTED infra" || true
          echo "$CHANGED" | grep -E '^(test/|e2e/|spec/)' && AFFECTED="$AFFECTED qa" || true
          
          if [[ -n "$AFFECTED" ]]; then
            echo "📋 影響を受けるAgent: $AFFECTED"
            
            for agent in $AFFECTED; do
              HISTORY="docs/agents/$agent/HISTORY.md"
              
              # HISTORYファイルが更新されているか確認
              if ! echo "$CHANGED" | grep -q "$HISTORY"; then
                echo "⚠️  Warning: $agent の履歴が更新されていません"
                echo "::warning file=$HISTORY::このAgentの領域が変更されていますが、履歴が更新されていません"
              fi
            done
          fi

  lint-prompts:
    name: Validate System Prompts
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Check PM prompts
        run: |
          set -e
          echo "🤖 Systemプロンプトを検証中..."
          
          # PMプロンプトの確認
          if [[ ! -f ".claude/.claude/pm/prompts/pm_system.txt" ]]; then
            echo "❌ PM system prompt not found"
            exit 1
          fi
          
          # 各Agentプロンプトの確認
          for agent in api next expo; do
            PROMPT=".claude/.claude/pm/prompts/subagent_system/$agent.txt"
            if [[ ! -f "$PROMPT" ]]; then
              echo "⚠️  Warning: $PROMPT not found"
            fi
          done
          
          echo "✅ プロンプト検証完了"

  security-check:
    name: Security Check
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Check for secrets
        run: |
          set -e
          echo "🔒 セキュリティチェック中..."
          
          # APIキーやトークンのパターンをチェック
          PATTERNS=(
            "api[_-]?key"
            "secret"
            "token"
            "password"
            "private[_-]?key"
          )
          
          for pattern in "${PATTERNS[@]}"; do
            if git grep -i "$pattern" -- '*.md' '*.txt' '*.json' | grep -v "REQUIREMENTS\|CHECKLIST\|example\|template"; then
              echo "⚠️  Warning: 機密情報の可能性がある文字列が検出されました"
            fi
          done
          
          echo "✅ セキュリティチェック完了"
GITHUB_EOF

# 4. .gitignore の更新
cat >> .gitignore << 'GITIGNORE_EOF'

# SubAgent System
.claude/.claude/pm/logs/*.json
.claude/.claude/pm/logs/*.log
.agent-cache/
*.agent.tmp

# 環境固有
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo
GITIGNORE_EOF

echo "✅ Git Hooks と CI/CD の設定が完了しました！"
echo ""
echo "🎉 基礎構築Phase 1 が完了しました！"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "セットアップ完了内容:"
echo ""
echo "📁 ディレクトリ構造:"
echo "  - docs/agents/*    : 各Agent用ドキュメント"
echo "  - .claude/pm/*            : PM設定とプロンプト"
echo "  - scripts/*       : 管理スクリプト"
echo ""
echo "🔧 Git Hooks:"
echo "  - pre-commit      : 履歴更新の確認"
echo "  - commit-msg      : メッセージ形式検証"
echo ""
echo "🚀 GitHub Actions:"
echo "  - agent-guard.yml : 構造と品質の自動検証"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 次のステップ:"
echo ""
echo "1. テスト実行:"
echo "   ./scripts/pm_validate.sh"
echo ""
echo "2. タスクの振り分けテスト:"
echo "   ./scripts/pm_dispatch.sh \"ユーザー検索APIを作成\""
echo ""
echo "3. Agent実行テスト:"
echo "   ./scripts/agent_start.sh api \"ユーザー検索API作成\""
echo ""
echo "4. 履歴記録テスト:"
echo "   ./scripts/agent_log.sh api \"テストタスク\" \"REQUIREMENTS.md#L1\""
echo ""
echo "Phase 2（自動化）の準備ができたら教えてください！"