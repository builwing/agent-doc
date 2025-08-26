# qa エージェント要件定義書

## 基本情報
- **エージェント名**: qa
- **説明**: 品質保証・テスト
- **優先度**: High
- **専門領域**: 自動テスト、E2Eテスト、品質管理
- **更新日**: 2025-08-26

## 参照ドキュメント
- [REQUIREMENTS.md](../../../REQUIREMENTS.md) - ビジネス要件
- [SPECIFICATIONS.md](../../../SPECIFICATIONS.md) - 技術仕様
- [AGENT_DEFINITIONS.md](../../../AGENT_DEFINITIONS.md) - エージェント定義

## エージェント固有要件

### 品質保証詳細機能要件

#### 1. テスト戦略と範囲

##### 単体テスト要件
```typescript
// テスト対象とカバレッジ目標
const UNIT_TEST_TARGETS = {
  gameLogic: {
    coverage: '95%+',
    testCases: [
      '乱数生成の範囲検証',
      '推測判定ロジック（大きい/小さい/正解）',
      'スコア計算アルゴリズム',
      '難易度別パラメータ適用',
      'ヒント生成ロジック',
      'ゲーム終了条件判定',
      'ユーザー入力検証'
    ]
  },
  
  uiComponents: {
    coverage: '85%+',
    testCases: [
      'コンポーネントレンダリング',
      'props渡しと状態更新',
      'イベントハンドリング',
      '条件分岐レンダリング',
      'アクセシビリティ属性'
    ]
  },
  
  stateManagement: {
    coverage: '90%+',
    testCases: [
      'Zustandストアアクション',
      'localStorage連携',
      '状態永続化と復元',
      'エラー状態のハンドリング'
    ]
  }
};
```

##### 統合テスト要件
```typescript
// コンポーネント間の統合テスト
const INTEGRATION_TEST_SCENARIOS = {
  gameFlow: [
    'ゲーム開始から終了までの完全フロー',
    'ヒント使用とスコアへの影響',
    '中断と再開の動作',
    '設定変更とゲームへの反映'
  ],
  
  dataFlow: [
    'ゲーム状態とUI表示の同期',
    'スコア更新とランキング連携',
    'ローカルストレージへの自動保存'
  ],
  
  errorHandling: [
    '無効入力に対するエラー表示',
    'ネットワークエラー時のフォールバック',
    'ストレージエラー時の復旧処理'
  ]
};
```

##### E2Eテスト要件
```typescript
// Playwrightでのエンドツーエンドテスト
const E2E_TEST_SCENARIOS = {
  criticalPath: [
    '初回訪問からゲーム完了までのフロー',
    '全難易度でのゲームクリア',
    'ヒント使用からスコア記録まで',
    '設定変更とゲームプレイ'
  ],
  
  crossBrowser: [
    'Chrome 最新版',
    'Firefox 最新版',
    'Safari 最新版（macOS）',
    'Edge 最新版'
  ],
  
  devices: [
    'iPhone 12/13/14 (iOS Safari)',
    'Samsung Galaxy S21+ (Chrome)',
    'iPad Pro (Safari)',
    'Desktop 1920x1080 (Chrome)'
  ],
  
  accessibility: [
    'キーボードナビゲーション',
    'スクリーンリーダー対応',
    'ハイコントラストモード',
    'フォントサイズ拡大機能'
  ]
};
```

#### 2. パフォーマンステスト要件

##### 負荷テスト
```typescript
const PERFORMANCE_BENCHMARKS = {
  loadTesting: {
    scenarios: [
      '初期ロード時間 < 2秒',
      'ページ遷移 < 300ms',
      'ゲーム操作レスポンス < 100ms'
    ],
    tools: ['Lighthouse', 'WebPageTest', 'Chrome DevTools'],
    metrics: ['FCP', 'LCP', 'FID', 'CLS', 'TTI']
  },
  
  memoryTesting: {
    scenarios: [
      'メモリリーク検証',
      '長時間プレイ時のメモリ使用量',
      'アニメーションフレームレート'
    ]
  },
  
  stressTest: {
    scenarios: [
      '連続ゲームプレイ（100回）',
      '高速入力連打',
      'ブラウザタブ切り替えストレス'
    ]
  }
};
```

#### 3. セキュリティテスト要件

##### 脆弱性テスト
```typescript
const SECURITY_TEST_CASES = {
  inputValidation: [
    'XSS攻撃スクリプトの注入テスト',
    'SQLインジェクションパターン',
    '異常な数値入力（負数、小数、巨大数）',
    '特殊文字や絵文字の入力'
  ],
  
  clientSideSecurity: [
    'localStorageデータのブラウザ加工テスト',
    'JavaScriptコンソールでの不正操作',
    'CSP（Content Security Policy）違反テスト'
  ],
  
  dataProtection: [
    'ゲームデータの暗号化状態確認',
    'プライベートブラウジングでのデータ永続化',
    'サードパーティCookieの不使用確認'
  ]
};
```

#### 4. ユーザビリティテスト要件

