# GuessNumber - アクセシビリティガイドライン

## 概要

GuessNumberアプリケーションは、WCAG 2.1 AA準拠を目標とし、すべてのユーザーが快適にゲームを楽しめるアクセシブルなWebアプリケーションを提供します。

## 基本方針

### 包含的デザイン原則
1. **知覚可能性 (Perceivable)** - すべての情報とUIコンポーネントが認識可能
2. **操作可能性 (Operable)** - すべてのUIコンポーネントが操作可能
3. **理解可能性 (Understandable)** - 情報とUIの操作が理解可能
4. **堅牢性 (Robust)** - 様々な支援技術で確実に解釈可能

### 対象ユーザー
- 視覚障害のあるユーザー（全盲、弱視、色覚多様性）
- 聴覚障害のあるユーザー
- 運動障害のあるユーザー
- 認知障害のあるユーザー
- 高齢者
- 一時的な障害のあるユーザー

## WCAG 2.1 準拠項目

### レベルA 基本要件

#### 1.1 テキストによる代替
```typescript
// 画像とアイコンの代替テキスト
<img src="icon.png" alt="ゲーム成功アイコン" />
<button aria-label="ヒントを使用">💡</button>

// 装飾的な要素
<span role="img" aria-label="成功">🎉</span>
<div aria-hidden="true">🎮</div>
```

#### 1.2 時間ベースメディア
- 音声フィードバックがある場合は字幕を提供
- 自動再生する音声には停止・制御機能を提供

#### 1.3 適応可能
```html
<!-- セマンティックなHTML構造 -->
<main role="main">
  <section aria-labelledby="game-title">
    <h1 id="game-title">数当てゲーム</h1>
    <form aria-labelledby="guess-form">
      <h2 id="guess-form">推測入力</h2>
      <label for="guess-input">数値を入力してください</label>
      <input id="guess-input" type="number" />
    </form>
  </section>
</main>
```

#### 1.4 識別可能
```css
/* 色以外での情報伝達 */
.feedback-success {
  background-color: #22c55e;
  border-left: 4px solid #16a34a;
}
.feedback-success::before {
  content: "✓ ";
}

.feedback-error {
  background-color: #ef4444;
  border-left: 4px solid #dc2626;
}
.feedback-error::before {
  content: "✗ ";
}
```

### レベルAA 拡張要件

#### 1.4.3 コントラスト（最低限）
```typescript
// design-tokens.ts でのコントラスト比設定
export const accessibility = {
  contrastRatio: {
    normal: 4.5,  // WCAG AA: 通常テキスト
    large: 3.0,   // WCAG AA: 大きなテキスト（18pt以上）
    enhanced: 7.0, // WCAG AAA
  },
}

// 実装例
const colors = {
  primary: {
    600: '#2563eb', // 白背景でのコントラスト比: 4.51
    700: '#1d4ed8', // 白背景でのコントラスト比: 5.93
  },
  neutral: {
    700: '#334155', // 白背景でのコントラスト比: 9.47
    900: '#0f172a', // 白背景でのコントラスト比: 16.89
  }
};
```

#### 1.4.4 テキストのサイズ変更
```css
/* 200%拡大対応 */
@media (min-resolution: 2x) {
  .game-board {
    font-size: 1.25em;
    line-height: 1.6;
  }
  
  .btn {
    min-height: 60px; /* 拡大時も44px以上を維持 */
    padding: 0.75rem 1.5rem;
  }
}
```

#### 2.1 キーボードアクセシブル
```typescript
// キーボードナビゲーション実装
const handleKeyDown = (e: React.KeyboardEvent) => {
  switch (e.key) {
    case 'Enter':
      if (e.target === inputRef.current) {
        handleSubmitGuess();
      }
      break;
    case 'Escape':
      handleClearInput();
      break;
    case 'Tab':
      // デフォルトのTab移動を利用
      break;
  }
};

// フォーカス管理
useEffect(() => {
  if (gameState.status === 'playing') {
    inputRef.current?.focus();
  }
}, [gameState.status]);
```

