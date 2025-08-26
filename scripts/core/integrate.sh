#!/usr/bin/env bash
# 既存プロジェクトにAgentixシステムを統合するスクリプト
set -euo pipefail

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔧 Agentix統合セットアップ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}このスクリプトは既存プロジェクトにAgentixシステムを統合します${NC}"
echo ""

# 1. 現在のディレクトリが既存プロジェクトかチェック
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}⚠️  警告: 現在のディレクトリはGitリポジトリではありません${NC}"
    read -p "続行しますか？ [y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${RED}キャンセルしました${NC}"
        exit 1
    fi
fi

# 2. 既存ファイルのバックアップ
echo -e "${BLUE}📦 既存ファイルのバックアップを作成中...${NC}"
BACKUP_DIR=".agentix_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 既存のREADME.mdがある場合はバックアップ
if [ -f "README.md" ]; then
    cp README.md "$BACKUP_DIR/README.md.original"
    echo -e "${GREEN}✅ README.mdをバックアップしました${NC}"
fi

# 既存のREQUIREMENTS.mdがある場合はバックアップ
if [ -f "REQUIREMENTS.md" ]; then
    cp REQUIREMENTS.md "$BACKUP_DIR/REQUIREMENTS.md.original"
    echo -e "${GREEN}✅ REQUIREMENTS.mdをバックアップしました${NC}"
fi

# 既存の.claudeディレクトリがある場合はバックアップ
if [ -d ".claude" ]; then
    cp -r .claude "$BACKUP_DIR/.claude.original"
    echo -e "${GREEN}✅ .claudeディレクトリをバックアップしました${NC}"
fi

# 3. Agentixコアファイルのダウンロード
echo ""
echo -e "${BLUE}📥 Agentixコアファイルを取得中...${NC}"

# Agentixリポジトリの場所を確認
AGENTIX_SOURCE=""
if [ -f "../Agentix/scripts/setup.sh" ]; then
    AGENTIX_SOURCE="../Agentix"
elif [ -f "./Agentix/scripts/setup.sh" ]; then
    AGENTIX_SOURCE="./Agentix"
else
    echo -e "${YELLOW}Agentixソースディレクトリのパスを入力してください:${NC}"
    read -p "パス: " AGENTIX_SOURCE
    if [ ! -f "$AGENTIX_SOURCE/scripts/setup.sh" ]; then
        echo -e "${RED}エラー: 指定されたパスにAgentixが見つかりません${NC}"
        exit 1
    fi
fi

# 4. scriptsディレクトリをコピー
echo -e "${BLUE}📁 スクリプトをコピー中...${NC}"
mkdir -p scripts
cp -r "$AGENTIX_SOURCE/scripts/"* scripts/
echo -e "${GREEN}✅ スクリプトをコピーしました${NC}"

# 5. 既存プロジェクトの構造を分析
echo ""
echo -e "${BLUE}🔍 既存プロジェクトの構造を分析中...${NC}"

PROJECT_TYPE="unknown"
FRAMEWORKS=""

# Next.jsプロジェクトの検出
if [ -f "next.config.js" ] || [ -f "next.config.ts" ] || [ -f "next.config.mjs" ]; then
    PROJECT_TYPE="nextjs"
    FRAMEWORKS="$FRAMEWORKS Next.js"
    
    # バージョン確認
    if [ -f "package.json" ]; then
        NEXT_VERSION=$(grep '"next"' package.json | grep -oE '[0-9]+\.[0-9]+' | head -1)
        echo -e "${CYAN}  ✓ Next.js $NEXT_VERSION を検出${NC}"
    fi
fi

# Expoプロジェクトの検出
if [ -f "app.json" ] || [ -f "expo.json" ]; then
    PROJECT_TYPE="expo"
    FRAMEWORKS="$FRAMEWORKS Expo"
    echo -e "${CYAN}  ✓ Expoプロジェクトを検出${NC}"
fi

