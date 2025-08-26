#!/usr/bin/env bash
# RAG（Retrieval-Augmented Generation）システムのセットアップ
set -euo pipefail

echo "🧠 RAG/埋め込み検索システムをセットアップ中..."

# 1. ディレクトリ構造
mkdir -p rag/{embeddings,indexes,search,vectordb}

# 2. RAGエンジン実装
cat > rag/rag-engine.js << 'RAGENGINE_EOF'
#!/usr/bin/env node
/**
 * RAG Engine for SubAgent System
 * ドキュメントの埋め込み生成と意味検索
 */

import { promises as fs } from 'fs';
import path from 'path';
import crypto from 'crypto';
import { pipeline } from '@xenova/transformers';
import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import chalk from 'chalk';
import ora from 'ora';

class RAGEngine {
    constructor() {
        this.db = null;
        this.embedder = null;
        this.indexedDocs = new Map();
        this.chunkSize = 512; // トークン数
        this.overlapSize = 50; // オーバーラップ
    }

    async initialize() {
        const spinner = ora('RAGエンジンを初期化中...').start();
        
        try {
            // データベース初期化
            await this.initDatabase();
            
            // 埋め込みモデル初期化
            await this.initEmbedder();
            
            spinner.succeed('RAGエンジン初期化完了');
        } catch (error) {
            spinner.fail('初期化エラー');
            throw error;
        }
    }

    async initDatabase() {
        // SQLiteデータベース作成
        this.db = await open({
            filename: 'rag/vectordb/embeddings.db',
            driver: sqlite3.Database
        });

        // テーブル作成
        await this.db.exec(`
            CREATE TABLE IF NOT EXISTS documents (
                id TEXT PRIMARY KEY,
                path TEXT NOT NULL,
                content TEXT NOT NULL,
                chunk_index INTEGER NOT NULL,
                embedding BLOB,
                metadata TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );

            CREATE INDEX IF NOT EXISTS idx_path ON documents(path);
            CREATE INDEX IF NOT EXISTS idx_created ON documents(created_at);

            CREATE TABLE IF NOT EXISTS search_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                query TEXT NOT NULL,
                results TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        `);
    }

    async initEmbedder() {
        // Transformers.js を使用してローカルで埋め込み生成
        // 小さいモデルを使用（sentence-transformers/all-MiniLM-L6-v2）
        this.embedder = await pipeline(
            'feature-extraction',
            'Xenova/all-MiniLM-L6-v2'
        );
    }

    // ドキュメントのチャンク分割
    chunkDocument(content, metadata = {}) {
        const chunks = [];
        const lines = content.split('\n');
        let currentChunk = [];
        let currentLength = 0;

        for (const line of lines) {
            const lineLength = line.split(/\s+/).length;
            
            if (currentLength + lineLength > this.chunkSize && currentChunk.length > 0) {
                // チャンクを保存
                chunks.push({
                    content: currentChunk.join('\n'),
                    metadata: {
                        ...metadata,
                        chunkIndex: chunks.length,
                        lines: currentChunk.length
                    }
                });

                // オーバーラップを考慮して次のチャンク開始
                const overlapLines = Math.floor(currentChunk.length * 0.1);
                currentChunk = currentChunk.slice(-overlapLines);
                currentLength = currentChunk.join('\n').split(/\s+/).length;
            }

            currentChunk.push(line);
            currentLength += lineLength;
        }

        // 最後のチャンク
        if (currentChunk.length > 0) {
            chunks.push({
                content: currentChunk.join('\n'),
                metadata: {
                    ...metadata,
                    chunkIndex: chunks.length,
                    lines: currentChunk.length
                }
            });
        }

        return chunks;
    }

    // 埋め込みベクトル生成
    async generateEmbedding(text) {
        const output = await this.embedder(text, {
            pooling: 'mean',
            normalize: true
        });
        
        // Float32Arrayに変換
        return Array.from(output.data);
    }

