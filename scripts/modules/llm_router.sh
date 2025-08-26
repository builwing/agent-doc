#!/usr/bin/env bash
# LLM統合による高度なタスク振り分けシステム
set -euo pipefail

echo "🤖 LLM統合ルーターをセットアップ中..."

# 1. Node.js プロジェクトの初期化（pm/router/）
mkdir -p .claude/pm/router

cat > .claude/pm/router/package.json << 'PACKAGE_EOF'
{
  "name": "subagent-router",
  "version": "1.0.0",
  "description": "Intelligent task router for SubAgent system",
  "main": "router.js",
  "scripts": {
    "start": "node router.js",
    "dev": "node --watch router.js",
    "test": "node test-router.js"
  },
  "dependencies": {
    "@anthropic-ai/sdk": "^0.20.0",
    "openai": "^4.28.0",
    "dotenv": "^16.4.0",
    "chalk": "^5.3.0",
    "ora": "^7.0.1",
    "commander": "^11.1.0",
    "winston": "^3.11.0",
    "zod": "^3.22.0"
  },
  "type": "module"
}
PACKAGE_EOF

# 2. メインルーター実装（TypeScript風のJavaScript）
cat > .claude/pm/router/router.js << 'ROUTER_EOF'
#!/usr/bin/env node
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import chalk from 'chalk';
import ora from 'ora';
import { z } from 'zod';
import winston from 'winston';

// 環境設定
dotenv.config();
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ロガー設定
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: '../logs/router.log' }),
        new winston.transports.Console({
            format: winston.format.simple()
        })
    ]
});

// スキーマ定義
const RouteResultSchema = z.object({
    route: z.string(),
    reason: z.string(),
    confidence: z.number().min(0).max(1),
    normalized_task: z.string(),
    required_docs: z.array(z.string()),
    acceptance_criteria: z.array(z.string()),
    attachments: z.array(z.string()).optional(),
    priority: z.number().min(1).max(4),
    estimated_effort: z.enum(['S', 'M', 'L', 'XL']),
    context_analysis: z.object({
        technical_complexity: z.enum(['low', 'medium', 'high']),
        risk_level: z.enum(['low', 'medium', 'high']),
        dependencies: z.array(z.string()).optional()
    }).optional()
});

// ルーター設定
class SubAgentRouter {
    constructor() {
        this.registry = null;
        this.pmPrompt = null;
        this.llmClient = null;
    }

    async initialize() {
        const spinner = ora('初期化中...').start();
        
        try {
            // レジストリ読み込み
            this.registry = JSON.parse(
                await fs.readFile(path.join(__dirname, '../registry.json'), 'utf-8')
            );
            
            // PMプロンプト読み込み
            this.pmPrompt = await fs.readFile(
                path.join(__dirname, '../prompts/pm_system.txt'), 
                'utf-8'
            );
            
            // LLMクライアント初期化（環境変数で選択）
            await this.initializeLLM();
            
            spinner.succeed('初期化完了');
        } catch (error) {
            spinner.fail('初期化エラー');
            throw error;
        }
    }

    async initializeLLM() {
        const provider = process.env.LLM_PROVIDER || 'mock';
        
        switch (provider) {
            case 'anthropic':
                const { Anthropic } = await import('@anthropic-ai/sdk');
                this.llmClient = new Anthropic({
                    apiKey: process.env.ANTHROPIC_API_KEY
                });
                this.llmProvider = 'anthropic';
                break;
            
            case 'openai':
                const { OpenAI } = await import('openai');
                this.llmClient = new OpenAI({
                    apiKey: process.env.OPENAI_API_KEY
                });
                this.llmProvider = 'openai';
                break;
            
            case 'mock':
            default:
                this.llmProvider = 'mock';
                logger.info('Using mock LLM provider');
                break;
        }
    }

    // ルールベース判定
    analyzeWithRules(message) {
        const analysis = {
            matchedAgents: [],
            keywords: [],
            confidence: 0
        };

        const lowerMessage = message.toLowerCase();

        for (const agent of this.registry.agents) {
            for (const keyword of agent.match) {
                if (lowerMessage.includes(keyword.toLowerCase())) {
                    if (!analysis.matchedAgents.includes(agent.id)) {
                        analysis.matchedAgents.push(agent.id);
                    }
                    analysis.keywords.push(keyword);
                }
            }
        }

        // 信頼度計算
        if (analysis.matchedAgents.length === 1) {
            analysis.confidence = 0.8;
        } else if (analysis.matchedAgents.length > 1) {
            analysis.confidence = 0.6;
        } else {
            analysis.confidence = 0.3;
        }

        return analysis;
    }

