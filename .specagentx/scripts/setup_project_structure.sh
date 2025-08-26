#!/usr/bin/env bash
# プロジェクト構造自動生成スクリプト
set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ロゴ表示
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════╗"
echo "║   🏗️  Project Structure Generator        ║"
echo "║   環境構築質疑応答システム                ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# プロジェクトタイプの選択
echo -e "${BLUE}📋 プロジェクトタイプを選択してください:${NC}"
echo "1) Next.js (Webアプリケーション)"
echo "2) Expo (モバイルアプリケーション)"
echo "3) Go-Zero (APIサーバー)"
echo "4) Express/Node.js (APIサーバー)"
echo "5) フルスタック (Go-Zero + Next.js + Expo)"
echo "6) カスタム構造"
echo ""
read -p "選択 (1-6): " project_type

# プロジェクト名の入力
echo ""
read -p "プロジェクト名を入力してください: " project_name

# プロジェクト名のバリデーション
if [[ -z "$project_name" ]]; then
    echo -e "${RED}❌ プロジェクト名が入力されていません${NC}"
    exit 1
fi

# プロジェクトディレクトリの作成
if [[ -d "$project_name" ]]; then
    echo -e "${YELLOW}⚠️  ディレクトリ '$project_name' は既に存在します${NC}"
    read -p "上書きしますか？ (y/N): " overwrite
    if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
        echo "中止しました"
        exit 0
    fi
    rm -rf "$project_name"
fi

mkdir -p "$project_name"
cd "$project_name"

