#!/usr/bin/env bash
# ClaudeCode カスタムサブエージェント作成スクリプト
# サブエージェント.mdの仕様に準じて新規エージェントを作成します
set -euo pipefail

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# 変数
AGENT_NAME=""
AGENT_DESCRIPTION=""
AGENT_TOOLS=""
INTERACTIVE=false

# ヘルプ表示
show_help() {
    cat << EOF
使用方法: ./scripts/setup_custom_agents.sh [オプション]

オプション:
    -n, --name NAME         エージェント名（必須、英小文字とハイフン）
    -d, --description DESC  エージェントの説明と呼び出し条件
    -t, --tools TOOLS       使用ツール（カンマ区切り）
    -i, --interactive       対話モードで実行
    -h, --help             このヘルプを表示

例:
    ./scripts/setup_custom_agents.sh -i                               # 対話モード
    ./scripts/setup_custom_agents.sh -n database -d "データベース管理" -t "Read,Write,Bash"
    ./scripts/setup_custom_agents.sh -n test-runner -d "テスト実行専門"

注意:
    - エージェントは .claude/agents/ ディレクトリに作成されます
    - ツールを指定しない場合、すべてのツールを継承します
    - ClaudeCodeのサブエージェント仕様に準拠します

利用可能なツール:
    Read, Write, Edit, MultiEdit, Bash, Grep, Glob, LS, 
    WebFetch, WebSearch, TodoWrite, NotebookEdit
EOF
}

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            AGENT_NAME="$2"
            shift 2
            ;;
        -d|--description)
            AGENT_DESCRIPTION="$2"
            shift 2
            ;;
        -t|--tools)
            AGENT_TOOLS="$2"
            shift 2
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}不明なオプション: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 対話モード
interactive_mode() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🤖 ClaudeCode カスタムサブエージェント作成ウィザード${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # エージェント名
    while [[ -z "$AGENT_NAME" ]]; do
        read -p "エージェント名（英小文字とハイフン、例: test-runner）: " AGENT_NAME
        if [[ ! "$AGENT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
            echo -e "${RED}エラー: エージェント名は英小文字で始まり、英小文字、数字、ハイフンのみ使用可能です${NC}"
            AGENT_NAME=""
        fi
    done

    # 説明
    echo -e "\n${YELLOW}エージェントの説明を入力してください:${NC}"
    echo "（このエージェントがいつ呼び出されるべきか明確に記述）"
    read -p "> " AGENT_DESCRIPTION
    if [[ -z "$AGENT_DESCRIPTION" ]]; then
        AGENT_DESCRIPTION="${AGENT_NAME} に関するタスクを処理する専門エージェント"
    fi

    # ツール選択
    echo -e "\n${YELLOW}ツールアクセスを設定しますか？${NC}"
    echo "1) すべてのツールを継承（デフォルト、推奨）"
    echo "2) 特定のツールのみを許可"
    read -p "選択 [1-2]: " tool_choice

    if [[ "$tool_choice" == "2" ]]; then
        echo -e "\n${CYAN}利用可能なツール:${NC}"
        echo "  基本: Read, Write, Edit, MultiEdit"
        echo "  検索: Grep, Glob, LS"
        echo "  実行: Bash"
        echo "  Web: WebFetch, WebSearch"
        echo "  その他: TodoWrite, NotebookEdit"
        echo ""
        echo "使用するツールをカンマ区切りで入力（例: Read,Write,Edit,Bash）:"
        read -p "> " AGENT_TOOLS
    fi

    # 確認
    echo ""
    echo -e "${GREEN}設定内容:${NC}"
    echo "  エージェント名: $AGENT_NAME"
    echo "  説明: $AGENT_DESCRIPTION"
    if [[ -n "$AGENT_TOOLS" ]]; then
        echo "  ツール: $AGENT_TOOLS"
    else
        echo "  ツール: すべてのツールを継承"
    fi
    echo ""
    read -p "この内容で作成しますか？ [Y/n]: " confirm
    if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
        echo "キャンセルしました"
        exit 0
    fi
}

# バリデーション
validate_inputs() {
    if [[ -z "$AGENT_NAME" ]]; then
        echo -e "${RED}エラー: エージェント名が指定されていません${NC}"
        echo "対話モードで実行するには -i オプションを使用してください"
        show_help
        exit 1
    fi

    # エージェント名の検証
    if [[ ! "$AGENT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
        echo -e "${RED}エラー: エージェント名は英小文字で始まり、英小文字、数字、ハイフンのみ使用可能です${NC}"
        exit 1
    fi

    # 既存チェック
    if [[ -f ".claude/agents/${AGENT_NAME}.md" ]]; then
        echo -e "${YELLOW}警告: エージェント '$AGENT_NAME' は既に存在します${NC}"
        read -p "上書きしますか？ [y/N]: " overwrite
        if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
            echo "キャンセルしました"
            exit 0
        fi
    fi

    # デフォルト説明
    if [[ -z "$AGENT_DESCRIPTION" ]]; then
        AGENT_DESCRIPTION="${AGENT_NAME} に関するタスクを処理する専門エージェント。${AGENT_NAME} に関連する実装、テスト、最適化を積極的に実施。"
    fi
}

# システムプロンプトの生成
generate_system_prompt() {
    local name="$1"
    
    # エージェント名から専門分野を推測
    local specialty=""
    local responsibilities=""
    local workflow=""
    
    case $name in
        *test*|*qa*)
            specialty="テスト自動化と品質保証"
            responsibilities="
1. **テスト戦略**
   - 単体テストの作成と実行
   - 統合テストの設計
   - E2Eテストの実装
   - テストカバレッジの向上

2. **品質管理**
   - コード品質の検証
   - パフォーマンステスト
   - セキュリティテスト
   - リグレッションテスト"
            workflow="
タスクを受け取ったら：
1. テスト対象を分析
2. テストケースを設計
3. テストコードを実装
4. テストを実行し結果を検証
5. カバレッジレポートを生成"
            ;;
        
        *database*|*db*)
            specialty="データベース設計と管理"
            responsibilities="
1. **データベース設計**
   - スキーマ設計
   - インデックス最適化
   - 正規化とパフォーマンスのバランス
   - マイグレーション管理

2. **クエリ最適化**
   - SQLクエリの最適化
   - 実行計画の分析
   - パフォーマンスチューニング
   - キャッシュ戦略"
            workflow="
タスクを受け取ったら：
1. データ要件を分析
2. スキーマを設計または最適化
3. マイグレーションを作成
4. クエリを実装
5. パフォーマンスを検証"
            ;;
        
        *deploy*|*ci*|*cd*)
            specialty="デプロイメントとCI/CD"
            responsibilities="
1. **CI/CDパイプライン**
   - ビルドプロセスの自動化
   - テスト自動実行
   - デプロイメント自動化
   - ロールバック戦略

2. **環境管理**
   - 開発/ステージング/本番環境
   - 設定管理
   - シークレット管理
   - モニタリング設定"
            workflow="
タスクを受け取ったら：
1. 現在のパイプラインを確認
2. 必要な変更を特定
3. ワークフローを更新
4. テスト環境で検証
5. 本番環境へデプロイ"
            ;;
        
        *)
            specialty="${name} に関する専門知識"
            responsibilities="
1. **主要タスク**
   - ${name} に関連する実装
   - コードの最適化
   - ドキュメント作成
   - 問題解決

2. **品質保証**
   - ベストプラクティスの適用
   - コードレビュー
   - テスト作成
   - パフォーマンス最適化"
            workflow="
タスクを受け取ったら：
1. 要件を詳細に分析
2. 実装計画を立案
3. コードを実装
4. テストを作成・実行
5. ドキュメントを更新"
            ;;
    esac

    cat << EOF
あなたは ${name} という名前の専門エージェントで、${specialty}を担当します。

## 主な責務
${responsibilities}

## 作業フロー
${workflow}

## コーディング原則

- クリーンで保守性の高いコード
- 適切なエラーハンドリング
- 包括的なテスト
- 明確なドキュメント
- パフォーマンスの考慮

## 重要な考慮事項

- セキュリティファーストのアプローチ
- スケーラビリティを考慮した設計
- チーム開発を意識したコード
- 継続的な改善
- ユーザー体験の向上
EOF
}