    // ドキュメントのインデックス作成
    async indexDocument(filePath, forceReindex = false) {
        console.log(`📄 インデックス作成: ${filePath}`);

        // 既存のインデックスをチェック
        if (!forceReindex) {
            const existing = await this.db.get(
                'SELECT COUNT(*) as count FROM documents WHERE path = ?',
                filePath
            );
            
            if (existing.count > 0) {
                console.log(`  ⏭️  スキップ（既にインデックス済み）`);
                return;
            }
        }

        // ファイル読み込み
        const content = await fs.readFile(filePath, 'utf-8');
        const stats = await fs.stat(filePath);

        // メタデータ抽出
        const metadata = {
            path: filePath,
            size: stats.size,
            modified: stats.mtime,
            type: path.extname(filePath),
            agent: this.extractAgentFromPath(filePath)
        };

        // チャンク分割
        const chunks = this.chunkDocument(content, metadata);

        // 各チャンクの埋め込みを生成して保存
        for (const chunk of chunks) {
            const embedding = await this.generateEmbedding(chunk.content);
            
            const id = crypto
                .createHash('sha256')
                .update(`${filePath}:${chunk.metadata.chunkIndex}`)
                .digest('hex');

            await this.db.run(
                `INSERT OR REPLACE INTO documents 
                (id, path, content, chunk_index, embedding, metadata, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)`,
                id,
                filePath,
                chunk.content,
                chunk.metadata.chunkIndex,
                Buffer.from(new Float32Array(embedding).buffer),
                JSON.stringify(chunk.metadata)
            );
        }

        console.log(`  ✅ ${chunks.length} チャンクをインデックス化`);
    }

    // Agent名をパスから抽出
    extractAgentFromPath(filePath) {
        const match = filePath.match(/doc\/agents\/([^\/]+)/);
        return match ? match[1] : 'unknown';
    }

    // すべてのドキュメントをインデックス
    async indexAllDocuments() {
        const spinner = ora('ドキュメントをインデックス中...').start();

        try {
            // docs/agents/ 配下のすべてのMarkdownファイル
            const { glob } = await import('glob');
            const files = await glob('docs/agents/**/*.md');

            spinner.text = `${files.length} ファイルを処理中...`;

            for (const file of files) {
                await this.indexDocument(file);
            }

            // ソースコードもインデックス（オプション）
            const sourceFiles = await glob('{api,app,mobile}/**/*.{go,ts,tsx,js,jsx}', {
                ignore: ['**/node_modules/**', '**/vendor/**', '**/.next/**']
            });

            for (const file of sourceFiles.slice(0, 100)) { // 最初の100ファイルのみ
                await this.indexDocument(file);
            }

            spinner.succeed(`インデックス完了: ${files.length + sourceFiles.length} ファイル`);
        } catch (error) {
            spinner.fail('インデックス作成エラー');
            throw error;
        }
    }

    // コサイン類似度計算
    cosineSimilarity(vec1, vec2) {
        let dotProduct = 0;
        let norm1 = 0;
        let norm2 = 0;

        for (let i = 0; i < vec1.length; i++) {
            dotProduct += vec1[i] * vec2[i];
            norm1 += vec1[i] * vec1[i];
            norm2 += vec2[i] * vec2[i];
        }

        return dotProduct / (Math.sqrt(norm1) * Math.sqrt(norm2));
    }

    // 意味検索
    async search(query, options = {}) {
        const {
            limit = 10,
            threshold = 0.5,
            agent = null,
            type = null
        } = options;

        console.log(`\n🔍 検索: "${query}"`);

        // クエリの埋め込みを生成
        const queryEmbedding = await this.generateEmbedding(query);

        // データベースから全ドキュメントを取得
        let sql = 'SELECT * FROM documents WHERE 1=1';
        const params = [];

        if (agent) {
            sql += ' AND path LIKE ?';
            params.push(`%/agents/${agent}/%`);
        }

        if (type) {
            sql += ' AND path LIKE ?';
            params.push(`%${type}.md`);
        }

        const documents = await this.db.all(sql, ...params);

        // 類似度計算とソート
        const results = documents.map(doc => {
            const docEmbedding = Array.from(new Float32Array(doc.embedding.buffer));
            const similarity = this.cosineSimilarity(queryEmbedding, docEmbedding);

            return {
                ...doc,
                similarity,
                metadata: JSON.parse(doc.metadata)
            };
        }).filter(doc => doc.similarity >= threshold)
          .sort((a, b) => b.similarity - a.similarity)
          .slice(0, limit);

        // 検索履歴を保存
        await this.db.run(
            'INSERT INTO search_history (query, results) VALUES (?, ?)',
            query,
            JSON.stringify(results.map(r => ({
                path: r.path,
                similarity: r.similarity,
                chunkIndex: r.chunk_index
            })))
        );

        return results;
    }

    // コンテキスト拡張検索（RAG用）
    async ragSearch(query, options = {}) {
        const results = await this.search(query, options);

        if (results.length === 0) {
            return {
                query,
                context: '',
                sources: []
            };
        }

        // 関連するチャンクを結合してコンテキストを作成
        const contextParts = [];
        const sources = new Set();

        for (const result of results) {
            contextParts.push(`[${result.path}:${result.chunk_index}]\n${result.content}`);
            sources.add(result.path);
        }

        return {
            query,
            context: contextParts.join('\n\n---\n\n'),
            sources: Array.from(sources),
            topSimilarity: results[0].similarity
        };
    }

