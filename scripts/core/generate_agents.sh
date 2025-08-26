#!/usr/bin/env bash
# 3つのマークダウンファイルからエージェントを生成するスクリプト
# REQUIREMENTS.md, SPECIFICATIONS.md, AGENT_DEFINITIONS.md を参照
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
SPECIFICATIONS_FILE="SPECIFICATIONS.md"
AGENT_DEFINITIONS_FILE="AGENT_DEFINITIONS.md"
AGENTS_DIR=".claude/agents"
DOCS_DIR="docs/agents"
BACKUP_DIR=".backup"

# ヘルプ表示
show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 統合エージェント生成システム
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

使用方法: ./scripts/core/generate_agents.sh [オプション]

オプション:
    -a, --agent AGENT       特定のエージェントのみ生成
    -u, --update            既存エージェントを更新
    -b, --backup            更新前にバックアップを作成
    -v, --validate          ドキュメントの検証のみ実行
    -h, --help              このヘルプを表示

例:
    # すべてのエージェントを生成
    ./scripts/core/generate_agents.sh

    # 特定のエージェントのみ更新
    ./scripts/core/generate_agents.sh -a api -u

    # バックアップを作成して更新
    ./scripts/core/generate_agents.sh -u -b

    # ドキュメントの検証
    ./scripts/core/generate_agents.sh -v

ワークフロー:
    1. REQUIREMENTS.md からビジネス要件を抽出
    2. SPECIFICATIONS.md から技術仕様を抽出
    3. AGENT_DEFINITIONS.md からエージェント定義を抽出
    4. 統合してエージェントファイルを生成
    5. .claude/agents/ にエージェントファイル作成
    6. docs/agents/ にドキュメント配置
EOF
}

# 引数解析
SPECIFIC_AGENT=""
UPDATE_MODE=false
BACKUP_MODE=false
VALIDATE_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
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

# ドキュメントの存在確認と検証
validate_documents() {
    echo -e "${BLUE}📋 ドキュメントを検証中...${NC}"
    
    local all_valid=true
    
    # REQUIREMENTS.md の検証
    if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
        echo -e "${RED}エラー: REQUIREMENTS.md が見つかりません${NC}"
        all_valid=false
    else
        echo -e "${GREEN}✅ REQUIREMENTS.md 検出${NC}"
        # 必須セクションの確認
        if ! grep -q "## 1. プロジェクト概要" "$REQUIREMENTS_FILE"; then
            echo -e "${YELLOW}  警告: プロジェクト概要セクションが見つかりません${NC}"
        fi
        if ! grep -q "## 2. ビジネス要件" "$REQUIREMENTS_FILE"; then
            echo -e "${YELLOW}  警告: ビジネス要件セクションが見つかりません${NC}"
        fi
    fi
    
    # SPECIFICATIONS.md の検証
    if [[ ! -f "$SPECIFICATIONS_FILE" ]]; then
        echo -e "${RED}エラー: SPECIFICATIONS.md が見つかりません${NC}"
        all_valid=false
    else
        echo -e "${GREEN}✅ SPECIFICATIONS.md 検出${NC}"
        # 技術スタックの確認
        if ! grep -q "## .* 技術スタック" "$SPECIFICATIONS_FILE"; then
            echo -e "${YELLOW}  警告: 技術スタックセクションが見つかりません${NC}"
        fi
    fi
    
    # AGENT_DEFINITIONS.md の検証
    if [[ ! -f "$AGENT_DEFINITIONS_FILE" ]]; then
        echo -e "${RED}エラー: AGENT_DEFINITIONS.md が見つかりません${NC}"
        all_valid=false
    else
        echo -e "${GREEN}✅ AGENT_DEFINITIONS.md 検出${NC}"
        # エージェント定義の確認
        if ! grep -q "## 2. コアエージェント一覧" "$AGENT_DEFINITIONS_FILE"; then
            echo -e "${YELLOW}  警告: コアエージェント一覧セクションが見つかりません${NC}"
        fi
    fi
    
    if [[ "$all_valid" == false ]]; then
        echo -e "${RED}エラー: 必要なドキュメントが不足しています${NC}"
        echo -e "${YELLOW}ヒント: まず以下のファイルを作成してください:${NC}"
        echo -e "  - REQUIREMENTS.md (ビジネス要件)"
        echo -e "  - SPECIFICATIONS.md (技術仕様)"
        echo -e "  - AGENT_DEFINITIONS.md (エージェント定義)"
        exit 1
    fi
    
    echo -e "${GREEN}✅ すべてのドキュメントの検証完了${NC}"
}

