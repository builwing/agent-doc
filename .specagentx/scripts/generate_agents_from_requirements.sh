#!/usr/bin/env bash
# 要件定義書からエージェントを生成・更新するスクリプト
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
AGENTS_DIR=".claude/agents"
DOCS_DIR="docs/agents"
BACKUP_DIR=".backup"

# ヘルプ表示
show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 要件定義書ベースのエージェント生成システム
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

使用方法: ./scripts/generate_agents_from_requirements.sh [オプション]

オプション:
    -r, --requirements FILE  要件定義書のパス（デフォルト: REQUIREMENTS.md）
    -a, --agent AGENT       特定のエージェントのみ生成
    -u, --update            既存エージェントを更新
    -b, --backup            更新前にバックアップを作成
    -v, --validate          要件定義書の検証のみ実行
    -h, --help              このヘルプを表示

例:
    # すべてのエージェントを生成
    ./scripts/generate_agents_from_requirements.sh

    # 特定のエージェントのみ更新
    ./scripts/generate_agents_from_requirements.sh -a api -u

    # バックアップを作成して更新
    ./scripts/generate_agents_from_requirements.sh -u -b

    # 要件定義書の検証
    ./scripts/generate_agents_from_requirements.sh -v

ワークフロー:
    1. REQUIREMENTS.md を解析
    2. エージェント定義を抽出
    3. 各エージェント用の設定を生成
    4. .claude/agents/ にエージェントファイル作成
    5. docs/agents/ に要件定義書を配置
EOF
}

# 引数解析
SPECIFIC_AGENT=""
UPDATE_MODE=false
BACKUP_MODE=false
VALIDATE_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--requirements)
            REQUIREMENTS_FILE="$2"
            shift 2
            ;;
        -a|--agent)
            SPECIFIC_AGENT="$2"
            shift 2
            ;;
        -u|--update)
            UPDATE_MODE=true
            shift
            ;;
        -b|--backup)
            BACKUP_MODE=true
            shift
            ;;
        -v|--validate)
            VALIDATE_ONLY=true
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

# 要件定義書の存在確認
validate_requirements() {
    echo -e "${BLUE}📋 要件定義書を検証中...${NC}"
    
    if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
        echo -e "${RED}エラー: 要件定義書が見つかりません: $REQUIREMENTS_FILE${NC}"
        echo -e "${YELLOW}ヒント: まず REQUIREMENTS.md を作成してください${NC}"
        exit 1
    fi
    
    # 必須セクションの確認
    local required_sections=(
        "プロジェクト概要"
        "ビジネス要件"
        "技術要件"
        "エージェント定義"
    )
    
    for section in "${required_sections[@]}"; do
        if ! grep -q "## .*$section" "$REQUIREMENTS_FILE"; then
            echo -e "${YELLOW}警告: セクション '$section' が見つかりません${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ 要件定義書の検証完了${NC}"
}