# エージェント作成
create_agent() {
    echo -e "${BLUE}📁 サブエージェントを作成中...${NC}"
    
    # ディレクトリ作成
    mkdir -p .claude/agents
    
    # エージェントファイル作成
    local agent_file=".claude/agents/${AGENT_NAME}.md"
    
    # YAMLフロントマター
    {
        echo "---"
        echo "name: $AGENT_NAME"
        echo "description: $AGENT_DESCRIPTION"
        if [[ -n "$AGENT_TOOLS" ]]; then
            echo "tools: $AGENT_TOOLS"
        fi
        echo "---"
        echo ""
    } > "$agent_file"
    
    # システムプロンプト
    generate_system_prompt "$AGENT_NAME" >> "$agent_file"
    
    echo -e "${GREEN}✅ サブエージェントを作成しました: $agent_file${NC}"
}

# 完了メッセージ
show_completion_message() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ カスタムサブエージェント作成完了！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}📁 作成されたファイル:${NC}"
    echo "  .claude/agents/${AGENT_NAME}.md"
    echo ""
    echo -e "${CYAN}📝 ファイル内容:${NC}"
    echo "  - name: エージェント識別子"
    echo "  - description: 自動委任の判定に使用"
    if [[ -n "$AGENT_TOOLS" ]]; then
        echo "  - tools: 許可されたツール"
    else
        echo "  - tools: すべてのツールを継承"
    fi
    echo "  - システムプロンプト: エージェントの動作定義"
    echo ""
    echo -e "${CYAN}🚀 次のステップ:${NC}"
    echo ""
    echo "  1. ClaudeCodeでサブエージェントを確認:"
    echo -e "     ${YELLOW}/agents${NC}"
    echo ""
    echo "  2. サブエージェントを明示的に呼び出す:"
    echo -e "     ${YELLOW}${AGENT_NAME}サブエージェントを使用して...${NC}"
    echo ""
    echo "  3. システムプロンプトをカスタマイズ:"
    echo -e "     ${YELLOW}vi .claude/agents/${AGENT_NAME}.md${NC}"
    echo ""
    echo -e "${BLUE}💡 ヒント:${NC}"
    echo "  - descriptionに「積極的に使用」を含めると自動委任されやすくなります"
    echo "  - ツールは必要最小限に制限することを推奨します"
    echo "  - プロジェクトレベルのエージェントはチームで共有できます"
}

# メイン処理
main() {
    # 対話モードチェック
    if [[ "$INTERACTIVE" == true ]]; then
        interactive_mode
    fi
    
    # 入力検証
    validate_inputs
    
    # エージェント作成
    create_agent
    
    # 完了メッセージ
    show_completion_message
}

# 実行
main