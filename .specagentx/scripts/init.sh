#!/bin/bash

# SpecAgentX 初期化スクリプト
# Version: 2.0.0
# Description: SpecAgentXプロジェクトの初期化と環境設定

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ロゴ表示
show_logo() {
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════╗
║                                                   ║
║   ███████╗██████╗ ███████╗ ██████╗               ║
║   ██╔════╝██╔══██╗██╔════╝██╔════╝               ║
║   ███████╗██████╔╝█████╗  ██║                    ║
║   ╚════██║██╔═══╝ ██╔══╝  ██║                    ║
║   ███████║██║     ███████╗╚██████╗               ║
║   ╚══════╝╚═╝     ╚══════╝ ╚═════╝               ║
║                                                   ║
║    █████╗  ██████╗ ███████╗███╗   ██╗████████╗   ║
║   ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝   ║
║   ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║      ║
║   ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║      ║
║   ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║      ║
║   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝      ║
║                                                   ║
║           ╔╗╔                                     ║
║           ╔╝╚╝                                    ║
║           ╚╗╔╗                                    ║  
║           ╚╝╚╝                                    ║
║                                                   ║
║   Specification-driven Agent eXecution System    ║
║                 Version 2.0.0                     ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# プログレスバー表示
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '='
    printf "%$((width - filled))s" | tr ' ' ' '
    printf "] %3d%%" $percentage
}