# エージェントリストの抽出
extract_agents() {
    echo -e "${BLUE}🔍 エージェント定義を抽出中...${NC}"
    
    # エージェント定義セクションから表を抽出
    local in_agent_section=false
    local agents=()
    
    while IFS= read -r line; do
        if [[ "$line" =~ "### 4.1 コアエージェント" ]]; then
            in_agent_section=true
            continue
        fi
        
        if [[ "$in_agent_section" == true ]]; then
            if [[ "$line" =~ "### " ]]; then
                break
            fi
            
            # テーブル行からエージェント情報を抽出（より厳密なパターン）
            if [[ "$line" =~ ^\|[[:space:]]*([a-z]+)[[:space:]]*\|[[:space:]]*([^|]+)[[:space:]]*\|[[:space:]]*(High|Medium|Low)[[:space:]]*\| ]]; then
                local agent_name="${BASH_REMATCH[1]}"
                local agent_desc="$(echo "${BASH_REMATCH[2]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
                local agent_priority="${BASH_REMATCH[3]}"
                
                # エージェント名の妥当性チェック
                # - 英小文字のみ
                # - 2文字以上20文字以下
                # - 既知のエージェント名またはプロジェクト固有のエージェント
                if [[ "$agent_name" =~ ^[a-z]{2,20}$ ]]; then
                    # ヘッダー行やノイズを除外
                    if [[ "$agent_name" != "エージェント名" ]] && 
                       [[ "$agent_name" != "---" ]] &&
                       [[ "$agent_name" != "sonnet" ]] &&
                       [[ -n "$agent_desc" ]] &&
                       [[ "$agent_desc" != "-"* ]]; then
                        agents+=("${agent_name}:${agent_desc}:${agent_priority}")
                        echo -e "  ${GREEN}✓${NC} 検出: ${agent_name}"
                    fi
                fi
            fi
        fi
    done < "$REQUIREMENTS_FILE"
    
    if [[ ${#agents[@]} -eq 0 ]]; then
        echo -e "${YELLOW}警告: エージェント定義が見つかりませんでした${NC}"
    else
        echo -e "${GREEN}検出完了: ${#agents[@]} エージェント${NC}"
    fi
    
    echo "${agents[@]}"
}

# バックアップ作成
create_backup() {
    if [[ "$BACKUP_MODE" == true ]]; then
        echo -e "${BLUE}💾 バックアップを作成中...${NC}"
        
        local timestamp=$(date +%Y%m%d_%H%M%S)
        mkdir -p "$BACKUP_DIR"
        
        if [[ -d "$AGENTS_DIR" ]]; then
            cp -r "$AGENTS_DIR" "$BACKUP_DIR/agents_${timestamp}"
        fi
        
        if [[ -d "$DOCS_DIR" ]]; then
            cp -r "$DOCS_DIR" "$BACKUP_DIR/docs_agents_${timestamp}"
        fi
        
        echo -e "${GREEN}✅ バックアップ完了: $BACKUP_DIR/*_${timestamp}${NC}"
    fi
}

# エージェントファイル生成
generate_agent_file() {
    local agent_name="$1"
    local agent_desc="$2"
    local agent_priority="$3"
    
    local agent_file="$AGENTS_DIR/${agent_name}.md"
    
    # 既存チェック
    if [[ -f "$agent_file" ]] && [[ "$UPDATE_MODE" != true ]]; then
        echo -e "${YELLOW}  スキップ: $agent_name (既存)${NC}"
        return
    fi
    
    echo -e "${CYAN}  生成中: $agent_name${NC}"
    
    # エージェントファイル作成
    cat > "$agent_file" << EOF
---
name: $agent_name
description: $agent_desc 優先度: $agent_priority
priority: $agent_priority
---

# ${agent_name} エージェント

## 概要
$agent_desc

## 責務
$(get_agent_responsibilities "$agent_name")

## 主要タスク
$(get_agent_tasks "$agent_name")

## 作業フロー
$(get_agent_workflow "$agent_name")

## 成功基準
- 要件定義書の内容を満たす
- テストが実装されている
- ドキュメントが更新されている
- エラーハンドリングが適切

## 連携エージェント
$(get_agent_dependencies "$agent_name")

## 注意事項
- REQUIREMENTS.md の最新版を確認すること
- 変更時は docs/agents/${agent_name}/HISTORY.md を更新すること
- 他のエージェントとの連携を考慮すること
EOF
}

# エージェント固有の責務を取得
get_agent_responsibilities() {
    local agent="$1"
    
    case "$agent" in
        requirements)
            echo "- 要件定義書の作成と管理"
            echo "- 要件変更の追跡"
            echo "- 各エージェント用要件の生成"
            ;;
        pm)
            echo "- プロジェクト全体の管理"
            echo "- タスクの分解と振り分け"
            echo "- 進捗の追跡とレポート"
            ;;
        api)
            echo "- RESTful APIの設計と実装"
            echo "- API仕様書（specs/*.yaml）の管理"
            echo "- データベース設計"
            echo "- ビジネスロジックの実装"
            echo "- ⚠️ 必ずAPI仕様書から開始すること"
            echo "- ⚠️ generated/backend/の直接編集は禁止"
            ;;
        logic)
            echo "- ビジネスロジックの設計と実装"
            echo "- アルゴリズムの最適化"
            echo "- データ処理の実装"
            ;;
        next)
            echo "- Next.jsアプリケーションの開発"
            echo "- UIコンポーネントの実装"
            echo "- SSR/SSGの最適化"
            echo "- ⚠️ generated/frontend/の型定義を使用"
            echo "- ⚠️ APIクライアントの手動作成は禁止"
            ;;
        expo)
            echo "- React Nativeアプリの開発"
            echo "- モバイル固有機能の実装"
            echo "- クロスプラットフォーム対応"
            echo "- ⚠️ generated/mobile/のAPIサービスを使用"
            echo "- ⚠️ オフライン対応は仕様書に従う"
            ;;
        infra)
            echo "- インフラストラクチャの構築"
            echo "- CI/CDパイプラインの設定"
            echo "- 環境構築の自動化"
            ;;
        qa)
            echo "- テスト戦略の立案"
            echo "- 自動テストの実装"
            echo "- 品質保証プロセスの管理"
            echo "- API仕様準拠の検証"
            ;;
        uiux)
            echo "- UIデザインの作成"
            echo "- UX設計と最適化"
            echo "- デザインシステムの管理"
            ;;
        security)
            echo "- セキュリティ監査の実施"
            echo "- 脆弱性の検出と修正"
            echo "- セキュリティポリシーの策定"
            ;;
        docs)
            echo "- ドキュメントの作成と管理"
            echo "- APIドキュメントの生成"
            echo "- ユーザーガイドの作成"
            ;;
        setup)
            echo "- 開発環境の構築"
            echo "- 初期設定の自動化"
            echo "- 依存関係の管理"
            echo "- API仕様システムの初期化"
            ;;
        *)
            echo "- ${agent}に関連するタスクの実行"
            echo "- 品質基準の維持"
            echo "- ドキュメントの更新"
            ;;
    esac
}