    // LLM分析
    async analyzeWithLLM(message, ruleAnalysis) {
        if (this.llmProvider === 'mock') {
            return this.mockLLMAnalysis(message, ruleAnalysis);
        }

        const prompt = `
${this.pmPrompt}

## ルールベース分析結果
- マッチしたAgent: ${ruleAnalysis.matchedAgents.join(', ')}
- 検出キーワード: ${ruleAnalysis.keywords.join(', ')}
- 初期信頼度: ${ruleAnalysis.confidence}

## ユーザータスク
${message}

上記のタスクを分析し、指定されたJSON形式で出力してください。
`;

        try {
            let response;
            
            if (this.llmProvider === 'anthropic') {
                const completion = await this.llmClient.messages.create({
                    model: 'claude-3-sonnet-20240229',
                    max_tokens: 1000,
                    messages: [{ role: 'user', content: prompt }]
                });
                response = completion.content[0].text;
            } else if (this.llmProvider === 'openai') {
                const completion = await this.llmClient.chat.completions.create({
                    model: 'gpt-4-turbo-preview',
                    messages: [{ role: 'user', content: prompt }],
                    response_format: { type: 'json_object' }
                });
                response = completion.choices[0].message.content;
            }

            // JSON抽出とパース
            const jsonMatch = response.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
                const parsed = JSON.parse(jsonMatch[0]);
                return RouteResultSchema.parse(parsed);
            }
            
            throw new Error('Invalid JSON response from LLM');
            
        } catch (error) {
            logger.error('LLM analysis failed:', error);
            return this.fallbackAnalysis(message, ruleAnalysis);
        }
    }

    // モックLLM分析（開発/テスト用）
    mockLLMAnalysis(message, ruleAnalysis) {
        const route = ruleAnalysis.matchedAgents[0] || 'human_review';
        const confidence = ruleAnalysis.confidence;
        
        // タスクの複雑度を推定
        const complexity = message.length > 100 ? 'high' : 
                          message.length > 50 ? 'medium' : 'low';
        
        const effort = complexity === 'high' ? 'L' :
                      complexity === 'medium' ? 'M' : 'S';

        return {
            route,
            reason: `ルールベース分析とキーワードマッチング`,
            confidence,
            normalized_task: message.slice(0, 200),
            required_docs: [
                `docs/agents/${route}/REQUIREMENTS.md`,
                `docs/agents/${route}/CHECKLIST.md`
            ],
            acceptance_criteria: [
                '要件定義に基づく実装',
                'テストの実装と合格',
                '履歴の記録'
            ],
            attachments: [],
            priority: route === 'security' ? 1 : 2,
            estimated_effort: effort,
            context_analysis: {
                technical_complexity: complexity,
                risk_level: route === 'security' ? 'high' : 'low',
                dependencies: ruleAnalysis.matchedAgents.slice(1)
            }
        };
    }

    // フォールバック分析
    fallbackAnalysis(message, ruleAnalysis) {
        const route = ruleAnalysis.matchedAgents[0] || 'human_review';
        
        return {
            route,
            reason: 'フォールバック判定',
            confidence: Math.min(ruleAnalysis.confidence, 0.5),
            normalized_task: message,
            required_docs: [
                `docs/agents/${route}/REQUIREMENTS.md`,
                `docs/agents/${route}/CHECKLIST.md`
            ],
            acceptance_criteria: ['要件確認が必要'],
            attachments: [],
            priority: 3,
            estimated_effort: 'M'
        };
    }

    // メイン処理
    async route(message) {
        const spinner = ora('タスクを分析中...').start();
        
        try {
            // Step 1: ルールベース分析
            spinner.text = 'ルールベース分析中...';
            const ruleAnalysis = this.analyzeWithRules(message);
            logger.info('Rule analysis:', ruleAnalysis);
            
            // Step 2: LLM分析
            spinner.text = 'AI分析中...';
            const result = await this.analyzeWithLLM(message, ruleAnalysis);
            
            // Step 3: 最終調整
            if (result.confidence < this.registry.routing.confidence_threshold) {
                result.route = 'human_review';
                result.reason = `信頼度が閾値未満 (${result.confidence} < ${this.registry.routing.confidence_threshold})`;
            }
            
            // セキュリティチェック
            for (const keyword of this.registry.routing.require_human_review) {
                if (message.toLowerCase().includes(keyword)) {
                    result.route = 'human_review';
                    result.reason = `セキュリティキーワード検出: ${keyword}`;
                    break;
                }
            }
            
            spinner.succeed('分析完了');
            
            // ログ記録
            await this.logResult(message, result);
            
            return result;
            
        } catch (error) {
            spinner.fail('分析エラー');
            logger.error('Routing error:', error);
            throw error;
        }
    }

    // 結果のログ記録
    async logResult(message, result) {
        const logEntry = {
            timestamp: new Date().toISOString(),
            message: message.slice(0, 100),
            result,
            provider: this.llmProvider
        };
        
        const logFile = path.join(
            __dirname, 
            '../logs',
            `${new Date().toISOString().split('T')[0]}.json`
        );
        
        try {
            await fs.mkdir(path.join(__dirname, '../logs'), { recursive: true });
            
            let logs = [];
            try {
                const existing = await fs.readFile(logFile, 'utf-8');
                logs = JSON.parse(existing);
            } catch (e) {
                // ファイルが存在しない場合は新規作成
            }
            
            logs.push(logEntry);
            await fs.writeFile(logFile, JSON.stringify(logs, null, 2));
            
        } catch (error) {
            logger.error('Failed to write log:', error);
        }
    }

    // 結果の表示
    displayResult(result) {
        console.log('\n' + chalk.cyan('━'.repeat(50)));
        console.log(chalk.bold('\n📊 ルーティング結果:\n'));
        
        const agentColor = result.route === 'human_review' ? chalk.yellow : chalk.green;
        
        console.log(`  ${chalk.gray('振り分け先:')} ${agentColor.bold(result.route)}`);
        console.log(`  ${chalk.gray('理由:')} ${result.reason}`);
        console.log(`  ${chalk.gray('信頼度:')} ${this.getConfidenceBar(result.confidence)} ${result.confidence.toFixed(2)}`);
        console.log(`  ${chalk.gray('優先度:')} ${this.getPriorityLabel(result.priority)}`);
        console.log(`  ${chalk.gray('推定工数:')} ${this.getEffortLabel(result.estimated_effort)}`);
        
        if (result.context_analysis) {
            console.log(`  ${chalk.gray('技術複雑度:')} ${result.context_analysis.technical_complexity}`);
            console.log(`  ${chalk.gray('リスクレベル:')} ${this.getRiskLabel(result.context_analysis.risk_level)}`);
        }
        
        console.log('\n' + chalk.cyan('━'.repeat(50)));
        
        if (result.route !== 'human_review') {
            console.log(chalk.bold('\n🚀 次のステップ:\n'));
            console.log(`  ${chalk.blue('1.')} 要件確認:`);
            console.log(`     ${chalk.gray('./scripts/agent_start.sh')} ${result.route} "${result.normalized_task}"`);
            console.log(`\n  ${chalk.blue('2.')} 実装後の履歴記録:`);
            console.log(`     ${chalk.gray('./scripts/agent_log.sh')} ${result.route} "<task>" "<refs>"`);
        } else {
            console.log(chalk.yellow('\n⚠️  人間によるレビューが必要です\n'));
        }
    }

    // UI補助メソッド
    getConfidenceBar(confidence) {
        const filled = Math.round(confidence * 10);
        const empty = 10 - filled;
        return chalk.green('█'.repeat(filled)) + chalk.gray('░'.repeat(empty));
    }

    getPriorityLabel(priority) {
        const labels = {
            1: chalk.red('🔴 緊急'),
            2: chalk.yellow('🟡 高'),
            3: chalk.blue('🔵 中'),
            4: chalk.gray('⚪ 低')
        };
        return labels[priority] || priority;
    }

    getEffortLabel(effort) {
        const labels = {
            'S': '👕 小 (1-2時間)',
            'M': '👔 中 (半日)',
            'L': '🧥 大 (1-2日)',
            'XL': '🦺 特大 (3日以上)'
        };
        return labels[effort] || effort;
    }

    getRiskLabel(risk) {
        const labels = {
            'low': chalk.green('低'),
            'medium': chalk.yellow('中'),
            'high': chalk.red('高')
        };
        return labels[risk] || risk;
    }
}

