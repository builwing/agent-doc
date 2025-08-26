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
