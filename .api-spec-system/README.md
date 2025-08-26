# API Specification System

Go-ZeroとOpenAPIの長所を組み合わせた統合API仕様管理システム

## 特徴

- **Go-Zeroの長所**: 高性能、マイクロサービス対応、自動コード生成
- **OpenAPIの長所**: 標準化、豊富なツール、ドキュメント自動生成
- **統合メリット**: 型安全性、一元管理、マルチプラットフォーム対応

## 対応プラットフォーム

- **Backend**: Go-Zero
- **Frontend**: Next.js 15
- **Mobile**: Expo (React Native)

## ディレクトリ構造

```
api-spec-system/
├── specs/                    # API仕様書
│   ├── core/                # コア仕様
│   └── services/            # サービス別仕様
├── templates/               # コード生成テンプレート
│   ├── go-zero/            # Go-Zero用
│   ├── nextjs/             # Next.js用
│   └── expo/               # Expo用
├── generated/              # 生成されたコード
│   ├── backend/
│   ├── frontend/
│   └── mobile/
├── scripts/                # 自動化スクリプト
└── examples/              # サンプル実装
```

## 使用方法

1. `specs/`ディレクトリにAPI仕様を定義
2. `make generate`で全プラットフォーム向けコードを生成
3. 生成されたコードを各プロジェクトで使用

## コマンド

```bash
# 全コード生成
make generate

# バックエンドのみ生成
make generate-backend

# フロントエンドのみ生成
make generate-frontend

# モバイルのみ生成
make generate-mobile

# 仕様の検証
make validate

# モックサーバー起動
make mock-server
```