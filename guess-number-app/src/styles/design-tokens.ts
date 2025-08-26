/**
 * GuessNumber デザインシステム - デザイントークン
 * WCAG 2.1 AA準拠のアクセシビリティ対応デザインシステム
 * 
 * 最新のUI/UXベストプラクティスと色覚多様性対応を含む
 */

// 基本的なスペーシングシステム（8pxグリッドシステム）
export const spacing = {
  0: '0px',
  1: '4px',     // 0.25rem
  2: '8px',     // 0.5rem
  3: '12px',    // 0.75rem
  4: '16px',    // 1rem
  5: '20px',    // 1.25rem
  6: '24px',    // 1.5rem
  8: '32px',    // 2rem
  10: '40px',   // 2.5rem
  12: '48px',   // 3rem
  16: '64px',   // 4rem
  20: '80px',   // 5rem
  24: '96px',   // 6rem
} as const;

// タイポグラフィシステム
export const typography = {
  fontFamily: {
    sans: ['Inter', 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', 'Yu Gothic UI', 'Meiryo', 'sans-serif'],
    mono: ['ui-monospace', 'SFMono-Regular', 'Monaco', 'Consolas', 'Liberation Mono', 'monospace'],
  },
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
  },
  fontWeight: {
    light: '300',
    normal: '400',
    medium: '500',
    semibold: '600',
    bold: '700',
    extrabold: '800',
  },
  letterSpacing: {
    tighter: '-0.05em',
    tight: '-0.025em',
    normal: '0em',
    wide: '0.025em',
    wider: '0.05em',
    widest: '0.1em',
  },
} as const;

// カラーシステム（WCAG 2.1 AA準拠 - コントラスト比4.5:1以上）
export const colors = {
  // プライマリカラー（ゲーム全体のブランドカラー）
  primary: {
    50: '#eff6ff',   // 背景色用
    100: '#dbeafe',  // 薄い背景用
    200: '#bfdbfe',  // ホバー状態用
    300: '#93c5fd',  // 無効状態用
    400: '#60a5fa',  // アクセント用
    500: '#3b82f6',  // メインカラー
    600: '#2563eb',  // ボタン標準色
    700: '#1d4ed8',  // ボタンホバー色
    800: '#1e40af',  // 濃いテキスト用
    900: '#1e3a8a',  // 最濃色
    950: '#172554',  // 極濃色
  },

  // セマンティックカラー
  success: {
    50: '#f0fdf4',
    100: '#dcfce7',
    200: '#bbf7d0',
    300: '#86efac',
    400: '#4ade80',
    500: '#22c55e',  // 正解時のフィードバック
    600: '#16a34a',  // ボタン色
    700: '#15803d',
    800: '#166534',
    900: '#14532d',
  },

  error: {
    50: '#fef2f2',
    100: '#fee2e2',
    200: '#fecaca',
    300: '#fca5a5',
    400: '#f87171',
    500: '#ef4444',  // 間違い時のフィードバック
    600: '#dc2626',  // ボタン色
    700: '#b91c1c',
    800: '#991b1b',
    900: '#7f1d1d',
  },

  warning: {
    50: '#fffbeb',
    100: '#fef3c7',
    200: '#fed7aa',
    300: '#fdba74',
    400: '#fb923c',
    500: '#f59e0b',  // 注意時のフィードバック
    600: '#d97706',  // ボタン色
    700: '#b45309',
    800: '#92400e',
    900: '#78350f',
  },

  info: {
    50: '#eff6ff',
    100: '#dbeafe',
    200: '#bfdbfe',
    300: '#93c5fd',
    400: '#60a5fa',
    500: '#3b82f6',  // 情報表示用
    600: '#2563eb',
    700: '#1d4ed8',
    800: '#1e40af',
    900: '#1e3a8a',
  },

  // ニュートラルカラー
  neutral: {
    50: '#f8fafc',   // 最薄背景
    100: '#f1f5f9',  // 薄い背景
    200: '#e2e8f0',  // ボーダー色
    300: '#cbd5e1',  // 無効状態
    400: '#94a3b8',  // プレースホルダー
    500: '#64748b',  // 補助テキスト
    600: '#475569',  // サブテキスト
    700: '#334155',  // メインテキスト
    800: '#1e293b',  // 濃いテキスト
    900: '#0f172a',  // 最濃テキスト
    950: '#020617',  // 極濃テキスト
  },

  // ゲーム専用カラー
  game: {
    correct: '#22c55e',     // 正解色
    incorrect: '#ef4444',   // 不正解色
    hint: '#f59e0b',       // ヒント色
    progress: '#3b82f6',   // プログレス色
    target: '#8b5cf6',     // ターゲット色
  },
} as const;

