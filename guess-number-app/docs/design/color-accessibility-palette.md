# GuessNumber - 色覚多様性対応カラーパレット

## 概要

GuessNumberアプリケーションでは、すべてのユーザーが快適にゲームを楽しめるよう、色覚多様性（色盲・色弱）に対応したインクルーシブなカラーパレットを提供します。

## 色覚多様性の理解

### 色覚多様性の種類
1. **第1色覚異常（プロタノマリー/プロタノピア）**: 赤色の感知が困難（約1%）
2. **第2色覚異常（デュータノマリー/デュータノピア）**: 緑色の感知が困難（約5%）
3. **第3色覚異常（トリタノマリー/トリタノピア）**: 青色の感知が困難（約0.002%）
4. **全色盲（モノクロマシー）**: すべての色の識別が困難（約0.003%）

### 設計への影響
- 赤と緑の組み合わせが判別困難
- 色だけでの情報伝達は不適切
- コントラストと明度の重要性

## 色覚多様性対応カラーシステム

### 基本方針
1. **色に依存しない情報設計**: 色以外の手法（形、パターン、テキスト）併用
2. **高コントラスト保持**: WCAG 2.1 AA準拠（4.5:1以上）
3. **検証可能性**: 色覚シミュレーターでのテスト実装

### 対応カラーパレット

#### プライマリカラー（メインブランド色）
```typescript
// 標準カラーパレット
primary: {
  50: '#eff6ff',   // 背景色（識別性向上）
  100: '#dbeafe',  // 薄い背景
  200: '#bfdbfe',  // ホバー状態
  500: '#3b82f6',  // メインカラー（青系）
  600: '#2563eb',  // ボタン標準色
  700: '#1d4ed8',  // ボタンホバー色
  900: '#1e3a8a',  // 最濃色
}

// 色覚多様性対応代替カラー
colorblindSafe: {
  primary: '#2563eb',    // 青系（識別しやすい）
  primaryLight: '#dbeafe', // 薄い青
}
```

#### セマンティックカラー（機能的色分け）

##### 成功・正解表示
```typescript
// 標準（緑系）
success: {
  50: '#f0fdf4',
  500: '#22c55e',  // 標準緑
  600: '#16a34a',
}

// 色覚多様性対応（青系）
colorblindSafe: {
  success: {
    primary: '#2563eb',    // 青系で代替
    light: '#dbeafe',
    pattern: 'diagonal-stripes', // パターンも併用
  }
}
```

##### エラー・不正解表示
```typescript
// 標準（赤系）
error: {
  50: '#fef2f2',
  500: '#ef4444',  // 標準赤
  600: '#dc2626',
}

// 色覚多様性対応（オレンジ系）
colorblindSafe: {
  error: {
    primary: '#ea580c',    // オレンジ系（識別しやすい）
    light: '#fed7aa',
    pattern: 'dots',       // ドットパターン併用
  }
}
```

##### 警告・ヒント表示
```typescript
// 標準（黄系）
warning: {
  50: '#fffbeb',
  500: '#f59e0b',  // 標準黄
  600: '#d97706',
}

// 色覚多様性対応（紫系）
colorblindSafe: {
  warning: {
    primary: '#7c3aed',    // 紫系
    light: '#e9d5ff',
    pattern: 'waves',      // 波パターン併用
  }
}
```

## 実装戦略

### 1. CSS カスタムプロパティでの管理
```css
:root {
  /* 標準カラー */
  --color-success: theme(colors.success.500);
  --color-error: theme(colors.error.500);
  --color-warning: theme(colors.warning.500);
  
  /* 色覚多様性対応モード */
  --color-success-safe: theme(colors.blue.600);
  --color-error-safe: theme(colors.orange.600);
  --color-warning-safe: theme(colors.purple.600);
}

/* 色覚多様性対応モード有効時 */
.colorblind-safe {
  --color-success: var(--color-success-safe);
  --color-error: var(--color-error-safe);
  --color-warning: var(--color-warning-safe);
}
```

### 2. パターンベースの情報伝達
```css
/* 成功パターン（縞模様） */
.pattern-success::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: repeating-linear-gradient(
    45deg,
    transparent,
    transparent 2px,
    rgba(255,255,255,0.1) 2px,
    rgba(255,255,255,0.1) 4px
  );
  pointer-events: none;
}

/* エラーパターン（ドット） */
.pattern-error::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: radial-gradient(
    circle at 2px 2px,
    rgba(255,255,255,0.15) 1px,
    transparent 1px
  );
  background-size: 8px 8px;
  pointer-events: none;
}

/* 警告パターン（波模様） */
.pattern-warning::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: repeating-linear-gradient(
    0deg,
    transparent,
    transparent 1px,
    rgba(255,255,255,0.1) 1px,
    rgba(255,255,255,0.1) 3px
  );
  pointer-events: none;
}
```

