# 技術仕様書

## 1. システムアーキテクチャ

### 1.1 アーキテクチャ概要
- **アーキテクチャパターン**: マイクロサービス + モノレポ構成
- **API設計**: OpenAPI 3.1.0 仕様準拠
- **通信プロトコル**: REST API (JSON) / gRPC (内部通信)
- **認証方式**: JWT + OAuth 2.0
- **デプロイメント**: コンテナベース (Docker/Kubernetes)

### 1.2 システム構成
```
SpecAgentX/
├── backend/           # Go-Zeroバックエンド
│   ├── api/          # APIゲートウェイ
│   ├── rpc/          # gRPCサービス
│   └── model/        # データモデル
├── frontend/          # Next.js 15 フロントエンド
│   ├── app/          # App Router
│   ├── components/   # UIコンポーネント
│   └── lib/          # ユーティリティ
├── mobile/            # Expo モバイルアプリ
│   ├── app/          # Expo Router
│   ├── components/   # ネイティブコンポーネント
│   └── services/     # APIクライアント
├── api-specs/         # OpenAPI仕様書
│   ├── openapi.yaml  # マスター仕様書
│   └── schemas/      # 共通スキーマ定義
└── shared/            # 共有リソース
    ├── types/        # TypeScript型定義
    └── proto/        # Protocol Buffers
```

## 2. 技術スタック

### 2.1 バックエンド - Go-Zero
- **バージョン**: go-zero v1.7.0 (最新安定版)
- **Go バージョン**: Go 1.22+
- **主要コンポーネント**:
  - goctl: コード生成ツール
  - go-zero/rest: HTTPフレームワーク
  - go-zero/zrpc: gRPCフレームワーク
  - go-zero/core/stores: データストア抽象化
- **データベース**: 
  - PostgreSQL 16 (メインDB)
  - Redis 7.2 (キャッシュ/セッション)
- **メッセージキュー**: Apache Kafka / RabbitMQ

### 2.2 フロントエンド - Next.js 15
- **バージョン**: Next.js 15.0.0 (最新版)
- **React バージョン**: React 19
- **主要機能**:
  - App Router (サーバーコンポーネント)
  - Turbopack (開発ビルド)
  - Server Actions
  - Streaming SSR
  - Partial Prerendering
- **スタイリング**: Tailwind CSS 3.4
- **状態管理**: Zustand / TanStack Query
- **フォーム**: React Hook Form + Zod
- **UIライブラリ**: shadcn/ui

### 2.3 モバイル - Expo
- **バージョン**: Expo SDK 51 (最新版)
- **React Native バージョン**: 0.74.0
- **主要機能**:
  - Expo Router (ファイルベースルーティング)
  - Expo Dev Client
  - EAS Build/Update
  - Expo Modules API
- **状態管理**: Zustand / TanStack Query
- **UIライブラリ**: NativeWind (Tailwind for RN)
- **ナビゲーション**: Expo Router v3

## 3. OpenAPI仕様による統合

### 3.1 API仕様管理
```yaml
# api-specs/openapi.yaml
openapi: 3.1.0
info:
  title: SpecAgentX API
  version: 1.0.0
  description: 統一API仕様書

servers:
  - url: https://api.specagentx.com/v1
    description: Production
  - url: http://localhost:8888/v1
    description: Development

paths:
  /users:
    get:
      operationId: getUsers
      tags: [Users]
      # ...

components:
  schemas:
    User:
      type: object
      required: [id, email, name]
      properties:
        id:
          type: string
          format: uuid
        email:
          type: string
          format: email
        name:
          type: string
```

### 3.2 コード生成フロー

#### バックエンド (Go-Zero)
```bash
# OpenAPI → Go-Zeroコード生成
goctl api plugin -plugin goctl-swagger="swagger -filename openapi.yaml" -api api-specs/openapi.yaml -dir backend/api

# 生成される構造
backend/
├── api/
│   ├── internal/
│   │   ├── config/     # 設定
│   │   ├── handler/    # HTTPハンドラー
│   │   ├── logic/      # ビジネスロジック
│   │   ├── svc/        # サービスコンテキスト
│   │   └── types/      # 型定義
│   └── api.go          # メインエントリ
```

#### フロントエンド (Next.js 15)
```bash
# OpenAPI → TypeScript型生成
npx openapi-typescript api-specs/openapi.yaml -o frontend/lib/api/types.ts

# OpenAPI → APIクライアント生成
npx openapi-typescript-codegen -i api-specs/openapi.yaml -o frontend/lib/api/client
```

#### モバイル (Expo)
```bash
# OpenAPI → React Native APIクライアント生成
npx openapi-generator-cli generate \
  -i api-specs/openapi.yaml \
  -g typescript-fetch \
  -o mobile/services/api
```

### 3.3 API統合パターン

#### 認証フロー
```typescript
// shared/types/auth.ts
export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

// frontend/lib/api/auth.ts (Next.js)
export const authApi = {
  login: async (credentials: LoginCredentials): Promise<AuthTokens> => {
    // OpenAPI定義に基づく実装
  }
};

// mobile/services/auth.ts (Expo)
export const authService = {
  login: async (credentials: LoginCredentials): Promise<AuthTokens> => {
    // 同じOpenAPI定義を使用
  }
};
```

## 4. データモデル