# エージェントのタスクを取得
get_agent_tasks() {
    local agent="$1"
    
    case "$agent" in
        requirements)
            echo "1. プロジェクト要件の収集"
            echo "2. 要件定義書の作成"
            echo "3. 各エージェント用要件の生成"
            echo "4. 変更管理"
            ;;
        pm)
            echo "1. スプリント計画"
            echo "2. タスク割り当て"
            echo "3. 進捗管理"
            echo "4. リスク管理"
            ;;
        api)
            echo "1. API設計"
            echo "2. エンドポイント実装"
            echo "3. データモデル定義"
            echo "4. 認証・認可実装"
            ;;
        *)
            echo "1. 要件分析"
            echo "2. 設計"
            echo "3. 実装"
            echo "4. テスト"
            ;;
    esac
}

# エージェントのワークフローを取得
get_agent_workflow() {
    local agent="$1"
    
    echo "1. REQUIREMENTS.md を確認"
    echo "2. docs/agents/${agent}/REQUIREMENTS.md を確認"
    echo "3. タスクを実行"
    echo "4. テストを実施"
    echo "5. ドキュメントを更新"
    echo "6. HISTORY.md に記録"
}

# エージェントの依存関係を取得
get_agent_dependencies() {
    local agent="$1"
    
    case "$agent" in
        requirements)
            echo "- なし（最上流）"
            ;;
        pm)
            echo "- requirements: 要件定義を受け取る"
            ;;
        api|logic|next|expo)
            echo "- pm: タスクを受け取る"
            echo "- requirements: 要件を確認"
            ;;
        qa)
            echo "- すべての開発エージェント: テスト対象"
            ;;
        docs)
            echo "- すべてのエージェント: ドキュメント化対象"
            ;;
        *)
            echo "- pm: タスク管理"
            echo "- requirements: 要件確認"
            ;;
    esac
}

