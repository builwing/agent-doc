#!/usr/bin/env bash
# PMエージェント自動起動・タスク振り分けスクリプト
set -euo pipefail

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# 設定
HOOKS_DIR=".claude/hooks"
DISPATCHER_SCRIPT="$HOOKS_DIR/task-dispatcher.py"
LAST_DISPATCH_FILE="$HOOKS_DIR/last_dispatch.json"
AGENTS_DIR=".claude/agents"
PM_AGENT="$AGENTS_DIR/pm.md"

# ヘルプ表示
show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 PMエージェント自動振り分けシステム
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

使用方法: ./scripts/core/pm_auto_dispatch.sh "タスクの説明"

例:
    # API開発タスク
    ./scripts/core/pm_auto_dispatch.sh "ユーザー認証APIを実装"
    
    # フロントエンド開発
    ./scripts/core/pm_auto_dispatch.sh "ログイン画面を作成"
    
    # 複合タスク
    ./scripts/core/pm_auto_dispatch.sh "ユーザー管理機能を実装（API、画面、テスト含む）"

オプション:
    -h, --help          このヘルプを表示
    -v, --verbose       詳細な出力
    -d, --dry-run       実行計画の表示のみ（実際には実行しない）
    -f, --force         確認なしで実行

機能:
    1. タスクの内容を解析
    2. 適切なエージェントを自動選択
    3. 複雑なタスクはPMエージェントが調整
    4. 単純なタスクは直接エージェントへ
EOF
}

# 引数解析
TASK_DESCRIPTION=""
VERBOSE=false
DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            TASK_DESCRIPTION="$1"
            shift
            ;;
    esac
done

# タスクが指定されていない場合
if [[ -z "$TASK_DESCRIPTION" ]]; then
    echo -e "${RED}エラー: タスクの説明を指定してください${NC}"
    echo ""
    show_help
    exit 1
fi

# Pythonの存在確認
check_python() {
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}エラー: Python3が見つかりません${NC}"
        echo -e "${YELLOW}インストール: brew install python3${NC}"
        exit 1
    fi
}

# ディスパッチャーの存在確認
check_dispatcher() {
    if [[ ! -f "$DISPATCHER_SCRIPT" ]]; then
        echo -e "${RED}エラー: タスクディスパッチャーが見つかりません${NC}"
        echo -e "${YELLOW}セットアップを実行してください:${NC}"
        echo "  ./scripts/core/setup_pm_hooks.sh"
        exit 1
    fi
}

# タスク解析
analyze_task() {
    echo -e "${BLUE}🔍 タスクを解析中...${NC}"
    echo ""
    
    # Pythonディスパッチャーを実行
    local output=$(python3 "$DISPATCHER_SCRIPT" "$TASK_DESCRIPTION" 2>&1)
    
    # 詳細モードの場合は全出力を表示
    if [[ "$VERBOSE" == true ]]; then
        echo "$output"
    else
        # 通常モードでは主要な情報のみ表示
        echo "$output" | grep -E "^(🤖|📝|🔍|📋|💡)" || echo "$output"
    fi
    
    echo ""
}