# REQUIREMENTS.md からビジネス要件を抽出
extract_business_requirements() {
    local agent_name="$1"
    local requirements=""
    
    # プロジェクト概要を抽出
    local project_name=$(grep -A1 "| \*\*プロジェクト名\*\*" "$REQUIREMENTS_FILE" | tail -1 | sed 's/.*| \(.*\) |.*/\1/' | xargs)
    
    # ビジネス要件の目的を抽出
    local in_purpose=false
    while IFS= read -r line; do
        if [[ "$line" =~ "### 2.1 目的" ]]; then
            in_purpose=true
            continue
        fi
        if [[ "$in_purpose" == true ]]; then
            if [[ "$line" =~ "###" ]]; then
                break
            fi
            if [[ "$line" =~ ^-[[:space:]] ]]; then
                requirements="${requirements}${line}\n"
            fi
        fi
    done < "$REQUIREMENTS_FILE"
    
    echo -e "$requirements"
}

# SPECIFICATIONS.md から技術仕様を抽出
extract_technical_specs() {
    local agent_name="$1"
    local specs=""
    
    case "$agent_name" in
        api)
            # Go-Zero仕様を抽出
            specs=$(sed -n '/### .*バックエンド - Go-Zero/,/### .*フロントエンド/p' "$SPECIFICATIONS_FILE" | head -n -1)
            ;;
        next)
            # Next.js仕様を抽出
            specs=$(sed -n '/### .*フロントエンド - Next.js/,/### .*モバイル/p' "$SPECIFICATIONS_FILE" | head -n -1)
            ;;
        expo)
            # Expo仕様を抽出
            specs=$(sed -n '/### .*モバイル - Expo/,/## /p' "$SPECIFICATIONS_FILE" | head -n -1)
            ;;
        *)
            # 汎用的な技術スタックを抽出
            specs="OpenAPI 3.1.0 準拠\nDocker/Kubernetes対応\nCI/CD: GitHub Actions"
            ;;
    esac
    
    echo "$specs"
}

# AGENT_DEFINITIONS.md からエージェント詳細を抽出
extract_agent_details() {
    local agent_name="$1"
    local details=""
    
    # エージェント詳細セクションを抽出
    local in_agent_section=false
    local found_agent=false
    
    while IFS= read -r line; do
        if [[ "$line" =~ "### 3.*${agent_name} エージェント" ]]; then
            found_agent=true
            in_agent_section=true
            continue
        fi
        
        if [[ "$in_agent_section" == true ]]; then
            if [[ "$line" =~ "### 3\." ]] && [[ ! "$line" =~ "$agent_name" ]]; then
                break
            fi
            details="${details}${line}\n"
        fi
    done < "$AGENT_DEFINITIONS_FILE"
    
    if [[ "$found_agent" == false ]]; then
        # コアエージェント一覧から基本情報を取得
        details=$(grep "^| $agent_name " "$AGENT_DEFINITIONS_FILE" || echo "")
    fi
    
    echo -e "$details"
}

