#!/usr/bin/env bash
# CLAUDE.md 自動生成スクリプト - API整合性重視版
set -euo pipefail

echo "🤖 CLAUDE.md を自動生成します（API整合性強化版）..."

# 設定読み込み
PROJECT_NAME=$(basename "$PWD")
TIMESTAMP=$(date +%Y-%m-%d)

# 実際に存在するディレクトリとファイルを検出
detect_agents() {
    if [ -d ".claude/agents" ]; then
        find .claude/agents -maxdepth 1 -type f -name "*.md" -exec basename {} .md \; 2>/dev/null || true
    fi
}

detect_requirements() {
    if [ -f "REQUIREMENTS.md" ]; then
        echo "true"
    else
        echo "false"
    fi
}

detect_api_spec_system() {
    if [ -d "api-spec-system" ]; then
        echo "true"
    else
        echo "false"
    fi
}

detect_mcp_tools() {
    if command -v claude &> /dev/null; then
        if claude mcp list 2>/dev/null | grep -q "context7"; then
            echo "true"
        else
            echo "false"
        fi
    else
        echo "false"
    fi
}

# 要件定義書から主要な目的を抽出
extract_project_purpose() {
    if [ -f "REQUIREMENTS.md" ]; then
        # プロジェクト概要セクションから抽出（最初の段落）
        awk '/## .*プロジェクト概要/,/^## [^#]/' REQUIREMENTS.md | \
        grep -v '^##' | \
        grep -v '^$' | \
        head -5 | \
        sed 's/^/  /' || echo "  プロジェクト概要を抽出できませんでした"
    else
        echo "  要件定義書が見つかりません"
    fi
}

# Agentリストの取得
AGENTS_RAW=$(detect_agents)
AGENTS=()
if [ -n "$AGENTS_RAW" ]; then
    while IFS= read -r agent; do
        AGENTS+=("$agent")
    done <<< "$AGENTS_RAW"
fi
HAS_REQUIREMENTS=$(detect_requirements)
HAS_API_SPEC=$(detect_api_spec_system)
HAS_CONTEXT7=$(detect_mcp_tools)

# CLAUDE.md 生成
cat > CLAUDE.md << 'EOF'
# CLAUDE.md - API整合性保証システム設定書

## 🇯🇵 最優先事項 - 日本語コミュニケーションの徹底

**すべての回答、コミュニケーション、ドキュメント作成、コード内コメントは必ず日本語で行ってください。**

---

## 🚨 最重要指示 - API整合性の絶対遵守

**このプロジェクトの最重要ミッション:**
1. **すべての対話・ドキュメント・コメントは日本語で記述する**
2. **バックエンド（Go-Zero）とフロントエンド（Next.js/Expo）間のAPI仕様の完全一致を保証する**
3. **すべてのSubAgentはAPI仕様書を唯一の真実（Single Source of Truth）として扱う**
4. **API仕様の変更は必ず `api-spec-system/specs/` から開始し、自動生成コードを使用する**
5. **手動でのAPI実装や型定義の作成は厳禁**

---

## 🎯 プロジェクトの目的

EOF

# プロジェクトの目的を要件定義書から抽出
echo "### 要件定義書より抽出:" >> CLAUDE.md
extract_project_purpose >> CLAUDE.md

cat >> CLAUDE.md << EOF

### システムの核心価値:
- **API仕様駆動開発**: すべての開発はAPI仕様書から開始
- **型安全性の保証**: TypeScriptとGoの型定義を自動生成で同期
- **齟齬の完全排除**: バックエンド・フロントエンド・モバイル間の不整合を防止
- **自動検証**: API仕様準拠を自動的にチェック

---

## 🛡️ API整合性保証ルール（全SubAgent必須遵守）

### ⚠️ 絶対禁止事項
1. ❌ **generated/ディレクトリ内のファイルの直接編集**
2. ❌ **API仕様書を経由しないエンドポイントの追加**
3. ❌ **手動での型定義やAPIクライアントの作成**
4. ❌ **API仕様と異なるレスポンス形式の実装**
5. ❌ **ドキュメント化されていないAPIの使用**