    // インテリジェントなAgent選択
    async suggestAgent(taskDescription) {
        // 各Agentの要件定義から最も関連性の高いものを検索
        const agents = ['api', 'logic', 'next', 'expo', 'infra', 'qa', 'uiux', 'security', 'docs'];
        const agentScores = {};

        for (const agent of agents) {
            const results = await this.search(taskDescription, {
                agent,
                type: 'REQUIREMENTS',
                limit: 3
            });

            if (results.length > 0) {
                agentScores[agent] = results[0].similarity;
            } else {
                agentScores[agent] = 0;
            }
        }

        // スコアでソート
        const sortedAgents = Object.entries(agentScores)
            .sort(([, a], [, b]) => b - a)
            .map(([agent, score]) => ({ agent, score }));

        return sortedAgents;
    }

    // 類似タスク検索
    async findSimilarTasks(taskDescription, limit = 5) {
        // HISTORYファイルから類似タスクを検索
        const results = await this.search(taskDescription, {
            type: 'HISTORY',
            limit: limit * 2 // 多めに取得してフィルタリング
        });

        // タスクを抽出
        const tasks = [];
        for (const result of results) {
            const taskMatches = result.content.match(/- task: "([^"]+)"/g) || [];
            for (const match of taskMatches) {
                const task = match.replace('- task: "', '').replace('"', '');
                tasks.push({
                    task,
                    agent: result.metadata.agent,
                    similarity: result.similarity,
                    path: result.path
                });
            }
        }

        // 重複を除去して上位を返す
        const uniqueTasks = [];
        const seen = new Set();

        for (const task of tasks) {
            if (!seen.has(task.task)) {
                seen.add(task.task);
                uniqueTasks.push(task);
                if (uniqueTasks.length >= limit) break;
            }
        }

        return uniqueTasks;
    }

    // 統計情報
    async getStats() {
        const stats = await this.db.get(`
            SELECT 
                COUNT(DISTINCT path) as total_files,
                COUNT(*) as total_chunks,
                AVG(LENGTH(content)) as avg_chunk_size,
                MAX(updated_at) as last_indexed
            FROM documents
        `);

        const agentStats = await this.db.all(`
            SELECT 
                json_extract(metadata, '$.agent') as agent,
                COUNT(*) as chunks,
                COUNT(DISTINCT path) as files
            FROM documents
            GROUP BY json_extract(metadata, '$.agent')
        `);

        return {
            ...stats,
            by_agent: agentStats
        };
    }
}

// CLI インターフェース
class RAGCLI {
    constructor() {
        this.engine = new RAGEngine();
    }

    async run() {
        const command = process.argv[2];
        
        await this.engine.initialize();

        switch (command) {
            case 'index':
                await this.index();
                break;
            case 'search':
                await this.search();
                break;
            case 'suggest':
                await this.suggest();
                break;
            case 'similar':
                await this.similar();
                break;
            case 'stats':
                await this.stats();
                break;
            default:
                this.usage();
        }

        await this.engine.db.close();
    }

    async index() {
        const file = process.argv[3];
        
        if (file) {
            await this.engine.indexDocument(file, true);
        } else {
            await this.engine.indexAllDocuments();
        }
    }

    async search() {
        const query = process.argv.slice(3).join(' ');
        
        if (!query) {
            console.error('検索クエリを指定してください');
            return;
        }

        const results = await this.engine.ragSearch(query);

        console.log('\n' + chalk.cyan('━'.repeat(50)));
        console.log(chalk.bold('\n📚 検索結果:\n'));
        
        if (results.sources.length === 0) {
            console.log(chalk.yellow('関連するドキュメントが見つかりませんでした'));
        } else {
            console.log(chalk.green(`✅ ${results.sources.length} 件のソース:`));
            results.sources.forEach(source => {
                console.log(`  - ${source}`);
            });
            
            console.log(chalk.bold('\n📝 コンテキスト（最初の500文字）:\n'));
            console.log(results.context.substring(0, 500) + '...');
        }
        
        console.log('\n' + chalk.cyan('━'.repeat(50)));
    }

