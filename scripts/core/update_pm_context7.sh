#!/usr/bin/env bash
# Context7 統合・最新ドキュメント参照システム
# 各エージェントに技術スタックの最新ドキュメントを参照させる
set -euo pipefail

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# 設定
AGENTS_DIR=".claude/agents"
CONTEXT7_CONFIG=".claude/context7"
LIBRARY_CACHE="$CONTEXT7_CONFIG/library_cache"
LAST_UPDATE_FILE="$CONTEXT7_CONFIG/last_update.json"

# ヘルプ表示
show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 Context7 最新ドキュメント参照システム
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

使用方法: ./scripts/core/update_pm_context7.sh [オプション] [コマンド]

コマンド:
    setup               Context7の初期セットアップ
    update              すべてのライブラリドキュメントを更新
    check <library>     特定のライブラリの最新バージョンを確認
    agent <name>        特定のエージェントに最新ドキュメントを設定
    all                 すべてのエージェントを更新

オプション:
    -f, --force         キャッシュを無視して強制更新
    -v, --verbose       詳細な出力
    -d, --dry-run       実行計画の表示のみ
    -h, --help          このヘルプを表示

例:
    # 初期セットアップ
    ./scripts/core/update_pm_context7.sh setup
    
    # すべてのドキュメントを更新
    ./scripts/core/update_pm_context7.sh update
    
    # APIエージェントに最新Go-Zeroドキュメントを設定
    ./scripts/core/update_pm_context7.sh agent api
    
    # Next.jsの最新バージョンを確認
    ./scripts/core/update_pm_context7.sh check nextjs

技術スタック:
    • Go-Zero (API)     - バックエンド開発
    • Next.js 15 (Next) - フロントエンド開発  
    • Expo SDK 51       - モバイル開発
    • PostgreSQL 16     - データベース
    • Redis 7.2         - キャッシュ
    • Docker/K8s        - インフラストラクチャ
EOF
}

# 引数解析
COMMAND=""
TARGET=""
FORCE=false
VERBOSE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        setup|update|check|agent|all)
            COMMAND="$1"
            if [[ "$1" == "check" || "$1" == "agent" ]]; then
                TARGET="$2"
                shift
            fi
            shift
            ;;
        *)
            if [[ -z "$COMMAND" ]]; then
                echo -e "${RED}エラー: 不明なコマンド: $1${NC}"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Context7 初期セットアップ
