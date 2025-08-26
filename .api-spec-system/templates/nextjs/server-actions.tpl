// api-spec-systemによって生成されたコード。編集しないでください。
// Next.js 15 サーバーアクション

'use server';

import { cookies } from 'next/headers';
import { cache } from 'react';
import { revalidatePath, revalidateTag } from 'next/cache';

const API_BASE_URL = process.env.API_URL || 'http://localhost:8888';

// サーバーサイドAPIリクエストヘルパー
async function serverRequest<T>(
  method: string,
  path: string,
  body?: any,
  options?: RequestInit
): Promise<T> {
  const cookieStore = await cookies();
  const accessToken = cookieStore.get('access_token')?.value;

  const response = await fetch(`${API_BASE_URL}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(accessToken && { 'Authorization': `Bearer ${accessToken}` }),
    },
    body: body ? JSON.stringify(body) : undefined,
    ...options,
    {{if .NextCache}}
    next: {
      revalidate: {{.NextCache.Revalidate}},
      tags: {{.NextCache.Tags}},
    },
    {{end}}
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message);
  }

  return response.json();
}

{{range .Endpoints}}
// {{.Summary}}
{{if .ServerAction}}
export async function {{.OperationId}}Action({{if .HasRequest}}formData: FormData{{end}}) {
  {{if .HasRequest}}
  // フォームデータをパース
  const data = {
    {{range .RequestFields}}
    {{.Name}}: formData.get('{{.Name}}'),
    {{end}}
  };

  // データを検証
  {{if .HasValidation}}
  // サーバーサイド検証
  {{end}}
  {{end}}

  try {
    const response = await serverRequest<{{.ResponseType}}>(
      '{{.Method}}',
      '{{.Path}}'{{if .HasRequest}},
      data{{end}}
    );

    {{if .RevalidatePaths}}
    // キャッシュを再検証
    {{range .RevalidatePaths}}
    revalidatePath('{{.}}');
    {{end}}
    {{end}}

    {{if .RevalidateTags}}
    {{range .RevalidateTags}}
    revalidateTag('{{.}}');
    {{end}}
    {{end}}

    return { success: true, data: response };
  } catch (error) {
    return { success: false, error: error.message };
  }
}
{{end}}
{{end}}

// キャッシュされたデータフェッチャー
{{range .Endpoints}}
{{if eq .Method "GET"}}
export const get{{.OperationId | title}} = cache(async ({{if .HasParams}}params: {{.ParamsType}}{{end}}) => {
  return serverRequest<{{.ResponseType}}>(
    'GET',
    '{{.Path}}'{{if .HasParams}},
    undefined,
    { 
      next: { 
        revalidate: {{.CacheTime | default "3600"}},
        tags: ['{{.OperationId}}']
      } 
    }{{end}}
  );
});
{{end}}
{{end}}