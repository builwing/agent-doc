import type { Config } from 'tailwindcss'
import { designTokens } from './src/styles/design-tokens'

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    // デザイントークンからスペーシングシステムを継承
    spacing: designTokens.spacing,
    
    extend: {
      // デザイントークンからカラーパレットを継承
      colors: {
        ...designTokens.colors,
        // ゲーム専用カラーも追加
        game: designTokens.colors.game,
        // ニュートラルカラーを標準のslateとして使用
        slate: designTokens.colors.neutral,
      },
      
      // タイポグラフィシステム
      fontFamily: designTokens.typography.fontFamily,
      fontSize: designTokens.typography.fontSize,
      fontWeight: designTokens.typography.fontWeight,
      letterSpacing: designTokens.typography.letterSpacing,
      
      // 影システム
      boxShadow: designTokens.shadows,
      
      // 角丸システム
      borderRadius: designTokens.borderRadius,
      
      // ブレークポイント
      screens: designTokens.breakpoints,
      
      // Z-index階層
      zIndex: designTokens.zIndex,
      
      // アニメーション拡張
      animation: {
        'bounce-in': 'bounceIn 0.5s cubic-bezier(0.68, -0.55, 0.265, 1.55)',
        'fade-in': 'fadeIn 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        'shake': 'shake 0.6s cubic-bezier(0.4, 0, 0.2, 1)',
        'pulse-slow': 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'scale-in': 'scaleIn 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
        'progress-fill': 'progressFill 0.5s cubic-bezier(0.4, 0, 0.2, 1)',
        'countdown': 'countdown 1s cubic-bezier(0.4, 0, 0.2, 1) infinite',
      },
      
      // キーフレーム定義
      keyframes: designTokens.animation.keyframes,
      
      // トランジション設定
      transitionDuration: designTokens.animation.duration,
      transitionTimingFunction: designTokens.animation.easing,
      
      // アクセシビリティ考慮の最小サイズ
      minHeight: {
        'touch': designTokens.accessibility.minTouchTarget,
      },
      minWidth: {
        'touch': designTokens.accessibility.minTouchTarget,
      },
      
      // PWA対応のセーフエリア
      padding: {
        'safe-top': 'max(1rem, env(safe-area-inset-top))',
        'safe-bottom': 'max(1rem, env(safe-area-inset-bottom))',
        'safe-left': 'max(1rem, env(safe-area-inset-left))',
        'safe-right': 'max(1rem, env(safe-area-inset-right))',
      },
      
      // カスタムグラデーション（ゲーム用）
      backgroundImage: {
        'game-gradient': 'linear-gradient(135deg, var(--color-primary-500), var(--color-primary-700))',
        'success-gradient': 'linear-gradient(135deg, var(--color-success-400), var(--color-success-600))',
        'error-gradient': 'linear-gradient(135deg, var(--color-error-400), var(--color-error-600))',
        'warning-gradient': 'linear-gradient(135deg, var(--color-warning-400), var(--color-warning-600))',
      },
      
      // カスタムフィルター効果
      filter: {
        'glow': 'drop-shadow(0 0 20px var(--color-primary-500))',
      },
      
      // カスタムアスペクト比
      aspectRatio: {
        'game-card': '4 / 3',
        'game-button': '3 / 1',
      },
    },
  },
  
  plugins: [
    // カスタムユーティリティプラグイン
    function({ addUtilities, theme }: { addUtilities: any; theme: any }) {
      const utilities = {
        // アクセシビリティヘルパー
        '.focus-visible-ring': {
          '&:focus-visible': {
            outline: `${designTokens.focus.ring.width} ${designTokens.focus.ring.style} ${designTokens.focus.ring.color}`,
            outlineOffset: designTokens.focus.ring.offset,
          },
        },
        
        // スクリーンリーダー専用コンテンツ
        '.sr-only': {
          position: 'absolute',
          width: '1px',
          height: '1px',
          padding: '0',
          margin: '-1px',
          overflow: 'hidden',
          clip: 'rect(0, 0, 0, 0)',
          whiteSpace: 'nowrap',
          border: '0',
        },
        
        // 色覚多様性対応モード
        '.colorblind-safe': {
          '&.success': {
            backgroundColor: designTokens.colorblindSafeColors.success.primary,
          },
          '&.error': {
            backgroundColor: designTokens.colorblindSafeColors.error.primary,
          },
          '&.warning': {
            backgroundColor: designTokens.colorblindSafeColors.warning.primary,
          },
        },
        
        // ゲーム専用ユーティリティ
        '.game-number-input': {
          fontFamily: theme('fontFamily.mono'),
          fontSize: '2rem',
          fontWeight: '700',
          textAlign: 'center',
          letterSpacing: '0.1em',
        },
        
        '.game-feedback': {
          borderWidth: '2px',
          borderStyle: 'solid',
          borderRadius: theme('borderRadius.lg'),
          padding: `${theme('spacing.3')} ${theme('spacing.4')}`,
          fontWeight: theme('fontWeight.medium'),
          textAlign: 'center',
          minHeight: theme('minHeight.touch'),
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        },
        
        '.game-card': {
          backgroundColor: 'white',
          borderRadius: theme('borderRadius.2xl'),
          boxShadow: theme('boxShadow.card'),
          border: '1px solid',
          borderColor: theme('colors.neutral.200'),
          overflow: 'hidden',
          transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
          
          '&:hover': {
            boxShadow: theme('boxShadow.cardHover'),
            transform: 'translateY(-2px)',
          },
        },
        
        '.game-button': {
          minHeight: theme('minHeight.touch'),
          borderRadius: theme('borderRadius.button'),
          fontWeight: theme('fontWeight.medium'),
          transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
          display: 'inline-flex',
          alignItems: 'center',
          justifyContent: 'center',
          
          '&:active': {
            transform: 'scale(0.95)',
          },
        },
      };
      
      addUtilities(utilities);
    },
  ],
  
  // ダークモード対応（クラスベース）
  darkMode: 'class',
  
  // JITモード最適化
  // corePlugins: {
  //   // 未使用機能を無効化してバンドルサイズを削減
  //   preflight: true,
  // },
}

export default config