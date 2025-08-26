# Go言語プロジェクトテンプレート

## プロジェクト構造

### 標準構造（go-zero使用時）
```
project-root/
├── api/                    # API定義
│   ├── proto/             # Protocol Buffers定義
│   │   └── *.proto
│   └── http/              # HTTP API定義
│       └── *.api
├── cmd/                    # メインアプリケーション
│   ├── api/               # APIサーバー
│   │   └── main.go
│   └── rpc/               # RPCサーバー
│       └── main.go
├── internal/              # プライベートパッケージ
│   ├── config/           # 設定
│   │   └── config.go
│   ├── handler/          # HTTPハンドラー
│   │   └── *.go
│   ├── logic/            # ビジネスロジック
│   │   └── *.go
│   ├── model/            # データモデル
│   │   └── *.go
│   ├── repository/       # データアクセス層
│   │   └── *.go
│   ├── service/          # サービス層
│   │   └── *.go
│   ├── svc/              # サービスコンテキスト
│   │   └── servicecontext.go
│   └── types/            # 型定義
│       └── types.go
├── pkg/                   # 公開パッケージ
│   ├── errors/           # エラー定義
│   ├── middleware/       # ミドルウェア
│   └── utils/            # ユーティリティ
├── test/                  # テスト
│   ├── integration/      # 統合テスト
│   └── e2e/              # E2Eテスト
├── scripts/               # スクリプト
├── docker/                # Docker設定
│   └── Dockerfile
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

## 基本設定

### go.mod
```go
module github.com/[username]/[project]

go 1.21

require (
    github.com/zeromicro/go-zero v1.5.0
    github.com/redis/go-redis/v9 v9.0.0
    github.com/golang-jwt/jwt/v4 v4.5.0
    gorm.io/gorm v1.25.0
    gorm.io/driver/postgres v1.5.0
)
```

### Makefile
```makefile
.PHONY: help build test clean

# ヘルプ
help:
	@echo "使用可能なコマンド:"
	@echo "  make build    - アプリケーションをビルド"
	@echo "  make test     - テストを実行"
	@echo "  make run      - アプリケーションを実行"
	@echo "  make clean    - ビルド成果物をクリーン"
	@echo "  make docker   - Dockerイメージをビルド"
	@echo "  make generate - コード生成"

# ビルド
build:
	go build -o bin/api cmd/api/main.go

# テスト
test:
	go test -v -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

# 実行
run:
	go run cmd/api/main.go

# クリーン
clean:
	rm -rf bin/ coverage.* tmp/

# Docker
docker:
	docker build -t $(PROJECT_NAME):latest -f docker/Dockerfile .

