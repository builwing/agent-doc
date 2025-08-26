// api-spec-systemによって生成されたコード。編集しないでください。
// ソース: {{.SpecFile}}

import { z } from 'zod';

// API設定
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8888';

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

// APIクライアントクラス
export class ApiClient {
  private baseUrl: string;
  private headers: HeadersInit;
  private accessToken?: string;

  constructor(baseUrl: string = API_BASE_URL) {
    this.baseUrl = baseUrl;
    this.headers = {
      'Content-Type': 'application/json',
    };
  }

  setAccessToken(token: string) {
    this.accessToken = token;
    this.headers = {
      ...this.headers,
      'Authorization': `Bearer ${token}`,
    };
  }

  private async request<T>(
    method: string,
    path: string,
    body?: any,
    options?: RequestInit
  ): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    
    const response = await fetch(url, {
      method,
      headers: this.headers,
      body: body ? JSON.stringify(body) : undefined,
      ...options,
    });

    if (!response.ok) {
      const error = await response.json();
      throw new ApiError(error.message, response.status, error.code);
    }

    return response.json();
  }

  {{range .Endpoints}}
  // {{.Summary}}
  async {{.OperationId}}({{if .HasRequest}}params: {{.OperationId}}Request{{end}}): Promise<{{.OperationId}}Response> {
    {{if .HasValidation}}
    // リクエストの検証
    const validated = {{.RequestType}}Schema.parse(params);
    {{end}}
    
    return this.request<{{.OperationId}}Response>(
      '{{.Method}}',
      '{{.Path}}'{{if .HasRequest}},
      validated{{end}}
    );
  }
  {{end}}
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
export const apiClient = new ApiClient();