# エージェントリストの抽出
extract_agents() {
    echo -e "${BLUE}🔍 エージェント定義を抽出中...${NC}"
    
    local agents=()
    local in_agent_section=false
    
    while IFS= read -r line; do
        if [[ "$line" =~ "### 2.1 エージェント概要" ]]; then
            in_agent_section=true
            continue
        fi
        
        if [[ "$in_agent_section" == true ]]; then
            if [[ "$line" =~ "## 3." ]]; then
                break
            fi
            
            # テーブル行からエージェント情報を抽出
            if [[ "$line" =~ ^\|[[:space:]]*([a-z]+)[[:space:]]*\|[[:space:]]*([^|]+)[[:space:]]*\|[[:space:]]*(High|Medium|Low)[[:space:]]*\|[[:space:]]*([^|]+)[[:space:]]*\| ]]; then
                local agent_name="${BASH_REMATCH[1]}"
                local agent_desc="$(echo "${BASH_REMATCH[2]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
                local agent_priority="${BASH_REMATCH[3]}"
                local agent_area="$(echo "${BASH_REMATCH[4]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
                
                # ヘッダー行を除外
                if [[ "$agent_name" != "エージェント名" ]] && [[ "$agent_name" =~ ^[a-z]{2,20}$ ]]; then
                    agents+=("${agent_name}:${agent_desc}:${agent_priority}:${agent_area}")
                    echo -e "  ${GREEN}✓${NC} 検出: ${agent_name} - ${agent_desc}"
                fi
            fi
        fi
    done < "$AGENT_DEFINITIONS_FILE"
    
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
    local agent_area="$4"
    
    local agent_file="$AGENTS_DIR/${agent_name}.md"
    
    # 既存チェック
    if [[ -f "$agent_file" ]] && [[ "$UPDATE_MODE" != true ]]; then
        echo -e "${YELLOW}  スキップ: $agent_name (既存)${NC}"
        return
    fi
    
    echo -e "${CYAN}  生成中: $agent_name${NC}"
    
    # 3つのドキュメントから情報を統合
    local business_req=$(extract_business_requirements "$agent_name")
    local tech_specs=$(extract_technical_specs "$agent_name")
    local agent_details=$(extract_agent_details "$agent_name")
    
    # エージェントファイル作成
    cat > "$agent_file" << EOF
---
name: $agent_name
description: $agent_desc
priority: $agent_priority
specialization: $agent_area
---

# ${agent_name} エージェント

## 概要
$agent_desc

専門領域: $agent_area

## ビジネス要件（REQUIREMENTS.md より）
$business_req

## 技術仕様（SPECIFICATIONS.md より）
$tech_specs

## エージェント詳細（AGENT_DEFINITIONS.md より）
$agent_details

## 作業指針

### 開発原則
- OpenAPI 3.1.0 仕様に準拠
- テスト駆動開発（TDD）を実践
- Clean Architectureの原則に従う
- エラーハンドリングを適切に実装

### 使用技術
$(get_agent_technologies "$agent_name")

### 成功基準
- REQUIREMENTS.md のビジネス要件を満たす
- SPECIFICATIONS.md の技術仕様に準拠
- AGENT_DEFINITIONS.md の責務を遂行
- テストカバレッジ 80% 以上
- ドキュメントが最新

### 連携エージェント
$(get_agent_dependencies "$agent_name")

## 注意事項
- 常に3つのマークダウンファイルを参照すること
- 変更時は docs/agents/${agent_name}/HISTORY.md を更新
- API変更は必ず OpenAPI 仕様書から開始
- generated/ ディレクトリは直接編集禁止
EOF
}

# エージェント固有の技術を取得
get_agent_technologies() {
    local agent="$1"
    
    case "$agent" in
        api)
            echo "- Go-Zero v1.7.0"
            echo "- PostgreSQL 16"
            echo "- Redis 7.2"
            echo "- gRPC"
            echo "- OpenAPI 3.1.0"
            ;;
        next)
            echo "- Next.js 15.0.0"
            echo "- React 19"
            echo "- TypeScript"
            echo "- Tailwind CSS 3.4"
            echo "- Zustand / TanStack Query"
            ;;
        expo)
            echo "- Expo SDK 51"
            echo "- React Native 0.74.0"
            echo "- Expo Router v3"
            echo "- NativeWind"
            ;;
        infra)
            echo "- Docker"
            echo "- Kubernetes"
            echo "- GitHub Actions"
            echo "- Terraform"
            ;;
        qa)
            echo "- Jest"
            echo "- Playwright"
            echo "- Vitest"
            echo "- OpenAPI Validator"
            ;;
        *)
            echo "- プロジェクト標準技術スタック"
            echo "- SPECIFICATIONS.md 参照"
            ;;
    esac
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
            echo "- すべてのエージェント: 進捗管理"
            ;;
        api|next|expo)
            echo "- pm: タスクを受け取る"
            echo "- requirements: 要件を確認"
            echo "- qa: テスト連携"
            echo "- OpenAPI仕様書を共有"
            ;;
        qa)
            echo "- すべての開発エージェント: テスト対象"
            echo "- security: セキュリティテスト連携"
            ;;
        security)
            echo "- すべてのエージェント: セキュリティ監査"
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
    local agent_area="$4"
    
    local agent_doc_dir="$DOCS_DIR/$agent_name"
    mkdir -p "$agent_doc_dir"
    
    # REQUIREMENTS.md
    cat > "$agent_doc_dir/REQUIREMENTS.md" << EOF