### 4.1 共通スキーマ定義
```yaml
# api-specs/schemas/common.yaml
components:
  schemas:
    Pagination:
      type: object
      properties:
        page:
          type: integer
          minimum: 1
        perPage:
          type: integer
          minimum: 1
          maximum: 100
        total:
          type: integer
        totalPages:
          type: integer

    Error:
      type: object
      required: [code, message]
      properties:
        code:
          type: string
        message:
          type: string
        details:
          type: object
```

### 4.2 ドメインモデル
```yaml
# api-specs/schemas/domain.yaml
components:
  schemas:
    Project:
      type: object
      required: [id, name, status]
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
          maxLength: 255
        description:
          type: string
        status:
          type: string
          enum: [active, archived, deleted]
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time
```

## 5. 開発環境セットアップ

### 5.1 前提条件
```bash
# 必要なツール
- Go 1.22+
- Node.js 20 LTS
- pnpm 8.0+
- Docker Desktop
- goctl (go install github.com/zeromicro/go-zero/tools/goctl@latest)
```

### 5.2 初期セットアップ
```bash
# リポジトリクローン
git clone https://github.com/yourorg/specagentx.git
cd specagentx

# 依存関係インストール
make install

# OpenAPIからコード生成
make generate

# 開発環境起動
make dev
```

### 5.3 開発コマンド
```makefile
# Makefile
.PHONY: install generate dev test build

install:
	cd backend && go mod download
	cd frontend && pnpm install
	cd mobile && pnpm install

generate:
	# OpenAPIからコード生成
	./scripts/generate-from-openapi.sh

dev:
	# 全サービス起動
	docker-compose up -d db redis
	make -j3 dev-backend dev-frontend dev-mobile

dev-backend:
	cd backend && go run api.go

dev-frontend:
	cd frontend && pnpm dev

dev-mobile:
	cd mobile && pnpm start

test:
	cd backend && go test ./...
	cd frontend && pnpm test
	cd mobile && pnpm test

build:
	docker-compose build
```

## 6. デプロイメント

### 6.1 コンテナ構成
```dockerfile
# backend/Dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN go build -o api api.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/api .
CMD ["./api"]
```

### 6.2 Kubernetes設定
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
    spec:
      containers:
      - name: api
        image: specagentx/api:latest
        ports:
        - containerPort: 8888
        env:
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: host
```

## 7. CI/CD パイプライン

### 7.1 GitHub Actions
```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  validate-openapi:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate OpenAPI Spec
        run: npx @apidevtools/swagger-cli validate api-specs/openapi.yaml

  test-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - run: cd backend && go test ./...

  test-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
      - run: cd frontend && pnpm install && pnpm test

  build-and-deploy:
    needs: [validate-openapi, test-backend, test-frontend]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and Push Docker Images
        run: |
          docker build -t specagentx/api:${{ github.sha }} ./backend
          docker push specagentx/api:${{ github.sha }}
```

## 8. モニタリング・ロギング

### 8.1 ログ設定
```go
// backend/internal/middleware/logger.go
func LoggerMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        path := c.Request.URL.Path
        
        c.Next()
        
        latency := time.Since(start)
        logx.WithContext(c.Request.Context()).Infow(
            "request",
            logx.Field("method", c.Request.Method),
            logx.Field("path", path),
            logx.Field("status", c.Writer.Status()),
            logx.Field("latency", latency),
            logx.Field("ip", c.ClientIP()),
        )
    }
}
```

### 8.2 メトリクス
```go
// backend/internal/middleware/metrics.go
var (
    httpDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "http_duration_seconds",
            Help: "Duration of HTTP requests in seconds",
        },
        []string{"path", "method", "status"},
    )
)
```

## 9. セキュリティ

### 9.1 認証・認可
```go
// backend/internal/middleware/auth.go
func JWTAuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        token := c.GetHeader("Authorization")
        if token == "" {
            c.JSON(401, gin.H{"error": "unauthorized"})
            c.Abort()
            return
        }
        
        claims, err := validateJWT(token)
        if err != nil {
            c.JSON(401, gin.H{"error": "invalid token"})
            c.Abort()
            return
        }
        
        c.Set("user", claims)
        c.Next()
    }
}
```

### 9.2 CORS設定
```typescript
// frontend/next.config.js
module.exports = {
  async headers() {
    return [
      {
        source: '/api/:path*',
        headers: [
          { key: 'Access-Control-Allow-Origin', value: process.env.ALLOWED_ORIGINS },
          { key: 'Access-Control-Allow-Methods', value: 'GET,POST,PUT,DELETE,OPTIONS' },
          { key: 'Access-Control-Allow-Headers', value: 'Content-Type, Authorization' },
        ],
      },
    ];
  },
};
```

## 10. パフォーマンス最適化

### 10.1 バックエンド最適化
- **データベースコネクションプール**: 最大100接続
- **Redisキャッシュ**: TTL 5分
- **レート制限**: 1000 req/min per IP
- **gRPC接続プール**: keepalive設定

### 10.2 フロントエンド最適化
- **静的生成 (SSG)**: 可能な限りビルド時生成
- **画像最適化**: next/image使用
- **コード分割**: 動的インポート
- **キャッシュ戦略**: SWR/React Query

### 10.3 モバイル最適化
- **画像キャッシュ**: expo-image使用
- **オフライン対応**: AsyncStorage + React Query
- **バンドルサイズ**: Metro設定で最適化
- **遅延ロード**: React.lazy使用

---
*最終更新: 2025-08-25*
*バージョン: 2.0.0*