# API共通仕様

## 1. API設計原則

### 1.1 RESTful設計
- **リソース指向**: 名詞を使用（動詞は避ける）
- **HTTPメソッド**: GET, POST, PUT, PATCH, DELETE を適切に使用
- **ステートレス**: 各リクエストは独立
- **統一インターフェース**: 一貫性のあるURL構造

### 1.2 命名規則
```
/api/v1/{resource}          # コレクション
/api/v1/{resource}/{id}     # 単一リソース
/api/v1/{resource}/{id}/{sub-resource}  # ネストリソース
```

## 2. リクエスト仕様

### 2.1 ヘッダー
```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
X-Request-ID: {uuid}
X-Client-Version: {version}
```

### 2.2 クエリパラメータ
```
# ページネーション
?page=1&limit=20

# フィルタリング
?status=active&created_after=2024-01-01

# ソート
?sort=created_at&order=desc

# フィールド選択
?fields=id,name,email
```

## 3. レスポンス仕様

### 3.1 成功レスポンス
```json
{
  "success": true,
  "data": {
    // リソースデータ
  },
  "meta": {
    "timestamp": "2025-01-01T00:00:00Z",
    "request_id": "uuid",
    "version": "1.0.0"
  }
}
```

### 3.2 エラーレスポンス
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力値が不正です",
    "details": [
      {
        "field": "email",
        "message": "有効なメールアドレスを入力してください"
      }
    ]
  },
  "meta": {
    "timestamp": "2025-01-01T00:00:00Z",
    "request_id": "uuid"
  }
}
```

## 4. HTTPステータスコード

| コード | 意味 | 使用場面 |
|--------|------|----------|
| 200 | OK | GET, PUT成功 |
| 201 | Created | POST成功（リソース作成） |
| 204 | No Content | DELETE成功 |
| 400 | Bad Request | 不正なリクエスト |
| 401 | Unauthorized | 認証失敗 |
| 403 | Forbidden | 権限不足 |
| 404 | Not Found | リソース不存在 |
| 409 | Conflict | リソース競合 |
| 422 | Unprocessable Entity | バリデーションエラー |
| 429 | Too Many Requests | レート制限超過 |
| 500 | Internal Server Error | サーバーエラー |
| 503 | Service Unavailable | メンテナンス中 |

## 5. 認証・認可

### 5.1 認証方式
```yaml
JWT:
  algorithm: RS256
  expiry: 
    access_token: 24h
    refresh_token: 30d
  claims:
    - sub: user_id
    - iat: issued_at
    - exp: expires_at
    - roles: user_roles

API_KEY:
  header: X-API-Key
  format: uuid-v4
  rotation: 90d
```

### 5.2 権限管理
```json
{
  "roles": {
    "admin": ["*"],
    "user": ["read:own", "write:own"],
    "guest": ["read:public"]
  }
}
```

## 6. レート制限

### 6.1 制限設定
```yaml
default:
  requests_per_minute: 60
  requests_per_hour: 1000

authenticated:
  requests_per_minute: 300
  requests_per_hour: 10000

premium:
  requests_per_minute: 1000
  requests_per_hour: 100000
```

### 6.2 レスポンスヘッダー
```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1609459200
```

## 7. バージョニング

### 7.1 URL方式（推奨）
```
/api/v1/users
/api/v2/users
```

### 7.2 ヘッダー方式（代替）
```http
Accept: application/vnd.api+json;version=2
```

## 8. ページネーション

### 8.1 オフセット方式
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

### 8.2 カーソル方式
```json
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTAwfQ==",
    "prev_cursor": "eyJpZCI6ODB9",
    "has_more": true
  }
}
```

## 9. データ検証

### 9.1 入力検証ルール
```yaml
string:
  min_length: 1
  max_length: 255
  pattern: regex

number:
  min: 0
  max: 999999
  precision: 2

date:
  format: ISO8601
  timezone: UTC

array:
  min_items: 0
  max_items: 100
  unique: true
```

## 10. セキュリティ

### 10.1 CORS設定
```yaml
allowed_origins:
  - https://example.com
  - https://app.example.com

allowed_methods:
  - GET
  - POST
  - PUT
  - DELETE
  - OPTIONS

allowed_headers:
  - Content-Type
  - Authorization
  - X-Request-ID

exposed_headers:
  - X-RateLimit-*
  - X-Request-ID
```

### 10.2 セキュリティヘッダー
```http
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

## 11. エラーコード体系

| コード | 説明 |
|--------|------|
| AUTH_* | 認証関連 |
| PERM_* | 権限関連 |
| VAL_* | バリデーション関連 |
| RES_* | リソース関連 |
| SYS_* | システム関連 |

---
*この仕様は全言語・フレームワーク共通のAPI設計ガイドラインです。*