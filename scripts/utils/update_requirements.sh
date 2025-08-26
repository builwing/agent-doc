#!/usr/bin/env bash
# 要件定義の変更管理・再生成スクリプト
set -euo pipefail

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# 設定
REQUIREMENTS_FILE="REQUIREMENTS.md"
CHANGE_LOG=".requirements_changes.log"
AGENTS_DIR=".claude/agents"
DOCS_DIR="docs/agents"

# ヘルプ表示
show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 要件変更管理・再生成システム
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

使用方法: ./scripts/update_requirements.sh [オプション] [コマンド]

コマンド:
    check       要件定義書の変更をチェック
    update      変更を検出して自動更新
    diff        前回からの変更内容を表示
    rollback    前回の状態にロールバック
    history     変更履歴を表示
    sync        すべてのエージェントを同期

オプション:
    -a, --agent AGENT   特定のエージェントのみ更新
    -m, --message MSG   変更理由をメッセージとして記録
    -f, --force         強制的に再生成
    -b, --backup        バックアップを作成
    -h, --help          このヘルプを表示

例:
    # 変更をチェック
    ./scripts/update_requirements.sh check

    # 変更を検出して自動更新
    ./scripts/update_requirements.sh update -m "API仕様を追加"

    # 特定のエージェントのみ更新
    ./scripts/update_requirements.sh update -a api

    # 前回の状態にロールバック
    ./scripts/update_requirements.sh rollback

ワークフロー:
    1. 要件定義書の変更を検出
    2. 影響を受けるエージェントを特定
    3. 該当エージェントの設定を更新
    4. 変更履歴を記録
    5. 通知を生成
EOF
}

# 引数解析
COMMAND=""
SPECIFIC_AGENT=""
CHANGE_MESSAGE=""
FORCE_MODE=false
BACKUP_MODE=false

# コマンドを先に取得
if [[ $# -gt 0 ]] && [[ ! "$1" =~ ^- ]]; then
    COMMAND="$1"
    shift
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--agent)
            SPECIFIC_AGENT="$2"
            shift 2
            ;;
        -m|--message)
            CHANGE_MESSAGE="$2"
            shift 2
            ;;
        -f|--force)
            FORCE_MODE=true
            shift
            ;;
        -b|--backup)
            BACKUP_MODE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            if [[ -z "$COMMAND" ]]; then
                COMMAND="$1"
            else
                echo -e "${RED}不明な引数: $1${NC}"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# デフォルトコマンド
if [[ -z "$COMMAND" ]]; then
    COMMAND="check"
fi

# 変更チェック
check_changes() {
    echo -e "${BLUE}🔍 要件定義書の変更をチェック中...${NC}"
    
    local hash_file=".requirements_hash"
    local current_hash=$(md5sum "$REQUIREMENTS_FILE" 2>/dev/null | cut -d' ' -f1)
    
    if [[ -z "$current_hash" ]]; then
        echo -e "${RED}エラー: 要件定義書が見つかりません${NC}"
        exit 1
    fi
    
    if [[ -f "$hash_file" ]]; then
        local previous_hash=$(cat "$hash_file")
        
        if [[ "$current_hash" == "$previous_hash" ]]; then
            echo -e "${GREEN}✅ 要件定義書に変更はありません${NC}"
            return 1
        else
            echo -e "${YELLOW}⚠️  要件定義書が変更されています${NC}"
            
            # 変更された部分を特定
            if [[ -f ".requirements_backup" ]]; then
                echo -e "\n${CYAN}変更内容:${NC}"
                diff -u ".requirements_backup" "$REQUIREMENTS_FILE" | head -20 || true
            fi
            
            return 0
        fi
    else
        echo -e "${YELLOW}初回実行です。ハッシュを記録します。${NC}"
        echo "$current_hash" > "$hash_file"
        cp "$REQUIREMENTS_FILE" ".requirements_backup"
        return 1
    fi
}