    async suggest() {
        const task = process.argv.slice(3).join(' ');
        
        if (!task) {
            console.error('タスク説明を指定してください');
            return;
        }

        const suggestions = await this.engine.suggestAgent(task);

        console.log('\n' + chalk.cyan('━'.repeat(50)));
        console.log(chalk.bold('\n🎯 推奨Agent:\n'));
        
        suggestions.slice(0, 5).forEach(({ agent, score }, index) => {
            const bar = '█'.repeat(Math.round(score * 20));
            const color = index === 0 ? chalk.green : 
                         index === 1 ? chalk.yellow : 
                         chalk.gray;
            
            console.log(`  ${index + 1}. ${color(agent.toUpperCase().padEnd(10))} ${bar} ${(score * 100).toFixed(1)}%`);
        });
        
        console.log('\n' + chalk.cyan('━'.repeat(50)));
    }

    async similar() {
        const task = process.argv.slice(3).join(' ');
        
        if (!task) {
            console.error('タスク説明を指定してください');
            return;
        }

        const similar = await this.engine.findSimilarTasks(task);

        console.log('\n' + chalk.cyan('━'.repeat(50)));
        console.log(chalk.bold('\n🔄 類似タスク:\n'));
        
        if (similar.length === 0) {
            console.log(chalk.yellow('類似タスクが見つかりませんでした'));
        } else {
            similar.forEach(({ task, agent, similarity }, index) => {
                console.log(`  ${index + 1}. [${chalk.blue(agent)}] ${task}`);
                console.log(`     類似度: ${(similarity * 100).toFixed(1)}%`);
            });
        }
        
        console.log('\n' + chalk.cyan('━'.repeat(50)));
    }

    async stats() {
        const stats = await this.engine.getStats();

        console.log('\n' + chalk.cyan('━'.repeat(50)));
        console.log(chalk.bold('\n📊 インデックス統計:\n'));
        
        console.log(`  総ファイル数: ${stats.total_files}`);
        console.log(`  総チャンク数: ${stats.total_chunks}`);
        console.log(`  平均チャンクサイズ: ${Math.round(stats.avg_chunk_size)} 文字`);
        console.log(`  最終更新: ${new Date(stats.last_indexed).toLocaleString()}`);
        
        console.log(chalk.bold('\n  Agent別:'));
        stats.by_agent.forEach(({ agent, chunks, files }) => {
            console.log(`    ${(agent || 'other').padEnd(10)} : ${files} files, ${chunks} chunks`);
        });
        
        console.log('\n' + chalk.cyan('━'.repeat(50)));
    }

    usage() {
        console.log(`
使用方法:
  node rag-engine.js index [file]     - ドキュメントをインデックス
  node rag-engine.js search <query>   - 意味検索
  node rag-engine.js suggest <task>   - Agent推奨
  node rag-engine.js similar <task>   - 類似タスク検索
  node rag-engine.js stats            - 統計情報
        `);
    }
}

// 実行
if (process.argv[1] === new URL(import.meta.url).pathname) {
    const cli = new RAGCLI();
    cli.run().catch(console.error);
}

export default RAGEngine;
RAGENGINE_EOF

# 3. RAG統合PM
cat > rag/rag-pm.js << 'RAGPM_EOF'
#!/usr/bin/env node
/**
 * RAG-Enhanced Project Manager
 * 埋め込み検索を使用した高度なタスク振り分け
 */

import RAGEngine from './rag-engine.js';
import { promises as fs } from 'fs';
import chalk from 'chalk';

class RAGProjectManager {
    constructor() {
        this.rag = new RAGEngine();
    }

    async initialize() {
        await this.rag.initialize();
    }

    async routeTask(taskDescription) {
        console.log(chalk.bold('\n🧠 RAG-Enhanced Routing\n'));
        
        // 1. 類似タスクを検索
        const similarTasks = await this.rag.findSimilarTasks(taskDescription, 3);
        
        if (similarTasks.length > 0) {
            console.log(chalk.green('類似タスクが見つかりました:'));
            similarTasks.forEach(({ task, agent }) => {
                console.log(`  - [${agent}] ${task}`);
            });
            console.log('');
        }

        // 2. Agent推奨
        const agentSuggestions = await this.rag.suggestAgent(taskDescription);
        const topAgent = agentSuggestions[0];

        // 3. 関連ドキュメント取得
        const context = await this.rag.ragSearch(taskDescription, {
            agent: topAgent.agent,
            limit: 5
        });

        // 4. ルーティング結果生成
        const result = {
            route: topAgent.agent,
            confidence: topAgent.score,
            reason: `RAG分析による最適Agent選択（類似度: ${(topAgent.score * 100).toFixed(1)}%）`,
            normalized_task: taskDescription,
            required_docs: context.sources,
            similar_tasks: similarTasks,
            context_preview: context.context.substring(0, 500),
            acceptance_criteria: await this.extractAcceptanceCriteria(topAgent.agent),
            estimated_effort: this.estimateEffort(similarTasks)
        };

        return result;
    }

