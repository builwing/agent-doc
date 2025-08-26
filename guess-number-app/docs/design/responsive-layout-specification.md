# GuessNumber - レスポンシブレイアウト仕様書

## 概要

GuessNumberアプリケーションは、モバイルファーストアプローチを採用し、すべてのデバイスサイズで最適なユーザーエクスペリエンスを提供するレスポンシブデザインを実装しています。

## ブレークポイント設計

### デザイントークンベースのブレークポイント

```typescript
// 定義済みブレークポイント（design-tokens.ts より）
export const breakpoints = {
  sm: '375px',   // 小さなモバイルデバイス
  md: '768px',   // タブレット・大きなモバイル
  lg: '1024px',  // デスクトップ・小さなラップトップ
  xl: '1280px',  // 大きなデスクトップ
  '2xl': '1536px', // 超大型ディスプレイ
} as const;
```

### デバイス対応範囲

| デバイス種別 | 画面幅 | ブレークポイント | 主な対象デバイス |
|------------|-------|---------------|----------------|
| Small Mobile | 320px - 374px | `< sm` | iPhone SE, 小型Android |
| Mobile | 375px - 767px | `sm` | iPhone, 標準Android |
| Tablet | 768px - 1023px | `md` | iPad, Android タブレット |
| Desktop | 1024px - 1279px | `lg` | ラップトップ, デスクトップ |
| Large Desktop | 1280px - 1535px | `xl` | 大型モニター |
| Extra Large | 1536px+ | `2xl` | 超大型ディスプレイ |

## レイアウト設計原則

### 1. モバイルファーストアプローチ

- 基本スタイルはモバイル（375px）向けに設計
- 大きな画面サイズは段階的に拡張
- パフォーマンス最適化を優先

### 2. フレキシブルグリッドシステム

```css
/* 基本グリッド構成 */
.container {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
}

/* レスポンシブパディング */
@media (min-width: 768px) {
  .container {
    padding: 0 2rem;
  }
}

@media (min-width: 1024px) {
  .container {
    padding: 0 3rem;
  }
}
```

### 3. タッチフレンドリーデザイン

- 最小タッチターゲット: 44x44px (WCAG準拠)
- 適切なスペーシング
- スワイプジェスチャー対応

## コンポーネント別レスポンシブ仕様

### GameBoard (メインゲーム画面)

#### モバイル (375px - 767px)
```css
.game-board {
  padding: 1rem;
  space-y: 1.5rem;
}

.game-stats {
  grid-template-columns: repeat(2, 1fr);
  gap: 0.75rem;
}

.number-input {
  font-size: 2rem;
  height: 4rem;
  width: 100%;
}

.guess-history {
  grid-template-columns: repeat(4, 1fr);
  gap: 0.5rem;
}
```

#### タブレット (768px - 1023px)
```css
.game-board {
  padding: 2rem;
  max-width: 600px;
  margin: 0 auto;
}

.game-stats {
  grid-template-columns: repeat(4, 1fr);
  gap: 1rem;
}

.number-input {
  font-size: 3rem;
  height: 5rem;
  max-width: 400px;
}

.guess-history {
  grid-template-columns: repeat(6, 1fr);
  gap: 0.75rem;
}
```

#### デスクトップ (1024px+)
```css
.game-board {
  padding: 3rem;
  max-width: 800px;
}

.game-stats {
  grid-template-columns: repeat(4, 1fr);
  gap: 1.5rem;
}

.number-input {
  font-size: 3rem;
  height: 5rem;
  max-width: 300px;
}

.guess-history {
  grid-template-columns: repeat(8, 1fr);
  gap: 1rem;
}
```

### DifficultySelector (難易度選択)

#### モバイル
```css
.difficulty-grid {
  grid-template-columns: 1fr;
  gap: 1.5rem;
}

.difficulty-card {
  padding: 1.5rem;
  min-height: 200px;
}

.card-content {
  font-size: 0.875rem;
}
```

#### タブレット
```css
.difficulty-grid {
  grid-template-columns: repeat(3, 1fr);
  gap: 2rem;
}

.difficulty-card {
  padding: 2rem;
  min-height: 300px;
}
```

#### デスクトップ
```css
.difficulty-grid {
  grid-template-columns: repeat(3, 1fr);
  gap: 2.5rem;
  max-width: 1200px;
}

.difficulty-card {
  padding: 2.5rem;
  min-height: 350px;
}
```

### Button Component

#### レスポンシブサイジング
```css
/* モバイル */
.btn-sm { height: 2rem; padding: 0 0.75rem; font-size: 0.75rem; }
.btn-md { height: 2.5rem; padding: 0 1rem; font-size: 0.875rem; }
.btn-lg { height: 3rem; padding: 0 1.5rem; font-size: 1rem; }

/* タブレット+ */
@media (min-width: 768px) {
  .btn-sm { height: 2.25rem; padding: 0 1rem; font-size: 0.875rem; }
  .btn-md { height: 2.75rem; padding: 0 1.25rem; font-size: 1rem; }
  .btn-lg { height: 3.5rem; padding: 0 2rem; font-size: 1.125rem; }
}
```

## PWA対応セーフエリア設計

