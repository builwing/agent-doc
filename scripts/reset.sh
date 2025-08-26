#!/usr/bin/env bash
# Agentix統合リセットスクリプト
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
echo -e "${BLUE}🧹 Agentix プロジェクトリセット${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# コアのリセットスクリプトを実行
if [[ -f "$SCRIPT_DIR/core/reset.sh" ]]; then
    bash "$SCRIPT_DIR/core/reset.sh"
else
    echo -e "${RED}❌ core/reset.sh が見つかりません${NC}"
    exit 1
fi