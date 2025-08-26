#!/usr/bin/env bash
# プロジェクトを初期状態に戻すクリーンアップスクリプト
set -euo pipefail

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🧹 プロジェクト初期化クリーンアップ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}⚠️  警告: このスクリプトは生成されたファイルをすべて削除します${NC}"
echo -e "${YELLOW}以下のディレクトリ/ファイルが削除されます:${NC}"
echo ""
echo "  • .claude/      (エージェント定義とPM設定)"
echo "  • .claude/hooks/ (PM自動振り分けシステム)"
echo "  • .claude/context7/ (Context7設定)"
echo "  • .github/workflows/ (CI/CD設定)"
echo "  • docs/         (エージェントドキュメント)"
echo "  • generated/    (自動生成コード)"
echo "  • .api-spec-system/generated/ (生成されたコード)"
echo "  • .api-spec-system/specs/core/api-spec.yaml (初期API仕様)"
echo "  • .api-spec-system/compliance-report.json"
echo "  • .api-spec-system/node_modules/"
echo "  • .api-spec-system/package-lock.json"
echo "  • CLAUDE.md     (自動生成された指示書)"
echo "  • PM_AGENT_GUIDE.md (PMガイド)"
echo "  • API_SPEC_ENFORCEMENT.md"
echo "  • .requirements_hash"
echo "  • .requirements_backup"
echo "  • .requirements_changes.log"
echo "  • .agent-cache/"
echo "  • scripts/.deprecated_*"
echo "  • scripts/.path_update_backup_*"
echo "  • scripts/core/pm_aliases.sh"
echo "  • scripts/*.bak"
echo "  • *.agent.tmp"
echo ""
echo -e "${CYAN}以下は保持されます:${NC}"
echo "  ✓ REQUIREMENTS.md (ビジネス要件)"
echo "  ✓ SPECIFICATIONS.md (技術仕様)"
echo "  ✓ AGENT_DEFINITIONS.md (エージェント定義)"
echo "  ✓ README.md"
echo "  ✓ scripts/ (スクリプト本体)"
echo "  ✓ .claude-templates/ (テンプレートファイル)"
echo "  ✓ .api-spec-system/ (仕様システム本体、生成物以外)"
echo ""

read -p "本当に初期状態に戻しますか？ [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${YELLOW}キャンセルしました${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🗑️  クリーンアップを開始...${NC}"

# 生成されたディレクトリの削除
if [[ -d ".claude" ]]; then
    rm -rf .claude
    echo -e "${GREEN}✅ .claude/ を削除しました${NC}"
fi

if [[ -d ".github/workflows" ]]; then
    rm -rf .github/workflows
    echo -e "${GREEN}✅ .github/workflows/ を削除しました${NC}"
fi

if [[ -d "docs" ]]; then
    rm -rf docs
    echo -e "${GREEN}✅ docs/ を削除しました${NC}"
fi

# 自動生成ファイルの削除
if [[ -f "CLAUDE.md" ]]; then
    rm -f CLAUDE.md
    echo -e "${GREEN}✅ CLAUDE.md を削除しました${NC}"
fi

if [[ -f "PM_AGENT_GUIDE.md" ]]; then
    rm -f PM_AGENT_GUIDE.md
    echo -e "${GREEN}✅ PM_AGENT_GUIDE.md を削除しました${NC}"
fi

# 追跡ファイルの削除
rm -f .requirements_hash .requirements_backup .requirements_changes.log
echo -e "${GREEN}✅ 追跡ファイルを削除しました${NC}"

# API Spec System関連のクリーンアップ
if [[ -d ".api-spec-system/generated" ]]; then
    rm -rf .api-spec-system/generated
    echo -e "${GREEN}✅ .api-spec-system/generated/ を削除しました${NC}"
fi

if [[ -f ".api-spec-system/specs/core/api-spec.yaml" ]]; then
    rm -f .api-spec-system/specs/core/api-spec.yaml
    echo -e "${GREEN}✅ .api-spec-system/specs/core/api-spec.yaml を削除しました${NC}"
fi

if [[ -d ".api-spec-system/specs" ]]; then
    # specsディレクトリが空の場合は削除
    if [[ -z "$(ls -A .api-spec-system/specs 2>/dev/null)" ]]; then
        rm -rf .api-spec-system/specs
        echo -e "${GREEN}✅ .api-spec-system/specs/ を削除しました${NC}"
    fi
fi

if [[ -d ".api-spec-system/templates" ]]; then
    # templatesディレクトリが空の場合は削除
    if [[ -z "$(ls -A .api-spec-system/templates 2>/dev/null)" ]]; then
        rm -rf .api-spec-system/templates
        echo -e "${GREEN}✅ .api-spec-system/templates/ を削除しました${NC}"
    fi
fi

if [[ -d ".api-spec-system/scripts" ]]; then
    # scriptsディレクトリが空の場合は削除
    if [[ -z "$(ls -A .api-spec-system/scripts 2>/dev/null)" ]]; then
        rm -rf .api-spec-system/scripts
        echo -e "${GREEN}✅ .api-spec-system/scripts/ を削除しました${NC}"
    fi