setup_context7() {
    echo -e "${BLUE}🔧 Context7をセットアップ中...${NC}"
    
    # ディレクトリ作成
    mkdir -p "$CONTEXT7_CONFIG"
    mkdir -p "$LIBRARY_CACHE"
    
    # ライブラリマッピング設定
    cat > "$CONTEXT7_CONFIG/library_mapping.json" << 'EOF'
{
  "libraries": {
    "go-zero": {
      "name": "go-zero",
      "context7_id": "/zeromicro/go-zero",
      "agents": ["api"],
      "description": "Go言語用マイクロサービスフレームワーク",
      "docs_url": "https://go-zero.dev/docs",
      "version_check": "github:zeromicro/go-zero"
    },
    "nextjs": {
      "name": "Next.js",
      "context7_id": "/vercel/next.js",
      "agents": ["next"],
      "description": "React製フルスタックフレームワーク",
      "docs_url": "https://nextjs.org/docs",
      "version_check": "npm:next"
    },
    "expo": {
      "name": "Expo",
      "context7_id": "/expo/expo",
      "agents": ["expo"],
      "description": "React Native開発プラットフォーム",
      "docs_url": "https://docs.expo.dev",
      "version_check": "npm:expo"
    },
    "postgresql": {
      "name": "PostgreSQL",
      "context7_id": "/postgresql/postgresql",
      "agents": ["api", "infra"],
      "description": "オープンソースリレーショナルデータベース",
      "docs_url": "https://www.postgresql.org/docs/",
      "version": "16"
    },
    "redis": {
      "name": "Redis",
      "context7_id": "/redis/redis",
      "agents": ["api", "infra"],
      "description": "インメモリデータストア",
      "docs_url": "https://redis.io/docs",
      "version": "7.2"
    },
    "docker": {
      "name": "Docker",
      "context7_id": "/docker/docker",
      "agents": ["infra"],
      "description": "コンテナ化プラットフォーム",
      "docs_url": "https://docs.docker.com"
    },
    "kubernetes": {
      "name": "Kubernetes",
      "context7_id": "/kubernetes/kubernetes",
      "agents": ["infra"],
      "description": "コンテナオーケストレーション",
      "docs_url": "https://kubernetes.io/docs"
    },
    "react": {
      "name": "React",
      "context7_id": "/facebook/react",
      "agents": ["next", "expo"],
      "description": "UIライブラリ",
      "docs_url": "https://react.dev",
      "version_check": "npm:react"
    },
    "typescript": {
      "name": "TypeScript",
      "context7_id": "/microsoft/TypeScript",
      "agents": ["next", "expo"],
      "description": "JavaScript型付き拡張",
      "docs_url": "https://www.typescriptlang.org/docs",
      "version_check": "npm:typescript"
    },
    "tailwindcss": {
      "name": "Tailwind CSS",
      "context7_id": "/tailwindlabs/tailwindcss",
      "agents": ["next"],
      "description": "ユーティリティファーストCSS",
      "docs_url": "https://tailwindcss.com/docs",
      "version_check": "npm:tailwindcss"
    },
    "jest": {
      "name": "Jest",
      "context7_id": "/facebook/jest",
      "agents": ["qa"],
      "description": "JavaScriptテストフレームワーク",
      "docs_url": "https://jestjs.io/docs",
      "version_check": "npm:jest"
    },
    "playwright": {
      "name": "Playwright",
      "context7_id": "/microsoft/playwright",
      "agents": ["qa"],
      "description": "E2Eテストフレームワーク",
      "docs_url": "https://playwright.dev/docs",
      "version_check": "npm:@playwright/test"
    }
  }
}
EOF
    
    # Context7 プロンプトテンプレート
    cat > "$CONTEXT7_CONFIG/prompt_template.md" << 'EOF'
# Context7 最新ドキュメント参照指示

## 使用可能なContext7ライブラリ

以下のライブラリの最新ドキュメントを参照できます：

### 技術スタック別ライブラリ
LIBRARY_LIST

## ドキュメント参照方法

1. **ライブラリID解決**:
   ```
   mcp__context7__resolve-library-id で "ライブラリ名" を検索
   ```

2. **最新ドキュメント取得**:
   ```
   mcp__context7__get-library-docs で Context7 ID を指定
   ```

## 参照例

### Go-Zero (API開発)
```
1. mcp__context7__resolve-library-id("go-zero")
2. mcp__context7__get-library-docs("/zeromicro/go-zero", topic="api-development")
```

### Next.js 15 (フロントエンド)
```
1. mcp__context7__resolve-library-id("nextjs")
2. mcp__context7__get-library-docs("/vercel/next.js", topic="app-router")
```

### Expo SDK 51 (モバイル)
```
1. mcp__context7__resolve-library-id("expo")
2. mcp__context7__get-library-docs("/expo/expo", topic="navigation")
```

## 重要な注意事項

- 実装前に必ず最新ドキュメントを参照すること
- バージョン固有の機能に注意すること
- 非推奨APIの使用を避けること
- ベストプラクティスに従うこと
EOF
    
    echo -e "${GREEN}✅ Context7セットアップ完了${NC}"
}