#### 2.4 ナビゲーション可能
```typescript
// スキップリンク実装
export const SkipLink: React.FC = () => (
  <a
    href="#main-content"
    className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-primary-600 text-white p-2 rounded"
  >
    メインコンテンツにスキップ
  </a>
);

// ページタイトル設定
useEffect(() => {
  document.title = `GuessNumber - ${gameState.status === 'playing' ? 'ゲーム中' : '難易度選択'}`;
}, [gameState.status]);
```

### レベルAAA 最高水準

#### 1.4.6 コントラスト（強化）
- 通常テキスト: 7:1以上
- 大きなテキスト: 4.5:1以上

#### 2.2.3 タイミングなし
```typescript
// タイムアウト延長機能
const [timeoutExtension, setTimeoutExtension] = useState(0);

const handleExtendTime = () => {
  setTimeoutExtension(prev => prev + 60); // 60秒延長
  // ユーザーに通知
  announce('制限時間を60秒延長しました');
};
```

## 支援技術対応

### スクリーンリーダー対応

#### ARIA ラベルとロール
```typescript
// 動的コンテンツの通知
const [announcement, setAnnouncement] = useState('');

const announce = (message: string) => {
  setAnnouncement(message);
  setTimeout(() => setAnnouncement(''), 1000);
};

// 実装例
<div
  role="status"
  aria-live="polite"
  aria-atomic="true"
  className="sr-only"
>
  {announcement}
</div>

// ゲーム状態の説明
<div
  role="region"
  aria-labelledby="game-status-title"
  aria-describedby="game-status-desc"
>
  <h2 id="game-status-title">ゲーム状況</h2>
  <p id="game-status-desc">
    現在{gameState.guesses.length}回推測済み、残り{gameState.attemptsLeft}回です
  </p>
</div>
```

#### ランドマーク使用
```typescript
<body>
  <SkipLink />
  <header role="banner">
    <h1>GuessNumber</h1>
  </header>
  
  <nav role="navigation" aria-label="ゲームナビゲーション">
    <ul>
      <li><button>新しいゲーム</button></li>
      <li><button>設定</button></li>
    </ul>
  </nav>
  
  <main role="main" id="main-content">
    <section aria-labelledby="game-section">
      <h2 id="game-section">ゲーム画面</h2>
      {/* ゲームコンテンツ */}
    </section>
  </main>
  
  <aside role="complementary" aria-labelledby="help-section">
    <h2 id="help-section">ヘルプ</h2>
    {/* ヘルプコンテンツ */}
  </aside>
  
  <footer role="contentinfo">
    <p>&copy; 2025 GuessNumber</p>
  </footer>
</body>
```

### キーボードナビゲーション

#### フォーカス管理
```typescript
// フォーカス順序の管理
const focusableElements = [
  'button',
  'input',
  'select',
  'textarea',
  'a[href]',
  '[tabindex]:not([tabindex="-1"])',
].join(',');

const handleTabOrder = () => {
  const elements = document.querySelectorAll(focusableElements);
  return Array.from(elements).filter(el => 
    !el.hasAttribute('disabled') && 
    !el.getAttribute('aria-hidden')
  );
};

// カスタムフォーカストラップ
export const FocusTrap: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const containerRef = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;
    
    const focusableElements = container.querySelectorAll(focusableElements);
    const firstElement = focusableElements[0] as HTMLElement;
    const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement;
    
    const handleTabKey = (e: KeyboardEvent) => {
      if (e.key === 'Tab') {
        if (e.shiftKey) {
          if (document.activeElement === firstElement) {
            e.preventDefault();
            lastElement?.focus();
          }
        } else {
          if (document.activeElement === lastElement) {
            e.preventDefault();
            firstElement?.focus();
          }
        }
      }
    };
    
    container.addEventListener('keydown', handleTabKey);
    return () => container.removeEventListener('keydown', handleTabKey);
  }, []);
  
  return <div ref={containerRef}>{children}</div>;
};
```

### 認知アクセシビリティ