// CLI実行
async function main() {
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.log(chalk.red('使用方法: node router.js "<タスク内容>"'));
        process.exit(1);
    }
    
    const message = args.join(' ');
    
    try {
        const router = new SubAgentRouter();
        await router.initialize();
        
        console.log(chalk.bold('\n🎯 タスク:'), message);
        
        const result = await router.route(message);
        router.displayResult(result);
        
        // JSON出力オプション
        if (process.env.OUTPUT_JSON === 'true') {
            console.log('\n' + JSON.stringify(result, null, 2));
        }
        
    } catch (error) {
        console.error(chalk.red('\n❌ エラー:'), error.message);
        logger.error('Fatal error:', error);
        process.exit(1);
    }
}

// 実行
if (process.argv[1] === fileURLToPath(import.meta.url)) {
    main();
}

export default SubAgentRouter;
ROUTER_EOF

# 3. 環境設定ファイル
cat > .claude/pm/router/.env.example << 'ENV_EOF'
# LLMプロバイダー設定
# 選択肢: mock, anthropic, openai
LLM_PROVIDER=mock

# APIキー（使用する場合）
# ANTHROPIC_API_KEY=your-api-key-here
# OPENAI_API_KEY=your-api-key-here

# 出力設定
OUTPUT_JSON=false

