# JavaScript/TypeScript プロジェクトテンプレート

## Next.js 15 プロジェクト構造

### App Router構造
```
project-root/
├── app/                      # App Router
│   ├── (auth)/              # 認証グループ
│   │   ├── login/
│   │   │   └── page.tsx
│   │   └── register/
│   │       └── page.tsx
│   ├── (dashboard)/         # ダッシュボードグループ
│   │   ├── layout.tsx
│   │   └── dashboard/
│   │       └── page.tsx
│   ├── api/                 # APIルート
│   │   └── v1/
│   │       └── [...route]/
│   │           └── route.ts
│   ├── layout.tsx           # ルートレイアウト
│   ├── page.tsx             # ホームページ
│   ├── loading.tsx          # ローディングUI
│   ├── error.tsx            # エラーUI
│   └── not-found.tsx        # 404ページ
├── components/              # コンポーネント
│   ├── ui/                 # UIコンポーネント
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   └── dialog.tsx
│   ├── features/           # 機能別コンポーネント
│   │   ├── auth/
│   │   └── user/
│   └── layouts/            # レイアウトコンポーネント
├── lib/                    # ライブラリ・ユーティリティ
│   ├── api/               # API関連
│   │   ├── client.ts
│   │   └── endpoints.ts
│   ├── hooks/             # カスタムフック
│   │   ├── use-auth.ts
│   │   └── use-toast.ts
│   ├── utils/             # ユーティリティ
│   │   ├── cn.ts
│   │   └── format.ts
│   └── validations/       # バリデーション
│       └── schemas.ts
├── services/              # サービス層
│   ├── auth.service.ts
│   └── user.service.ts
├── stores/                # 状態管理（Zustand/Redux）
│   ├── auth.store.ts
│   └── user.store.ts
├── types/                 # 型定義
│   ├── api.types.ts
│   └── models.types.ts
├── styles/                # スタイル
│   └── globals.css
├── public/                # 静的ファイル
├── tests/                 # テスト
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── .env.local            # 環境変数
├── next.config.js        # Next.js設定
├── tsconfig.json         # TypeScript設定
├── tailwind.config.ts    # Tailwind設定
├── package.json
└── README.md
```

## 基本設定

### package.json
```json
{
  "name": "project-name",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "type-check": "tsc --noEmit",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "format": "prettier --write .",
    "prepare": "husky install"
  },
  "dependencies": {
    "next": "15.0.0",
    "react": "^18.3.0",
    "react-dom": "^18.3.0",
    "@tanstack/react-query": "^5.0.0",
    "axios": "^1.6.0",
    "zustand": "^4.4.0",
    "zod": "^3.22.0",
    "react-hook-form": "^7.48.0",
    "@hookform/resolvers": "^3.3.0"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "typescript": "^5",
    "eslint": "^8",
    "eslint-config-next": "15.0.0",
    "@typescript-eslint/parser": "^6",
    "@typescript-eslint/eslint-plugin": "^6",
    "prettier": "^3.1.0",
    "tailwindcss": "^3.4.0",
    "autoprefixer": "^10.4.0",
    "postcss": "^8.4.0",
    "jest": "^29.7.0",
    "@testing-library/react": "^14.1.0",
    "@testing-library/jest-dom": "^6.1.0",
    "husky": "^8.0.0",
    "lint-staged": "^15.0.0"
  }
}
```

### tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"],
      "@/components/*": ["./components/*"],
      "@/lib/*": ["./lib/*"],
      "@/hooks/*": ["./lib/hooks/*"],
      "@/types/*": ["./types/*"],
      "@/services/*": ["./services/*"],
      "@/stores/*": ["./stores/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

## コード規約

### 命名規則
```typescript
// ファイル名: kebab-case
user-profile.tsx
api-client.ts

// コンポーネント: PascalCase
export function UserProfile() { }

// 関数・変数: camelCase
const getUserData = async () => { }
const isLoading = false

// 定数: UPPER_SNAKE_CASE
const API_BASE_URL = 'https://api.example.com'
const MAX_RETRY_COUNT = 3

// 型・インターフェース: PascalCase
interface User {
  id: string
  name: string
}

type ApiResponse<T> = {
  data: T
  error?: string
}

// Enum: PascalCase、値はUPPER_SNAKE_CASE
enum UserRole {
  ADMIN = 'ADMIN',
  USER = 'USER',
  GUEST = 'GUEST'
}
```

### コンポーネント実装

#### Server Component（デフォルト）
```typescript
// app/users/page.tsx
import { getUsers } from '@/services/user.service'

export default async function UsersPage() {
  const users = await getUsers()
  
  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">ユーザー一覧</h1>
      <UserList users={users} />
    </div>
  )
}
```

#### Client Component
```typescript
// components/features/user/user-form.tsx
'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { userSchema } from '@/lib/validations/schemas'

interface UserFormProps {
  onSubmit: (data: UserFormData) => Promise<void>
}

export function UserForm({ onSubmit }: UserFormProps) {
  const [isSubmitting, setIsSubmitting] = useState(false)
  
  const form = useForm<UserFormData>({
    resolver: zodResolver(userSchema),
    defaultValues: {
      name: '',
      email: ''
    }
  })
  
  const handleSubmit = async (data: UserFormData) => {
    setIsSubmitting(true)
    try {
      await onSubmit(data)
    } finally {
      setIsSubmitting(false)
    }
  }
  
  return (
    <form onSubmit={form.handleSubmit(handleSubmit)}>
      {/* フォームフィールド */}
    </form>
  )
}
```

### API実装

#### Route Handler
```typescript
// app/api/v1/users/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'

const createUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email()
})

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams
    const page = searchParams.get('page') || '1'
    
    const users = await getUsersFromDB(parseInt(page))
    
    return NextResponse.json({
      success: true,
      data: users
    })
  } catch (error) {
    return NextResponse.json(
      { success: false, error: 'Internal Server Error' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const validated = createUserSchema.parse(body)
    
    const user = await createUser(validated)
    
    return NextResponse.json(
      { success: true, data: user },
      { status: 201 }
    )
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { success: false, errors: error.errors },
        { status: 400 }
      )
    }
    
    return NextResponse.json(
      { success: false, error: 'Internal Server Error' },
      { status: 500 }
    )
  }
}
```

### 状態管理（Zustand）
```typescript
// stores/auth.store.ts
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface User {
  id: string
  name: string
  email: string
}

interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  login: (user: User, token: string) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      
      login: (user, token) => set({
        user,
        token,
        isAuthenticated: true
      }),
      
      logout: () => set({
        user: null,
        token: null,
        isAuthenticated: false
      })
    }),
    {
      name: 'auth-storage'
    }
  )
)
```

### カスタムフック
```typescript
// lib/hooks/use-api.ts
import { useState, useEffect } from 'react'
import { useQuery, useMutation } from '@tanstack/react-query'
import { apiClient } from '@/lib/api/client'

export function useApi<T>(
  endpoint: string,
  options?: RequestOptions
) {
  return useQuery<T>({
    queryKey: [endpoint, options],
    queryFn: () => apiClient.get<T>(endpoint, options),
    ...options
  })
}

export function useApiMutation<TData, TVariables>(
  endpoint: string,
  method: 'POST' | 'PUT' | 'PATCH' | 'DELETE' = 'POST'
) {
  return useMutation<TData, Error, TVariables>({
    mutationFn: (variables) => 
      apiClient.request<TData>(endpoint, {
        method,
        data: variables
      })
  })
}
```

## テスト

### ユニットテスト
```typescript
// tests/unit/components/button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import { Button } from '@/components/ui/button'

describe('Button', () => {
  it('renders correctly', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByText('Click me')).toBeInTheDocument()
  })
  
  it('handles click events', () => {
    const handleClick = jest.fn()
    render(<Button onClick={handleClick}>Click me</Button>)
    
    fireEvent.click(screen.getByText('Click me'))
    expect(handleClick).toHaveBeenCalledTimes(1)
  })
})
```

### 統合テスト
```typescript
// tests/integration/auth.test.ts
import { POST } from '@/app/api/auth/login/route'
import { NextRequest } from 'next/server'

describe('Auth API', () => {
  it('should login with valid credentials', async () => {
    const request = new NextRequest('http://localhost:3000/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({
        email: 'test@example.com',
        password: 'password123'
      })
    })
    
    const response = await POST(request)
    const data = await response.json()
    
    expect(response.status).toBe(200)
    expect(data.success).toBe(true)
    expect(data.data.token).toBeDefined()
  })
})
```

## Expo (React Native) 追加構造

### Expoプロジェクト構造
```
mobile/
├── app/                    # Expo Router
│   ├── (tabs)/            # タブナビゲーション
│   │   ├── _layout.tsx
│   │   ├── index.tsx
│   │   └── profile.tsx
│   ├── (auth)/            # 認証スクリーン
│   │   ├── login.tsx
│   │   └── register.tsx
│   └── _layout.tsx        # ルートレイアウト
├── components/            # コンポーネント
├── constants/             # 定数
├── hooks/                 # カスタムフック
├── services/              # API サービス
├── utils/                 # ユーティリティ
├── app.json              # Expo設定
├── babel.config.js       # Babel設定
├── tsconfig.json         # TypeScript設定
└── package.json
```

### Expo設定（app.json）
```json
{
  "expo": {
    "name": "MyApp",
    "slug": "my-app",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "automatic",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "assetBundlePatterns": ["**/*"],
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.example.myapp"
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#ffffff"
      },
      "package": "com.example.myapp"
    }
  }
}
```

---
*このテンプレートはNext.js 15とExpoを使用したJavaScript/TypeScriptプロジェクトの標準構造を定義しています。*