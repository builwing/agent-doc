# GuessNumber - アニメーション仕様書

## 概要

GuessNumberアプリケーションでは、ユーザーエクスペリエンスを向上させるための意図的で洗練されたアニメーションシステムを採用します。すべてのアニメーションはアクセシビリティを考慮し、パフォーマンスを最適化した実装とします。

## アニメーション設計原則

### 1. 目的志向のモーション
- **機能的**: UIの状態変化を明確に伝える
- **感情的**: 楽しさと達成感を演出
- **案内的**: ユーザーの注意を適切に誘導

### 2. 自然な動き
- **物理的リアリティ**: 重力や慣性を模した動き
- **予測可能性**: ユーザーが期待する動作パターン
- **一貫性**: アプリ全体で統一された動きの言語

### 3. パフォーマンス最優先
- **60FPS維持**: スムーズな描画レートの確保
- **GPU加速**: transform3dとopacityの活用
- **軽量実装**: 必要最小限のアニメーション

## アニメーションシステム

### 基本設定（design-tokens.tsより）

```typescript
export const animation = {
  // イージング関数
  easing: {
    linear: 'linear',
    easeIn: 'cubic-bezier(0.4, 0, 1, 1)',
    easeOut: 'cubic-bezier(0, 0, 0.2, 1)',
    easeInOut: 'cubic-bezier(0.4, 0, 0.2, 1)',
    bounce: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)',
    elastic: 'cubic-bezier(0.68, -0.6, 0.32, 1.6)',
  },

  // 継続時間
  duration: {
    instant: '0ms',
    fast: '150ms',
    normal: '200ms',
    slow: '300ms',
    slower: '500ms',
    slowest: '1000ms',
  },
};
```

## コンテキスト別アニメーション

### 1. ページ遷移・状態変化

#### フェードイン（コンテンツ表示）
```css
@keyframes fadeIn {
  0% { 
    opacity: 0; 
    transform: translateY(10px);
  }
  100% { 
    opacity: 1; 
    transform: translateY(0);
  }
}

.animate-fade-in {
  animation: fadeIn 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
```

**使用場面:**
- 新しいゲーム画面の表示
- 難易度選択カードの表示
- ヘルプセクションの展開

#### カスケードフェードイン（順次表示）
```css
.cascade-fade-in {
  animation: fadeIn 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  animation-fill-mode: both;
}

.cascade-fade-in:nth-child(1) { animation-delay: 0ms; }
.cascade-fade-in:nth-child(2) { animation-delay: 100ms; }
.cascade-fade-in:nth-child(3) { animation-delay: 200ms; }
.cascade-fade-in:nth-child(4) { animation-delay: 300ms; }
```

**使用場面:**
- 統計情報カードの順次表示
- 推測履歴アイテムの表示

### 2. インタラクションフィードバック

#### ボタンプレス（スケールイン）
```css
@keyframes scaleIn {
  0% { transform: scale(0.95); }
  100% { transform: scale(1); }
}

.animate-scale-in {
  animation: scaleIn 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

/* CSS classes for interactive elements */
.game-button:active {
  transform: scale(0.95);
  transition: transform 0.1s cubic-bezier(0.4, 0, 0.2, 1);
}
```

**使用場面:**
- ボタンクリック時の視覚的フィードバック
- カードタップ時の応答

#### ホバーエフェクト（カード浮上）
```css
.game-card {
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  transform: translateY(0);
}

.game-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
}
```

### 3. ゲーム固有のアニメーション

#### 成功時のバウンス
```css
@keyframes bounceIn {
  0% { 
    transform: scale(0.3); 
    opacity: 0; 
  }
  50% { 
    transform: scale(1.05); 
    opacity: 0.8; 
  }
  70% { 
    transform: scale(0.9); 
    opacity: 0.9; 
  }
  100% { 
    transform: scale(1); 
    opacity: 1; 
  }
}

.animate-bounce-in {
  animation: bounceIn 0.5s cubic-bezier(0.68, -0.55, 0.265, 1.55);
}
```

**使用場面:**
- 正解時のフィードバック表示
- 新記録達成時の演出
- 難易度選択時の確認表示

#### エラー時のシェイク
```css
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  10%, 30%, 50%, 70%, 90% { transform: translateX(-8px); }
  20%, 40%, 60%, 80% { transform: translateX(8px); }
}

.animate-shake {
  animation: shake 0.6s cubic-bezier(0.4, 0, 0.2, 1);
}
```