### ✅ 必須実施事項
1. ✅ **API変更は必ず specs/*.yaml を編集**
2. ✅ **make generate でコード生成後に実装**
3. ✅ **make validate で仕様検証を実施**
4. ✅ **make compliance で準拠性チェック**
5. ✅ **Context7 MCPでライブラリの最新仕様を確認**

---

## 🤖 SubAgent 役割分担と責任

EOF

cat >> CLAUDE.md << EOF
あなたは **${PROJECT_NAME} プロジェクトのAPI整合性管理者** として、以下の役割を持ちます：

### 📋 管理対象SubAgent一覧と責任範囲

| Agent | API関連の責任 | 遵守事項 |
|-------|--------------|---------|
| **api** | API仕様書の管理、バックエンド実装 | specs/*.yamlを必ず更新、generated/backend/を使用 |
| **next** | Webフロントエンド実装 | generated/frontend/の型定義とAPIクライアントを使用 |
| **expo** | モバイルアプリ実装 | generated/mobile/のAPIサービスを使用 |
| **logic** | ビジネスロジック設計 | API仕様に準拠したロジック実装 |
| **qa** | APIテスト、整合性検証 | API仕様書に基づくテストケース作成 |
| **security** | API認証・認可 | OpenAPI Security Schemesに準拠 |
| **docs** | API仕様書のドキュメント化 | OpenAPI仕様から自動生成 |

EOF

# 動的にAgent一覧を追加
if [ ${#AGENTS[@]} -gt 0 ]; then
    echo "" >> CLAUDE.md
    echo "### 検出されたSubAgent設定ファイル:" >> CLAUDE.md
    echo "| Agent | 設定パス |" >> CLAUDE.md
    echo "|-------|----------|" >> CLAUDE.md
    
    for agent in "${AGENTS[@]}"; do
        echo "| $agent | \`.claude/agents/$agent.md\` |" >> CLAUDE.md
    done
fi

cat >> CLAUDE.md << 'EOF'

---

## 🔄 API開発ワークフロー（厳格遵守）

### 1️⃣ 新規API追加時のフロー

```bash
# STEP 1: API仕様書を編集
vi api-spec-system/specs/core/api-spec.yaml
# または
vi api-spec-system/specs/services/{service-name}.yaml

# STEP 2: 仕様を検証
cd api-spec-system
make validate

# STEP 3: コードを自動生成
make generate

# STEP 4: 生成されたコードを確認
ls -la generated/backend/   # Go-Zero APIコード
ls -la generated/frontend/  # Next.js 型定義とクライアント
ls -la generated/mobile/    # Expo APIサービス

# STEP 5: ビジネスロジックのみ実装
# generated/のコードは編集せず、ロジック層で実装

# STEP 6: 準拠性チェック
make compliance
```

### 2️⃣ API変更時のフロー

```markdown
1. **変更前チェック**
   □ 現在のAPI仕様書を確認
   □ 影響を受けるクライアントを特定
   □ 後方互換性を検討

2. **仕様変更**
   □ specs/*.yaml を更新
   □ バージョニング戦略を適用
   □ Breaking Changeの場合は明記

3. **再生成と検証**
   □ make clean && make generate
   □ make validate
   □ make test

4. **全プラットフォーム更新**
   □ backend: 生成されたハンドラーを確認
   □ frontend: 型定義とAPIクライアントを確認
   □ mobile: APIサービスを確認

5. **テスト実施**
   □ 単体テスト更新
   □ 統合テスト実施
   □ E2Eテスト確認
```

---

## 📊 API整合性チェックリスト

### 各SubAgentが実装前に確認すること:

```markdown
## API Agent
□ OpenAPI 3.1仕様に準拠しているか
□ すべてのエンドポイントにoperationIdがあるか
□ レスポンススキーマが定義されているか
□ エラーレスポンスが標準化されているか
□ x-go-zero拡張が適切に設定されているか
□ API仕様書のdescriptionは日本語で記述されているか

## Next.js Agent
□ generated/frontend/types/ の型定義を使用しているか
□ generated/frontend/api/ のクライアントを使用しているか
□ 手動でfetch()を使っていないか
□ 型安全性が保証されているか

## Expo Agent  
□ generated/mobile/services/ のAPIサービスを使用しているか
□ オフライン対応が仕様通りか
□ 認証トークンの管理が適切か
□ エラーハンドリングが統一されているか

## QA Agent
□ API仕様書に基づくテストケースか
□ Contract Testingを実施しているか
□ レスポンスの型検証をしているか
□ エラーケースを網羅しているか
```

---

## 🚨 エラー防止のためのContext7活用

EOF

if [ "$HAS_CONTEXT7" = "true" ]; then
    cat >> CLAUDE.md << 'EOF'
### Context7 MCPサーバーが検出されました ✅

**必須実施事項:**
1. Next.js 15の最新仕様確認: `mcp__context7__get-library-docs`
2. Expo SDK最新版の確認: `mcp__context7__resolve-library-id`
3. Go-Zeroの最新パターン確認
4. 実装前に必ず最新ドキュメントを参照

```typescript
// 例: Next.js 15の最新機能を確認
await mcp__context7__get-library-docs({
  context7CompatibleLibraryID: '/vercel/next.js',
  topic: 'app-router'
});
```
EOF
else
    cat >> CLAUDE.md << 'EOF'
### ⚠️ Context7 MCPサーバーが未検出

**推奨:** `./scripts/generate_agents_from_requirements.sh` を実行してContext7を自動セットアップしてください。
これにより、ライブラリの最新仕様を自動参照し、古いAPIの使用を防げます。
EOF
fi

cat >> CLAUDE.md << 'EOF'

---

## 🎯 成功指標とメトリクス

### API整合性指標:
- **仕様準拠率**: 100%（generated/のみ使用）
- **型安全カバレッジ**: 100%（すべてのAPIコール）
- **自動生成率**: 95%以上（手動コード最小化）
- **API仕様ドキュメント化率**: 100%
- **日本語化率**: 100%（ドキュメント、コメント、エラーメッセージ）

### 品質指標:
- **テストカバレッジ**: 80%以上
- **E2Eテスト成功率**: 95%以上
- **APIレスポンスタイム**: 200ms以下
- **エラー率**: 1%未満
- **日本語コミュニケーション遵守率**: 100%

---

## 💡 トラブルシューティング

### よくある問題と解決方法:

| 問題 | 原因 | 解決方法 |
|------|------|----------|
| 型エラー | 手動で型定義を作成 | generated/の型定義を使用 |
| API不整合 | 仕様書を更新せずに実装 | specs/*.yamlから再生成 |
| CORS エラー | API仕様にCORS設定なし | OpenAPIにCORS設定追加 |
| 認証エラー | Security Schemes未定義 | OpenAPIにSecurity追加 |
| レスポンス不一致 | 手動実装との齟齬 | make complianceで検証 |

---

## 📚 必須参照ドキュメント

### API仕様システム:
- `api-spec-system/README.md` - API仕様システムガイド
- `api-spec-system/specs/` - API仕様書（真実の源）
- `api-spec-system/generated/` - 自動生成コード（編集禁止）

### 要件定義:
EOF

if [ "$HAS_REQUIREMENTS" = "true" ]; then
    echo "- \`REQUIREMENTS.md\` - プロジェクト要件定義書 ✅" >> CLAUDE.md
else
    echo "- \`REQUIREMENTS.md\` - プロジェクト要件定義書 ⚠️ 未作成" >> CLAUDE.md
fi

if [ ${#AGENTS[@]} -gt 0 ]; then
    echo "- \`docs/agents/*/REQUIREMENTS.md\` - 各Agent要件定義" >> CLAUDE.md
fi

cat >> CLAUDE.md << EOF

---

## 🔄 更新履歴

- ${TIMESTAMP}: API整合性強化版として自動生成
- プロジェクト: ${PROJECT_NAME}
- 検出されたAgent数: ${#AGENTS[@]}
- API仕様システム: ${HAS_API_SPEC}
- Context7統合: ${HAS_CONTEXT7}
- 要件定義書: ${HAS_REQUIREMENTS}

---

## ⚠️ 最終確認事項

**すべてのSubAgentは以下を厳守してください:**

1. **日本語コミュニケーション** - すべての回答・説明・ドキュメントは日本語で記述
2. **API仕様書がすべての始まり** - specs/*.yamlを更新してから実装
3. **自動生成コードの使用** - generated/ディレクトリのコードを活用
4. **手動実装の最小化** - ビジネスロジック層のみ手動実装
5. **型安全性の保証** - TypeScriptとGoの型を自動同期
6. **継続的検証** - make validate/complianceを定期実行
7. **コード内コメントの日本語化** - 変数名は英語、コメントは日本語

**このファイルはAPI整合性保証システムの中核設定です。**
**すべての開発作業はこの設定に従って実行してください。**

---

### 🚀 開発開始コマンド

\`\`\`bash
# API仕様システムの初期化と検証
cd api-spec-system
make setup      # 初回のみ
make validate   # 仕様検証
make generate   # コード生成
make compliance # 準拠性チェック
\`\`\`

**API仕様の整合性こそが、このプロジェクトの成功の鍵です。**
EOF

echo "✅ CLAUDE.md を生成しました（API整合性強化版）！"
echo ""
echo "📊 生成内容:"
echo "  - プロジェクト名: ${PROJECT_NAME}"
echo "  - 検出されたAgent: ${AGENTS[@]:-なし}"
echo "  - API仕様システム: ${HAS_API_SPEC}"
echo "  - Context7統合: ${HAS_CONTEXT7}"
echo "  - 要件定義書: ${HAS_REQUIREMENTS}"
echo ""
echo "🎯 このCLAUDE.mdの特徴:"
echo "  • API仕様駆動開発の徹底"
echo "  • バックエンド/フロントエンド/モバイル間の整合性保証"
echo "  • 自動生成コードによる型安全性"
echo "  • 手動実装の最小化"
echo "  • Context7による最新仕様の自動参照"
echo ""
echo "次のステップ:"
echo "  1. CLAUDE.md を確認"
echo "  2. API仕様書（api-spec-system/specs/）を定義"
echo "  3. make generate でコード生成"
echo "  4. 各SubAgentが生成コードを使用して実装"