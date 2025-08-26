#!/usr/bin/env bash
# Agentix統合セットアップスクリプト
set -euo pipefail

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# スクリプトディレクトリの取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🚀 Agentix プロジェクトセットアップ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 使用方法の表示
show_usage() {
    echo -e "${CYAN}使用方法:${NC}"
    echo "  ./setup.sh [オプション]"
    echo ""
    echo -e "${CYAN}オプション:${NC}"
    echo "  --basic     基本セットアップのみ実行"
    echo "  --full      すべてのモジュールを含む完全セットアップ"
    echo "  --agents    エージェントのみ生成"
    echo "  --help      このヘルプを表示"
    echo ""
    echo -e "${CYAN}例:${NC}"
    echo "  ./setup.sh --basic   # 最小構成でセットアップ"
    echo "  ./setup.sh --full    # すべての機能を有効化"
    echo ""
    exit 0
}

# オプション解析
SETUP_MODE="basic"
if [[ $# -gt 0 ]]; then
    case "$1" in
        --help)
            show_usage
            ;;
        --basic)
            SETUP_MODE="basic"
            ;;
        --full)
            SETUP_MODE="full"
            ;;
        --agents)
            SETUP_MODE="agents"
            ;;
        *)
            echo -e "${RED}❌ 不明なオプション: $1${NC}"
            show_usage
            ;;
    esac
fi

# 基本セットアップ
run_basic_setup() {
    echo -e "${BLUE}📦 基本セットアップを開始...${NC}"
    
    # コアスクリプトの実行
    if [[ -f "$SCRIPT_DIR/core/setup.sh" ]]; then
        bash "$SCRIPT_DIR/core/setup.sh"
    else
        echo -e "${RED}❌ core/setup.sh が見つかりません${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 基本セットアップ完了${NC}"
}

# エージェント生成
generate_agents() {
    echo -e "${BLUE}🤖 エージェントを生成...${NC}"
    
    if [[ -f "$SCRIPT_DIR/core/generate_agents.sh" ]]; then
        bash "$SCRIPT_DIR/core/generate_agents.sh"
    else
        echo -e "${YELLOW}⚠️  generate_agents.sh が見つかりません${NC}"
    fi
    
    echo -e "${GREEN}✅ エージェント生成完了${NC}"
}

# モジュールインストール
install_modules() {
    echo -e "${BLUE}🔧 追加モジュールをインストール...${NC}"
    echo ""
    
    # 利用可能なモジュールを表示
    echo -e "${CYAN}利用可能なモジュール:${NC}"
    echo "  1) auto_testing     - 自動テスト実行システム"
    echo "  2) coordination     - エージェント間協調システム"
    echo "  3) hooks           - Git Hooks設定"
    echo "  4) metrics         - メトリクス収集システム"
    echo "  5) mcp_tools       - MCP連携ツール"
    echo "  6) dashboard       - リアルタイム監視ダッシュボード"
    echo "  7) all             - すべてのモジュール"
    echo ""
    
    read -p "インストールするモジュールを選択 (カンマ区切り、例: 1,3,5): " modules
    
    IFS=',' read -ra MODULE_LIST <<< "$modules"
    for module in "${MODULE_LIST[@]}"; do
        case "$module" in
            1)
                [[ -f "$SCRIPT_DIR/modules/auto_testing.sh" ]] && bash "$SCRIPT_DIR/modules/auto_testing.sh"
                ;;
            2)
                [[ -f "$SCRIPT_DIR/modules/coordination.sh" ]] && bash "$SCRIPT_DIR/modules/coordination.sh"
                ;;
            3)
                [[ -f "$SCRIPT_DIR/modules/hooks.sh" ]] && bash "$SCRIPT_DIR/modules/hooks.sh"
                ;;
            4)
                [[ -f "$SCRIPT_DIR/modules/metrics.sh" ]] && bash "$SCRIPT_DIR/modules/metrics.sh"
                ;;
            5)
                [[ -f "$SCRIPT_DIR/modules/mcp_tools.sh" ]] && bash "$SCRIPT_DIR/modules/mcp_tools.sh"
                ;;
            6)
                [[ -f "$SCRIPT_DIR/modules/realtime_dashboard.sh" ]] && bash "$SCRIPT_DIR/modules/realtime_dashboard.sh"
                ;;
            7|all)
                for module_script in "$SCRIPT_DIR/modules/"*.sh; do
                    [[ -f "$module_script" ]] && bash "$module_script"
                done
                ;;
        esac
    done
    
    echo -e "${GREEN}✅ モジュールインストール完了${NC}"
}

# メイン処理
main() {
    cd "$PROJECT_ROOT"
    
    case "$SETUP_MODE" in
        basic)
            run_basic_setup
            generate_agents
            ;;
        full)
            run_basic_setup
            generate_agents
            # すべてのモジュールを自動インストール
            echo -e "${BLUE}🔧 すべてのモジュールを自動インストール...${NC}"
            for module_script in "$SCRIPT_DIR/modules/"*.sh; do
                if [[ -f "$module_script" ]]; then
                    echo -e "${CYAN}  → $(basename "$module_script")${NC}"
                    bash "$module_script"
                fi
            done
            ;;
        agents)
            generate_agents
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ セットアップ完了！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}次のステップ:${NC}"
    echo "  1. 追加モジュールのインストール:"
    echo -e "     ${YELLOW}./scripts/setup.sh --full${NC}"
    echo ""
    echo "  2. プロジェクトのリセット:"
    echo -e "     ${YELLOW}./scripts/reset.sh${NC}"
    echo ""
    echo "  3. 既存プロジェクトへの統合:"
    echo -e "     ${YELLOW}./scripts/integrate.sh${NC}"
    echo ""
}

# 実行
main