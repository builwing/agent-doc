# SpecAgentX クイックスタートガイド

## 🚀 クイックスタート（3ステップ）

### 1. 初期化
```bash
.specagentx/scripts/init.sh
```

### 2. 要件定義
`.specagentx/REQUIREMENTS.md`を編集して、プロジェクトの要件を記載

### 3. エージェント起動
ClaudeCodeで以下を実行：
```
PMエージェントとして、要件定義書を基にプロジェクトを開始してください
```

## 📁 プロジェクト構成

```
あなたのプロジェクト/
├── .specagentx/           # システムファイル（隠し）
│   ├── REQUIREMENTS.md    # 要件定義書
│   ├── SPECIFICATIONS.md  # 技術仕様書
│   └── ...
├── .claude/               # ClaudeCode設定
└── [あなたのコード]        # 自由に配置可能
```

## 🎯 主要コマンド

### 進捗確認
```bash
cat .specagentx/pm/PROGRESS_OVERVIEW.md
```

### タスク確認
```bash
cat .specagentx/pm/ASSIGNMENTS.md
```

### トークン使用量確認
```bash
cat .specagentx/TOKENS_USAGE.md
```

## 🔧 カスタマイズ

### 言語選択
`.env`ファイルで設定：
```env
PRIMARY_LANGUAGE=go        # go, javascript, python, java, rust
SECONDARY_LANGUAGES=javascript,python
```

### 技術スタック選択
`.specagentx/SPECIFICATIONS.md`の「技術スタック」セクションで定義

## 📚 ドキュメント

- [要件定義書](.specagentx/REQUIREMENTS.md) - プロジェクト要件
- [技術仕様書](.specagentx/SPECIFICATIONS.md) - 技術詳細
- [構造説明](.specagentx/STRUCTURE.md) - ディレクトリ構造
- [移行計画](.specagentx/MIGRATION_PLAN.md) - Agenixからの移行

## ❓ トラブルシューティング

### Q: エージェントが動作しない
A: `.specagentx/REQUIREMENTS.md`と`.specagentx/SPECIFICATIONS.md`が存在することを確認

### Q: 既存のAgenixプロジェクトを移行したい
A: `init.sh`実行時に自動検出され、移行オプションが表示されます

### Q: トークン使用量を削減したい
A: `CONTEXT_CACHE.md`が自動的に頻繁に使用される情報をキャッシュします

## 🎉 準備完了！

これでSpecAgentXを使用する準備が整いました。
ClaudeCodeと連携して、効率的なプロジェクト開発をお楽しみください！

---
*SpecAgentX v2.0.0 - Specification-driven Agent eXecution System*