# ライブラリバージョンチェック
check_library_version() {
    local library="$1"
    
    echo -e "${BLUE}🔍 ${library} の最新バージョンを確認中...${NC}"
    
    # library_mapping.jsonから情報取得
    local lib_info=$(python3 -c "
import json
with open('$CONTEXT7_CONFIG/library_mapping.json', 'r') as f:
    data = json.load(f)
    if '$library' in data['libraries']:
        lib = data['libraries']['$library']
        print(f\"{lib['name']}|{lib.get('version_check', '')}|{lib.get('version', 'latest')}\")
" 2>/dev/null)
    
    if [[ -z "$lib_info" ]]; then
        echo -e "${RED}エラー: ライブラリ '$library' が見つかりません${NC}"
        return 1
    fi
    
    IFS='|' read -r name version_check current_version <<< "$lib_info"
    
    if [[ -n "$version_check" ]]; then
        if [[ "$version_check" =~ ^npm: ]]; then
            # NPMパッケージのバージョン確認
            local package="${version_check#npm:}"
            local latest=$(npm view "$package" version 2>/dev/null || echo "unknown")
            echo -e "${GREEN}  $name: 最新 v$latest${NC}"
        elif [[ "$version_check" =~ ^github: ]]; then
            # GitHubリリースの確認
            local repo="${version_check#github:}"
            local latest=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/' || echo "unknown")
            echo -e "${GREEN}  $name: 最新 v$latest${NC}"
        fi
    else
        echo -e "${GREEN}  $name: v$current_version (固定)${NC}"
    fi
}

# エージェントにContext7設定を追加
update_agent_context7() {
    local agent_name="$1"
    local agent_file="$AGENTS_DIR/${agent_name}.md"
    
    if [[ ! -f "$agent_file" ]]; then
        echo -e "${RED}エラー: エージェント '$agent_name' が見つかりません${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📝 ${agent_name} エージェントを更新中...${NC}"
    
    # 該当エージェント用のライブラリリストを生成
    local libraries=$(python3 -c "
import json
with open('$CONTEXT7_CONFIG/library_mapping.json', 'r') as f:
    data = json.load(f)
    libs = []
    for key, lib in data['libraries'].items():
        if '$agent_name' in lib['agents']:
            libs.append(f\"- **{lib['name']}** (Context7 ID: \`{lib['context7_id']}\`): {lib['description']}\")
    print('\\n'.join(libs))
" 2>/dev/null)
    
    if [[ -z "$libraries" ]]; then
        echo -e "${YELLOW}  ${agent_name} エージェント用のライブラリが設定されていません${NC}"
        return 0
    fi
    
    # Context7セクションを追加/更新
    local context7_section="
## Context7 最新ドキュメント参照

このエージェントは以下のライブラリの最新ドキュメントを参照できます：

$libraries

### ドキュメント参照手順

1. 実装開始前に必ず最新ドキュメントを確認
2. \`mcp__context7__resolve-library-id\` でライブラリIDを解決
3. \`mcp__context7__get-library-docs\` で最新ドキュメントを取得
4. バージョン固有の機能と非推奨APIに注意

### 参照コマンド例

\`\`\`bash
# ライブラリIDの解決
mcp__context7__resolve-library-id(\"ライブラリ名\")

# ドキュメント取得
mcp__context7__get-library-docs(\"/org/project\", topic=\"specific-topic\")
\`\`\`
"
    
    # エージェントファイルにContext7セクションがあるか確認
    if grep -q "## Context7 最新ドキュメント参照" "$agent_file"; then
        # 既存セクションを更新
        echo -e "${CYAN}  既存のContext7セクションを更新${NC}"
        
        # 一時ファイルに書き出し
        local temp_file="/tmp/agent_context7_$$.md"
        local in_context7=false
        local skip_until_next_section=false
        
        while IFS= read -r line; do
            if [[ "$line" =~ ^##[[:space:]]Context7 ]]; then
                in_context7=true
                skip_until_next_section=true
                echo "$context7_section" >> "$temp_file"
            elif [[ "$skip_until_next_section" == true ]] && [[ "$line" =~ ^## ]]; then
                skip_until_next_section=false
                echo "$line" >> "$temp_file"
            elif [[ "$skip_until_next_section" == false ]]; then
                echo "$line" >> "$temp_file"
            fi
        done < "$agent_file"
        
        mv "$temp_file" "$agent_file"
    else
        # 新規セクションを追加
        echo -e "${CYAN}  新規Context7セクションを追加${NC}"
        
        # 注意事項セクションの前に挿入
        if grep -q "## 注意事項" "$agent_file"; then
            sed -i.bak "/## 注意事項/i\\
$context7_section
" "$agent_file"
            rm -f "${agent_file}.bak"
        else
            # ファイル末尾に追加
            echo "$context7_section" >> "$agent_file"
        fi
    fi
    
    echo -e "${GREEN}  ✅ ${agent_name} エージェント更新完了${NC}"
}

# すべてのライブラリドキュメントを更新
update_all_docs() {
    echo -e "${BLUE}📚 すべてのライブラリドキュメントを更新中...${NC}"
    
    # キャッシュディレクトリ作成
    mkdir -p "$LIBRARY_CACHE"
    
    # library_mapping.jsonを読み込み
    local libraries=$(python3 -c "
import json
with open('$CONTEXT7_CONFIG/library_mapping.json', 'r') as f:
    data = json.load(f)
    for key in data['libraries']:
        print(key)
" 2>/dev/null)
    
    for library in $libraries; do
        check_library_version "$library"
        
        # キャッシュファイル
        local cache_file="$LIBRARY_CACHE/${library}.md"
        
        if [[ "$FORCE" == true ]] || [[ ! -f "$cache_file" ]]; then
            echo -e "${CYAN}  ${library} のドキュメント情報をキャッシュ${NC}"
            
            # ライブラリ情報をキャッシュに保存
            python3 -c "
import json
from datetime import datetime

with open('$CONTEXT7_CONFIG/library_mapping.json', 'r') as f:
    data = json.load(f)
    if '$library' in data['libraries']:
        lib = data['libraries']['$library']
        with open('$cache_file', 'w') as out:
            out.write(f\"# {lib['name']} Context7 Reference\\n\\n\")
            out.write(f\"**Context7 ID**: \`{lib['context7_id']}\`\\n\")
            out.write(f\"**Description**: {lib['description']}\\n\")
            out.write(f\"**Documentation**: {lib['docs_url']}\\n\")
            out.write(f\"**Agents**: {', '.join(lib['agents'])}\\n\")
            out.write(f\"**Cached**: {datetime.now().isoformat()}\\n\")
"
        fi
    done
    
    # 最終更新時刻を記録
    echo "{\"last_update\": \"$(date -Iseconds)\", \"force\": $FORCE}" > "$LAST_UPDATE_FILE"
    
    echo -e "${GREEN}✅ ドキュメント更新完了${NC}"
}

# すべてのエージェントを更新
update_all_agents() {
    echo -e "${BLUE}🤖 すべてのエージェントにContext7設定を適用中...${NC}"
    
    # エージェントディレクトリの確認
    if [[ ! -d "$AGENTS_DIR" ]]; then
        echo -e "${RED}エラー: エージェントディレクトリが見つかりません${NC}"
        echo -e "${YELLOW}ヒント: ./scripts/core/generate_agents.sh を実行してください${NC}"
        exit 1
    fi
    
    # 各エージェントを更新
    for agent_file in "$AGENTS_DIR"/*.md; do
        if [[ -f "$agent_file" ]]; then
            agent_name=$(basename "$agent_file" .md)
            update_agent_context7 "$agent_name"
        fi
    done
    
    echo -e "${GREEN}✅ 全エージェント更新完了${NC}"
}

# 統合レポート生成
generate_report() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}📊 Context7 統合レポート${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ -f "$LAST_UPDATE_FILE" ]]; then
        local last_update=$(python3 -c "
import json
with open('$LAST_UPDATE_FILE', 'r') as f:
    data = json.load(f)
    print(data.get('last_update', 'unknown'))
")
        echo -e "${CYAN}最終更新: $last_update${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}📚 登録ライブラリ:${NC}"
    python3 -c "
import json
with open('$CONTEXT7_CONFIG/library_mapping.json', 'r') as f:
    data = json.load(f)
    for key, lib in data['libraries'].items():
        agents = ', '.join(lib['agents'])
        print(f\"  • {lib['name']:<20} → {agents}\")
"
    
    echo ""
    echo -e "${CYAN}🤖 エージェント設定状況:${NC}"
    for agent_file in "$AGENTS_DIR"/*.md; do
        if [[ -f "$agent_file" ]]; then
            agent_name=$(basename "$agent_file" .md)
            if grep -q "## Context7 最新ドキュメント参照" "$agent_file" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} $agent_name - Context7設定済み"
            else
                echo -e "  ${YELLOW}○${NC} $agent_name - 未設定"
            fi
        fi
    done
    
    echo ""
    echo -e "${CYAN}💡 使用方法:${NC}"
    echo "  1. タスク振り分け時に自動的にContext7が利用される"
    echo "  2. エージェントは最新ドキュメントを参照して実装"
    echo "  3. 定期的に update コマンドで最新化"
    echo ""
    echo -e "${CYAN}🔧 次のコマンド:${NC}"
    echo "  • ドキュメント更新: $0 update"
    echo "  • 特定エージェント更新: $0 agent <name>"
    echo "  • バージョン確認: $0 check <library>"
}

# メイン処理
main() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📚 Context7 最新ドキュメント参照システム${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # コマンドが指定されていない場合
    if [[ -z "$COMMAND" ]]; then
        echo -e "${RED}エラー: コマンドを指定してください${NC}"
        show_help
        exit 1
    fi
    
    # ドライランモード
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}[DRY RUN MODE] 実際の変更は行いません${NC}"
        echo ""
    fi
    
    # コマンド実行
    case "$COMMAND" in
        setup)
            setup_context7
            update_all_docs
            update_all_agents
            generate_report
            ;;
        update)
            if [[ ! -d "$CONTEXT7_CONFIG" ]]; then
                echo -e "${YELLOW}Context7が未設定です。セットアップを実行します...${NC}"
                setup_context7
            fi
            update_all_docs
            generate_report
            ;;
        check)
            if [[ -z "$TARGET" ]]; then
                echo -e "${RED}エラー: ライブラリ名を指定してください${NC}"
                exit 1
            fi
            check_library_version "$TARGET"
            ;;
        agent)
            if [[ -z "$TARGET" ]]; then
                echo -e "${RED}エラー: エージェント名を指定してください${NC}"
                exit 1
            fi
            update_agent_context7 "$TARGET"
            ;;
        all)
            if [[ ! -d "$CONTEXT7_CONFIG" ]]; then
                echo -e "${YELLOW}Context7が未設定です。セットアップを実行します...${NC}"
                setup_context7
            fi
            update_all_docs
            update_all_agents
            generate_report
            ;;
        *)
            echo -e "${RED}エラー: 不明なコマンド: $COMMAND${NC}"
            show_help
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}✅ 処理完了${NC}"
}

# 実行
main