**使用場面:**
- 不正な入力時のエラー表示
- バリデーション失敗時の入力フィールド

#### プログレス表示（フィル）
```css
@keyframes progressFill {
  0% { width: 0%; }
  100% { width: var(--progress-width); }
}

.animate-progress-fill {
  animation: progressFill 0.5s cubic-bezier(0.4, 0, 0.2, 1);
}
```

**使用場面:**
- タイマーバーの減少
- ゲーム進行状況バー
- スコア表示ゲージ

#### 数値カウントアップ
```typescript
// React実装例
export const CountUpAnimation: React.FC<{
  from: number;
  to: number;
  duration?: number;
  onComplete?: () => void;
}> = ({ from, to, duration = 1000, onComplete }) => {
  const [current, setCurrent] = useState(from);
  
  useEffect(() => {
    const startTime = Date.now();
    const difference = to - from;
    
    const animate = () => {
      const elapsed = Date.now() - startTime;
      const progress = Math.min(elapsed / duration, 1);
      
      // イージング関数適用
      const eased = 1 - Math.pow(1 - progress, 3);
      const value = Math.round(from + difference * eased);
      
      setCurrent(value);
      
      if (progress < 1) {
        requestAnimationFrame(animate);
      } else {
        onComplete?.();
      }
    };
    
    requestAnimationFrame(animate);
  }, [from, to, duration, onComplete]);
  
  return <span className="font-mono font-bold">{current}</span>;
};
```

### 4. ローディング・待機状態

#### スピナーアニメーション
```css
@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.animate-spin {
  animation: spin 1s linear infinite;
}

/* パルス効果（処理中表示） */
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.8; }
}

.animate-pulse-slow {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
```

#### タイピング効果（テキスト表示）
```typescript
export const TypewriterText: React.FC<{
  text: string;
  speed?: number;
  onComplete?: () => void;
}> = ({ text, speed = 50, onComplete }) => {
  const [displayText, setDisplayText] = useState('');
  const [index, setIndex] = useState(0);
  
  useEffect(() => {
    if (index < text.length) {
      const timeout = setTimeout(() => {
        setDisplayText(prev => prev + text[index]);
        setIndex(prev => prev + 1);
      }, speed);
      
      return () => clearTimeout(timeout);
    } else {
      onComplete?.();
    }
  }, [index, text, speed, onComplete]);
  
  return (
    <span>
      {displayText}
      <span className="animate-pulse">|</span>
    </span>
  );
};
```

## 特殊効果・マイクロインタラクション

### 1. パーティクル効果（勝利時）
```typescript
export const ParticleEffect: React.FC<{
  isActive: boolean;
  particleCount?: number;
}> = ({ isActive, particleCount = 50 }) => {
  if (!isActive) return null;
  
  return (
    <div className="fixed inset-0 pointer-events-none z-50">
      {Array.from({ length: particleCount }).map((_, i) => (
        <div
          key={i}
          className="absolute w-2 h-2 bg-yellow-400 rounded-full animate-bounce"
          style={{
            left: `${Math.random() * 100}%`,
            top: `${Math.random() * 100}%`,
            animationDelay: `${Math.random() * 2}s`,
            animationDuration: `${1 + Math.random()}s`,
          }}
        />
      ))}
    </div>
  );
};
```

### 2. フォーカス強調（リング拡張）
```css
.focus-ring-expand {
  position: relative;
}

.focus-ring-expand::after {
  content: '';
  position: absolute;
  inset: -2px;
  border: 2px solid transparent;
  border-radius: inherit;
  pointer-events: none;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.focus-ring-expand:focus-visible::after {
  border-color: theme(colors.primary.500);
  box-shadow: 0 0 0 4px rgb(59 130 246 / 0.15);
}
```

### 3. カウントダウンエフェクト
```css
@keyframes countdown {
  0% { 
    transform: scale(1); 
    color: theme(colors.neutral.600);
  }
  50% { 
    transform: scale(1.1); 
    color: theme(colors.warning.500);
  }
  100% { 
    transform: scale(1); 
    color: theme(colors.error.500);
  }
}

.animate-countdown {
  animation: countdown 1s cubic-bezier(0.4, 0, 0.2, 1) infinite;
}
```

## アクセシビリティ対応

### 動きの軽減対応
```css
/* prefers-reduced-motionの尊重 */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
  
  /* スクロール動作の軽減 */
  html {
    scroll-behavior: auto;
  }
  
  /* パーティクル効果の無効化 */
  .particle-effect {
    display: none !important;
  }
}
```