### セーフエリア変数
```css
:root {
  --safe-area-inset-top: env(safe-area-inset-top);
  --safe-area-inset-bottom: env(safe-area-inset-bottom);
  --safe-area-inset-left: env(safe-area-inset-left);
  --safe-area-inset-right: env(safe-area-inset-right);
}
```

### セーフエリア対応レイアウト
```css
.app-layout {
  padding-top: max(1rem, var(--safe-area-inset-top));
  padding-bottom: max(1rem, var(--safe-area-inset-bottom));
  padding-left: max(1rem, var(--safe-area-inset-left));
  padding-right: max(1rem, var(--safe-area-inset-right));
}
```

## 画面向き対応

### ポートレート（縦向き）
- デフォルトレイアウト
- 縦スクロールを基本とした設計

### ランドスケープ（横向き）
```css
@media (orientation: landscape) {
  .game-board {
    padding: 1rem 2rem;
  }
  
  .difficulty-grid {
    grid-template-columns: repeat(3, 1fr);
  }
  
  .game-stats {
    grid-template-columns: repeat(4, 1fr);
  }
}

/* モバイル横向きの特別対応 */
@media (max-height: 500px) and (orientation: landscape) {
  .card {
    padding: 1rem;
  }
  
  .space-y-6 > * + * {
    margin-top: 1rem;
  }
}
```

## フォントサイズのレスポンシブスケーリング

### ベースフォントサイズ
```css
html {
  font-size: 16px; /* デスクトップ基準 */
}

/* モバイル調整 */
@media (max-width: 767px) {
  html {
    font-size: 14px;
  }
}

/* 大型ディスプレイ調整 */
@media (min-width: 1536px) {
  html {
    font-size: 18px;
  }
}
```

### 階層的スケーリング
```typescript
// design-tokens.ts より
export const typography = {
  fontSize: {
    xs: ['12px', { lineHeight: '16px' }],
    sm: ['14px', { lineHeight: '20px' }],
    base: ['16px', { lineHeight: '24px' }],
    lg: ['18px', { lineHeight: '28px' }],
    xl: ['20px', { lineHeight: '28px' }],
    '2xl': ['24px', { lineHeight: '32px' }],
    '3xl': ['30px', { lineHeight: '36px' }],
    '4xl': ['36px', { lineHeight: '40px' }],
    '5xl': ['48px', { lineHeight: '1' }],
  }
};
```

## パフォーマンス最適化

### 画像とメディア
- WebP形式の採用（フォールバック付き）
- レスポンシブイメージ対応
- Lazy loading実装

### CSS最適化
- Critical CSSの優先読み込み
- 未使用CSSの除去
- CSS Grid/Flexboxの活用

### JavaScript最適化
- コードスプリッティング
- 遅延ローディング
- バンドルサイズ最小化

## アクセシビリティ考慮事項

### フォーカス管理
```css
/* フォーカス可視性の強化 */
@media (min-width: 768px) {
  *:focus-visible {
    outline-width: 3px;
    outline-offset: 3px;
  }
}
```

### 拡大表示対応
```css
/* 200%拡大時の対応 */
@media (min-resolution: 2x), (min-device-pixel-ratio: 2) {
  .game-number-input {
    font-size: 3.5rem;
    height: 6rem;
  }
}
```

### 高コントラストモード
```css
@media (prefers-contrast: high) {
  .card {
    border-width: 3px;
    border-color: currentColor;
  }
  
  .btn {
    border-width: 2px;
    border-color: currentColor;
  }
}
```

## テスト要件

### 対象デバイス
- iPhone SE (375x667)
- iPhone 12 Pro (390x844)
- iPad Air (820x1180)
- MacBook Air (1440x900)
- Desktop Full HD (1920x1080)

### テスト項目
1. **レスポンシビリティ**
   - すべてのブレークポイントでの表示確認
   - 画面向き変更時の動作確認
   - コンテンツの読みやすさ

2. **インタラクション**
   - タッチ操作の快適性
   - ボタンサイズの適切性
   - フォーム入力の使いやすさ

3. **パフォーマンス**
   - 初期読み込み時間
   - インタラクション応答速度
   - メモリ使用量

## 実装チェックリスト

### 基本実装
- [x] デザイントークンベースのブレークポイント設定
- [x] モバイルファーストCSS実装
- [x] フレキシブルグリッドシステム
- [x] タッチフレンドリーサイジング

### コンポーネント対応
- [x] GameBoard レスポンシブ実装
- [x] DifficultySelector レスポンシブ実装
- [x] Button レスポンシブサイジング
- [x] Input レスポンシブサイジング
- [x] Card レスポンシブレイアウト

### 特殊対応
- [ ] PWA セーフエリア対応
- [ ] ランドスケープモード最適化
- [ ] 高解像度ディスプレイ対応
- [ ] 動きの軽減対応

### テスト・検証
- [ ] 各ブレークポイントでの表示テスト
- [ ] 実デバイスでのインタラクションテスト
- [ ] アクセシビリティテスト
- [ ] パフォーマンステスト

## 更新履歴

| 日付 | 変更内容 | 担当者 |
|------|----------|--------|
| 2025-08-26 | 初版作成、レスポンシブレイアウト仕様策定 | uiux エージェント |

---

この仕様書は、GuessNumberアプリケーションのレスポンシブデザイン実装における統一基準として運用し、すべてのUI開発者が参照することで一貫性のあるユーザーエクスペリエンスを実現します。