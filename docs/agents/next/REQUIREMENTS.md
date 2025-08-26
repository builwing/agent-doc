# next エージェント要件定義書

## 基本情報
- **エージェント名**: next
- **説明**: Next.jsフロントエンド開発
- **優先度**: Medium
- **専門領域**: React、Next.js
- **更新日**: 2025-08-26

## 参照ドキュメント
- [REQUIREMENTS.md](../../../REQUIREMENTS.md) - ビジネス要件
- [SPECIFICATIONS.md](../../../SPECIFICATIONS.md) - 技術仕様
- [AGENT_DEFINITIONS.md](../../../AGENT_DEFINITIONS.md) - エージェント定義

## エージェント固有要件

### フロントエンド実装詳細機能要件

#### 1. コンポーネント構成要件
```
app/
├── (game)/                 # ゲーム関連ページ
│   ├── page.tsx          # メインゲームページ
│   ├── settings/         # 設定ページ
│   ├── stats/            # 統計ページ
│   └── tutorial/         # チュートリアル
├── layout.tsx             # ルートレイアウト
├── loading.tsx            # ローディングUI
├── error.tsx              # エラーUI
└── not-found.tsx          # 404ページ

components/
├── game/                  # ゲームコンポーネント
│   ├── GameBoard.tsx
│   ├── GuessInput.tsx
│   ├── GameStats.tsx
│   ├── HintDisplay.tsx
│   └── GameResult.tsx
├── ui/                    # 再利用可能UIコンポーネント
│   ├── Button.tsx
│   ├── Modal.tsx
│   ├── Toast.tsx
│   └── ProgressBar.tsx
└── layout/                # レイアウトコンポーネント
    ├── Header.tsx
    ├── Navigation.tsx
    └── Footer.tsx
```

#### 2. 状態管理設計要件
```typescript
// Zustand Store構成
interface GameStore {
  // ゲーム状態
  currentGame: GameState | null;
  gameHistory: GameSession[];
  
  // ユーザー設定
  settings: UserSettings;
  
  // スコア・統計
  bestRecords: Record<Difficulty, BestRecord>;
  sessionStats: SessionStats;
  
  // アクション
  startNewGame: (difficulty: Difficulty) => void;
  makeGuess: (guess: number) => void;
  useHint: (hintType: HintType) => void;
  pauseGame: () => void;
  resumeGame: () => void;
  endGame: () => void;
  
  // 設定操作
  updateSettings: (settings: Partial<UserSettings>) => void;
  resetStats: () => void;
}

// ローカルストレージ連携
interface StoragePersistence {
  saveGameState: (state: GameState) => Promise<void>;
  loadGameState: () => Promise<GameState | null>;
  saveSettings: (settings: UserSettings) => Promise<void>;
  saveBestRecords: (records: Record<Difficulty, BestRecord>) => Promise<void>;
}
```

#### 3. レスポンシブデザイン実装要件
```typescript
// Tailwindブレークポイント設定
const RESPONSIVE_BREAKPOINTS = {
  mobile: '320px-639px',
  tablet: '640px-1023px', 
  desktop: '1024px+'
};

// デバイス別UIコンポーネント要件
interface ResponsiveGameBoard {
  mobile: {
    layout: 'single-column',
    touchTargetSize: '44px+',
    fontSize: '16px+',
    spacing: 'compact'
  },
  tablet: {
    layout: 'two-column',
    gameArea: '60%',
    sidePanel: '40%',
    orientation: 'landscape-optimized'
  },
  desktop: {
    layout: 'three-column',
    navigation: '200px',
    gameArea: 'flex-1',
    statistics: '300px',
    keyboardShortcuts: 'visible'
  }
}
```

#### 4. アニメーション実装要件
```typescript
// Framer Motionアニメーション設定
const ANIMATION_VARIANTS = {
  // ページ遷移
  pageTransition: {
    initial: { opacity: 0, x: 20 },
    animate: { opacity: 1, x: 0 },
    exit: { opacity: 0, x: -20 },
    transition: { duration: 0.3 }
  },
  
  // ゲームフィードバック
  correctGuess: {
    scale: [1, 1.2, 1],
    backgroundColor: ['#ffffff', '#10b981', '#ffffff'],
    transition: { duration: 0.4 }
  },
  
  incorrectGuess: {
    x: [-10, 10, -10, 10, 0],
    backgroundColor: ['#ffffff', '#ef4444', '#ffffff'],
    transition: { duration: 0.5 }
  },
  
  // スコアアニメーション
  scoreCountUp: {
    scale: [0.8, 1.1, 1],
    transition: { duration: 0.6 }
  }
};
```