# ${agent_name} エージェント要件定義書

## 基本情報
- **エージェント名**: $agent_name
- **説明**: $agent_desc
- **優先度**: $agent_priority
- **専門領域**: $agent_area
- **更新日**: $(date +%Y-%m-%d)

## 参照ドキュメント
- [REQUIREMENTS.md](../../../REQUIREMENTS.md) - ビジネス要件
- [SPECIFICATIONS.md](../../../SPECIFICATIONS.md) - 技術仕様
- [AGENT_DEFINITIONS.md](../../../AGENT_DEFINITIONS.md) - エージェント定義

## エージェント固有要件

### 機能要件
$(extract_agent_details "$agent_name" | grep "^-" || echo "- AGENT_DEFINITIONS.md 参照")

### 技術要件
$(get_agent_technologies "$agent_name")

### 品質要件
- レスポンス時間: SPECIFICATIONS.md の性能要件に準拠
- エラー率: 1%未満
- テストカバレッジ: 80%以上
- ドキュメント: 100%

## 成功基準
- [ ] 3つのマークダウンファイルの要件を満たす
- [ ] OpenAPI仕様に準拠（該当する場合）
- [ ] テストが実装され、合格している
- [ ] ドキュメントが完成している
- [ ] コードレビューを通過

## 変更履歴
| 日付 | バージョン | 変更内容 |
|------|-----------|----------|
| $(date +%Y-%m-%d) | 1.0.0 | 初版作成（3ファイル統合版） |
EOF

    # CHECKLIST.md
    cat > "$agent_doc_dir/CHECKLIST.md" << EOF
# ${agent_name} エージェント チェックリスト

## 🔍 開始前チェック
- [ ] REQUIREMENTS.md（ビジネス要件）を確認
- [ ] SPECIFICATIONS.md（技術仕様）を確認
- [ ] AGENT_DEFINITIONS.md（エージェント定義）を確認
- [ ] OpenAPI仕様書を確認（該当する場合）
- [ ] 開発環境が準備完了

## 🔨 実装中チェック
- [ ] 技術仕様に従った実装
- [ ] OpenAPI仕様に準拠（API関連）
- [ ] エラーハンドリング実装
- [ ] ログ出力実装
- [ ] テスト同時作成

## ✅ 完了チェック
- [ ] 3つのドキュメントの要件を満たした
- [ ] 単体テスト合格
- [ ] 統合テスト合格
- [ ] ドキュメント更新
- [ ] コードレビュー完了
- [ ] HISTORY.md 更新

## 📝 リリース前チェック
- [ ] パフォーマンステスト実施
- [ ] セキュリティチェック実施
- [ ] OpenAPI仕様準拠確認
- [ ] 本番環境動作確認
EOF

    # HISTORY.md (初期化のみ)
    if [[ ! -f "$agent_doc_dir/HISTORY.md" ]]; then
        cat > "$agent_doc_dir/HISTORY.md" << EOF
# ${agent_name} エージェント 作業履歴

## 更新ログ

### $(date +%Y-%m-%d)
- **作業者**: System
- **作業内容**: エージェント初期生成（3ファイル統合版）
- **ステータス**: 完了
- **備考**: REQUIREMENTS.md, SPECIFICATIONS.md, AGENT_DEFINITIONS.md から自動生成

---
EOF
    fi
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
    echo ""
    echo -e "${CYAN}📚 参照ドキュメント:${NC}"
    echo "  • REQUIREMENTS.md - ビジネス要件"
    echo "  • SPECIFICATIONS.md - 技術仕様"
    echo "  • AGENT_DEFINITIONS.md - エージェント定義"
    echo ""
    echo -e "${CYAN}🚀 次のステップ:${NC}"
    echo "  1. 生成されたエージェントを確認"
    echo "  2. タスクを自動振り分け: ./scripts/core/pm_auto_dispatch.sh \"タスクの説明\""
    echo "  3. 必要に応じて各エージェントファイルをカスタマイズ"
    echo "  4. OpenAPI仕様書を定義（API開発の場合）"
    echo "  5. 開発を開始"
    echo ""
    echo -e "${YELLOW}💡 重要な原則:${NC}"
    echo "  • 常に3つのマークダウンファイルを真実の源とする"
    echo "  • API変更は OpenAPI 仕様書から開始"
    echo "  • generated/ ディレクトリは直接編集禁止"
    echo "  • テスト駆動開発（TDD）を実践"
}

