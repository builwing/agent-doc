// api-spec-systemによって生成されたコード。編集しないでください。
// ソース: {{.SpecFile}}

import AsyncStorage from '@react-native-async-storage/async-storage';
import NetInfo from '@react-native-community/netinfo';
import { z } from 'zod';
import { fetch } from 'expo/fetch'; // WinterCG準拠のfetchを使用

// API設定
const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:8888';

// 型定義
{{range .Schemas}}
export const {{.Name}}Schema = z.object({
  {{range .Properties}}
  {{.Name}}: z.{{.ZodType}}(){{if .Optional}}.optional(){{end}},
  {{end}}
});

export type {{.Name}} = z.infer<typeof {{.Name}}Schema>;
{{end}}

// リクエスト/レスポンス型
{{range .Endpoints}}
{{if .Request}}
export type {{.OperationId}}Request = {{.RequestType}};
{{end}}
export type {{.OperationId}}Response = {{.ResponseType}};
{{end}}

// オフラインキュー管理
class OfflineQueue {
  private queue: Array<{
    id: string;
    method: string;
    path: string;
    body?: any;
    timestamp: number;
  }> = [];

  async add(request: any) {
    const id = `${Date.now()}_${Math.random()}`;
    this.queue.push({ ...request, id, timestamp: Date.now() });
    await this.persist();
    return id;
  }

  async process(apiService: ApiService) {
    const isConnected = await NetInfo.fetch().then(state => state.isConnected);
    if (!isConnected) return;

    const queue = [...this.queue];
    this.queue = [];

    for (const request of queue) {
      try {
        await apiService.request(request.method, request.path, request.body);
      } catch (error) {
        // 失敗した場合はキューに再追加
        this.queue.push(request);
      }
    }

    await this.persist();
  }

  private async persist() {
    await AsyncStorage.setItem('offline_queue', JSON.stringify(this.queue));
  }

  async load() {
    const data = await AsyncStorage.getItem('offline_queue');
    if (data) {
      this.queue = JSON.parse(data);
    }
  }
}

// キャッシュ管理
class CacheManager {
  private cachePrefix = 'api_cache_';

  async get<T>(key: string): Promise<T | null> {
    try {
      const data = await AsyncStorage.getItem(this.cachePrefix + key);
      if (!data) return null;

      const cached = JSON.parse(data);
      if (cached.expiresAt && cached.expiresAt < Date.now()) {
        await this.remove(key);
        return null;
      }

      return cached.data;
    } catch {
      return null;
    }
  }

  async set<T>(key: string, data: T, ttl?: number) {
    const cacheData = {
      data,
      expiresAt: ttl ? Date.now() + ttl * 1000 : null,
    };
    await AsyncStorage.setItem(this.cachePrefix + key, JSON.stringify(cacheData));
  }

  async remove(key: string) {
    await AsyncStorage.removeItem(this.cachePrefix + key);
  }

  async clear() {
    const keys = await AsyncStorage.getAllKeys();
    const cacheKeys = keys.filter(key => key.startsWith(this.cachePrefix));
    await AsyncStorage.multiRemove(cacheKeys);
  }
}

// APIサービスクラス
export class ApiService {
  private baseUrl: string;
  private accessToken?: string;
  private offlineQueue: OfflineQueue;
  private cache: CacheManager;

  constructor(baseUrl: string = API_BASE_URL) {
    this.baseUrl = baseUrl;
    this.offlineQueue = new OfflineQueue();
    this.cache = new CacheManager();
    this.initializeOfflineQueue();
  }

  private async initializeOfflineQueue() {
    await this.offlineQueue.load();
    
    // ネットワーク状態が変更されたときにキューを処理
    NetInfo.addEventListener(state => {
      if (state.isConnected) {
        this.offlineQueue.process(this);
      }
    });
  }

  async setAccessToken(token: string) {
    this.accessToken = token;
    await AsyncStorage.setItem('access_token', token);
  }

  async loadAccessToken() {
    const token = await AsyncStorage.getItem('access_token');
    if (token) {
      this.accessToken = token;
    }
  }

  async request<T>(
    method: string,
    path: string,
    body?: any,
    options?: RequestInit & { offline?: boolean; cacheTime?: number }
  ): Promise<T> {
    // GETリクエストのキャッシュを確認
    if (method === 'GET' && options?.cacheTime) {
      const cached = await this.cache.get<T>(path);
      if (cached) return cached;
    }

    // ネットワーク接続を確認
    const netInfo = await NetInfo.fetch();
    if (!netInfo.isConnected) {
      if (options?.offline) {
        // オフラインキューに追加
        await this.offlineQueue.add({ method, path, body });
        // 利用可能な場合はキャッシュデータを返す
        const cached = await this.cache.get<T>(path);
        if (cached) return cached;
        throw new Error('ネットワーク接続がなく、キャッシュデータもありません');
      }
      throw new Error('ネットワーク接続がありません');
    }

    const url = `${this.baseUrl}${path}`;
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...(this.accessToken && { 'Authorization': `Bearer ${this.accessToken}` }),
    };

    const response = await fetch(url, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
      ...options,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: 'リクエストが失敗しました' }));
      throw new ApiError(error.message || `HTTP ${response.status}`, response.status, error.code);
    }

    const data = await response.json();

    // 成功したGETリクエストをキャッシュ
    if (method === 'GET' && options?.cacheTime) {
      await this.cache.set(path, data, options.cacheTime);
    }

    return data;
  }

  {{range .Endpoints}}
  // {{.Summary}}
  async {{.OperationId}}({{if .HasRequest}}params: {{.OperationId}}Request{{end}}{{if .HasQueryParams}}, query?: Record<string, any>{{end}}): Promise<{{.OperationId}}Response> {
    {{if .HasValidation}}
    // リクエストを検証
    const validated = {{.RequestType}}Schema.parse(params);
    {{end}}
    
    {{if .HasQueryParams}}
    const queryString = query ? `?${new URLSearchParams(query).toString()}` : '';
    {{end}}
    
    return this.request<{{.OperationId}}Response>(
      '{{.Method}}',
      '{{.Path}}'{{if .HasQueryParams}} + queryString{{end}}{{if .HasRequest}},
      validated{{end}},
      {
        {{if .Mobile.Offline}}offline: true,{{end}}
        {{if .Mobile.CacheTime}}cacheTime: {{.Mobile.CacheTime}},{{end}}
      }
    );
  }
  {{end}}

  // すべてのキャッシュデータをクリア
  async clearCache() {
    await this.cache.clear();
  }

  // オフラインキューを手動で処理
  async syncOfflineData() {
    await this.offlineQueue.process(this);
  }
}

// エラーハンドリング
export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public code?: number
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

// シングルトンインスタンス
export const apiService = new ApiService();