### フォーカス管理付きアニメーション
```typescript
export const AccessibleModal: React.FC<{
  isOpen: boolean;
  onClose: () => void;
  children: React.ReactNode;
}> = ({ isOpen, onClose, children }) => {
  const modalRef = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    if (isOpen && modalRef.current) {
      // アニメーション後にフォーカス設定
      const timer = setTimeout(() => {
        modalRef.current?.focus();
      }, 300); // アニメーション完了後
      
      return () => clearTimeout(timer);
    }
  }, [isOpen]);
  
  return (
    <div
      className={cn(
        'fixed inset-0 z-50 transition-all duration-300',
        isOpen
          ? 'opacity-100 backdrop-blur-sm'
          : 'opacity-0 pointer-events-none'
      )}
    >
      <div
        ref={modalRef}
        className={cn(
          'absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2',
          'transition-all duration-300',
          isOpen
            ? 'scale-100 opacity-100'
            : 'scale-95 opacity-0'
        )}
        tabIndex={-1}
        role="dialog"
        aria-modal="true"
      >
        {children}
      </div>
    </div>
  );
};
```

## パフォーマンス最適化

### GPU加速の活用
```css
/* GPU層に移動（will-change使用） */
.optimized-animation {
  will-change: transform, opacity;
  transform: translateZ(0); /* 3D変換コンテキスト作成 */
}

/* アニメーション完了後のクリーンアップ */
.animation-complete {
  will-change: auto;
}
```

### バッチ処理による最適化
```typescript
export const useBatchedAnimations = () => {
  const animationQueue = useRef<(() => void)[]>([]);
  const isRunning = useRef(false);
  
  const addAnimation = useCallback((animation: () => void) => {
    animationQueue.current.push(animation);
    
    if (!isRunning.current) {
      isRunning.current = true;
      requestAnimationFrame(() => {
        // すべてのアニメーションを同時実行
        animationQueue.current.forEach(anim => anim());
        animationQueue.current = [];
        isRunning.current = false;
      });
    }
  }, []);
  
  return { addAnimation };
};
```

## 実装チェックリスト

### 基本アニメーション
- [x] フェードイン/アウト
- [x] スケールイン/アウト
- [x] スライド遷移
- [x] ローテーション

### ゲーム固有アニメーション  
- [x] バウンス（成功時）
- [x] シェイク（エラー時）
- [x] プログレスバー
- [ ] パーティクル効果
- [ ] カウントアップ

### インタラクション
- [x] ホバーエフェクト
- [x] フォーカスエフェクト
- [x] タップフィードバック
- [ ] ドラッグ&ドロップ

### アクセシビリティ
- [x] 動きの軽減対応
- [x] フォーカス管理
- [ ] スクリーンリーダー対応
- [ ] タイミング調整機能

### パフォーマンス
- [x] GPU加速活用
- [x] 60FPS維持
- [ ] メモリ使用量最適化
- [ ] バッテリー消費軽減

## 使用例

### GameBoardでの実装例
```typescript
export const GameBoard: React.FC = () => {
  const [feedback, setFeedback] = useState<{
    type: 'success' | 'error';
    message: string;
    isVisible: boolean;
  }>({ type: 'success', message: '', isVisible: false });
  
  const showFeedback = (type: 'success' | 'error', message: string) => {
    setFeedback({ type, message, isVisible: true });
    
    // 自動的にフィードバックを非表示
    setTimeout(() => {
      setFeedback(prev => ({ ...prev, isVisible: false }));
    }, 3000);
  };
  
  return (
    <div className="space-y-6">
      {/* アニメーション付きフィードバック */}
      {feedback.isVisible && (
        <div
          className={cn(
            'game-feedback border-2 transition-all duration-300',
            feedback.type === 'success'
              ? 'animate-bounce-in border-success-300 bg-success-50'
              : 'animate-shake border-error-300 bg-error-50'
          )}
        >
          {feedback.message}
        </div>
      )}
      
      {/* その他のコンテンツ */}
    </div>
  );
};
```

## 更新履歴

| 日付 | 変更内容 | 担当者 |
|------|----------|--------|
| 2025-08-26 | 初版作成、包括的アニメーション仕様策定 | uiux エージェント |

---

このアニメーション仕様書により、GuessNumberアプリケーションは一貫性があり、アクセシブルで、パフォーマンスが最適化されたアニメーションシステムを実現します。すべてのアニメーションは意図的で機能的な役割を持ち、ユーザーエクスペリエンスの向上に寄与します。