# コード生成
generate:
	go generate ./...
	goctl api go -api api/http/*.api -dir .
```

## コード規約

### 命名規則
```go
// パッケージ名: 小文字、単数形
package user

// インターフェース: 動詞+erまたは名詞
type UserRepository interface {
    GetByID(ctx context.Context, id int64) (*User, error)
}

// 構造体: PascalCase
type UserService struct {
    repo UserRepository
}

// 関数・メソッド: PascalCase（公開）、camelCase（非公開）
func NewUserService(repo UserRepository) *UserService {
    return &UserService{repo: repo}
}

func (s *UserService) GetUser(ctx context.Context, id int64) (*User, error) {
    return s.repo.GetByID(ctx, id)
}

// 定数: PascalCaseまたはALL_CAPS
const (
    MaxRetries = 3
    DEFAULT_TIMEOUT = 30
)

// エラー: ErrXxx
var (
    ErrUserNotFound = errors.New("user not found")
    ErrInvalidInput = errors.New("invalid input")
)
```

### エラーハンドリング
```go
// カスタムエラー型
type AppError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Details any    `json:"details,omitempty"`
}

func (e *AppError) Error() string {
    return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

// エラーラッピング
if err != nil {
    return fmt.Errorf("failed to get user: %w", err)
}

// エラーチェック
if errors.Is(err, ErrUserNotFound) {
    // 特定のエラー処理
}
```

### コンテキスト使用
```go
// 常にcontext.Contextを第一引数に
func (s *Service) DoSomething(ctx context.Context, param string) error {
    // タイムアウト設定
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    
    // キャンセレーションチェック
    select {
    case <-ctx.Done():
        return ctx.Err()
    default:
        // 処理実行
    }
    
    return nil
}
```

## go-zero特有の実装

### API定義（.api）
```api
syntax = "v1"

info (
    title: "User API"
    desc: "ユーザー管理API"
    author: "SpecAgentX"
    version: "1.0.0"
)

type (
    UserRequest {
        ID int64 `path:"id"`
    }
    
    UserResponse {
        ID       int64  `json:"id"`
        Name     string `json:"name"`
        Email    string `json:"email"`
        Created  string `json:"created"`
    }
)

service user-api {
    @handler GetUser
    get /api/v1/users/:id (UserRequest) returns (UserResponse)
    
    @handler CreateUser
    post /api/v1/users (CreateUserRequest) returns (UserResponse)
}
```

### ハンドラー実装
```go
func GetUserHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        var req types.UserRequest
        if err := httpx.Parse(r, &req); err != nil {
            httpx.ErrorCtx(r.Context(), w, err)
            return
        }

        l := logic.NewGetUserLogic(r.Context(), svcCtx)
        resp, err := l.GetUser(&req)
        if err != nil {
            httpx.ErrorCtx(r.Context(), w, err)
        } else {
            httpx.OkJsonCtx(r.Context(), w, resp)
        }
    }
}
```

### ロジック層
```go
type GetUserLogic struct {
    logx.Logger
    ctx    context.Context
    svcCtx *svc.ServiceContext
}

func NewGetUserLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetUserLogic {
    return &GetUserLogic{
        Logger: logx.WithContext(ctx),
        ctx:    ctx,
        svcCtx: svcCtx,
    }
}

func (l *GetUserLogic) GetUser(req *types.UserRequest) (*types.UserResponse, error) {
    user, err := l.svcCtx.UserRepo.GetByID(l.ctx, req.ID)
    if err != nil {
        if errors.Is(err, repository.ErrNotFound) {
            return nil, errorx.NewCodeError(404, "ユーザーが見つかりません")
        }
        return nil, err
    }

    return &types.UserResponse{
        ID:      user.ID,
        Name:    user.Name,
        Email:   user.Email,
        Created: user.CreatedAt.Format(time.RFC3339),
    }, nil
}
```

## テスト

### ユニットテスト
```go
func TestUserService_GetUser(t *testing.T) {
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()

    mockRepo := mocks.NewMockUserRepository(ctrl)
    service := NewUserService(mockRepo)

    tests := []struct {
        name    string
        userID  int64
        mock    func()
        wantErr bool
    }{
        {
            name:   "正常系",
            userID: 1,
            mock: func() {
                mockRepo.EXPECT().
                    GetByID(gomock.Any(), int64(1)).
                    Return(&User{ID: 1, Name: "Test"}, nil)
            },
            wantErr: false,
        },
        {
            name:   "ユーザー不存在",
            userID: 999,
            mock: func() {
                mockRepo.EXPECT().
                    GetByID(gomock.Any(), int64(999)).
                    Return(nil, ErrUserNotFound)
            },
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            tt.mock()
            _, err := service.GetUser(context.Background(), tt.userID)
            if (err != nil) != tt.wantErr {
                t.Errorf("GetUser() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

### ベンチマークテスト
```go
func BenchmarkUserService_GetUser(b *testing.B) {
    service := setupTestService()
    ctx := context.Background()
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _, _ = service.GetUser(ctx, 1)
    }
}
```

## デプロイメント

### Dockerfile
```dockerfile
# ビルドステージ
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o api cmd/api/main.go

# 実行ステージ
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/

COPY --from=builder /app/api .
COPY --from=builder /app/etc /etc

EXPOSE 8080

CMD ["./api", "-f", "/etc/config.yaml"]
```

## 設定管理

### config.yaml
```yaml
server:
  host: 0.0.0.0
  port: 8080
  mode: release # debug, release

database:
  driver: postgres
  source: "host=localhost port=5432 user=app password=secret dbname=myapp sslmode=disable"
  maxIdleConns: 10
  maxOpenConns: 100
  connMaxLifetime: 3600

redis:
  host: localhost:6379
  password: ""
  db: 0

log:
  level: info
  format: json
  output: stdout

jwt:
  secret: "your-secret-key"
  expire: 86400 # 24 hours
```

---
*このテンプレートはGo言語とgo-zeroフレームワークを使用したプロジェクトの標準構造を定義しています。*