fi

if [[ -f ".api-spec-system/compliance-report.json" ]]; then
    rm -f .api-spec-system/compliance-report.json
    echo -e "${GREEN}✅ compliance-report.json を削除しました${NC}"
fi

if [[ -d ".api-spec-system/node_modules" ]]; then
    rm -rf .api-spec-system/node_modules
    echo -e "${GREEN}✅ node_modules/ を削除しました${NC}"
fi

if [[ -f ".api-spec-system/package-lock.json" ]]; then
    rm -f .api-spec-system/package-lock.json
    echo -e "${GREEN}✅ package-lock.json を削除しました${NC}"
fi

# .api-spec-systemディレクトリ全体が空の場合は削除
if [[ -d ".api-spec-system" ]]; then
    if [[ -z "$(ls -A .api-spec-system 2>/dev/null)" ]]; then
        rm -rf .api-spec-system
        echo -e "${GREEN}✅ .api-spec-system/ を削除しました${NC}"
    fi
fi

if [[ -f "API_SPEC_ENFORCEMENT.md" ]]; then
    rm -f API_SPEC_ENFORCEMENT.md
    echo -e "${GREEN}✅ API_SPEC_ENFORCEMENT.md を削除しました${NC}"
fi

# バックアップディレクトリの削除
if ls scripts/.deprecated_* 1> /dev/null 2>&1; then
    rm -rf scripts/.deprecated_*
    echo -e "${GREEN}✅ 非推奨スクリプトのバックアップを削除しました${NC}"
fi

if ls scripts/.path_update_backup_* 1> /dev/null 2>&1; then
    rm -rf scripts/.path_update_backup_*
    echo -e "${GREEN}✅ パス更新バックアップを削除しました${NC}"
fi

# .bakファイルの削除
if ls scripts/*.bak 1> /dev/null 2>&1; then
    rm -f scripts/*.bak
    echo -e "${GREEN}✅ .bakファイルを削除しました${NC}"
fi

# .backup ディレクトリの削除
if [[ -d ".backup" ]]; then
    rm -rf .backup
    echo -e "${GREEN}✅ .backup/ を削除しました${NC}"
fi

# generated ディレクトリの削除
if [[ -d "generated" ]]; then
    rm -rf generated
    echo -e "${GREEN}✅ generated/ を削除しました${NC}"
fi

# .agent-cache ディレクトリの削除
if [[ -d ".agent-cache" ]]; then
    rm -rf .agent-cache
    echo -e "${GREEN}✅ .agent-cache/ を削除しました${NC}"
fi

# PM自動振り分けシステム関連の削除
if [[ -f "scripts/core/pm_aliases.sh" ]]; then
    rm -f scripts/core/pm_aliases.sh
    echo -e "${GREEN}✅ pm_aliases.sh を削除しました${NC}"
fi

# 一時ファイルの削除
if ls *.agent.tmp 1> /dev/null 2>&1; then
    rm -f *.agent.tmp
    echo -e "${GREEN}✅ *.agent.tmp ファイルを削除しました${NC}"
fi

# .git/hooks の削除
if [[ -f ".git/hooks/pre-commit" ]]; then
    rm -f .git/hooks/pre-commit
    echo -e "${GREEN}✅ .git/hooks/pre-commit を削除しました${NC}"
fi

if [[ -f ".git/hooks/commit-msg" ]]; then
    rm -f .git/hooks/commit-msg
    echo -e "${GREEN}✅ .git/hooks/commit-msg を削除しました${NC}"
fi

# SPECIFICATIONS.md と AGENT_DEFINITIONS.md は保持（ユーザーが作成した場合）

# Node.js関連の削除（オプション）
if [[ -d "scripts/requirements" ]]; then
    echo ""
    echo -e "${YELLOW}Node.js要件定義ツールが検出されました${NC}"
    read -p "scripts/requirements/ も削除しますか？ [y/N]: " remove_node
    if [[ "$remove_node" == "y" || "$remove_node" == "Y" ]]; then
        rm -rf scripts/requirements
        echo -e "${GREEN}✅ scripts/requirements/ を削除しました${NC}"
    fi
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ クリーンアップ完了！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📝 現在の状態:${NC}"
echo "  • プロジェクトは初期状態に戻りました"
echo "  • REQUIREMENTS.md は保持されています"
echo "  • SPECIFICATIONS.md は保持されています"
echo "  • AGENT_DEFINITIONS.md は保持されています"
echo "  • すべてのスクリプトは利用可能です"
echo ""
echo -e "${CYAN}🚀 再セットアップ方法:${NC}"
echo ""
echo "  1. 基本セットアップ:"
echo -e "     ${YELLOW}./scripts/setup.sh${NC}"
echo ""
echo "  2. エージェント生成（PM自動振り分け、Context7も自動設定）:"
echo -e "     ${YELLOW}./scripts/core/generate_agents.sh${NC}"
echo ""
echo "  これで、PMによる自動振り分け機能とContext7を含む"
echo "  すべての機能が再生成されます。"
echo ""