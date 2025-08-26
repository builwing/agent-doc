// api-spec-systemによって生成されたコード。編集しないでください。
// API統合用React Hooks

import useSWR, { SWRConfiguration, mutate } from 'swr';
import { useCallback } from 'react';
import { apiClient } from './api-client';

{{range .Endpoints}}
{{if eq .Method "GET"}}
// {{.Summary}}
export function use{{.OperationId | title}}(
  {{if .HasParams}}params: {{.ParamsType}},{{end}}
  options?: SWRConfiguration
) {
  const key = {{if .HasParams}}params ? ['{{.Path}}', params] : null{{else}}'{{.Path}}'{{end}};
  
  return useSWR(
    key,
    {{if .HasParams}}() => apiClient.{{.OperationId}}(params){{else}}() => apiClient.{{.OperationId}}(){{end}},
    {
      {{if .SWR}}
      revalidateOnFocus: {{.SWR.RevalidateOnFocus}},
      revalidateOnReconnect: {{.SWR.RevalidateOnReconnect}},
      refreshInterval: {{.SWR.RefreshInterval}},
      {{end}}
      ...options,
    }
  );
}
{{else}}
// {{.Summary}}
export function use{{.OperationId | title}}() {
  const execute = useCallback(async (params: {{.RequestType}}) => {
    try {
      const response = await apiClient.{{.OperationId}}(params);
      
      {{if .InvalidatesCache}}
      // 関連キャッシュを無効化
      {{range .InvalidatesCache}}
      await mutate('{{.}}');
      {{end}}
      {{end}}
      
      return response;
    } catch (error) {
      throw error;
    }
  }, []);

  return { execute };
}
{{end}}
{{end}}

// 楽観的更新ヘルパー
export function optimisticUpdate<T>(
  key: string | string[],
  updateFn: (data: T) => T
) {
  return mutate(
    key,
    async (currentData: T) => {
      const newData = updateFn(currentData);
      return newData;
    },
    false
  );
}

// SSR/SSG用プリフェッチヘルパー
export async function prefetchData(keys: string[]) {
  const promises = keys.map(key => {
    const [path, params] = Array.isArray(key) ? key : [key, undefined];
    return apiClient.request('GET', path, params);
  });
  
  return Promise.all(promises);
}