/**
 * ErrorBoundary - React エラーバウンダリ
 * アプリケーション全体のエラーハンドリングとリカバリ機能
 * 日本語エラーメッセージとデバッグ情報表示
 */

import React, { Component, ReactNode, ErrorInfo } from 'react';
import { Button } from '@/components/ui/Button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { cn } from '@/lib/utils';

interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
  errorInfo: ErrorInfo | null;
  errorId: string;
  retryCount: number;
}

interface ErrorBoundaryProps {
  children: ReactNode;
  fallback?: ReactNode;
  onError?: (error: Error, errorInfo: ErrorInfo) => void;
  maxRetries?: number;
  className?: string;
}

/**
 * React Error Boundary コンポーネント
 * Next.js 15とReact 19に最適化
 */
export class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  private retryTimer: NodeJS.Timeout | null = null;

  constructor(props: ErrorBoundaryProps) {
    super(props);
    
    this.state = {
      hasError: false,
      error: null,
      errorInfo: null,
      errorId: '',
      retryCount: 0,
    };
  }

  static getDerivedStateFromError(error: Error): Partial<ErrorBoundaryState> {
    // エラーIDを生成（デバッグ用）
    const errorId = `err_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    return {
      hasError: true,
      error,
      errorId,
    };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    // エラー情報を記録
    console.error('ErrorBoundary caught an error:', error, errorInfo);
    
    // 外部エラーハンドラーを呼び出し
    if (this.props.onError) {
      this.props.onError(error, errorInfo);
    }
    
    // LocalStorageにエラー情報を保存（オプション）
    try {
      const errorLog = {
        error: {
          name: error.name,
          message: error.message,
          stack: error.stack,
        },
        errorInfo,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        url: window.location.href,
        errorId: this.state.errorId,
      };
      
      localStorage.setItem(`error_${this.state.errorId}`, JSON.stringify(errorLog));
    } catch (e) {
      console.warn('Failed to save error log to localStorage:', e);
    }
    
    this.setState({
      errorInfo,
    });
  }

  componentWillUnmount() {
    if (this.retryTimer) {
      clearTimeout(this.retryTimer);
    }
  }

  // エラーリセット（リトライ）
  private handleRetry = () => {
    const maxRetries = this.props.maxRetries || 3;
    
    if (this.state.retryCount < maxRetries) {
      console.log(`Retrying... (${this.state.retryCount + 1}/${maxRetries})`);
      
      this.setState(prevState => ({
        hasError: false,
        error: null,
        errorInfo: null,
        retryCount: prevState.retryCount + 1,
      }));
    } else {
      alert('最大リトライ回数に達しました。ページをリロードしてください。');
    }
  };

  // 自動リトライ（開発時のみ）
  private handleAutoRetry = () => {
    if (process.env.NODE_ENV === 'development') {
      this.retryTimer = setTimeout(this.handleRetry, 5000);
    }
  };

  // ページリロード
  private handleReload = () => {
    window.location.reload();
  };

  // エラー報告（デバッグ用）
  private handleReportError = () => {
    const { error, errorInfo, errorId } = this.state;
    
    const errorReport = {
      errorId,
      error: error ? {
        name: error.name,
        message: error.message,
        stack: error.stack,
      } : null,
      errorInfo,
      timestamp: new Date().toISOString(),
      url: window.location.href,
      userAgent: navigator.userAgent,
    };
    
    // デバッグ用にコンソールに出力
    console.group('🐛 Error Report');
    console.error('Error ID:', errorId);
    console.error('Error:', error);
    console.error('Error Info:', errorInfo);
    console.error('Full Report:', errorReport);
    console.groupEnd();
    
    // クリップボードにコピー
    navigator.clipboard?.writeText(JSON.stringify(errorReport, null, 2))
      .then(() => alert('エラーレポートをクリップボードにコピーしました'))
      .catch(() => console.warn('Failed to copy to clipboard'));
  };

  render() {
    const { children, fallback, className } = this.props;
    const { hasError, error, errorInfo, errorId, retryCount } = this.state;
    
    if (hasError) {
      // カスタムフォールバックがある場合は使用
      if (fallback) {
        return fallback;
      }
      
      // デフォルトのエラー表示
      return (
        <div className={cn(
          'min-h-screen bg-gradient-to-br from-error-50 via-white to-warning-50',
          'flex items-center justify-center p-4',
          className
        )}>
          <Card variant="error" className="w-full max-w-2xl shadow-2xl">
            <CardHeader>
              <CardTitle level={1} className="text-error-700 flex items-center gap-2">
                🚨 エラーが発生しました
              </CardTitle>
              <p className="text-error-600">
                申し訳ありません。予期しないエラーが発生しました。
              </p>
            </CardHeader>
            
            <CardContent className="space-y-6">
              {/* エラー情報 */}
              <div className="space-y-4">
                <div className="p-4 bg-error-50 rounded-lg border-l-4 border-error-400">
                  <h3 className="font-semibold text-error-800 mb-2">
                    エラーの詳細
                  </h3>
                  <p className="text-error-700 font-mono text-sm">
                    {error?.message || 'Unknown error'}
                  </p>
                  {errorId && (
                    <p className="text-error-600 text-xs mt-2">
                      エラーID: {errorId}
                    </p>
                  )}
                </div>
                
                {/* 開発環境でのみスタックトレース表示 */}
                {process.env.NODE_ENV === 'development' && error?.stack && (
                  <details className="p-4 bg-neutral-100 rounded-lg">
                    <summary className="font-semibold text-neutral-700 cursor-pointer">
                      詳細なエラー情報（開発者向け）
                    </summary>
                    <pre className="mt-2 text-xs text-neutral-600 overflow-auto max-h-40 whitespace-pre-wrap">
                      {error.stack}
                    </pre>
                    {errorInfo?.componentStack && (
                      <pre className="mt-2 text-xs text-neutral-600 overflow-auto max-h-40 whitespace-pre-wrap">
                        Component Stack:{errorInfo.componentStack}
                      </pre>
                    )}
                  </details>
                )}
              </div>
              
              {/* リトライ情報 */}
              {retryCount > 0 && (
                <div className="p-3 bg-warning-50 rounded-lg border border-warning-200">
                  <p className="text-warning-800 text-sm">
                    リトライ回数: {retryCount}/{this.props.maxRetries || 3}
                  </p>
                </div>
              )}
              
              {/* 対処方法の提案 */}
              <div className="p-4 bg-info-50 rounded-lg border-l-4 border-info-400">
                <h3 className="font-semibold text-info-800 mb-2">
                  💡 対処方法
                </h3>
                <ul className="text-info-700 text-sm space-y-1">
                  <li>• 「再試行」ボタンを押してもう一度お試しください</li>
                  <li>• それでも解決しない場合はページを再読み込みしてください</li>
                  <li>• 問題が続く場合は、ブラウザのキャッシュをクリアしてみてください</li>
                  <li>• 他のブラウザでお試しください</li>
                </ul>
              </div>
              
              {/* アクションボタン */}
              <div className="flex flex-col sm:flex-row gap-3">
                <Button
                  variant="primary"
                  size="lg"
                  onClick={this.handleRetry}
                  disabled={retryCount >= (this.props.maxRetries || 3)}
                  className="flex-1"
                >
                  🔄 再試行
                  {retryCount >= (this.props.maxRetries || 3) && ' (上限に達しました)'}
                </Button>
                
                <Button
                  variant="secondary"
                  size="lg"
                  onClick={this.handleReload}
                  className="flex-1"
                >
                  🔃 ページを再読み込み
                </Button>
              </div>
              
              {/* デバッグ用ボタン（開発環境のみ） */}
              {process.env.NODE_ENV === 'development' && (
                <div className="flex justify-center">
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={this.handleReportError}
                  >
                    📋 エラーレポートをコピー
                  </Button>
                </div>
              )}
              
              {/* 自動リトライメッセージ（開発環境のみ） */}
              {process.env.NODE_ENV === 'development' && retryCount === 0 && (
                <div className="text-center text-sm text-neutral-600">
                  <p>開発モード: 5秒後に自動リトライします...</p>
                  {!this.retryTimer && this.handleAutoRetry()}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      );
    }
    
    return children;
  }
}

/**
 * 関数コンポーネント版のエラーバウンダリフック
 * React 19の新機能を使用した場合の代替案
 */
export const useErrorBoundary = () => {
  const [error, setError] = React.useState<Error | null>(null);
  
  const resetError = React.useCallback(() => {
    setError(null);
  }, []);
  
  const captureError = React.useCallback((error: Error) => {
    console.error('Error captured by useErrorBoundary:', error);
    setError(error);
  }, []);
  
  // エラーが発生した場合は throw する（ErrorBoundaryでキャッチするため）
  React.useEffect(() => {
    if (error) {
      throw error;
    }
  }, [error]);
  
  return { captureError, resetError };
};

export default ErrorBoundary;