# API Specification System - 統合ガイド

## 概要

このシステムは、Go-ZeroとOpenAPIの長所を組み合わせた統合API仕様管理システムです。
単一の仕様書から、バックエンド（Go-Zero）、フロントエンド（Next.js 15）、モバイル（Expo）のコードを自動生成します。

## 主な特徴

### 1. 統一された型定義
- **単一の真実の源**: OpenAPI仕様書で全プラットフォームの型を定義
- **型安全性**: 自動生成により型の不整合を防止
- **バリデーション**: 各プラットフォーム用のバリデーションルールを自動生成

### 2. プラットフォーム固有の最適化
- **Go-Zero**: 高性能、マイクロサービス対応、Redis キャッシュ統合
- **Next.js 15**: Server Actions、SWR統合、自動再検証
- **Expo**: オフラインサポート、バックグラウンド同期、キャッシュ管理

### 3. 開発効率の向上
- **自動コード生成**: 仕様変更時に全プラットフォームのコードを再生成
- **モックサーバー**: 仕様書から自動的にモックAPIを起動
- **ドキュメント生成**: APIドキュメントを自動生成

## セットアップ

### 1. 依存関係のインストール

```bash
# プロジェクトのクローン
git clone <repository-url>
cd api-spec-system

# 依存関係のインストール
make install
```

### 2. 開発環境のセットアップ

```bash
# 開発環境の初期化
make dev-setup
```

## 使用方法

### 1. API仕様の定義

`specs/core/api-spec.yaml`または`specs/services/`に仕様を追加：

```yaml
paths:
  /api/v1/your-endpoint:
    get:
      summary: エンドポイントの説明
      operationId: getYourData
      x-go-zero:
        handler: YourHandler
        cache:
          enabled: true
          ttl: 300
      x-frontend:
        swr: true
        revalidate: 60
      x-mobile:
        offline: true
        cacheTime: 600
```

### 2. コード生成

```bash
# 全プラットフォーム向けコード生成
make generate

# 特定プラットフォームのみ
make generate-backend   # Go-Zero
make generate-frontend  # Next.js
make generate-mobile    # Expo
```

### 3. 生成されたコードの使用

#### バックエンド（Go-Zero）
```go
// generated/backend/internal/handler/
// 自動生成されたハンドラーを使用
```

#### フロントエンド（Next.js）
```typescript
// generated/frontend/api-client.ts
import { apiClient } from './api-client';

// React Hook
import { useGetProducts } from './hooks';

function ProductList() {
  const { data, error, isLoading } = useGetProducts();
  // ...
}
```

#### モバイル（Expo）
```typescript
// generated/mobile/api-service.ts
import { apiService } from './api-service';

// オフライン対応
await apiService.getProducts(); // 自動的にキャッシュとオフライン処理
```

## 拡張ポイント

### カスタムバリデーション

```yaml
x-validation:
  frontend:
    required: true
    minLength: 8
    pattern: "^[a-zA-Z0-9]+$"
  mobile:
    required: true
    custom: "validatePassword"
```

### キャッシュ設定

```yaml
x-go-zero:
  cache:
    enabled: true
    ttl: 300
    key: "product:${id}"
x-frontend:
  swr: true
  revalidate: 60
x-mobile:
  offline: true
  cacheTime: 600
```

### WebSocket統合

```yaml
x-websocket:
  /ws/chat:
    x-go-zero:
      handler: ChatWebSocketHandler
    x-frontend:
      reconnect: true
      heartbeat: 30
    x-mobile:
      background: true
```

## ベストプラクティス

### 1. 仕様ファースト開発
- 実装前に必ずAPI仕様を定義
- 仕様レビューを実施してから実装開始

### 2. バージョン管理
- 仕様ファイルをGitで管理
- 重大な変更時は新バージョンのエンドポイントを作成

### 3. テスト戦略
- 生成されたコードに対する統合テスト
- モックサーバーを使用したフロントエンドテスト

### 4. CI/CD統合

```yaml
# .github/workflows/api-spec.yml
name: API Specification
on:
  push:
    paths:
      - 'specs/**'
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - run: make validate
      - run: make generate
      - run: make test-backend
```

## トラブルシューティング

### 生成エラー
```bash
# 仕様の検証
make validate

# 詳細ログを表示
bash scripts/generate.sh all 2>&1 | tee generate.log
```

### 型の不整合
- 仕様書の型定義を確認
- `x-go-zero`、`x-typescript`の設定を確認

### キャッシュの問題
```bash
# キャッシュクリア
make clean
make generate
```

## まとめ

このシステムにより、フロントエンドとバックエンドの齟齬を最小限に抑え、開発効率を大幅に向上させることができます。仕様書を中心とした開発フローにより、チーム間のコミュニケーションコストも削減されます。