#### わかりやすいインターface
```typescript
// 複雑性の軽減
export const SimpleInstructions: React.FC = () => (
  <Card variant="filled">
    <CardHeader>
      <CardTitle level={2}>遊び方</CardTitle>
    </CardHeader>
    <CardContent>
      <ol className="space-y-3 text-sm">
        <li className="flex items-start">
          <span className="inline-block w-6 h-6 bg-primary-100 text-primary-600 rounded-full text-xs font-bold flex items-center justify-center mr-3 flex-shrink-0">
            1
          </span>
          コンピューターが1から{gameState?.upper || 100}の数字を決めます
        </li>
        <li className="flex items-start">
          <span className="inline-block w-6 h-6 bg-primary-100 text-primary-600 rounded-full text-xs font-bold flex items-center justify-center mr-3 flex-shrink-0">
            2
          </span>
          あなたが数字を推測して入力します
        </li>
        <li className="flex items-start">
          <span className="inline-block w-6 h-6 bg-primary-100 text-primary-600 rounded-full text-xs font-bold flex items-center justify-center mr-3 flex-shrink-0">
            3
          </span>
          「大きい」「小さい」のヒントをもらいます
        </li>
        <li className="flex items-start">
          <span className="inline-block w-6 h-6 bg-success-100 text-success-600 rounded-full text-xs font-bold flex items-center justify-center mr-3 flex-shrink-0">
            ✓
          </span>
          正解するまで繰り返します
        </li>
      </ol>
    </CardContent>
  </Card>
);
```

#### エラー防止と回復
```typescript
// 入力検証とエラーメッセージ
const validateGuess = (guess: string): string | null => {
  if (!guess.trim()) {
    return '数値を入力してください';
  }
  
  const num = parseInt(guess, 10);
  if (isNaN(num)) {
    return '数値のみを入力してください';
  }
  
  if (num < 1 || num > gameState.upper) {
    return `1から${gameState.upper}の間の数値を入力してください`;
  }
  
  if (gameState.guesses.includes(num)) {
    return 'この数値は既に推測済みです。別の数値を入力してください';
  }
  
  return null;
};

// 確認ダイアログ
const ConfirmDialog: React.FC<{
  isOpen: boolean;
  onConfirm: () => void;
  onCancel: () => void;
  message: string;
}> = ({ isOpen, onConfirm, onCancel, message }) => {
  if (!isOpen) return null;
  
  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="confirm-title"
      className="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
    >
      <FocusTrap>
        <Card className="max-w-md mx-4">
          <CardHeader>
            <CardTitle id="confirm-title" level={3}>確認</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <p>{message}</p>
            <div className="flex gap-3 justify-end">
              <Button variant="secondary" onClick={onCancel}>
                キャンセル
              </Button>
              <Button onClick={onConfirm}>
                確認
              </Button>
            </div>
          </CardContent>
        </Card>
      </FocusTrap>
    </div>
  );
};
```

## 色覚多様性対応

### 色以外の情報提示
```typescript
// パターンとアイコンでの情報伝達
const FeedbackMessage: React.FC<{
  type: 'success' | 'error' | 'warning' | 'info';
  message: string;
}> = ({ type, message }) => {
  const config = {
    success: { icon: '✓', pattern: 'diagonal-lines', colorClass: 'success' },
    error: { icon: '✗', pattern: 'dots', colorClass: 'error' },
    warning: { icon: '⚠', pattern: 'waves', colorClass: 'warning' },
    info: { icon: 'ℹ', pattern: 'stripes', colorClass: 'info' },
  }[type];
  
  return (
    <div 
      className={cn(
        'game-feedback border-2',
        `border-${config.colorClass}-300 bg-${config.colorClass}-50`,
        `pattern-${config.pattern}` // カスタムパターン用クラス
      )}
      role="status"
      aria-live="polite"
    >
      <span aria-hidden="true" className="text-lg mr-2">
        {config.icon}
      </span>
      {message}
    </div>
  );
};
```

### 色覚多様性対応カラーパレット
```typescript
// design-tokens.ts での設定使用
export const useColorblindMode = () => {
  const [isColorblindMode, setIsColorblindMode] = useState(false);
  
  useEffect(() => {
    const savedMode = getLocalStorageItem('colorblind-mode', false);
    setIsColorblindMode(savedMode);
    
    if (savedMode) {
      document.documentElement.classList.add('colorblind-safe');
    }
  }, []);
  
  const toggleColorblindMode = () => {
    const newMode = !isColorblindMode;
    setIsColorblindMode(newMode);
    setLocalStorageItem('colorblind-mode', newMode);
    
    if (newMode) {
      document.documentElement.classList.add('colorblind-safe');
    } else {
      document.documentElement.classList.remove('colorblind-safe');
    }
  };
  
  return { isColorblindMode, toggleColorblindMode };
};
```