# 影響分析
analyze_impact() {
    echo -e "${BLUE}📊 影響分析を実行中...${NC}"
    
    local affected_agents=()
    
    # 変更内容から影響を受けるエージェントを特定
    if [[ -f ".requirements_backup" ]]; then
        local diff_output=$(diff -u ".requirements_backup" "$REQUIREMENTS_FILE" 2>/dev/null || true)
        
        # エージェント名を検索
        for agent in requirements pm api logic next expo infra qa uiux security docs setup; do
            if echo "$diff_output" | grep -qi "$agent"; then
                affected_agents+=("$agent")
            fi
        done
    fi
    
    if [[ ${#affected_agents[@]} -gt 0 ]]; then
        echo -e "${YELLOW}影響を受けるエージェント:${NC}"
        for agent in "${affected_agents[@]}"; do
            echo "  • $agent"
        done
    else
        echo -e "${CYAN}全体的な変更として扱います${NC}"
        affected_agents=(requirements pm api logic next expo infra qa uiux security docs setup)
    fi
    
    echo "${affected_agents[@]}"
}

# エージェント更新
update_agents() {
    local agents="$1"
    
    echo -e "${BLUE}🔄 エージェントを更新中...${NC}"
    
    # バックアップ作成
    if [[ "$BACKUP_MODE" == true ]]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        mkdir -p .backup
        
        if [[ -d "$AGENTS_DIR" ]]; then
            cp -r "$AGENTS_DIR" ".backup/agents_${timestamp}"
        fi
        
        if [[ -d "$DOCS_DIR" ]]; then
            cp -r "$DOCS_DIR" ".backup/docs_agents_${timestamp}"
        fi
        
        echo -e "${GREEN}✅ バックアップ作成完了${NC}"
    fi
    
    # generate_agents_from_requirements.sh を使用して更新
    if [[ -f "scripts/generate_agents_from_requirements.sh" ]]; then
        if [[ -n "$SPECIFIC_AGENT" ]]; then
            ./scripts/generate_agents_from_requirements.sh -a "$SPECIFIC_AGENT" -u
        else
            ./scripts/generate_agents_from_requirements.sh -u
        fi
    else
        echo -e "${RED}エラー: generate_agents_from_requirements.sh が見つかりません${NC}"
        exit 1
    fi
    
    # 変更を記録
    record_change
}

# 変更記録
record_change() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="${CHANGE_MESSAGE:-自動更新}"
    
    echo "[$timestamp] $message" >> "$CHANGE_LOG"
    
    # 各エージェントのHISTORY.mdも更新
    if [[ -n "$SPECIFIC_AGENT" ]]; then
        update_agent_history "$SPECIFIC_AGENT"
    else
        for agent in requirements pm api logic next expo infra qa uiux security docs setup; do
            update_agent_history "$agent"
        done
    fi
    
    # 新しいハッシュを保存
    local current_hash=$(md5sum "$REQUIREMENTS_FILE" | cut -d' ' -f1)
    echo "$current_hash" > ".requirements_hash"
    cp "$REQUIREMENTS_FILE" ".requirements_backup"
    
    echo -e "${GREEN}✅ 変更が記録されました${NC}"
}

# エージェント履歴更新
update_agent_history() {
    local agent="$1"
    local history_file="$DOCS_DIR/$agent/HISTORY.md"
    
    if [[ -f "$history_file" ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        cat >> "$history_file" << EOF

### $timestamp
- **作業者**: Requirements Update System
- **作業内容**: 要件定義変更に伴う更新
- **理由**: ${CHANGE_MESSAGE:-要件定義書の変更}
- **ステータス**: 完了

---
EOF
    fi
}

# 差分表示
show_diff() {
    echo -e "${BLUE}📝 要件定義書の変更内容${NC}"
    echo ""
    
    if [[ -f ".requirements_backup" ]]; then
        diff -u ".requirements_backup" "$REQUIREMENTS_FILE" || true
    else
        echo -e "${YELLOW}比較対象のバックアップがありません${NC}"
    fi
}

# ロールバック
rollback() {
    echo -e "${BLUE}⏪ ロールバックを実行中...${NC}"
    
    if [[ ! -f ".requirements_backup" ]]; then
        echo -e "${RED}エラー: バックアップが見つかりません${NC}"
        exit 1
    fi
    
    # 現在の状態をバックアップ
    local timestamp=$(date +%Y%m%d_%H%M%S)
    cp "$REQUIREMENTS_FILE" ".requirements_rollback_${timestamp}"
    
    # ロールバック実行
    cp ".requirements_backup" "$REQUIREMENTS_FILE"
    
    # エージェントも前回のバックアップから復元
    local latest_backup=$(ls -t .backup/agents_* 2>/dev/null | head -1)
    if [[ -n "$latest_backup" ]]; then
        rm -rf "$AGENTS_DIR"
        cp -r "$latest_backup" "$AGENTS_DIR"
    fi
    
    echo -e "${GREEN}✅ ロールバック完了${NC}"
    echo -e "${CYAN}元の状態は .requirements_rollback_${timestamp} に保存されています${NC}"
}

# 変更履歴表示
show_history() {
    echo -e "${BLUE}📚 要件定義変更履歴${NC}"
    echo ""
    
    if [[ -f "$CHANGE_LOG" ]]; then
        cat "$CHANGE_LOG" | tail -20
    else
        echo -e "${YELLOW}変更履歴がありません${NC}"
    fi
}

# 同期実行
sync_all() {
    echo -e "${BLUE}🔄 すべてのエージェントを同期中...${NC}"
    
    # 強制的に全エージェントを再生成
    ./scripts/generate_agents_from_requirements.sh -u -b
    
    # 変更記録
    CHANGE_MESSAGE="${CHANGE_MESSAGE:-完全同期実行}"
    record_change
    
    echo -e "${GREEN}✅ 同期完了${NC}"
}

# 通知生成
generate_notification() {
    local affected="$1"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📢 更新通知${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "要件定義が更新されました。"
    echo ""
    echo "更新理由: ${CHANGE_MESSAGE:-要件定義書の変更}"
    echo "影響範囲: $affected"
    echo "更新時刻: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "各エージェントは最新の要件定義に基づいて動作してください。"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# メイン処理
main() {
    case "$COMMAND" in
        check)
            if check_changes; then
                affected=$(analyze_impact)
                echo -e "\n${YELLOW}💡 更新が必要です。'update' コマンドを実行してください${NC}"
            fi
            ;;
            
        update)
            if check_changes || [[ "$FORCE_MODE" == true ]]; then
                affected=$(analyze_impact)
                update_agents "$affected"
                generate_notification "$affected"
            else
                echo -e "${GREEN}変更がないため、更新は不要です${NC}"
            fi
            ;;
            
        diff)
            show_diff
            ;;
            
        rollback)
            rollback
            ;;
            
        history)
            show_history
            ;;
            
        sync)
            sync_all
            ;;
            
        *)
            echo -e "${RED}不明なコマンド: $COMMAND${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 実行
main