// 色覚多様性対応カラーセット
export const colorblindSafeColors = {
  // 赤緑色覚異常対応（青とオレンジの組み合わせ）
  success: {
    primary: '#2563eb',    // 青系
    light: '#dbeafe',      // 薄い青
  },
  error: {
    primary: '#ea580c',    // オレンジ系
    light: '#fed7aa',      // 薄いオレンジ
  },
  warning: {
    primary: '#7c3aed',    // 紫系
    light: '#e9d5ff',      // 薄い紫
  },
} as const;

// 影とエレベーション
export const shadows = {
  none: 'none',
  xs: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
  sm: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
  base: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
  md: '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
  lg: '0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)',
  xl: '0 25px 50px -12px rgb(0 0 0 / 0.25)',
  inner: 'inset 0 2px 4px 0 rgb(0 0 0 / 0.05)',
  
  // インタラクティブエレメント用
  button: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
  buttonHover: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
  card: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
  cardHover: '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
} as const;

// 角丸設定
export const borderRadius = {
  none: '0px',
  sm: '2px',
  base: '4px',
  md: '6px',
  lg: '8px',
  xl: '12px',
  '2xl': '16px',
  '3xl': '24px',
  full: '9999px',
  
  // コンポーネント専用
  button: '8px',
  card: '12px',
  input: '6px',
  badge: '9999px',
} as const;

// アニメーション設定
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

  // キーフレームアニメーション
  keyframes: {
    // 成功時のバウンス
    bounceIn: {
      '0%': { transform: 'scale(0.3)', opacity: '0' },
      '50%': { transform: 'scale(1.05)', opacity: '0.8' },
      '70%': { transform: 'scale(0.9)', opacity: '0.9' },
      '100%': { transform: 'scale(1)', opacity: '1' },
    },
    
    // フェードイン
    fadeIn: {
      '0%': { opacity: '0', transform: 'translateY(10px)' },
      '100%': { opacity: '1', transform: 'translateY(0)' },
    },
    
    // エラー時のシェイク
    shake: {
      '0%, 100%': { transform: 'translateX(0)' },
      '10%, 30%, 50%, 70%, 90%': { transform: 'translateX(-8px)' },
      '20%, 40%, 60%, 80%': { transform: 'translateX(8px)' },
    },
    
    // プルス効果（注目を集める）
    pulse: {
      '0%, 100%': { opacity: '1' },
      '50%': { opacity: '0.8' },
    },
    
    // スケール効果（ボタンクリック時）
    scaleIn: {
      '0%': { transform: 'scale(0.95)' },
      '100%': { transform: 'scale(1)' },
    },
    
    // 進行状況バー
    progressFill: {
      '0%': { width: '0%' },
      '100%': { width: 'var(--progress-width)' },
    },
    
    // タイマー効果
    countdown: {
      '0%': { transform: 'scale(1)', color: 'var(--color-neutral-600)' },
      '50%': { transform: 'scale(1.1)', color: 'var(--color-warning-500)' },
      '100%': { transform: 'scale(1)', color: 'var(--color-error-500)' },
    },
  },
} as const;

// ブレークポイント（モバイルファーストアプローチ）
export const breakpoints = {
  sm: '375px',   // 小さなモバイル
  md: '768px',   // タブレット
  lg: '1024px',  // デスクトップ
  xl: '1280px',  // 大きなデスクトップ
  '2xl': '1536px', // 超大型ディスプレイ
} as const;