#### 5. アクセシビリティ実装要件
```typescript
// キーボードショートカットシステム
interface KeyboardShortcuts {
  'Enter': () => submitGuess();
  'Escape': () => closeModal();
  'Space': () => togglePause();
  'KeyH': () => showHint();
  'KeyR': () => resetGame();
  'ArrowUp': () => navigateHistory('prev');
  'ArrowDown': () => navigateHistory('next');
}

// ARIAサポート要件
interface AriaSupport {
  gameStatus: 'aria-live="polite"',
  inputField: 'aria-label="数値を入力してください"',
  hintButton: 'aria-describedby="hint-description"',
  scoreDisplay: 'aria-live="assertive"',
  progressBar: 'role="progressbar" aria-valuenow aria-valuemax'
}
```

#### 6. PWA実装要件
```typescript
// Service Worker機能要件
interface PWAFeatures {
  caching: {
    strategy: 'CacheFirst' | 'NetworkFirst' | 'StaleWhileRevalidate',
    assets: string[],
    runtime: 'background-sync'
  },
  
  offline: {
    fallbackPage: '/offline',
    gameDataSync: 'localStorage-backup',
    notification: 'オフラインモードで継続中'
  },
  
  installPrompt: {
    trigger: 'after-first-game',
    customButton: true,
    deferUntilEngaged: true
  }
}

// manifest.json連携
interface ManifestIntegration {
  shortcuts: 'context-menu-integration',
  icons: 'maskable-icons-support',
  themeColor: 'dynamic-based-on-settings',
  displayMode: 'standalone-with-fallback'
}
```

### 技術要件詳細

#### コアテクノロジー
- **Next.js**: 15.0.0 (App Router使用)
- **React**: 19 (他のReact Server Components対応)
- **TypeScript**: 5.5+ (厳密モード有効)
- **Node.js**: 20.x LTS

#### UI/スタイリング
- **Tailwind CSS**: 3.4+ (カスタムカラーパレット含む)
- **Headless UI**: アクセシビリティ対応コンポーネント
- **Framer Motion**: アニメーションライブラリ
- **Lucide React**: アイコンライブラリ

#### 状態管理
- **Zustand**: グローバル状態管理（軽量）
- **React Hook Form**: フォーム管理
- **localStorage**: ローカルデータ永続化

#### PWA関連
- **next-pwa**: PWAサポート（Service Worker自動生成）
- **workbox**: カスタムService Worker機能

### 品質要件詳細

#### パフォーマンス要件
* **初期ロード時間**: 2秒以内（First Contentful Paint）
* **ページ遷移**: 300ms以内
* **ゲーム操作レスポンス**: 100ms以内
* **アニメーションフレームレート**: 60fps維持
* **バンドルサイズ**: 500KB以内（gzip圧縮後）

#### ユーザビリティ要件
* **Lighthouse Score**: 90点以上（全項目）
* **Core Web Vitals**: すべてGoodレンジ
  - LCP: 2.5秒以内
  - FID: 100ms以内  
  - CLS: 0.1以内
* **アクセシビリティ**: WCAG 2.1 AAレベル準拠

#### テスト要件
* **単体テスト**: 85%以上（コンポーネントロジック）
* **統合テスト**: 70%以上（ユーザーシナリオ）
* **E2Eテスト**: 主要フロー100%カバー
* **ビジュアルリグレッションテスト**: コンポーネントスナップショット

#### エラーハンドリング要件
* **JavaScriptエラー率**: 0.1%未満
* **ネットワークエラー**: 適切なフォールバック表示
* **メモリリーク**: ゼロトレランス
* **エラーバウンダリ**: React Error Boundaryで全コンポーネントカバー

#### セキュリティ要件
* **XSS対策**: すべてのユーザー入力をサニタイズ
* **CSP**: Content Security Policy設定
* **HTTPS**: 本番環境で必須
* **データ保護**: localStorageデータの暗号化（将来版）

## 成功基準
- [ ] 3つのマークダウンファイルの要件を満たす
- [ ] OpenAPI仕様に準拠（該当する場合）
- [ ] テストが実装され、合格している
- [ ] ドキュメントが完成している
- [ ] コードレビューを通過

## 変更履歴
| 日付 | バージョン | 変更内容 |
|------|-----------|----------|
| 2025-08-26 | 1.0.0 | 初版作成（3ファイル統合版） |
