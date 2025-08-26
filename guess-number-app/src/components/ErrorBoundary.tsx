/**
 * ErrorBoundary - React エラーバウンダリ
 * アプリケーション全体のエラーハンドリングとリカバリ機能
 * 日本語エラーメッセージとデバッグ情報表示
 */

'use client';

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
    }
  };

  // ページリロード
  private handleReload = () => {
    window.location.reload();
  };

  render() {
    const { children, fallback, className } = this.props;
    const { hasError, error, retryCount } = this.state;
    
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
              <div className="p-4 bg-error-50 rounded-lg border-l-4 border-error-400">
                <h3 className="font-semibold text-error-800 mb-2">
                  エラーの詳細
                </h3>
                <p className="text-error-700 font-mono text-sm">
                  {error?.message || 'Unknown error'}
                </p>
              </div>
              
              {/* 対処方法の提案 */}
              <div className="p-4 bg-info-50 rounded-lg border-l-4 border-info-400">
                <h3 className="font-semibold text-info-800 mb-2">
                  💡 対処方法
                </h3>
                <ul className="text-info-700 text-sm space-y-1">
                  <li>• 「再試行」ボタンを押してもう一度お試しください</li>
                  <li>• それでも解決しない場合はページを再読み込みしてください</li>
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
            </CardContent>
          </Card>
        </div>
      );
    }
    
    return children;
  }
}

export default ErrorBoundary;