# エージェント用ドキュメント生成
generate_agent_docs() {
    local agent_name="$1"
    local agent_desc="$2"
    local agent_priority="$3"
    
    local agent_doc_dir="$DOCS_DIR/$agent_name"
    mkdir -p "$agent_doc_dir"
    
    # REQUIREMENTS.md
    cat > "$agent_doc_dir/REQUIREMENTS.md" << EOF
# ${agent_name} エージェント要件定義書

## 基本情報
- **エージェント名**: $agent_name
- **説明**: $agent_desc
- **優先度**: $agent_priority
- **更新日**: $(date +%Y-%m-%d)

## マスター要件参照
このドキュメントは [REQUIREMENTS.md](../../../REQUIREMENTS.md) のサブセットです。

## エージェント固有要件

### 機能要件
$(get_agent_responsibilities "$agent_name" | sed 's/^//')

### 非機能要件
- レスポンス時間: 要件に準拠
- エラー率: 1%未満
- テストカバレッジ: 80%以上

## タスク定義
$(get_agent_tasks "$agent_name" | sed 's/^//')

## 成功基準
- [ ] すべての機能要件を満たす
- [ ] テストが実装されている
- [ ] ドキュメントが完成している
- [ ] コードレビューを通過

## 変更履歴
| 日付 | バージョン | 変更内容 |
|------|-----------|----------|
| $(date +%Y-%m-%d) | 1.0.0 | 初版作成 |
EOF

    # CHECKLIST.md
    cat > "$agent_doc_dir/CHECKLIST.md" << EOF
# ${agent_name} エージェント チェックリスト

## 🔍 開始前チェック
- [ ] REQUIREMENTS.md を読んで理解した
- [ ] マスター要件定義書を確認した
- [ ] 必要な権限を持っている
- [ ] 開発環境が準備できている

## 🔨 実装中チェック
- [ ] コーディング規約に従っている
- [ ] エラーハンドリングを実装した
- [ ] ログを適切に出力している
- [ ] テストを書きながら実装している

## ✅ 完了チェック
- [ ] すべての要件を満たした
- [ ] 単体テストが通っている
- [ ] 統合テストが通っている
- [ ] ドキュメントを更新した
- [ ] コードレビューを受けた
- [ ] HISTORY.md に記録した

## 📝 リリース前チェック
- [ ] パフォーマンステストを実施
- [ ] セキュリティチェックを実施
- [ ] 本番環境での動作確認
- [ ] ロールバック手順を確認
EOF

    # HISTORY.md (初期化のみ)
    if [[ ! -f "$agent_doc_dir/HISTORY.md" ]]; then
        cat > "$agent_doc_dir/HISTORY.md" << EOF
# ${agent_name} エージェント 作業履歴

## 更新ログ

### $(date +%Y-%m-%d)
- **作業者**: System
- **作業内容**: エージェント初期生成
- **ステータス**: 完了
- **備考**: REQUIREMENTS.md から自動生成

---
EOF
    fi
}

# 要件変更検出
detect_changes() {
    echo -e "${BLUE}🔄 要件変更を検出中...${NC}"
    
    # 要件定義書のハッシュを保存・比較
    local hash_file=".requirements_hash"
    local current_hash=$(md5sum "$REQUIREMENTS_FILE" | cut -d' ' -f1)
    
    if [[ -f "$hash_file" ]]; then
        local previous_hash=$(cat "$hash_file")
        if [[ "$current_hash" != "$previous_hash" ]]; then
            echo -e "${YELLOW}⚠️  要件定義書が変更されています${NC}"
            echo -e "${CYAN}   変更日時: $(stat -f %Sm -t '%Y-%m-%d %H:%M:%S' "$REQUIREMENTS_FILE")${NC}"
            
            # 変更履歴を記録
            local change_log=".requirements_changes.log"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 要件定義書が更新されました" >> "$change_log"
            
            return 0  # 変更あり
        fi
    fi
    
    echo "$current_hash" > "$hash_file"
    return 1  # 変更なし
}

