#!/usr/bin/env bash
# PMエージェント自動振り分けシステムのセットアップ
set -euo pipefail

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# 設定
HOOKS_DIR=".claude/hooks"
SCRIPTS_DIR="scripts/core"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔧 PM自動振り分けシステム セットアップ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 1. ディレクトリ作成
echo -e "${BLUE}📁 ディレクトリを作成中...${NC}"
mkdir -p "$HOOKS_DIR"
mkdir -p ".claude/pm/state"
echo -e "${GREEN}✅ ディレクトリ作成完了${NC}"
echo ""

# 2. Python環境の確認
echo -e "${BLUE}🐍 Python環境を確認中...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}⚠️  Python3が見つかりません${NC}"
    echo -e "${CYAN}インストール方法:${NC}"
    echo "  macOS: brew install python3"
    echo "  Ubuntu: sudo apt-get install python3"
    echo ""
    read -p "続行しますか？ (y/N): " continue_anyway
    if [[ "$continue_anyway" != "y" && "$continue_anyway" != "Y" ]]; then
        exit 1
    fi
else
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo -e "${GREEN}✅ Python $python_version 検出${NC}"
fi
echo ""

# 3. 必要なファイルの確認
echo -e "${BLUE}📋 必要なファイルを確認中...${NC}"

files_ok=true

# task-dispatcher.py
if [[ ! -f "$HOOKS_DIR/task-dispatcher.py" ]]; then
    echo -e "${YELLOW}⚠️  task-dispatcher.py が見つかりません${NC}"
    files_ok=false
else
    echo -e "${GREEN}✅ task-dispatcher.py 検出${NC}"
fi

# pm_auto_dispatch.sh
if [[ ! -f "$SCRIPTS_DIR/pm_auto_dispatch.sh" ]]; then
    echo -e "${YELLOW}⚠️  pm_auto_dispatch.sh が見つかりません${NC}"
    files_ok=false
else
    echo -e "${GREEN}✅ pm_auto_dispatch.sh 検出${NC}"
fi

# エージェント定義ファイル
if [[ ! -f "AGENT_DEFINITIONS.md" ]]; then
    echo -e "${YELLOW}⚠️  AGENT_DEFINITIONS.md が見つかりません${NC}"
    echo "  エージェント生成を先に実行してください:"
    echo "  ./scripts/core/generate_agents.sh"
    files_ok=false
else
    echo -e "${GREEN}✅ AGENT_DEFINITIONS.md 検出${NC}"
fi

if [[ "$files_ok" == false ]]; then
    echo ""
    echo -e "${RED}エラー: 必要なファイルが不足しています${NC}"
    exit 1
fi
echo ""

# 4. 実行権限の設定
echo -e "${BLUE}🔐 実行権限を設定中...${NC}"
chmod +x "$HOOKS_DIR/task-dispatcher.py" 2>/dev/null || true
chmod +x "$SCRIPTS_DIR/pm_auto_dispatch.sh" 2>/dev/null || true
chmod +x "$SCRIPTS_DIR/generate_agents.sh" 2>/dev/null || true
echo -e "${GREEN}✅ 実行権限設定完了${NC}"
echo ""

# 5. エイリアスの設定
echo -e "${BLUE}🔗 便利なエイリアスを設定中...${NC}"

# エイリアス設定ファイル
ALIAS_FILE="scripts/core/pm_aliases.sh"
cat > "$ALIAS_FILE" << 'EOF'
#!/usr/bin/env bash
# PM自動振り分けシステムのエイリアス

# タスク振り分けコマンド
alias dispatch='./scripts/core/pm_auto_dispatch.sh'
alias task='./scripts/core/pm_auto_dispatch.sh'

# タスク解析のみ（実行しない）
alias analyze='./scripts/core/pm_auto_dispatch.sh -d'

# 詳細モードでタスク振り分け
alias dispatch-verbose='./scripts/core/pm_auto_dispatch.sh -v'

# エージェント生成
alias generate-agents='./scripts/core/generate_agents.sh'