### 3. アイコンとテキストラベル
```typescript
// アイコンと色の組み合わせ
const FeedbackMessage: React.FC<{
  type: 'success' | 'error' | 'warning';
  message: string;
  useColorblindMode?: boolean;
}> = ({ type, message, useColorblindMode = false }) => {
  const config = {
    success: { 
      icon: '✓', 
      label: '成功',
      className: useColorblindMode ? 'colorblind-safe success' : 'success'
    },
    error: { 
      icon: '✗', 
      label: 'エラー',
      className: useColorblindMode ? 'colorblind-safe error' : 'error'
    },
    warning: { 
      icon: '⚠', 
      label: '警告',
      className: useColorblindMode ? 'colorblind-safe warning' : 'warning'
    },
  }[type];
  
  return (
    <div 
      className={cn('game-feedback', config.className)}
      role="alert"
      aria-label={config.label}
    >
      <span className="text-lg mr-2" aria-hidden="true">
        {config.icon}
      </span>
      <span className="sr-only">{config.label}: </span>
      {message}
    </div>
  );
};
```

### 4. ユーザー設定での切り替え機能
```typescript
// カラーモード管理フック
export const useColorAccessibility = () => {
  const [isColorblindMode, setIsColorblindMode] = useState(false);
  const [contrastMode, setContrastMode] = useState<'normal' | 'high'>('normal');
  
  useEffect(() => {
    // ローカルストレージから設定を復元
    const savedColorblindMode = getLocalStorageItem('colorblind-mode', false);
    const savedContrastMode = getLocalStorageItem('contrast-mode', 'normal');
    
    setIsColorblindMode(savedColorblindMode);
    setContrastMode(savedContrastMode);
    
    // CSS クラスの適用
    const root = document.documentElement;
    root.classList.toggle('colorblind-safe', savedColorblindMode);
    root.classList.toggle('high-contrast', savedContrastMode === 'high');
  }, []);
  
  const toggleColorblindMode = () => {
    const newMode = !isColorblindMode;
    setIsColorblindMode(newMode);
    setLocalStorageItem('colorblind-mode', newMode);
    
    document.documentElement.classList.toggle('colorblind-safe', newMode);
  };
  
  const toggleContrastMode = () => {
    const newMode = contrastMode === 'normal' ? 'high' : 'normal';
    setContrastMode(newMode);
    setLocalStorageItem('contrast-mode', newMode);
    
    document.documentElement.classList.toggle('high-contrast', newMode === 'high');
  };
  
  return {
    isColorblindMode,
    contrastMode,
    toggleColorblindMode,
    toggleContrastMode,
  };
};
```

## コンポーネント実装例

### GameFeedback コンポーネント
```typescript
export const GameFeedback: React.FC<{
  type: 'correct' | 'higher' | 'lower';
  guess: number;
  target?: number;
}> = ({ type, guess, target }) => {
  const { isColorblindMode } = useColorAccessibility();
  
  const getFeedbackConfig = () => {
    switch (type) {
      case 'correct':
        return {
          icon: '🎉',
          message: `正解です！答えは ${guess} でした！`,
          className: cn(
            'border-2',
            isColorblindMode 
              ? 'border-blue-300 bg-blue-50 text-blue-800'
              : 'border-success-300 bg-success-50 text-success-800'
          ),
          animation: 'animate-bounce-in',
        };
      case 'higher':
        return {
          icon: '⬆️',
          message: `${guess} より大きい数です`,
          className: cn(
            'border-2',
            isColorblindMode 
              ? 'border-orange-300 bg-orange-50 text-orange-800 pattern-error'
              : 'border-warning-300 bg-warning-50 text-warning-800'
          ),
          animation: 'animate-fade-in',
        };
      case 'lower':
        return {
          icon: '⬇️',
          message: `${guess} より小さい数です`,
          className: cn(
            'border-2',
            isColorblindMode 
              ? 'border-orange-300 bg-orange-50 text-orange-800 pattern-error'
              : 'border-warning-300 bg-warning-50 text-warning-800'
          ),
          animation: 'animate-fade-in',
        };
    }
  };
  
  const config = getFeedbackConfig();
  
  return (
    <div
      className={cn('game-feedback relative', config.className, config.animation)}
      role="status"
      aria-live="polite"
    >
      <span className="text-2xl mr-3" aria-hidden="true">
        {config.icon}
      </span>
      <span className="font-medium">
        {config.message}
      </span>
    </div>
  );
};
```