# サマリー表示
show_summary() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ エージェント生成完了${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}📊 生成結果:${NC}"
    echo "  エージェント数: $(ls -1 "$AGENTS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')"
    echo "  ドキュメント: $(find "$DOCS_DIR" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')"
    echo ""
    echo -e "${CYAN}📁 生成ファイル:${NC}"
    echo "  • $AGENTS_DIR/*.md - エージェント定義"
    echo "  • $DOCS_DIR/*/REQUIREMENTS.md - 個別要件"
    echo "  • $DOCS_DIR/*/CHECKLIST.md - チェックリスト"
    echo "  • $DOCS_DIR/*/HISTORY.md - 作業履歴"
    echo "  • CLAUDE.md - API整合性保証設定書"
    echo ""
    echo -e "${CYAN}🚀 次のステップ:${NC}"
    echo "  1. 生成されたエージェントを確認"
    echo "  2. API仕様書を定義: api-spec-system/specs/core/api-spec.yaml"
    echo "  3. コード生成: cd api-spec-system && make generate"
    echo "  4. PMエージェントでタスク管理開始"
    echo ""
    echo -e "${YELLOW}💡 ヒント:${NC}"
    echo "  • 要件変更時は再度このスクリプトを実行"
    echo "  • -u オプションで既存エージェントを更新"
    echo "  • -b オプションでバックアップ作成を推奨"
    echo ""
    echo -e "${RED}⚠️  API仕様システムルール:${NC}"
    echo "  • APIの変更は必ず specs/*.yaml から開始"
    echo "  • generated/ ディレクトリは直接編集禁止"
    echo "  • make validate で仕様検証"
    echo "  • make compliance で準拠性チェック"
}

# メイン処理
main() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🚀 要件定義書ベースのエージェント生成${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # 要件定義書の検証
    validate_requirements
    
    if [[ "$VALIDATE_ONLY" == true ]]; then
        echo -e "${GREEN}検証のみモードで終了${NC}"
        exit 0
    fi
    
    # 変更検出
    if detect_changes; then
        echo -e "${YELLOW}要件が変更されているため、エージェントを更新します${NC}"
        UPDATE_MODE=true
    fi
    
    # バックアップ
    create_backup
    
    # ディレクトリ作成
    mkdir -p "$AGENTS_DIR" "$DOCS_DIR"
    
    # エージェント抽出
    echo -e "${BLUE}📋 エージェントを生成中...${NC}"
    
    local agents_data=$(extract_agents)
    
    if [[ -z "$agents_data" ]]; then
        echo -e "${RED}エラー: エージェント定義が見つかりません${NC}"
        exit 1
    fi
    
    # エージェント生成
    for agent_info in $agents_data; do
        IFS=':' read -r name desc priority <<< "$agent_info"
        
        # 空のエージェント名をスキップ
        if [[ -z "$name" ]] || [[ -z "$desc" ]]; then
            continue
        fi
        
        if [[ -n "$SPECIFIC_AGENT" ]] && [[ "$name" != "$SPECIFIC_AGENT" ]]; then
            continue
        fi
        
        generate_agent_file "$name" "$desc" "$priority"
        generate_agent_docs "$name" "$desc" "$priority"
    done
    
    # Context7 MCPサーバーのセットアップ
    echo ""
    echo -e "${BLUE}🔧 Context7 MCPサーバーをセットアップ中...${NC}"
    
    # Context7がまだ追加されていない場合のみ実行
    if ! claude mcp list 2>/dev/null | grep -q "context7"; then
        claude mcp add context7 -- npx --yes @upstash/context7-mcp
        echo -e "${GREEN}✅ Context7 MCPサーバーをインストールしました${NC}"
    else
        echo -e "${CYAN}ℹ️  Context7 MCPサーバーは既にインストール済みです${NC}"
    fi
    
    # CLAUDE.md の自動生成
    echo ""
    echo -e "${BLUE}📝 CLAUDE.md（API整合性保証設定書）を生成中...${NC}"
    
    if [ -f "scripts/generate_claude_md.sh" ]; then
        chmod +x scripts/generate_claude_md.sh
        if ./scripts/generate_claude_md.sh > /dev/null 2>&1; then
            echo -e "${GREEN}✅ CLAUDE.md を生成しました（API整合性強化版）${NC}"
            echo -e "${CYAN}   • バックエンド/フロントエンド間の整合性を保証${NC}"
            echo -e "${CYAN}   • 自動生成コードによる型安全性を確保${NC}"
            echo -e "${CYAN}   • すべてのSubAgentが遵守すべきルールを定義${NC}"
        else
            echo -e "${YELLOW}⚠️  CLAUDE.md の生成に失敗しました${NC}"
            echo -e "${YELLOW}   手動で実行: ./scripts/generate_claude_md.sh${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  generate_claude_md.sh が見つかりません${NC}"
    fi
    
    # サマリー表示
    show_summary
}

# 実行
main