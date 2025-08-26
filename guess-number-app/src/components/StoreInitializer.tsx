/**
 * StoreInitializer - Zustand Store初期化コンポーネント
 * アプリケーション起動時にストアの初期化とLocalStorageからの復元を行う
 * クライアントサイドでのみ実行されるようにする
 */

'use client';

import { useEffect, useState } from 'react';
import { useGameStore, initializeGameStore } from '@/lib/game-store';

export const StoreInitializer: React.FC = () => {
  const [isInitialized, setIsInitialized] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;

    const initializeStore = async () => {
      try {
        console.log('🚀 Zustand Store初期化開始...');
        
        // ストアの初期化とLocalStorageからの復元
        await initializeGameStore();
        
        if (isMounted) {
          setIsInitialized(true);
          console.log('✅ Zustand Store初期化完了');
        }
      } catch (err) {
        console.error('❌ Zustand Store初期化エラー:', err);
        
        if (isMounted) {
          setError(err instanceof Error ? err.message : 'Store初期化に失敗しました');
        }
        
        // エラーが発生した場合でも初期化完了として扱う（デフォルト値で動作）
        if (isMounted) {
          setIsInitialized(true);
        }
      }
    };

    // ブラウザ環境でのみ初期化
    if (typeof window !== 'undefined') {
      initializeStore();
    } else {
      // サーバーサイドでは即座に初期化完了とする
      setIsInitialized(true);
    }

    return () => {
      isMounted = false;
    };
  }, []);

  // エラー表示（開発環境のみ）
  if (error && process.env.NODE_ENV === 'development') {
    return (
      <div className="fixed top-4 right-4 z-50 p-3 bg-warning-100 border border-warning-400 rounded-lg text-warning-800 text-sm max-w-sm">
        <strong>Store初期化警告:</strong><br />
        {error}
      </div>
    );
  }

  // 初期化中は何も表示しない（レイアウトシフトを防ぐ）
  return null;
};

/**
 * StoreStatus - Store状態確認用コンポーネント（開発用）
 */
export const StoreStatus: React.FC = () => {
  const gameState = useGameStore((state) => state.gameState);
  const settings = useGameStore((state) => state.settings);
  const bestRecords = useGameStore((state) => state.bestRecords);
  const gameHistory = useGameStore((state) => state.gameHistory);

  // 本番環境では表示しない
  if (process.env.NODE_ENV !== 'development') {
    return null;
  }

  return (
    <div className="fixed bottom-4 left-4 z-50 p-3 bg-neutral-900 text-white text-xs rounded-lg shadow-lg max-w-sm">
      <h4 className="font-semibold mb-2">🔍 Store Status (Dev)</h4>
      <div className="space-y-1">
        <div>Game State: {gameState?.status || 'null'}</div>
        <div>Difficulty: {settings.difficulty}</div>
        <div>Best Records: {Object.values(bestRecords).filter(Boolean).length}/3</div>
        <div>History: {gameHistory.length} games</div>
        <div>LocalStorage: {typeof localStorage !== 'undefined' ? '✅' : '❌'}</div>
      </div>
    </div>
  );
};

export default StoreInitializer;