# ログレベル
LOG_LEVEL=info
ENV_EOF

# 4. テストスクリプト
cat > .claude/pm/router/test-router.js << 'TEST_EOF'
#!/usr/bin/env node
import SubAgentRouter from './router.js';
import chalk from 'chalk';

const testCases = [
    {
        name: 'API開発タスク',
        input: 'ユーザー検索APIにページング機能を追加',
        expected: 'api'
    },
    {
        name: 'Next.js タスク',
        input: 'ダッシュボード画面のSSR対応とSEO最適化',
        expected: 'next'
    },
    {
        name: 'Expo タスク',
        input: 'プッシュ通知の実装とディープリンク設定',
        expected: 'expo'
    },
    {
        name: 'セキュリティタスク',
        input: 'JWT認証の実装とRBAC設定',
        expected: 'security'
    },
    {
        name: '曖昧なタスク',
        input: 'あれをやって',
        expected: 'human_review'
    },
    {
        name: '複合タスク',
        input: 'APIとフロントエンドの連携部分を修正',
        expected: ['api', 'next', 'human_review']
    }
];

async function runTests() {
    console.log(chalk.bold('\n🧪 ルーターテスト開始\n'));
    
    const router = new SubAgentRouter();
    await router.initialize();
    
    let passed = 0;
    let failed = 0;
    
    for (const test of testCases) {
        process.stdout.write(`Testing: ${test.name}... `);
        
        try {
            const result = await router.route(test.input);
            
            const isValid = Array.isArray(test.expected) 
                ? test.expected.includes(result.route)
                : result.route === test.expected;
            
            if (isValid) {
                console.log(chalk.green('✓ PASS'));
                console.log(chalk.gray(`  → ${result.route} (confidence: ${result.confidence.toFixed(2)})`));
                passed++;
            } else {
                console.log(chalk.red('✗ FAIL'));
                console.log(chalk.gray(`  期待: ${test.expected}, 実際: ${result.route}`));
                failed++;
            }
        } catch (error) {
            console.log(chalk.red('✗ ERROR'));
            console.log(chalk.gray(`  ${error.message}`));
            failed++;
        }
    }
    
    console.log('\n' + chalk.cyan('━'.repeat(50)));
    console.log(chalk.bold('\n📊 テスト結果:'));
    console.log(`  ${chalk.green(`成功: ${passed}`)}`);
    console.log(`  ${chalk.red(`失敗: ${failed}`)}`);
    console.log(`  合計: ${testCases.length}`);
    
    process.exit(failed > 0 ? 1 : 0);
}

runTests();
TEST_EOF

# 5. 更新版 pm_dispatch.sh
cat > scripts/pm_dispatch_v2.sh << 'DISPATCH_V2_EOF'
#!/usr/bin/env bash
# 高度なLLM統合タスク振り分け
set -euo pipefail

MESSAGE="${1:-}"
[[ -z "$MESSAGE" ]] && {
    echo "使用方法: $0 \"<タスク内容>\""
    exit 1
}

# Node.jsがインストールされているか確認
if ! command -v node &> /dev/null; then
    echo "⚠️  Node.js がインストールされていません"
    echo "従来のルールベース振り分けを使用します"
    exec ./scripts/pm_dispatch.sh "$MESSAGE"
fi

# LLMルーターが初期化されているか確認
if [[ ! -f ".claude/pm/router/node_modules/.package-lock.json" ]]; then
    echo "📦 初回セットアップ: 依存関係をインストール中..."
    cd .claude/pm/router
    npm install
    cd ../..
fi

# 環境設定
if [[ ! -f ".claude/pm/router/.env" ]]; then
    cp .claude/pm/router/.env.example .claude/pm/router/.env
    echo "📝 .claude/pm/router/.env を作成しました（必要に応じて編集してください）"
fi

# LLMルーター実行
cd .claude/pm/router
node router.js "$MESSAGE"
DISPATCH_V2_EOF

chmod +x scripts/pm_dispatch_v2.sh
chmod +x .claude/pm/router/router.js
chmod +x .claude/pm/router/test-router.js

echo "✅ LLM統合ルーターのセットアップが完了しました！"
echo ""
echo "📝 作成されたファイル:"
echo "  - .claude/pm/router/router.js       : メインルーター"
echo "  - .claude/pm/router/test-router.js  : テストスクリプト"
echo "  - .claude/pm/router/.env.example    : 環境設定テンプレート"
echo "  - scripts/pm_dispatch_v2.sh : 新しい振り分けスクリプト"
echo ""
echo "🚀 使い方:"
echo "  1. cd .claude/pm/router && npm install"
echo "  2. cp .env.example .env （必要に応じて編集）"
echo "  3. npm test （テスト実行）"
echo "  4. cd ../.. && ./scripts/pm_dispatch_v2.sh \"タスク内容\""