// Z-index階層管理
export const zIndex = {
  base: 0,
  raised: 10,
  dropdown: 1000,
  sticky: 1020,
  fixed: 1030,
  modal: 1040,
  popover: 1050,
  tooltip: 1060,
  toast: 1070,
  maximum: 2147483647, // JavaScript の最大整数値
} as const;

// フォーカス設定（アクセシビリティ対応）
export const focus = {
  ring: {
    width: '2px',
    offset: '2px',
    color: colors.primary[500],
    style: 'solid',
  },
  outline: {
    width: '2px',
    offset: '2px',
    color: colors.primary[500],
    style: 'solid',
  },
} as const;

// コンポーネント固有のデザイントークン
export const components = {
  button: {
    height: {
      sm: '32px',
      md: '40px',
      lg: '48px',
      xl: '56px',
    },
    padding: {
      sm: { x: '12px', y: '6px' },
      md: { x: '16px', y: '8px' },
      lg: { x: '20px', y: '12px' },
      xl: { x: '24px', y: '16px' },
    },
    fontSize: {
      sm: typography.fontSize.sm,
      md: typography.fontSize.base,
      lg: typography.fontSize.lg,
      xl: typography.fontSize.xl,
    },
  },
  
  card: {
    padding: {
      sm: spacing[4],
      md: spacing[6],
      lg: spacing[8],
    },
    borderRadius: borderRadius['2xl'],
    shadow: shadows.card,
    hoverShadow: shadows.cardHover,
  },
  
  input: {
    height: {
      sm: '36px',
      md: '44px',
      lg: '52px',
    },
    padding: {
      sm: { x: '12px', y: '8px' },
      md: { x: '16px', y: '12px' },
      lg: { x: '20px', y: '16px' },
    },
    borderRadius: borderRadius.lg,
    fontSize: {
      sm: typography.fontSize.sm,
      md: typography.fontSize.base,
      lg: typography.fontSize.lg,
    },
  },
  
  feedback: {
    padding: { x: spacing[4], y: spacing[3] },
    borderRadius: borderRadius.lg,
    fontSize: typography.fontSize.sm,
    fontWeight: typography.fontWeight.medium,
  },
} as const;

// ダークモードカラーパレット
export const darkMode = {
  colors: {
    background: {
      primary: '#0f172a',
      secondary: '#1e293b',
      tertiary: '#334155',
    },
    text: {
      primary: '#f8fafc',
      secondary: '#cbd5e1',
      tertiary: '#94a3b8',
    },
    border: {
      primary: '#334155',
      secondary: '#475569',
    },
  },
} as const;

// アクセシビリティ設定
export const accessibility = {
  // 最小タッチターゲットサイズ（WCAG 2.1）
  minTouchTarget: '44px',
  
  // 最小コントラスト比
  contrastRatio: {
    normal: 4.5,  // WCAG AA
    large: 3.0,   // WCAG AA（大きなテキスト）
    enhanced: 7.0, // WCAG AAA
  },
  
  // フォーカス可視性
  focusVisible: {
    outlineWidth: '2px',
    outlineOffset: '2px',
    outlineColor: colors.primary[500],
  },
  
  // 動きの軽減対応
  reducedMotion: {
    duration: '0.01ms',
    iterationCount: 1,
  },
} as const;

// 型定義をエクスポート
export type SpacingToken = keyof typeof spacing;
export type ColorToken = keyof typeof colors;
export type TypographyToken = keyof typeof typography;
export type ShadowToken = keyof typeof shadows;
export type AnimationToken = keyof typeof animation;
export type BreakpointToken = keyof typeof breakpoints;

// デザインシステム全体をまとめたオブジェクト
export const designTokens = {
  spacing,
  typography,
  colors,
  colorblindSafeColors,
  shadows,
  borderRadius,
  animation,
  breakpoints,
  zIndex,
  focus,
  components,
  darkMode,
  accessibility,
} as const;

export default designTokens;