# 実行計画の取得
get_execution_plan() {
    if [[ ! -f "$LAST_DISPATCH_FILE" ]]; then
        echo -e "${RED}エラー: 実行計画が生成されていません${NC}"
        exit 1
    fi
    
    # JSONから主要な情報を抽出
    local primary_agent=$(python3 -c "
import json
with open('$LAST_DISPATCH_FILE', 'r') as f:
    data = json.load(f)
    print(data['task_info']['primary_agent'])
")
    
    local requires_pm=$(python3 -c "
import json
with open('$LAST_DISPATCH_FILE', 'r') as f:
    data = json.load(f)
    print('true' if data['task_info']['requires_pm'] else 'false')
")
    
    local related_agents=$(python3 -c "
import json
with open('$LAST_DISPATCH_FILE', 'r') as f:
    data = json.load(f)
    print(' '.join(data['task_info']['related_agents']))
")
    
    echo "$primary_agent|$requires_pm|$related_agents"
}

# エージェント用プロンプトの生成
generate_agent_prompt() {
    local agent="$1"
    local task="$2"
    local is_pm="$3"
    
    local prompt=""
    
    if [[ "$is_pm" == "true" ]]; then
        prompt="# PMエージェントによるタスク管理

## タスク
$task

## 実行指示
1. このタスクを分析し、必要なサブタスクに分解してください
2. 各サブタスクを適切なエージェントに割り当ててください
3. TodoWriteツールを使用して進捗を管理してください
4. 各エージェントの成果物を統合してください

## 関連エージェント
$(cat "$LAST_DISPATCH_FILE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for agent in data['task_info']['related_agents']:
    print(f'- {agent}')
")

## 参照ドキュメント
- REQUIREMENTS.md: ビジネス要件
- SPECIFICATIONS.md: 技術仕様
- AGENT_DEFINITIONS.md: エージェント定義
"
    else
        prompt="# ${agent}エージェントタスク

## タスク
$task

## 実行指示
1. SPECIFICATIONS.mdの技術仕様に従って実装してください
2. テストを作成してください
3. ドキュメントを更新してください

## 技術スタック
$(grep -A 10 "### .* ${agent}" SPECIFICATIONS.md 2>/dev/null | head -15 || echo "SPECIFICATIONS.md参照")

## 注意事項
- OpenAPI仕様に準拠すること（API関連の場合）
- エラーハンドリングを適切に実装すること
- generated/ディレクトリは編集禁止
"
    fi
    
    echo "$prompt"
}

# 実行確認
confirm_execution() {
    local agent="$1"
    local is_pm="$2"
    
    if [[ "$FORCE" == true ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}実行確認${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [[ "$is_pm" == "true" ]]; then
        echo -e "PMエージェントがタスクを調整します"
    else
        echo -e "${agent}エージェントが直接実行します"
    fi
    
    echo ""
    read -p "実行しますか？ (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}キャンセルしました${NC}"
        exit 0
    fi
}

# エージェントの実行
execute_agent() {
    local agent="$1"
    local task="$2"
    local is_pm="$3"
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🚀 エージェント実行${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # プロンプトを生成
    local prompt=$(generate_agent_prompt "$agent" "$task" "$is_pm")
    
    # プロンプトをファイルに保存
    local prompt_file="/tmp/claude_agent_prompt_$$.md"
    echo "$prompt" > "$prompt_file"
    
    echo -e "${CYAN}生成されたプロンプト:${NC}"
    echo "----------------------------------------"
    echo "$prompt"
    echo "----------------------------------------"
    echo ""
    
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}[DRY RUN] 実際の実行はスキップされました${NC}"
        rm -f "$prompt_file"
        return 0
    fi
    
    echo -e "${MAGENTA}💡 推奨される使用方法:${NC}"
    echo ""
    
    if [[ "$is_pm" == "true" ]]; then
        echo "1. ClaudeCodeで以下のように入力:"
        echo "   「PMエージェントを使用して以下のタスクを管理してください」"
        echo ""
        echo "2. 上記のプロンプトをコピー＆ペースト"
        echo ""
        echo "3. PMエージェントがタスクを分解し、各エージェントに振り分けます"
    else
        echo "1. ClaudeCodeで以下のように入力:"
        echo "   「${agent}エージェントを使用して以下を実行してください」"
        echo ""
        echo "2. 上記のプロンプトをコピー＆ペースト"
        echo ""
        echo "3. ${agent}エージェントが直接タスクを実行します"
    fi
    
    echo ""
    echo -e "${CYAN}プロンプトは以下に保存されました:${NC}"
    echo "  $prompt_file"
    echo ""
    echo -e "${YELLOW}注: 現在のバージョンではClaudeCodeへの自動入力はサポートされていません${NC}"
    echo -e "${YELLOW}    上記の手順に従って手動で実行してください${NC}"
    
    # 履歴に記録
    record_dispatch_history "$agent" "$task" "$is_pm"
}

# 振り分け履歴の記録
record_dispatch_history() {
    local agent="$1"
    local task="$2"
    local is_pm="$3"
    
    local history_file=".claude/hooks/dispatch_history.log"
    mkdir -p "$(dirname "$history_file")"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local entry="[$timestamp] Agent: $agent, PM: $is_pm, Task: $task"
    
    echo "$entry" >> "$history_file"
    
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${CYAN}履歴に記録: $entry${NC}"
    fi
}

# メイン処理
main() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🤖 PMエージェント自動振り分けシステム${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # 前提条件の確認
    check_python
    check_dispatcher
    
    # タスクの解析
    analyze_task
    
    # 実行計画の取得
    IFS='|' read -r primary_agent requires_pm related_agents <<< "$(get_execution_plan)"
    
    # 実行確認
    confirm_execution "$primary_agent" "$requires_pm"
    
    # エージェントの実行
    execute_agent "$primary_agent" "$TASK_DESCRIPTION" "$requires_pm"
    
    echo ""
    echo -e "${GREEN}✅ タスク振り分け完了${NC}"
    echo ""
    echo -e "${CYAN}次のステップ:${NC}"
    echo "1. 生成されたプロンプトをClaudeCodeで使用"
    echo "2. エージェントの実行結果を確認"
    echo "3. 必要に応じて追加のタスクを振り分け"
}

# 実行
main