##### ユーザビリティ評価指標
```typescript
const USABILITY_METRICS = {
  taskCompletion: {
    target: '95%+',
    scenarios: [
      '初回ユーザーのゲーム完了率',
      'ヒント機能の理解と使用',
      '設定変更の成功率'
    ]
  },
  
  userSatisfaction: {
    target: '4.0/5.0+',
    metrics: [
      'ゲームの楽しさ',
      'UIの直感性',
      'レスポンシブデザインの品質',
      'アクセシビリティの適切さ'
    ]
  },
  
  learnability: {
    target: '初回プレイから熟練までの時間',
    measurements: [
      'チュートリアル完了時間 < 60秒',
      '独立したゲームプレイ達成時間 < 3分'
    ]
  }
};
```

### 技術要件詳細

#### テストフレームワーク構成
```typescript
// テストツールスタック
const TEST_STACK = {
  unitTesting: {
    framework: 'Vitest',
    version: '2.0+',
    features: [
      'TypeScriptネイティブサポート',
      'ESMサポート',
      'Viteエコシステム連携',
      'Hot Module Replacement'
    ]
  },
  
  integrationTesting: {
    framework: 'React Testing Library',
    version: '16.0+',
    utilities: [
      '@testing-library/jest-dom',
      '@testing-library/user-event',
      'MSW (Mock Service Worker)'
    ]
  },
  
  e2eTesting: {
    framework: 'Playwright',
    version: '1.40+',
    configuration: {
      browsers: ['chromium', 'firefox', 'webkit'],
      devices: ['Desktop', 'Mobile Safari', 'Mobile Chrome'],
      headless: true,
      screenshot: 'only-on-failure',
      video: 'retain-on-failure',
      trace: 'on-first-retry'
    }
  },
  
  visualTesting: {
    tool: 'Playwright Visual Comparisons',
    threshold: '0.3', // 30%の差異まで許容
    updateSnapshots: 'ci-environment-only'
  },
  
  performanceTesting: {
    tools: ['Lighthouse CI', 'WebPageTest API'],
    metrics: ['Core Web Vitals', 'Lighthouse Score'],
    budgets: {
      'bundle-size': '500KB',
      'first-contentful-paint': '2s',
      'largest-contentful-paint': '2.5s'
    }
  }
};
```

#### テスト環境設定
```typescript
// テスト実行環境
const TEST_ENVIRONMENTS = {
  local: {
    database: 'in-memory',
    storage: 'mock-localStorage',
    network: 'MSW-mocked',
    authentication: 'bypassed'
  },
  
  ci: {
    database: 'dockerized-test-db',
    storage: 'temporary-volume',
    network: 'stubbed-external-apis',
    parallelization: 'max-workers=4'
  },
  
  staging: {
    database: 'staging-replica',
    storage: 'staging-compatible',
    network: 'staging-endpoints',
    dataSeeding: 'automated-fixtures'
  }
};

// テストデータ管理
const TEST_DATA_STRATEGY = {
  gameStates: {
    fixtures: 'json-based-test-data',
    generation: 'factory-pattern',
    isolation: 'per-test-cleanup'
  },
  
  userScenarios: {
    personas: ['beginner', 'intermediate', 'expert'],
    journeys: 'json-scenario-definitions',
    variations: 'property-based-testing'
  }
};
```

#### 品質指標とメトリクス
```typescript
// 品質ゲート基準
const QUALITY_GATES = {
  coverage: {
    statements: '85%',
    branches: '80%',
    functions: '90%',
    lines: '85%'
  },
  
  performance: {
    lighthouse: '90+',
    webVitals: 'all-good',
    bundleSize: '<500KB',
    loadTime: '<2s'
  },
  
  accessibility: {
    axeCore: 'zero-violations',
    keyboardNav: '100%-navigable',
    screenReader: 'fully-announced'
  },
  
  reliability: {
    e2eSuccessRate: '98%+',
    flakiness: '<2%',
    crashRate: '<0.1%'
  }
};
```

### 品質保証基準詳細

#### テスト品質要件
* **テストカバレッジ**: 
  - 単体テスト: 85%以上
  - 統合テスト: 75%以上
  - E2Eテスト: 主要フロー100%カバー
* **テスト実行時間**: 
  - 単体テスト: 30秒以内
  - 統合テスト: 2分以内
  - E2Eテスト: 10分以内
* **テストの安定性**: Flakyテスト率 2%未満
* **テストメンテナンス**: 月次レビューとリファクタリング

#### パフォーマンス品質要件
* **レスポンシブデザイン**: 全デバイスで適切な表示
* **アクセシビリティ**: WCAG 2.1 AAレベル準拠
* **Core Web Vitals**: すべてGoodレンジ
* **Lighthouse Score**: 90点以上維持
* **クロスブラウザ互換性**: Chrome/Firefox/Safariで同等機能

#### セキュリティ品質要件
* **脆弱性ゼロ**: OWASP Top 10対策完了
* **データ保護**: localStorageデータの適切なサニタイズ
* **CSP準拠**: Content Security Policy適切設定
* **入力検証**: すべてのユーザー入力をサニタイズと検証

#### ユーザビリティ品質要件
* **タスク完了率**: 95%以上
* **ユーザー満足度**: 4.0/5.0以上
* **エラー率**: ユーザー操作エラー 1%未満
* **サポートコスト**: ユーザーからの問合せ最小化

#### ドキュメント品質要件
* **テスト計画書**: 100%完成・最新
* **テストケース仕様書**: 全シナリオ文書化
* **テスト実行レポート**: 自動生成とトレンド分析
* **品質メトリクスダッシュボード**: リアルタイム更新

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
