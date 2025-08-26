#!/usr/bin/env bash
# モジュール個別インストールスクリプト
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
echo -e "${BLUE}📦 モジュールインストーラー${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 使用方法の表示
show_usage() {
    echo -e "${CYAN}使用方法:${NC}"
    echo "  ./install-modules.sh [モジュール名]"
    echo ""
    echo -e "${CYAN}利用可能なモジュール:${NC}"
    echo "  auto-testing      自動テスト実行システム"
    echo "  coordination      エージェント間協調システム"
    echo "  hooks            Git Hooks と GitHub Actions"
    echo "  llm-router       LLM統合タスク振り分け"
    echo "  mcp-tools        MCP連携ツール"
    echo "  metrics          メトリクス収集システム"
    echo "  multi-llm        複数LLMプロバイダー対応"
    echo "  pm-prompts       PMプロンプト設定"
    echo "  rag-system       RAGシステム"
    echo "  dashboard        リアルタイム監視ダッシュボード"
    echo "  all              すべてのモジュール"
    echo ""
    echo -e "${CYAN}例:${NC}"
    echo "  ./install-modules.sh auto-testing"
    echo "  ./install-modules.sh hooks metrics"
    echo "  ./install-modules.sh all"
    echo ""
    exit 0
}

# モジュールインストール関数
install_module() {
    local module=$1
    local script_name=""
    
    case "$module" in
        auto-testing)
            script_name="auto_testing.sh"
            ;;
        coordination)
            script_name="coordination.sh"
            ;;
        hooks)
            script_name="hooks.sh"
            ;;
        llm-router)
            script_name="llm_router.sh"
            ;;
        mcp-tools)
            script_name="mcp_tools.sh"
            ;;
        metrics)
            script_name="metrics.sh"
            ;;
        multi-llm)
            script_name="multi_llm.sh"
            ;;
        pm-prompts)
            script_name="pm_prompts.sh"
            ;;
        rag-system)
            script_name="rag_system.sh"
            ;;
        dashboard)
            script_name="realtime_dashboard.sh"
            ;;
        all)
            echo -e "${BLUE}🔧 すべてのモジュールをインストール...${NC}"
            for module_script in "$SCRIPT_DIR/modules/"*.sh; do
                if [[ -f "$module_script" ]]; then
                    local module_name=$(basename "$module_script" .sh)
                    echo -e "${CYAN}  → ${module_name}${NC}"
                    bash "$module_script"
                fi
            done
            return 0
            ;;
        *)
            echo -e "${RED}❌ 不明なモジュール: $module${NC}"
            return 1
            ;;
    esac
    
    if [[ -n "$script_name" ]] && [[ -f "$SCRIPT_DIR/modules/$script_name" ]]; then
        echo -e "${BLUE}📦 ${module} をインストール中...${NC}"
        bash "$SCRIPT_DIR/modules/$script_name"
        echo -e "${GREEN}✅ ${module} のインストール完了${NC}"
    else
        echo -e "${RED}❌ モジュールスクリプトが見つかりません: $script_name${NC}"
        return 1
    fi
}

# メイン処理
main() {
    if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_usage
    fi
    
    cd "$PROJECT_ROOT"
    
    # 各引数に対してモジュールをインストール
    for module in "$@"; do
        install_module "$module"
    done
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ モジュールインストール完了${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 実行
main "$@"