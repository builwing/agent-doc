// api-spec-systemによって生成されたコード。編集しないでください。
// Expo用React Native Hooks

import { useQuery, useMutation, useQueryClient, UseQueryOptions, UseMutationOptions } from '@tanstack/react-query';
import { useEffect, useState } from 'react';
import NetInfo from '@react-native-community/netinfo';
import { apiService } from './api-service';

// ネットワーク状態フック
export function useNetworkStatus() {
  const [isConnected, setIsConnected] = useState<boolean | null>(null);
  const [isInternetReachable, setIsInternetReachable] = useState<boolean | null>(null);

  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener(state => {
      setIsConnected(state.isConnected);
      setIsInternetReachable(state.isInternetReachable);
    });

    return () => unsubscribe();
  }, []);

  return { isConnected, isInternetReachable };
}

{{range .Endpoints}}
{{if eq .Method "GET"}}
// {{.Summary}}
export function use{{.OperationId | title}}(
  {{if .HasParams}}params: {{.ParamsType}},{{end}}
  options?: UseQueryOptions<{{.ResponseType}}, Error>
) {
  const { isConnected } = useNetworkStatus();
  
  return useQuery({
    queryKey: ['{{.OperationId}}'{{if .HasParams}}, params{{end}}],
    queryFn: () => apiService.{{.OperationId}}({{if .HasParams}}params{{end}}),
    enabled: isConnected !== false{{if .HasParams}} && !!params{{end}},
    {{if .Mobile.CacheTime}}
    staleTime: {{.Mobile.CacheTime}} * 1000,
    gcTime: {{.Mobile.CacheTime}} * 1000 * 2,
    {{end}}
    {{if .Mobile.Offline}}
    // このエンドポイントはオフラインモードをサポート
    retry: (failureCount, error) => {
      if (!isConnected) return false;
      return failureCount < 3;
    },
    {{end}}
    ...options,
  });
}
{{else}}
// {{.Summary}}
export function use{{.OperationId | title}}(
  options?: UseMutationOptions<{{.ResponseType}}, Error, {{.RequestType}}>
) {
  const queryClient = useQueryClient();
  const { isConnected } = useNetworkStatus();

  return useMutation({
    mutationFn: (params: {{.RequestType}}) => apiService.{{.OperationId}}(params),
    onSuccess: (data, variables, context) => {
      {{if .InvalidatesCache}}
      // 関連クエリを無効化
      {{range .InvalidatesCache}}
      queryClient.invalidateQueries({ queryKey: ['{{.}}'] });
      {{end}}
      {{end}}
      
      options?.onSuccess?.(data, variables, context);
    },
    onError: (error, variables, context) => {
      if (!isConnected) {
        // リクエストはオフライン同期用にキューに追加されました
        console.log('リクエストはオフライン同期用にキューに追加されました');
      }
      options?.onError?.(error, variables, context);
    },
    ...options,
  });
}
{{end}}
{{end}}

// ナビゲーション用プリフェッチヘルパー
export function usePrefetch() {
  const queryClient = useQueryClient();

  return {
    {{range .Endpoints}}
    {{if eq .Method "GET"}}
    prefetch{{.OperationId | title}}: ({{if .HasParams}}params: {{.ParamsType}}{{end}}) => {
      return queryClient.prefetchQuery({
        queryKey: ['{{.OperationId}}'{{if .HasParams}}, params{{end}}],
        queryFn: () => apiService.{{.OperationId}}({{if .HasParams}}params{{end}}),
      });
    },
    {{end}}
    {{end}}
  };
}

// 楽観的更新ヘルパー
export function useOptimisticUpdate<T>(queryKey: string[]) {
  const queryClient = useQueryClient();

  return {
    update: (updater: (old: T | undefined) => T) => {
      queryClient.setQueryData(queryKey, updater);
    },
    rollback: () => {
      queryClient.invalidateQueries({ queryKey });
    },
  };
}