# 使用方法を表示
pm-help() {
    echo "🤖 PM自動振り分けシステム コマンド一覧"
    echo ""
    echo "タスク振り分け:"
    echo "  dispatch \"タスクの説明\"     - タスクを解析して適切なエージェントに振り分け"
    echo "  task \"タスクの説明\"         - dispatchと同じ（短縮形）"
    echo "  analyze \"タスクの説明\"      - 解析のみ実行（ドライラン）"
    echo "  dispatch-verbose \"タスク\"   - 詳細出力モード"
    echo ""
    echo "エージェント管理:"
    echo "  generate-agents            - エージェントを生成/更新"
    echo ""
    echo "例:"
    echo "  dispatch \"ユーザー認証APIを実装\""
    echo "  task \"ログイン画面を作成\""
    echo "  analyze \"テストを追加\""
}

echo "PM自動振り分けシステムのエイリアスが読み込まれました"
echo "使用方法: pm-help"
EOF

chmod +x "$ALIAS_FILE"
echo -e "${GREEN}✅ エイリアス設定完了${NC}"
echo ""

# 6. テスト実行
echo -e "${BLUE}🧪 システムテストを実行中...${NC}"
echo ""

# ディスパッチャーのテスト
echo "テスト1: タスク解析テスト"
test_output=$(python3 "$HOOKS_DIR/task-dispatcher.py" "テスト: APIを作成" 2>&1 | head -n 5)
if [[ -n "$test_output" ]]; then
    echo -e "${GREEN}✅ タスク解析テスト成功${NC}"
else
    echo -e "${RED}❌ タスク解析テスト失敗${NC}"
fi

# JSONファイルの生成確認
if [[ -f "$HOOKS_DIR/last_dispatch.json" ]]; then
    echo -e "${GREEN}✅ JSON出力テスト成功${NC}"
else
    echo -e "${YELLOW}⚠️  JSON出力テスト失敗${NC}"
fi
echo ""

# 7. 使用方法の表示
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ セットアップ完了！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📚 使用方法:${NC}"
echo ""
echo "1. エイリアスを読み込む:"
echo -e "   ${YELLOW}source scripts/core/pm_aliases.sh${NC}"
echo ""
echo "2. タスクを振り分ける:"
echo -e "   ${YELLOW}dispatch \"ユーザー認証APIを実装\"${NC}"
echo -e "   ${YELLOW}task \"ログイン画面を作成\"${NC}"
echo ""
echo "3. 解析のみ実行（ドライラン）:"
echo -e "   ${YELLOW}analyze \"新機能を追加\"${NC}"
echo ""
echo "4. 直接実行:"
echo -e "   ${YELLOW}./scripts/core/pm_auto_dispatch.sh \"タスクの説明\"${NC}"
echo ""
echo -e "${CYAN}💡 ヒント:${NC}"
echo "• 複雑なタスクは自動的にPMエージェントが調整します"
echo "• 単純なタスクは直接担当エージェントが実行します"
echo "• -v オプションで詳細な解析結果が表示されます"
echo "• -d オプションで実行計画のみ確認できます"
echo ""
echo -e "${MAGENTA}📝 注意事項:${NC}"
echo "• 現在のバージョンではClaudeCodeへの自動入力は未対応です"
echo "• 生成されたプロンプトを手動でClaudeCodeに入力してください"
echo "• 将来のバージョンでClaudeCode APIとの統合を予定しています"
echo ""

# 8. エイリアスの自動読み込み設定の提案
echo -e "${CYAN}🔧 永続的な設定（オプション）:${NC}"
echo ""
echo "毎回エイリアスを自動で読み込むには、以下を実行:"
echo ""
echo "  # bashの場合"
echo "  echo 'source $(pwd)/scripts/core/pm_aliases.sh' >> ~/.bashrc"
echo ""
echo "  # zshの場合"
echo "  echo 'source $(pwd)/scripts/core/pm_aliases.sh' >> ~/.zshrc"
echo ""

# 9. 動作確認の提案
echo -e "${CYAN}🎯 動作確認:${NC}"
echo ""
echo "以下のコマンドで動作を確認してください:"
echo ""
echo "1. シンプルなタスク:"
echo -e "   ${YELLOW}./scripts/core/pm_auto_dispatch.sh -d \"READMEを更新\"${NC}"
echo ""
echo "2. API関連タスク:"
echo -e "   ${YELLOW}./scripts/core/pm_auto_dispatch.sh -d \"ユーザー検索APIを実装\"${NC}"
echo ""
echo "3. 複合タスク:"
echo -e "   ${YELLOW}./scripts/core/pm_auto_dispatch.sh -d \"ユーザー管理機能を実装（API、画面、テスト含む）\"${NC}"
echo ""