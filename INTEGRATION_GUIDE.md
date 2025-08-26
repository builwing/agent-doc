# 🔧 Agentix統合ガイド

既存プロジェクトにAgentixシステムを安全に統合する方法を説明します。

## 📋 目次

1. [統合前の準備](#統合前の準備)
2. [統合方法](#統合方法)
3. [プロジェクトタイプ別の注意点](#プロジェクトタイプ別の注意点)
4. [トラブルシューティング](#トラブルシューティング)
5. [ロールバック方法](#ロールバック方法)

## 統合前の準備

### 必須要件
- Git（バージョン管理）
- Bash 4.0以上
- Node.js 18以上（Context7 MCP用）

### 推奨事項
1. **現在のプロジェクトをコミット**
   ```bash
   git add -A
   git commit -m "Before Agentix integration"
   ```

2. **ブランチを作成**
   ```bash
   git checkout -b feature/agentix-integration
   ```

## 統合方法

### 方法1: 自動統合スクリプトを使用（推奨）

```bash
# 1. Agentixリポジトリをクローン（一時的）
git clone https://github.com/builwing/Agentix.git /tmp/Agentix

# 2. 既存プロジェクトのルートに移動
cd /path/to/your/existing/project

# 3. 統合スクリプトをコピーして実行
cp /tmp/Agentix/scripts/integrate_to_existing.sh ./
chmod +x integrate_to_existing.sh
./integrate_to_existing.sh

# 4. 要件定義書を編集
vi REQUIREMENTS.md  # プロジェクトに合わせて編集

# 5. エージェントを生成
./scripts/generate_agents_from_requirements.sh

# 6. Context7エラー防止設定（推奨）
./scripts/update_pm_context7.sh
```

### 方法2: 手動統合

```bash
# 1. 既存プロジェクトのバックアップ
cp -r . ../project_backup_$(date +%Y%m%d)

# 2. Agentixのscriptsディレクトリをコピー
cp -r /path/to/Agentix/scripts ./scripts

# 3. 基本セットアップを実行
./scripts/setup.sh

# 4. 既存のREQUIREMENTS.mdがない場合は作成
cat > REQUIREMENTS.md << 'EOF'
# プロジェクト要件定義書
[テンプレート内容]
EOF

# 5. エージェント生成
./scripts/generate_agents_from_requirements.sh

# 6. Context7設定
./scripts/update_pm_context7.sh
```

## プロジェクトタイプ別の注意点

### Next.js プロジェクト

#### App Router (Next.js 13+) の場合
```javascript
// ✅ 推奨: App Routerを使用
// app/page.tsx
export default function Page() {
  return <div>Hello</div>
}
```

#### Pages Router (旧式) の場合
```javascript
// ⚠️ 注意: Context7設定でApp Routerへの移行を推奨
// pages/index.tsx - 非推奨パターン
```

**対応方法:**
1. `update_pm_context7.sh`を実行してNext.js 15設定を強制
2. PMエージェントがApp Routerパターンを自動採用

### Expo プロジェクト

```bash
# Expo SDK 51以上を推奨
expo upgrade
```

### Go-Zero プロジェクト

```bash
# go.modの確認
grep "github.com/zeromicro/go-zero" go.mod

# 最新版へアップデート
go get -u github.com/zeromicro/go-zero
```

## 既存コードとの共存

### ディレクトリ構造の影響

```
your-project/
├── src/              # 既存のソースコード（影響なし）
├── components/       # 既存のコンポーネント（影響なし）
├── .claude/          # 新規追加（エージェント設定）
├── docs/agents/      # 新規追加（エージェントドキュメント）
├── scripts/          # 新規追加または統合
└── REQUIREMENTS.md   # 新規追加または更新
```

### 既存CI/CDとの統合

**.github/workflows/existing-ci.yml**を維持したまま、Agentixのワークフローを追加:

```yaml
# .github/workflows/agentix-validation.yml
name: Agentix Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate Requirements
        run: ./scripts/update_requirements.sh check
```

## トラブルシューティング

### 問題1: スクリプトの権限エラー
```bash
# 解決方法
chmod +x scripts/*.sh
```

### 問題2: Context7 MCPのインストール失敗
```bash
# Node.jsバージョンを確認
node --version  # v18以上が必要

# 手動インストール
npm install -g @upstash/context7-mcp
```

### 問題3: 既存の.claudeディレクトリとの競合
```bash
# バックアップして再生成
mv .claude .claude.old
./scripts/setup.sh
```

### 問題4: REQUIREMENTS.mdの競合
```bash
# 既存の要件定義を統合
cat .agentix_backup_*/REQUIREMENTS.md.original >> REQUIREMENTS.md
vi REQUIREMENTS.md  # 手動で統合
```

## ロールバック方法

### 完全なロールバック

```bash
# 1. Agentix関連ファイルを削除
./scripts/reset_to_initial.sh

# 2. バックアップから復元
cp .agentix_backup_*/README.md.original README.md
cp .agentix_backup_*/REQUIREMENTS.md.original REQUIREMENTS.md

# 3. Agentixスクリプトを削除
rm -rf scripts/
rm integrate_to_existing.sh

# 4. gitで元の状態に戻す
git checkout main
git branch -D feature/agentix-integration
```

### 部分的なロールバック

```bash
# エージェント設定のみリセット
rm -rf .claude/ docs/agents/
./scripts/setup.sh
```

## ベストプラクティス

### 1. 段階的な統合

```bash
# Phase 1: 基本統合
./scripts/setup.sh

# Phase 2: 1つのエージェントでテスト
./scripts/setup_custom_agents.sh -n test -d "テスト用"

# Phase 3: 全エージェント展開
./scripts/generate_agents_from_requirements.sh
```

### 2. 既存チームへの説明

```markdown
## チームへの共有事項

1. **新機能**: AI駆動の開発支援システム
2. **影響範囲**: 開発プロセスの効率化（既存コードに影響なし）
3. **使い方**: PMエージェントにタスクを伝えるだけ

例:
「ユーザー認証機能を実装してください」
→ PM、API、Security、QAエージェントが自動的に協力
```

### 3. 既存ワークフローとの統合例

```bash
# 既存のビルドスクリプトにAgentix検証を追加
# package.json
{
  "scripts": {
    "build": "npm run agentix:validate && next build",
    "agentix:validate": "./scripts/update_requirements.sh check"
  }
}
```

## セキュリティ考慮事項

1. **APIキーの管理**
   ```bash
   # .envファイルは.gitignoreに含める
   echo ".env" >> .gitignore
   ```

2. **権限管理**
   ```bash
   # エージェントの権限を制限
   vi .claude/claude.json
   # "restricted": ["WebSearch", "WebFetch"]
   ```

3. **監査ログ**
   ```bash
   # PMログを確認
   tail -f pm/logs/*.log
   ```

## サポート

問題が発生した場合:

1. [GitHub Issues](https://github.com/builwing/Agentix/issues)
2. Email: wingnakaada@gmail.com

---

**統合成功のポイント**: 既存プロジェクトの特性を理解し、段階的にAgentixシステムを導入することで、リスクを最小限に抑えながら開発効率を向上させることができます。