## 運動アクセシビリティ

### 大きなタッチターゲット
```css
/* 最小44x44pxの保証 */
.btn, .input, [role="button"] {
  min-height: 44px;
  min-width: 44px;
}

/* タッチデバイスでの余白確保 */
@media (pointer: coarse) {
  .btn {
    min-height: 48px;
    margin: 4px;
  }
}
```

### ドラッグ操作の代替
```typescript
// クリック/タップによる代替操作
const AlternativeControls: React.FC = () => (
  <div className="flex gap-2" role="group" aria-label="数値選択">
    <Button size="lg" onClick={() => adjustValue(-10)}>-10</Button>
    <Button size="lg" onClick={() => adjustValue(-1)}>-1</Button>
    <Input value={currentValue} onChange={handleDirectInput} className="w-20" />
    <Button size="lg" onClick={() => adjustValue(1)}>+1</Button>
    <Button size="lg" onClick={() => adjustValue(10)}>+10</Button>
  </div>
);
```

## パフォーマンスとアクセシビリティ

### 遅延読み込み
```typescript
// 重要コンテンツの優先読み込み
const LazyComponent = lazy(() => import('./HeavyComponent'));

export const AccessibleLazyLoader: React.FC = () => (
  <Suspense 
    fallback={
      <div
        role="status"
        aria-label="コンテンツを読み込み中"
        className="flex items-center justify-center p-8"
      >
        <div className="animate-spin w-8 h-8 border-4 border-primary-200 border-t-primary-600 rounded-full" />
        <span className="ml-3">読み込み中...</span>
      </div>
    }
  >
    <LazyComponent />
  </Suspense>
);
```

## テストとバリデーション

### 自動テスト
```typescript
// jest-axeを使用したアクセシビリティテスト
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

describe('GameBoard アクセシビリティ', () => {
  test('WCAG violations がないこと', async () => {
    const { container } = render(<GameBoard {...mockProps} />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
  
  test('キーボードナビゲーションが機能すること', () => {
    const { getByRole } = render(<GameBoard {...mockProps} />);
    const input = getByRole('spinbutton');
    
    input.focus();
    expect(document.activeElement).toBe(input);
    
    fireEvent.keyDown(input, { key: 'Tab' });
    expect(document.activeElement).not.toBe(input);
  });
});
```

### 手動テスト項目
1. **スクリーンリーダーテスト**
   - NVDA, JAWS, VoiceOverでの動作確認
   - 適切な読み上げ順序の確認

2. **キーボードナビゲーションテスト**
   - Tabキーでの移動確認
   - Enter, Space, Escapeキーでの操作確認
   - フォーカストラップの動作確認

3. **色覚テスト**
   - 色覚シミュレーターでの確認
   - 高コントラストモードでの確認

## 実装チェックリスト

### WCAG 2.1 A
- [x] セマンティックHTML使用
- [x] 画像の代替テキスト
- [x] キーボード操作可能
- [x] フォーカス管理

### WCAG 2.1 AA
- [x] 4.5:1以上のコントラスト比
- [x] 200%拡大対応
- [x] ARIAラベル・ロール使用
- [x] エラー識別と説明

### 追加対応
- [x] 色覚多様性対応
- [ ] スクリーンリーダー最適化
- [ ] 認知アクセシビリティ強化
- [ ] 運動アクセシビリティ対応

## 更新履歴

| 日付 | 変更内容 | 担当者 |
|------|----------|--------|
| 2025-08-26 | 初版作成、WCAG 2.1 AA準拠ガイドライン策定 | uiux エージェント |

---

このガイドラインは継続的に更新され、新しいアクセシビリティ標準や技術に対応していきます。すべての開発者がこのガイドラインに従って実装することで、包含的で使いやすいアプリケーションを提供します。