# メイン処理
main() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🚀 統合エージェント生成システム${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # ドキュメントの検証
    validate_documents
    
    if [[ "$VALIDATE_ONLY" == true ]]; then
        echo -e "${GREEN}検証のみモードで終了${NC}"
        exit 0
    fi
    
    # バックアップ
    create_backup
    
    # ディレクトリ作成
    mkdir -p "$AGENTS_DIR" "$DOCS_DIR"
    
    # エージェント抽出
    echo ""
    echo -e "${BLUE}📋 エージェントを生成中...${NC}"
    
    local agents_data=$(extract_agents)
    
    if [[ -z "$agents_data" ]]; then
        echo -e "${RED}エラー: エージェント定義が見つかりません${NC}"
        exit 1
    fi
    
    # エージェント生成
    for agent_info in $agents_data; do
        IFS=':' read -r name desc priority area <<< "$agent_info"
        
        if [[ -z "$name" ]] || [[ -z "$desc" ]]; then
            continue
        fi
        
        if [[ -n "$SPECIFIC_AGENT" ]] && [[ "$name" != "$SPECIFIC_AGENT" ]]; then
            continue
        fi
        
        generate_agent_file "$name" "$desc" "$priority" "$area"
        generate_agent_docs "$name" "$desc" "$priority" "$area"
    done
    
    # CLAUDE.md の生成
    echo ""
    echo -e "${BLUE}📝 CLAUDE.md を生成中...${NC}"
    
    if [ -f "scripts/core/generate_claude_md.sh" ]; then
        chmod +x scripts/core/generate_claude_md.sh
        if ./scripts/core/generate_claude_md.sh > /dev/null 2>&1; then
            echo -e "${GREEN}✅ CLAUDE.md を生成しました${NC}"
        else
            echo -e "${YELLOW}⚠️  CLAUDE.md の生成に失敗しました${NC}"
        fi
    fi
    
    # PM自動振り分けシステムのセットアップ
    echo ""
    echo -e "${BLUE}🔧 PM自動振り分けシステムをセットアップ中...${NC}"
    
    if [[ -f "scripts/core/setup_pm_hooks.sh" ]]; then
        chmod +x scripts/core/setup_pm_hooks.sh
        if ./scripts/core/setup_pm_hooks.sh > /dev/null 2>&1; then
            echo -e "${GREEN}✅ PM自動振り分けシステムをセットアップしました${NC}"
            echo -e "${CYAN}   使用方法: ./scripts/core/pm_auto_dispatch.sh \"タスクの説明\"${NC}"
        else
            echo -e "${YELLOW}⚠️  PM自動振り分けシステムのセットアップをスキップしました${NC}"
            echo -e "${YELLOW}   手動でセットアップする場合: ./scripts/core/setup_pm_hooks.sh${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  setup_pm_hooks.sh が見つかりません${NC}"
        echo -e "${YELLOW}   PM自動振り分けシステムは後で手動セットアップしてください${NC}"
    fi
    
    # Context7 最新ドキュメント参照システムのセットアップ
    echo ""
    echo -e "${BLUE}📚 Context7 最新ドキュメント参照システムをセットアップ中...${NC}"
    
    if [[ -f "scripts/core/update_pm_context7.sh" ]]; then
        chmod +x scripts/core/update_pm_context7.sh
        if ./scripts/core/update_pm_context7.sh setup > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Context7 システムをセットアップしました${NC}"
            echo -e "${CYAN}   各エージェントが最新ドキュメントを参照可能になりました${NC}"
        else
            echo -e "${YELLOW}⚠️  Context7 システムのセットアップをスキップしました${NC}"
            echo -e "${YELLOW}   手動でセットアップする場合: ./scripts/core/update_pm_context7.sh setup${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  update_pm_context7.sh が見つかりません${NC}"
        echo -e "${YELLOW}   Context7 システムは後で手動セットアップしてください${NC}"
    fi
    
    # サマリー表示
    show_summary
}

# 実行
main