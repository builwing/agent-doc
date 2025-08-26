# Python プロジェクトテンプレート

## FastAPI プロジェクト構造

### 標準構造
```
project-root/
├── app/                      # アプリケーションコア
│   ├── api/                 # APIエンドポイント
│   │   ├── v1/             # APIバージョン1
│   │   │   ├── endpoints/  # エンドポイント定義
│   │   │   │   ├── auth.py
│   │   │   │   ├── users.py
│   │   │   │   └── items.py
│   │   │   ├── deps.py     # 依存関係
│   │   │   └── router.py   # ルーター集約
│   │   └── health.py       # ヘルスチェック
│   ├── core/               # コア機能
│   │   ├── config.py       # 設定管理
│   │   ├── security.py     # セキュリティ
│   │   ├── database.py     # DB接続
│   │   └── exceptions.py   # 例外定義
│   ├── models/             # データモデル
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── item.py
│   ├── schemas/            # Pydanticスキーマ
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── item.py
│   ├── services/           # ビジネスロジック
│   │   ├── __init__.py
│   │   ├── user_service.py
│   │   └── auth_service.py
│   ├── repositories/       # データアクセス層
│   │   ├── __init__.py
│   │   ├── user_repository.py
│   │   └── item_repository.py
│   ├── utils/              # ユーティリティ
│   │   ├── __init__.py
│   │   ├── validators.py
│   │   └── formatters.py
│   └── main.py            # エントリーポイント
├── migrations/             # DBマイグレーション
│   └── versions/
├── tests/                  # テスト
│   ├── unit/              # ユニットテスト
│   ├── integration/       # 統合テスト
│   └── conftest.py        # pytest設定
├── scripts/                # スクリプト
│   ├── init_db.py
│   └── seed_data.py
├── docker/                 # Docker設定
│   ├── Dockerfile
│   └── docker-compose.yml
├── .env.example           # 環境変数サンプル
├── requirements.txt       # 依存パッケージ
├── requirements-dev.txt   # 開発用依存パッケージ
├── pyproject.toml         # プロジェクト設定
├── setup.cfg              # ツール設定
├── alembic.ini            # Alembic設定
└── README.md
```

## 基本設定

### pyproject.toml
```toml
[tool.poetry]
name = "project-name"
version = "1.0.0"
description = "Project description"
authors = ["Your Name <email@example.com>"]

[tool.poetry.dependencies]
python = "^3.11"
fastapi = "^0.109.0"
uvicorn = {extras = ["standard"], version = "^0.27.0"}
sqlalchemy = "^2.0.0"
alembic = "^1.13.0"
psycopg2-binary = "^2.9.0"
redis = "^5.0.0"
pydantic = "^2.5.0"
pydantic-settings = "^2.1.0"
python-jose = {extras = ["cryptography"], version = "^3.3.0"}
passlib = {extras = ["bcrypt"], version = "^1.7.4"}
python-multipart = "^0.0.6"
httpx = "^0.26.0"
celery = "^5.3.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.4.0"
pytest-asyncio = "^0.21.0"
pytest-cov = "^4.1.0"
black = "^23.12.0"
ruff = "^0.1.0"
mypy = "^1.8.0"
pre-commit = "^3.6.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"

[tool.black]
line-length = 88
target-version = ['py311']

[tool.ruff]
line-length = 88
select = ["E", "F", "I", "N", "W", "B", "C90", "UP"]
ignore = ["E501"]

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
ignore_missing_imports = true

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["."]
addopts = "-ra -q --cov=app --cov-report=html"
```

### requirements.txt
```txt
fastapi==0.109.0
uvicorn[standard]==0.27.0
sqlalchemy==2.0.25
alembic==1.13.1
psycopg2-binary==2.9.9
redis==5.0.1
pydantic==2.5.3
pydantic-settings==2.1.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
httpx==0.26.0
celery==5.3.4
```

## コード規約

### 命名規則
```python
# ファイル名: snake_case
user_service.py
database_config.py

# クラス: PascalCase
class UserService:
    pass

class DatabaseConnection:
    pass

# 関数・変数: snake_case
def get_user_by_id(user_id: int) -> User:
    pass

user_name = "John"
is_active = True

# 定数: UPPER_SNAKE_CASE
MAX_RETRY_COUNT = 3
API_BASE_URL = "https://api.example.com"
DEFAULT_TIMEOUT = 30

# プライベート: 先頭にアンダースコア
class MyClass:
    def __init__(self):
        self._private_var = "private"
    
    def _private_method(self):
        pass
```

### 型ヒント
```python
from typing import Optional, List, Dict, Any, Union
from datetime import datetime

def process_data(
    data: List[Dict[str, Any]],
    filter_key: Optional[str] = None,
    limit: int = 100
) -> Dict[str, Union[int, List[str]]]:
    """
    データを処理する

    Args:
        data: 処理するデータのリスト
        filter_key: フィルタリングキー
        limit: 最大処理数

    Returns:
        処理結果の辞書
    """
    pass
```

## FastAPI実装

### メインアプリケーション
```python
# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.database import engine, Base

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 起動時
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    # 終了時
    await engine.dispose()

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan
)

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ルーター登録
app.include_router(api_router, prefix=settings.API_V1_STR)
```

### 設定管理
```python
# app/core/config.py
from pydantic_settings import BaseSettings
from typing import List, Optional
from functools import lru_cache

class Settings(BaseSettings):
    # アプリケーション設定
    PROJECT_NAME: str = "FastAPI Project"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # セキュリティ
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # データベース
    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 10
    DATABASE_MAX_OVERFLOW: int = 20
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379"
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["http://localhost:3000"]
    
    class Config:
        env_file = ".env"
        case_sensitive = True

@lru_cache()
def get_settings() -> Settings:
    return Settings()

settings = get_settings()
```