### 設定画面
```typescript
export const AccessibilitySettings: React.FC = () => {
  const { 
    isColorblindMode, 
    contrastMode, 
    toggleColorblindMode, 
    toggleContrastMode 
  } = useColorAccessibility();
  
  return (
    <Card>
      <CardHeader>
        <CardTitle>アクセシビリティ設定</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* 色覚多様性対応 */}
        <div className="flex items-center justify-between">
          <div>
            <h4 className="font-medium">色覚多様性対応モード</h4>
            <p className="text-sm text-neutral-600">
              赤緑色覚異常に配慮した色使いに切り替えます
            </p>
          </div>
          <button
            role="switch"
            aria-checked={isColorblindMode}
            onClick={toggleColorblindMode}
            className={cn(
              'relative inline-flex h-6 w-11 items-center rounded-full transition-colors',
              isColorblindMode ? 'bg-primary-600' : 'bg-neutral-300'
            )}
          >
            <span className="sr-only">色覚多様性対応モードの切り替え</span>
            <span
              className={cn(
                'inline-block h-4 w-4 transform rounded-full bg-white transition-transform',
                isColorblindMode ? 'translate-x-6' : 'translate-x-1'
              )}
            />
          </button>
        </div>
        
        {/* 高コントラストモード */}
        <div className="flex items-center justify-between">
          <div>
            <h4 className="font-medium">高コントラストモード</h4>
            <p className="text-sm text-neutral-600">
              より強いコントラストで表示します
            </p>
          </div>
          <button
            role="switch"
            aria-checked={contrastMode === 'high'}
            onClick={toggleContrastMode}
            className={cn(
              'relative inline-flex h-6 w-11 items-center rounded-full transition-colors',
              contrastMode === 'high' ? 'bg-primary-600' : 'bg-neutral-300'
            )}
          >
            <span className="sr-only">高コントラストモードの切り替え</span>
            <span
              className={cn(
                'inline-block h-4 w-4 transform rounded-full bg-white transition-transform',
                contrastMode === 'high' ? 'translate-x-6' : 'translate-x-1'
              )}
            />
          </button>
        </div>
        
        {/* プレビュー */}
        <div className="space-y-3">
          <h4 className="font-medium">プレビュー</h4>
          <div className="space-y-2">
            <GameFeedback type="correct" guess={42} />
            <GameFeedback type="higher" guess={25} />
            <GameFeedback type="lower" guess={75} />
          </div>
        </div>
      </CardContent>
    </Card>
  );
};
```

## テストと検証

### 色覚シミュレーター
```typescript
// 色覚シミュレーション用のCSS Filter
const ColorblindSimulator: React.FC<{
  type: 'protanopia' | 'deuteranopia' | 'tritanopia' | 'achromatopsia';
  children: React.ReactNode;
}> = ({ type, children }) => {
  const filters = {
    protanopia: 'url(#protanopia)',
    deuteranopia: 'url(#deuteranopia)', 
    tritanopia: 'url(#tritanopia)',
    achromatopsia: 'grayscale(100%)',
  };
  
  return (
    <>
      {/* SVG フィルタ定義 */}
      <svg style={{ position: 'absolute', width: 0, height: 0 }}>
        <defs>
          <filter id="protanopia">
            <feColorMatrix values="0.567,0.433,0,0,0 0.558,0.442,0,0,0 0,0.242,0.758,0,0 0,0,0,1,0"/>
          </filter>
          <filter id="deuteranopia">
            <feColorMatrix values="0.625,0.375,0,0,0 0.7,0.3,0,0,0 0,0.3,0.7,0,0 0,0,0,1,0"/>
          </filter>
          <filter id="tritanopia">
            <feColorMatrix values="0.95,0.05,0,0,0 0,0.433,0.567,0,0 0,0.475,0.525,0,0 0,0,0,1,0"/>
          </filter>
        </defs>
      </svg>
      
      <div style={{ filter: filters[type] }}>
        {children}
      </div>
    </>
  );
};
```

### 自動テスト
```typescript
// 色覚多様性対応テスト
describe('色覚多様性対応', () => {
  test('colorblind-safe クラスが適用された時に適切な色が使用される', () => {
    document.documentElement.classList.add('colorblind-safe');
    
    const { getByRole } = render(<GameFeedback type="correct" guess={42} />);
    const feedback = getByRole('status');
    
    // 青系の色が使用されていることを確認
    expect(feedback).toHaveClass('border-blue-300');
    expect(feedback).toHaveClass('bg-blue-50');
    expect(feedback).toHaveClass('text-blue-800');
  });
  
  test('パターンが正しく適用される', () => {
    const { getByRole } = render(<GameFeedback type="higher" guess={25} />);
    const feedback = getByRole('status');
    
    expect(feedback).toHaveClass('pattern-error');
  });
});
```

## 実装チェックリスト

### 基本対応
- [x] 色覚多様性対応カラーパレット定義
- [x] パターンベースの情報伝達
- [x] アイコンとテキストラベル併用
- [x] ユーザー設定での切り替え機能

### 実装コンポーネント
- [x] GameFeedback コンポーネント
- [ ] AccessibilitySettings コンポーネント
- [ ] ColorblindSimulator コンポーネント  
- [ ] 設定画面統合

### テストと検証
- [ ] 色覚シミュレーターテスト
- [ ] 自動テスト実装
- [ ] 実際のユーザーテスト
- [ ] WCAG準拠性チェック

## 更新履歴

| 日付 | 変更内容 | 担当者 |
|------|----------|--------|
| 2025-08-26 | 初版作成、包括的色覚多様性対応設計 | uiux エージェント |

---

この色覚多様性対応カラーパレットにより、GuessNumberアプリケーションはすべてのユーザーが平等にゲームを楽しめるインクルーシブな体験を提供します。色だけに依存しない情報設計と、ユーザーが選択可能な設定により、真にアクセシブルなアプリケーションを実現します。