# 共通ディレクトリの作成
create_common_structure() {
    echo -e "${GREEN}📁 共通ディレクトリを作成中...${NC}"
    mkdir -p docs
    mkdir -p scripts
    mkdir -p tests
    mkdir -p .github/workflows
    
    # 基本的な.gitignoreの作成
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
vendor/

# Environment
.env
.env.local
.env.*.local

# Build outputs
dist/
build/
out/
.next/
.expo/

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# IDE
.vscode/
.idea/
*.swp
*.swo
.DS_Store

# Testing
coverage/
.nyc_output/

# Temporary files
tmp/
temp/
EOF

    # 基本的なREADME.mdの作成
    cat > README.md << EOF
# $project_name

## 概要
このプロジェクトは Agentix Setup Agent によって自動生成されました。

## セットアップ

### 前提条件
- Node.js 18以上
- npm または yarn

### インストール
\`\`\`bash
npm install
# または
yarn install
\`\`\`

### 開発サーバーの起動
\`\`\`bash
npm run dev
# または
yarn dev
\`\`\`

## プロジェクト構造
\`\`\`
$project_name/
├── docs/          # ドキュメント
├── scripts/       # ユーティリティスクリプト
├── tests/         # テストファイル
└── src/           # ソースコード
\`\`\`

## ライセンス
MIT

---
Generated with 🤖 Agentix Setup Agent
EOF
}

# Next.jsプロジェクト構造
create_nextjs_structure() {
    echo -e "${BLUE}⚛️  Next.jsプロジェクト構造を作成中...${NC}"
    
    mkdir -p src/app
    mkdir -p src/components
    mkdir -p src/lib
    mkdir -p src/styles
    mkdir -p public
    
    # package.json
    cat > package.json << 'EOF'
{
  "name": "PROJECT_NAME",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.1.0",
    "react": "^18",
    "react-dom": "^18"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "autoprefixer": "^10.0.1",
    "eslint": "^8",
    "eslint-config-next": "14.1.0",
    "postcss": "^8",
    "tailwindcss": "^3.3.0",
    "typescript": "^5"
  }
}
EOF
    sed -i.bak "s/PROJECT_NAME/$project_name/g" package.json && rm package.json.bak
    
    # tsconfig.json
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF
    
    # .env.example
    cat > .env.example << 'EOF'
# Environment variables
NEXT_PUBLIC_API_URL=http://localhost:3000
DATABASE_URL=
JWT_SECRET=
EOF
    
    echo -e "${GREEN}✅ Next.jsプロジェクト構造を作成しました${NC}"
}

# Expoプロジェクト構造
create_expo_structure() {
    echo -e "${BLUE}📱 Expoプロジェクト構造を作成中...${NC}"
    
    mkdir -p src/screens
    mkdir -p src/components
    mkdir -p src/navigation
    mkdir -p src/services
    mkdir -p src/utils
    mkdir -p assets
    
    # package.json
    cat > package.json << 'EOF'
{
  "name": "PROJECT_NAME",
  "version": "1.0.0",
  "main": "node_modules/expo/AppEntry.js",
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web"
  },
  "dependencies": {
    "expo": "~50.0.0",
    "expo-status-bar": "~1.11.1",
    "react": "18.2.0",
    "react-native": "0.73.2"
  },
  "devDependencies": {
    "@babel/core": "^7.20.0",
    "@types/react": "~18.2.45",
    "typescript": "^5.1.3"
  },
  "private": true
}
EOF
    sed -i.bak "s/PROJECT_NAME/$project_name/g" package.json && rm package.json.bak
    
    # app.json
    cat > app.json << EOF
{
  "expo": {
    "name": "$project_name",
    "slug": "$project_name",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "light",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "assetBundlePatterns": [
      "**/*"
    ],
    "ios": {
      "supportsTablet": true
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#ffffff"
      }
    },
    "web": {
      "favicon": "./assets/favicon.png"
    }
  }
}
EOF
    
    echo -e "${GREEN}✅ Expoプロジェクト構造を作成しました${NC}"
}

# Go-Zeroプロジェクト構造
create_gozero_structure() {
    echo -e "${BLUE}🚀 Go-Zeroプロジェクト構造を作成中...${NC}"
    
    mkdir -p api/internal/config
    mkdir -p api/internal/handler
    mkdir -p api/internal/logic
    mkdir -p api/internal/svc
    mkdir -p api/internal/types
    mkdir -p api/etc
    mkdir -p model
    mkdir -p rpc
    
    # go.mod
    cat > go.mod << EOF
module $project_name

go 1.21

require (
    github.com/zeromicro/go-zero v1.6.0
)
EOF
    
    # api/etc/config.yaml
    cat > api/etc/config.yaml << 'EOF'
Name: api
Host: 0.0.0.0
Port: 8888

# Database
DataSource: 

# Redis
Redis:
  Host: localhost:6379
  Type: node

# JWT
Auth:
  AccessSecret: 
  AccessExpire: 86400
EOF
    
    # Makefile
    cat > Makefile << 'EOF'
.PHONY: api
api:
	cd api && go run main.go -f etc/config.yaml

.PHONY: gen
gen:
	goctl api go -api api/api.api -dir api

.PHONY: docker
docker:
	docker build -t api:latest .

.PHONY: test
test:
	go test -v ./...
EOF
    
    echo -e "${GREEN}✅ Go-Zeroプロジェクト構造を作成しました${NC}"
}

# Express/Node.jsプロジェクト構造
create_express_structure() {
    echo -e "${BLUE}🚂 Express/Node.jsプロジェクト構造を作成中...${NC}"
    
    mkdir -p src/routes
    mkdir -p src/controllers
    mkdir -p src/models
    mkdir -p src/middleware
    mkdir -p src/services
    mkdir -p src/utils
    mkdir -p src/config
    
    # package.json
    cat > package.json << 'EOF'
{
  "name": "PROJECT_NAME",
  "version": "1.0.0",
  "description": "Express API Server",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "jest",
    "lint": "eslint src/"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "helmet": "^7.1.0",
    "morgan": "^1.10.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "eslint": "^8.54.0",
    "jest": "^29.7.0"
  }
}
EOF
    sed -i.bak "s/PROJECT_NAME/$project_name/g" package.json && rm package.json.bak
    
    # src/index.js
    cat > src/index.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'API Server is running' });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send('Something broke!');
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
EOF
    
    echo -e "${GREEN}✅ Express/Node.jsプロジェクト構造を作成しました${NC}"
}

# フルスタックプロジェクト構造
create_fullstack_structure() {
    echo -e "${BLUE}🎯 フルスタックプロジェクト構造を作成中...${NC}"
    
    mkdir -p backend
    mkdir -p frontend
    mkdir -p mobile
    mkdir -p shared
    
    # backend構造
    cd backend
    mkdir -p api/internal/{config,handler,logic,svc,types}
    mkdir -p api/etc
    mkdir -p model
    mkdir -p rpc
    
    cat > go.mod << EOF
module $project_name/backend

go 1.21

require (
    github.com/zeromicro/go-zero v1.6.0
)
EOF
    cd ..
    
    # frontend構造
    cd frontend
    mkdir -p src/{app,components,lib,styles}
    mkdir -p public
    
    cat > package.json << EOF
{
  "name": "$project_name-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  }
}
EOF
    cd ..
    
    # mobile構造
    cd mobile
    mkdir -p src/{screens,components,navigation,services}
    mkdir -p assets
    
    cat > package.json << EOF
{
  "name": "$project_name-mobile",
  "version": "1.0.0",
  "main": "node_modules/expo/AppEntry.js",
  "scripts": {
    "start": "expo start"
  }
}
EOF
    cd ..
    
    # docker-compose.yml
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "8888:8888"
    environment:
      - ENV=development
    volumes:
      - ./backend:/app
    
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:8888
    volumes:
      - ./frontend:/app
    
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: app
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql
    
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

volumes:
  db_data:
EOF
    
    echo -e "${GREEN}✅ フルスタックプロジェクト構造を作成しました${NC}"
}

# カスタム構造の作成
create_custom_structure() {
    echo -e "${CYAN}🛠️  カスタムプロジェクト構造を作成します${NC}"
    echo ""
    
    # ディレクトリ構造の入力
    echo "作成したいディレクトリを入力してください（カンマ区切り）:"
    echo "例: src,tests,docs,config"
    read -p "> " directories
    
    IFS=',' read -ra DIRS <<< "$directories"
    for dir in "${DIRS[@]}"; do
        dir=$(echo "$dir" | xargs)  # trim whitespace
        if [[ -n "$dir" ]]; then
            mkdir -p "$dir"
            echo -e "${GREEN}✅ ディレクトリ作成: $dir${NC}"
        fi
    done
    
    # 基本ファイルの作成
    echo ""
    echo "package.jsonを作成しますか？ (y/N): "
    read -p "> " create_package
    
    if [[ "$create_package" == "y" || "$create_package" == "Y" ]]; then
        cat > package.json << EOF
{
  "name": "$project_name",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \\"Error: no test specified\\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "MIT"
}
EOF
        echo -e "${GREEN}✅ package.jsonを作成しました${NC}"
    fi
}

# メイン処理
case $project_type in
    1)
        create_common_structure
        create_nextjs_structure
        ;;
    2)
        create_common_structure
        create_expo_structure
        ;;
    3)
        create_common_structure
        create_gozero_structure
        ;;
    4)
        create_common_structure
        create_express_structure
        ;;
    5)
        create_common_structure
        create_fullstack_structure
        ;;
    6)
        create_common_structure
        create_custom_structure
        ;;
    *)
        echo -e "${RED}❌ 無効な選択です${NC}"
        exit 1
        ;;
esac

# 成功メッセージ
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   ${GREEN}✅ プロジェクト構造の作成完了！       ${CYAN}║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📁 作成されたプロジェクト: ${YELLOW}$project_name${NC}"
echo ""
echo -e "${GREEN}次のステップ:${NC}"
echo "1. cd $project_name"
echo "2. npm install (Node.jsプロジェクトの場合)"
echo "3. npm run dev (開発サーバーの起動)"
echo ""
echo -e "${CYAN}📚 詳細は README.md を参照してください${NC}"