# Go-Zeroプロジェクトの検出
if [ -f "go.mod" ] && grep -q "github.com/zeromicro/go-zero" go.mod 2>/dev/null; then
    PROJECT_TYPE="gozero"
    FRAMEWORKS="$FRAMEWORKS Go-Zero"
    echo -e "${CYAN}  ✓ Go-Zeroプロジェクトを検出${NC}"
fi

# Node.jsプロジェクトの検出
if [ -f "package.json" ]; then
    if [ "$PROJECT_TYPE" = "unknown" ]; then
        PROJECT_TYPE="nodejs"
    fi
    FRAMEWORKS="$FRAMEWORKS Node.js"
    echo -e "${CYAN}  ✓ Node.jsプロジェクトを検出${NC}"
fi

# Goプロジェクトの検出
if [ -f "go.mod" ]; then
    if [ "$PROJECT_TYPE" = "unknown" ]; then
        PROJECT_TYPE="go"
    fi
    FRAMEWORKS="$FRAMEWORKS Go"
    echo -e "${CYAN}  ✓ Goプロジェクトを検出${NC}"
fi

# 6. REQUIREMENTS.mdテンプレートの生成
echo ""
echo -e "${BLUE}📝 要件定義書テンプレートを生成中...${NC}"

if [ ! -f "REQUIREMENTS.md" ]; then
    cat > REQUIREMENTS.md << 'EOF'
# プロジェクト要件定義書

## 1. プロジェクト概要
- **プロジェクト名**: [プロジェクト名を入力]
- **バージョン**: 1.0.0
- **作成日**: $(date +%Y-%m-%d)
- **更新日**: $(date +%Y-%m-%d)

## 2. ビジネス要件
### 2.1 目的
[プロジェクトの目的を記述]

### 2.2 スコープ
[プロジェクトのスコープを記述]

### 2.3 ステークホルダー
- 開発チーム
- プロダクトオーナー
- エンドユーザー

## 3. 機能要件
### 3.1 ユーザー管理
- [ ] ユーザー登録
- [ ] ログイン/ログアウト
- [ ] プロファイル管理

### 3.2 [主要機能名]
- [ ] [機能詳細]

## 4. 非機能要件
### 4.1 パフォーマンス
- レスポンスタイム: 3秒以内
- 同時接続数: 1000ユーザー

### 4.2 セキュリティ
- 認証: JWT
- 暗号化: TLS 1.3

### 4.3 可用性
- 稼働率: 99.9%

## 5. 技術スタック
### 5.1 フロントエンド
EOF

    # 検出されたフレームワークに基づいて技術スタックを追加
    if [[ "$FRAMEWORKS" == *"Next.js"* ]]; then
        echo "- Framework: Next.js 15 (App Router)" >> REQUIREMENTS.md
        echo "- Language: TypeScript" >> REQUIREMENTS.md
        echo "- Styling: Tailwind CSS" >> REQUIREMENTS.md
    elif [[ "$FRAMEWORKS" == *"Expo"* ]]; then
        echo "- Framework: Expo (React Native)" >> REQUIREMENTS.md
        echo "- Language: TypeScript" >> REQUIREMENTS.md
    else
        echo "- Framework: [フレームワークを指定]" >> REQUIREMENTS.md
        echo "- Language: [言語を指定]" >> REQUIREMENTS.md
    fi

    cat >> REQUIREMENTS.md << 'EOF'

### 5.2 バックエンド
EOF

    if [[ "$FRAMEWORKS" == *"Go-Zero"* ]]; then
        echo "- Framework: Go-Zero" >> REQUIREMENTS.md
        echo "- Language: Go" >> REQUIREMENTS.md
        echo "- Database: MariaDB/Redis" >> REQUIREMENTS.md
    else
        echo "- Framework: [フレームワークを指定]" >> REQUIREMENTS.md
        echo "- Language: [言語を指定]" >> REQUIREMENTS.md
        echo "- Database: [データベースを指定]" >> REQUIREMENTS.md
    fi

    cat >> REQUIREMENTS.md << 'EOF'

### 5.3 インフラ
- Containerization: Docker
- CI/CD: GitHub Actions
- Hosting: [ホスティングサービスを指定]

## 6. 制約事項
- [制約事項を記述]