# 基本ディレクトリ構造の作成
create_directory_structure() {
    echo -e "${YELLOW}📁 ディレクトリ構造を作成中...${NC}"
    
    local dirs=(
        ".specagentx/docs"
        ".specagentx/pm/TEMPLATES"
        ".specagentx/pm/SUMMARY"
        ".specagentx/agents/api-designer"
        ".specagentx/agents/backend-impl"
        ".specagentx/agents/frontend-impl"
        ".specagentx/agents/mobile-impl"
        ".specagentx/agents/db-designer"
        ".specagentx/agents/infra-architect"
        ".specagentx/agents/test-qa"
        ".specagentx/agents/cicd"
        ".specagentx/specifications/common"
        ".specagentx/specifications/languages/go"
        ".specagentx/specifications/languages/javascript"
        ".specagentx/specifications/languages/python"
        ".specagentx/specifications/languages/java"
        ".specagentx/specifications/languages/rust"
        ".specagentx/scripts"
        ".claude/agents"
    )
    
    local total=${#dirs[@]}
    local current=0
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        current=$((current + 1))
        show_progress $current $total
        sleep 0.05
    done
    
    echo -e "\n${GREEN}✅ ディレクトリ構造作成完了${NC}"
}

# 初期ファイルの作成
create_initial_files() {
    echo -e "${YELLOW}📝 初期ファイルを作成中...${NC}"
    
    # .gitignore
    cat > .gitignore << 'EOF'
# SpecAgentX
.specagentx/TOKENS_USAGE.md
.specagentx/CONTEXT_CACHE.md
.specagentx/pm/PROGRESS_OVERVIEW.md
.specagentx/agents/*/PROGRESS.md
.specagentx/agents/*/OUTCOME.md

# Environment
.env
.env.local
*.log

# Dependencies
node_modules/
vendor/
venv/
__pycache__/

# Build
dist/
build/
*.exe
*.dll
*.so
*.dylib

# IDE
.vscode/
.idea/
*.swp
*.swo
.DS_Store
EOF

    # README
    cat > README.md << 'EOF'
# SpecAgentX Project

このプロジェクトはSpecAgentXによって管理されています。

## 構造

- `.specagentx/` - システムファイル（隠しディレクトリ）
- `.claude/` - ClaudeCode設定
- プロジェクトコードはルートディレクトリに自由に配置可能

## 使用方法

1. 要件定義: `.specagentx/REQUIREMENTS.md`を編集
2. 技術仕様: `.specagentx/SPECIFICATIONS.md`を編集
3. エージェント起動: ClaudeCodeで実行

## コマンド

```bash
# 初期化
.specagentx/scripts/init.sh

# エージェント生成
.specagentx/scripts/generate_agents.sh

# 進捗確認
cat .specagentx/pm/PROGRESS_OVERVIEW.md
```
EOF

    echo -e "${GREEN}✅ 初期ファイル作成完了${NC}"
}

# エージェント定義の初期化
initialize_agents() {
    echo -e "${YELLOW}🤖 エージェント定義を初期化中...${NC}"
    
    # 各エージェントディレクトリにDEFINITION.mdを配置
    local agents=(
        "api-designer"
        "backend-impl"
        "frontend-impl"
        "mobile-impl"
        "db-designer"
        "infra-architect"
        "test-qa"
        "cicd"
    )
    
    for agent in "${agents[@]}"; do
        touch ".specagentx/agents/$agent/DEFINITION.md"
        touch ".specagentx/agents/$agent/PLAN.md"
        touch ".specagentx/agents/$agent/PROGRESS.md"
        echo "# $agent OUTCOME" > ".specagentx/agents/$agent/OUTCOME.md"
    done
    
    echo -e "${GREEN}✅ エージェント定義初期化完了${NC}"
}

# 環境変数設定
setup_environment() {
    echo -e "${YELLOW}⚙️  環境変数を設定中...${NC}"
    
    if [ ! -f .env ]; then
        cat > .env << 'EOF'
# SpecAgentX Configuration
SPECAGENTX_VERSION=2.0.0
SPECAGENTX_HOME=.specagentx
SPECAGENTX_MODE=development

# Project Settings
PROJECT_NAME=MyProject
PROJECT_VERSION=1.0.0

# Language Settings
PRIMARY_LANGUAGE=go
SECONDARY_LANGUAGES=javascript,python

# Feature Flags
ENABLE_TOKEN_TRACKING=true
ENABLE_CONTEXT_CACHE=true
ENABLE_AUTO_PROGRESS=true
EOF
        echo -e "${GREEN}✅ .env ファイル作成完了${NC}"
    else
        echo -e "${BLUE}ℹ️  .env ファイルは既に存在します${NC}"
    fi
}

# 互換性チェック
check_compatibility() {
    echo -e "${YELLOW}🔍 互換性をチェック中...${NC}"
    
    # 既存のAgenixプロジェクトチェック
    if [ -f "REQUIREMENTS.md" ] && [ ! -f ".specagentx/REQUIREMENTS.md" ]; then
        echo -e "${BLUE}ℹ️  既存のAgenixプロジェクトを検出しました${NC}"
        read -p "既存のファイルを移行しますか？ (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            migrate_from_agenix
        fi
    fi
}

# Agenixからの移行
migrate_from_agenix() {
    echo -e "${YELLOW}📦 Agenixから移行中...${NC}"
    
    # バックアップ作成
    backup_dir="../Agenix_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    cp -r . "$backup_dir/"
    echo -e "${GREEN}✅ バックアップ作成: $backup_dir${NC}"
    
    # ファイル移行
    [ -f "REQUIREMENTS.md" ] && mv REQUIREMENTS.md .specagentx/
    [ -f "SPECIFICATIONS.md" ] && mv SPECIFICATIONS.md .specagentx/
    [ -d "agents" ] && cp -r agents/* .specagentx/agents/ 2>/dev/null || true
    [ -d "docs" ] && cp -r docs/* .specagentx/docs/ 2>/dev/null || true
    
    echo -e "${GREEN}✅ 移行完了${NC}"
}

# 完了メッセージ
show_completion() {
    echo -e "${GREEN}"
    cat << "EOF"

╔═══════════════════════════════════════════════════╗
║                                                   ║
║            ✨ 初期化完了！ ✨                      ║
║                                                   ║
║   SpecAgentXの準備が整いました。                   ║
║                                                   ║
║   次のステップ:                                   ║
║   1. .specagentx/REQUIREMENTS.md を編集          ║
║   2. .specagentx/SPECIFICATIONS.md を編集        ║
║   3. ClaudeCodeでエージェントを起動              ║
║                                                   ║
║   詳細は README.md をご覧ください。              ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# メイン処理
main() {
    show_logo
    
    echo -e "${BLUE}SpecAgentX 初期化を開始します...${NC}\n"
    
    create_directory_structure
    create_initial_files
    initialize_agents
    setup_environment
    check_compatibility
    
    show_completion
}

# 実行
main "$@"