### データベースモデル
```python
# app/models/user.py
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func
from app.core.database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
```

### Pydanticスキーマ
```python
# app/schemas/user.py
from pydantic import BaseModel, EmailStr, ConfigDict
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    username: str
    is_active: bool = True

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    password: Optional[str] = None
    is_active: Optional[bool] = None

class UserInDB(UserBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    model_config = ConfigDict(from_attributes=True)

class UserResponse(UserInDB):
    pass

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
```

### APIエンドポイント
```python
# app/api/v1/endpoints/users.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.api.v1.deps import get_current_user, get_db
from app.schemas.user import UserResponse, UserCreate, UserUpdate
from app.services.user_service import UserService
from app.models.user import User

router = APIRouter()

@router.get("/", response_model=List[UserResponse])
async def get_users(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db)
):
    """ユーザー一覧を取得"""
    service = UserService(db)
    return await service.get_multi(skip=skip, limit=limit)

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db)
):
    """特定のユーザーを取得"""
    service = UserService(db)
    user = await service.get(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return user

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_in: UserCreate,
    db: AsyncSession = Depends(get_db)
):
    """新規ユーザーを作成"""
    service = UserService(db)
    user = await service.create(user_in)
    return user

@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user_in: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """ユーザー情報を更新"""
    service = UserService(db)
    user = await service.update(user_id, user_in)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return user
```

### サービス層
```python
# app/services/user_service.py
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from passlib.context import CryptContext

from app.repositories.user_repository import UserRepository
from app.schemas.user import UserCreate, UserUpdate
from app.models.user import User

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserService:
    def __init__(self, db: AsyncSession):
        self.repository = UserRepository(db)
    
    async def get(self, user_id: int) -> Optional[User]:
        return await self.repository.get(user_id)
    
    async def get_by_email(self, email: str) -> Optional[User]:
        return await self.repository.get_by_email(email)
    
    async def get_multi(self, skip: int = 0, limit: int = 100) -> List[User]:
        return await self.repository.get_multi(skip=skip, limit=limit)
    
    async def create(self, user_in: UserCreate) -> User:
        # パスワードのハッシュ化
        hashed_password = pwd_context.hash(user_in.password)
        
        # ユーザー作成
        user_data = user_in.model_dump(exclude={"password"})
        user_data["hashed_password"] = hashed_password
        
        return await self.repository.create(user_data)
    
    async def update(self, user_id: int, user_in: UserUpdate) -> Optional[User]:
        user = await self.repository.get(user_id)
        if not user:
            return None
        
        update_data = user_in.model_dump(exclude_unset=True)
        
        # パスワードが含まれている場合はハッシュ化
        if "password" in update_data:
            update_data["hashed_password"] = pwd_context.hash(update_data.pop("password"))
        
        return await self.repository.update(user, update_data)
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        return pwd_context.verify(plain_password, hashed_password)
```

## テスト

### pytest設定
```python
# tests/conftest.py
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.core.database import Base
from app.api.v1.deps import get_db

# テスト用データベース
DATABASE_URL = "sqlite+aiosqlite:///:memory:"

@pytest.fixture
async def async_session():
    engine = create_async_engine(DATABASE_URL, echo=True)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    AsyncSessionLocal = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async with AsyncSessionLocal() as session:
        yield session
    
    await engine.dispose()

@pytest.fixture
async def client(async_session):
    def override_get_db():
        yield async_session
    
    app.dependency_overrides[get_db] = override_get_db
    
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac
```

### ユニットテスト
```python
# tests/unit/test_user_service.py
import pytest
from unittest.mock import AsyncMock

from app.services.user_service import UserService
from app.schemas.user import UserCreate

@pytest.mark.asyncio
async def test_create_user():
    # モックの準備
    mock_db = AsyncMock()
    service = UserService(mock_db)
    service.repository.create = AsyncMock(return_value={"id": 1, "email": "test@example.com"})
    
    # テスト実行
    user_in = UserCreate(
        email="test@example.com",
        username="testuser",
        password="password123"
    )
    
    result = await service.create(user_in)
    
    # 検証
    assert result["email"] == "test@example.com"
    service.repository.create.assert_called_once()
```

### 統合テスト
```python
# tests/integration/test_api.py
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_create_and_get_user(client: AsyncClient):
    # ユーザー作成
    response = await client.post(
        "/api/v1/users/",
        json={
            "email": "test@example.com",
            "username": "testuser",
            "password": "password123"
        }
    )
    assert response.status_code == 201
    user_id = response.json()["id"]
    
    # ユーザー取得
    response = await client.get(f"/api/v1/users/{user_id}")
    assert response.status_code == 200
    assert response.json()["email"] == "test@example.com"
```

## Django追加構造（オプション）

### Djangoプロジェクト構造
```
django-project/
├── config/                 # プロジェクト設定
│   ├── settings/
│   │   ├── base.py
│   │   ├── development.py
│   │   └── production.py
│   ├── urls.py
│   └── wsgi.py
├── apps/                   # アプリケーション
│   ├── users/
│   ├── products/
│   └── orders/
├── static/                 # 静的ファイル
├── media/                  # メディアファイル
├── templates/              # テンプレート
└── manage.py
```

---
*このテンプレートはPython（FastAPI/Django）を使用したプロジェクトの標準構造を定義しています。*