## 7. 受け入れ基準
- [ ] すべての機能要件が実装されている
- [ ] パフォーマンス要件を満たしている
- [ ] セキュリティ要件を満たしている
- [ ] テストカバレッジ80%以上

## 8. マイルストーン
- Phase 1: 基本機能実装 (YYYY-MM-DD)
- Phase 2: 拡張機能実装 (YYYY-MM-DD)
- Phase 3: 本番リリース (YYYY-MM-DD)
EOF

    echo -e "${GREEN}✅ REQUIREMENTS.mdを生成しました${NC}"
else
    echo -e "${YELLOW}⚠️  REQUIREMENTS.mdは既に存在します（バックアップ済み）${NC}"
fi

# 7. .gitignoreの更新
echo ""
echo -e "${BLUE}📝 .gitignoreを更新中...${NC}"

if [ ! -f ".gitignore" ]; then
    touch .gitignore
fi

# Agentix関連の除外設定を追加
if ! grep -q "# Agentix" .gitignore; then
    cat >> .gitignore << 'EOF'

# Agentix
.agentix_backup_*
.requirements_hash
.requirements_backup
.requirements_changes.log
scripts/.deprecated_*
scripts/.path_update_backup_*
scripts/*.bak
.backup/
pm/logs/
EOF
    echo -e "${GREEN}✅ .gitignoreを更新しました${NC}"
fi

# 8. 統合実行
echo ""
echo -e "${BLUE}🚀 Agentixシステムを統合中...${NC}"

# setup.shを実行（Context7も自動セットアップ）
chmod +x scripts/*.sh
./scripts/setup.sh

# 9. 既存プロジェクトに合わせた設定
echo ""
echo -e "${BLUE}⚙️  プロジェクト固有の設定を適用中...${NC}"

# プロジェクトタイプに応じた追加設定
case "$PROJECT_TYPE" in
    "nextjs")
        echo -e "${CYAN}Next.jsプロジェクト用の設定を適用...${NC}"
        # Next.js 15の設定を強制
        if [ -f ".claude/pm/prompts/subagent_system/next.txt" ]; then
            sed -i.bak 's/Next.js [0-9]+/Next.js 15+/g' .claude/pm/prompts/subagent_system/next.txt
        fi
        ;;
    "expo")
        echo -e "${CYAN}Expoプロジェクト用の設定を適用...${NC}"
        ;;
    "gozero")
        echo -e "${CYAN}Go-Zeroプロジェクト用の設定を適用...${NC}"
        ;;
esac

# 10. 統合レポートの生成
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Agentix統合完了！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📊 統合結果:${NC}"
echo "  • プロジェクトタイプ: $PROJECT_TYPE"
echo "  • 検出されたフレームワーク: $FRAMEWORKS"
echo "  • バックアップ: $BACKUP_DIR"
echo ""
echo -e "${CYAN}📁 作成されたディレクトリ:${NC}"
echo "  • .claude/       - エージェント設定"
echo "  • docs/agents/   - エージェントドキュメント"
echo "  • scripts/       - Agentixスクリプト"
echo ""
echo -e "${CYAN}🚀 次のステップ:${NC}"
echo ""
echo "  1. 要件定義書を編集:"
echo -e "     ${YELLOW}vi REQUIREMENTS.md${NC}"
echo ""
echo "  2. エージェントを生成:"
echo -e "     ${YELLOW}./scripts/generate_agents_from_requirements.sh${NC}"
echo ""
echo "  3. Context7エラー防止を設定:"
echo -e "     ${YELLOW}./scripts/update_pm_context7.sh${NC}"
echo ""
echo "  4. 既存コードベースの分析:"
echo "     PMエージェントが既存コードを理解し、"
echo "     適切なタスク振り分けを行います。"
echo ""
echo -e "${YELLOW}⚠️  重要な注意事項:${NC}"
echo "  • 既存ファイルはすべて $BACKUP_DIR にバックアップされています"
echo "  • REQUIREMENTS.mdを必ず編集してプロジェクトに合わせてください"
echo "  • 既存のCI/CDパイプラインとの競合に注意してください"
echo ""