    async extractAcceptanceCriteria(agent) {
        // 要件定義から受け入れ基準を抽出
        const reqPath = `docs/agents/${agent}/REQUIREMENTS.md`;
        try {
            const content = await fs.readFile(reqPath, 'utf-8');
            const acMatch = content.match(/# 受け入れ基準[\s\S]*?(?=\n#|\n\n#|$)/);
            
            if (acMatch) {
                const criteria = acMatch[0]
                    .split('\n')
                    .filter(line => line.match(/^\d+\./))
                    .map(line => line.replace(/^\d+\.\s*/, ''));
                
                return criteria.slice(0, 3);
            }
        } catch (e) {
            // エラーは無視
        }
        
        return ['要件定義を確認してください'];
    }

    estimateEffort(similarTasks) {
        // 類似タスクから工数を推定
        if (similarTasks.length === 0) return 'M';
        
        // 簡易的な推定ロジック
        const avgSimilarity = similarTasks.reduce((sum, t) => sum + t.similarity, 0) / similarTasks.length;
        
        if (avgSimilarity > 0.8) return 'S';  // 非常に類似
        if (avgSimilarity > 0.6) return 'M';  // 中程度の類似
        return 'L';  // 新規性が高い
    }

    displayResult(result) {
        console.log('\n' + chalk.cyan('━'.repeat(50)));
        console.log(chalk.bold('\n📊 RAG ルーティング結果:\n'));
        
        const color = result.confidence > 0.7 ? chalk.green :
                     result.confidence > 0.5 ? chalk.yellow :
                     chalk.red;
        
        console.log(`  振り分け先: ${color.bold(result.route.toUpperCase())}`);
        console.log(`  信頼度: ${(result.confidence * 100).toFixed(1)}%`);
        console.log(`  推定工数: ${result.estimated_effort}`);
        
        if (result.similar_tasks.length > 0) {
            console.log(`\n  類似タスク参考:`);
            result.similar_tasks.forEach((t, i) => {
                console.log(`    ${i + 1}. [${t.agent}] ${t.task.substring(0, 50)}...`);
            });
        }
        
        console.log(`\n  関連ドキュメント:`);
        result.required_docs.slice(0, 3).forEach(doc => {
            console.log(`    - ${doc}`);
        });
        
        console.log('\n' + chalk.cyan('━'.repeat(50)));
    }
}

// CLI実行
async function main() {
    const task = process.argv.slice(2).join(' ');
    
    if (!task) {
        console.error('使用方法: node rag-pm.js <タスク説明>');
        process.exit(1);
    }

    const pm = new RAGProjectManager();
    await pm.initialize();
    
    const result = await pm.routeTask(task);
    pm.displayResult(result);
    
    // JSON出力（オプション）
    if (process.env.OUTPUT_JSON === 'true') {
        console.log('\n' + JSON.stringify(result, null, 2));
    }
}

if (process.argv[1] === new URL(import.meta.url).pathname) {
    main().catch(console.error);
}

export default RAGProjectManager;
RAGPM_EOF

# 4. package.json
cat > rag/package.json << 'RAG_PACKAGE_EOF'
{
  "name": "subagent-rag",
  "version": "1.0.0",
  "description": "RAG system for SubAgent",
  "type": "module",
  "scripts": {
    "index": "node rag-engine.js index",
    "search": "node rag-engine.js search",
    "pm": "node rag-pm.js",
    "test": "node test-rag.js"
  },
  "dependencies": {
    "@xenova/transformers": "^2.17.0",
    "sqlite3": "^5.1.7",
    "sqlite": "^5.1.1",
    "glob": "^10.3.10",
    "chalk": "^5.3.0",
    "ora": "^7.0.1"
  }
}
RAG_PACKAGE_EOF

echo "✅ RAG/埋め込み検索システムのセットアップが完了しました！"
echo ""
echo "🧠 機能:"
echo "  - ドキュメントの自動インデックス作成"
echo "  - 意味的類似度による検索"
echo "  - タスクからのAgent推奨"
echo "  - 類似タスク検索"
echo ""
echo "🚀 使い方:"
echo "  cd rag && npm install"
echo "  npm run index                    # インデックス作成"
echo "  npm run search -- 'クエリ'       # 検索"
echo "  npm run pm -- 'タスク説明'       # RAG振り分け"