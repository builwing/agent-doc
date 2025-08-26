#!/usr/bin/env bash
# Agent間自動協調システムのセットアップ
set -euo pipefail

echo "🤝 Agent間自動協調システムをセットアップ中..."

# 1. ディレクトリ構造
mkdir -p coordination/{orchestrator,workflows,templates,logs}

# 2. オーケストレーター実装
cat > coordination/orchestrator/coordinator.js << 'COORDINATOR_EOF'
#!/usr/bin/env node
/**
 * Agent Coordination System
 * 複数Agentの協調作業を管理
 */

import { EventEmitter } from 'events';
import { promises as fs } from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import chalk from 'chalk';
import ora from 'ora';

// Agent間メッセージング
class AgentMessageBus extends EventEmitter {
    constructor() {
        super();
        this.messages = [];
        this.subscriptions = new Map();
    }

    publish(from, to, message) {
        const msg = {
            id: uuidv4(),
            from,
            to,
            message,
            timestamp: new Date().toISOString()
        };
        
        this.messages.push(msg);
        this.emit(`message:${to}`, msg);
        this.emit('message', msg);
        
        console.log(chalk.blue(`📨 ${from} → ${to}: ${message.type}`));
        
        return msg.id;
    }

    subscribe(agent, callback) {
        this.on(`message:${agent}`, callback);
        this.subscriptions.set(agent, callback);
    }

    broadcast(from, message) {
        const agents = Array.from(this.subscriptions.keys());
        agents.forEach(agent => {
            if (agent !== from) {
                this.publish(from, agent, message);
            }
        });
    }

    getHistory(agent = null) {
        if (agent) {
            return this.messages.filter(m => 
                m.from === agent || m.to === agent
            );
        }
        return this.messages;
    }
}

// Agent基底クラス
class Agent {
    constructor(name, capabilities = []) {
        this.name = name;
        this.capabilities = capabilities;
        this.status = 'idle';
        this.currentTask = null;
        this.dependencies = [];
        this.results = {};
    }

    async canHandle(task) {
        // タスクが自分の能力に含まれるか確認
        return this.capabilities.some(cap => 
            task.type.includes(cap) || task.requirements.includes(cap)
        );
    }

    async execute(task, context = {}) {
        this.status = 'working';
        this.currentTask = task;
        
        console.log(chalk.green(`🔧 ${this.name} executing: ${task.description}`));
        
        try {
            // Agent固有の実行ロジック
            const result = await this.performTask(task, context);
            
            this.results[task.id] = result;
            this.status = 'idle';
            this.currentTask = null;
            
            return result;
        } catch (error) {
            this.status = 'error';
            throw error;
        }
    }

    async performTask(task, context) {
        // サブクラスでオーバーライド
        throw new Error('performTask must be implemented');
    }

    async requestAssistance(targetAgent, request) {
        return {
            from: this.name,
            to: targetAgent,
            request,
            timestamp: new Date().toISOString()
        };
    }
}

// 具体的なAgent実装
class APIAgent extends Agent {
    constructor() {
        super('api', ['backend', 'api', 'database', 'go-zero']);
    }

    async performTask(task, context) {
        // API設計・実装タスク
        const steps = [
            'API仕様定義',
            'エンドポイント設計',
            'データモデル定義',
            'ハンドラー実装',
            'テスト作成'
        ];

        const results = [];
        for (const step of steps) {
            await this.simulateWork(step, 500);
            results.push(`✅ ${step} 完了`);
        }

        // Next.jsとの連携が必要な場合
        if (task.requirements.includes('frontend-integration')) {
            return {
                ...results,
                needsCoordination: 'next',
                apiSpec: this.generateAPISpec(task)
            };
        }

        return { steps: results, completed: true };
    }

    generateAPISpec(task) {
        return {
            endpoints: [
                {
                    path: `/api/${task.resource}`,
                    method: 'GET',
                    response: { type: 'array' }
                },
                {
                    path: `/api/${task.resource}/:id`,
                    method: 'GET',
                    response: { type: 'object' }
                }
            ]
        };
    }

    async simulateWork(step, duration) {
        return new Promise(resolve => setTimeout(resolve, duration));
    }
}

class NextAgent extends Agent {
    constructor() {
        super('next', ['frontend', 'ui', 'nextjs', 'react']);
    }

    async performTask(task, context) {
        const steps = [
            'コンポーネント設計',
            'ページ作成',
            'データフェッチ実装',
            'UIスタイリング',
            'テスト作成'
        ];

        const results = [];
        for (const step of steps) {
            await this.simulateWork(step, 400);
            results.push(`✅ ${step} 完了`);
        }

        // APIとの連携が必要な場合
        if (context.apiSpec) {
            results.push('✅ API統合完了');
        }

        return { steps: results, completed: true };
    }

    async simulateWork(step, duration) {
        return new Promise(resolve => setTimeout(resolve, duration));
    }
}

class QAAgent extends Agent {
    constructor() {
        super('qa', ['testing', 'quality', 'e2e', 'validation']);
    }

    async performTask(task, context) {
        const tests = [
            '単体テスト実行',
            '統合テスト実行',
            'E2Eテスト実行',
            'パフォーマンステスト'
        ];

        const results = {
            passed: [],
            failed: [],
            coverage: 85
        };

        for (const test of tests) {
            await this.simulateWork(test, 300);
            // ランダムでテスト結果を生成（デモ用）
            if (Math.random() > 0.2) {
                results.passed.push(test);
            } else {
                results.failed.push(test);
            }
        }

        return results;
    }

    async simulateWork(step, duration) {
        return new Promise(resolve => setTimeout(resolve, duration));
    }
}

// ワークフロー定義
class Workflow {
    constructor(name, steps = []) {
        this.id = uuidv4();
        this.name = name;
        this.steps = steps;
        this.status = 'pending';
        this.currentStep = 0;
        this.results = {};
        this.startTime = null;
        this.endTime = null;
    }

    addStep(step) {
        this.steps.push(step);
    }

    getNextStep() {
        if (this.currentStep < this.steps.length) {
            return this.steps[this.currentStep];
        }
        return null;
    }

    completeStep(result) {
        const step = this.steps[this.currentStep];
        this.results[step.id] = result;
        this.currentStep++;
        
        if (this.currentStep >= this.steps.length) {
            this.status = 'completed';
            this.endTime = new Date();
        }
    }

    getDuration() {
        if (this.startTime && this.endTime) {
            return this.endTime - this.startTime;
        }
        return null;
    }
}

// コーディネーター
class AgentCoordinator {
    constructor() {
        this.agents = new Map();
        this.workflows = new Map();
        this.messageBus = new AgentMessageBus();
        this.executionQueue = [];
        this.isProcessing = false;
    }

    registerAgent(agent) {
        this.agents.set(agent.name, agent);
        
        // メッセージバスに登録
        this.messageBus.subscribe(agent.name, async (msg) => {
            await this.handleAgentMessage(agent, msg);
        });
        
        console.log(chalk.green(`✅ Agent registered: ${agent.name}`));
    }

    async handleAgentMessage(agent, message) {
        console.log(chalk.cyan(`📬 ${agent.name} received: ${message.message.type}`));
        
        switch (message.message.type) {
            case 'assistance_request':
                await this.handleAssistanceRequest(agent, message);
                break;
            case 'result_share':
                await this.handleResultShare(agent, message);
                break;
            case 'coordination_request':
                await this.handleCoordinationRequest(agent, message);
                break;
        }
    }

    async handleAssistanceRequest(agent, message) {
        const { task, context } = message.message;
        
        if (await agent.canHandle(task)) {
            const result = await agent.execute(task, context);
            
            // 結果を要求元に返す
            this.messageBus.publish(agent.name, message.from, {
                type: 'assistance_response',
                result,
                taskId: task.id
            });
        }
    }

    async handleResultShare(agent, message) {
        // 結果を他のAgentと共有
        const { result, taskId } = message.message;
        
        // 依存するAgentに通知
        this.messageBus.broadcast(agent.name, {
            type: 'shared_result',
            result,
            taskId,
            source: agent.name
        });
    }

    async handleCoordinationRequest(agent, message) {
        const { workflow, role } = message.message;
        
        // ワークフローに参加
        await this.assignAgentToWorkflow(agent.name, workflow.id, role);
    }

    async createWorkflow(name, taskDescription) {
        const workflow = new Workflow(name);
        
        // タスクを分析してステップを生成
        const steps = await this.analyzeAndDecomposeTask(taskDescription);
        
        for (const step of steps) {
            workflow.addStep(step);
        }
        
        this.workflows.set(workflow.id, workflow);
        
        return workflow;
    }

    async analyzeAndDecomposeTask(taskDescription) {
        // タスクを分解（簡易版）
        const steps = [];
        
        // キーワードベースで必要なAgentを判定
        const keywords = {
            api: ['api', 'backend', 'database', 'endpoint'],
            next: ['frontend', 'ui', 'page', 'component'],
            expo: ['mobile', 'app', 'ios', 'android'],
            qa: ['test', 'quality', 'validation']
        };
        
        const requiredAgents = new Set();
        const lowerTask = taskDescription.toLowerCase();
        
        for (const [agent, words] of Object.entries(keywords)) {
            if (words.some(word => lowerTask.includes(word))) {
                requiredAgents.add(agent);
            }
        }
        
        // ステップを生成
        let stepIndex = 0;
        
        // API開発が必要な場合
        if (requiredAgents.has('api')) {
            steps.push({
                id: `step_${stepIndex++}`,
                agent: 'api',
                type: 'api_development',
                description: 'APIエンドポイント開発',
                requirements: ['backend', 'database'],
                dependencies: []
            });
        }
        
        // フロントエンド開発が必要な場合
        if (requiredAgents.has('next')) {
            steps.push({
                id: `step_${stepIndex++}`,
                agent: 'next',
                type: 'frontend_development',
                description: 'フロントエンド実装',
                requirements: ['frontend', 'ui'],
                dependencies: requiredAgents.has('api') ? ['step_0'] : []
            });
        }
        
        // テストが必要な場合
        if (requiredAgents.size > 0) {
            steps.push({
                id: `step_${stepIndex++}`,
                agent: 'qa',
                type: 'testing',
                description: '品質保証テスト',
                requirements: ['testing'],
                dependencies: steps.map(s => s.id)
            });
        }
        
        return steps;
    }

    async executeWorkflow(workflowId) {
        const workflow = this.workflows.get(workflowId);
        if (!workflow) {
            throw new Error(`Workflow ${workflowId} not found`);
        }
        
        console.log(chalk.bold(`\n🚀 Executing workflow: ${workflow.name}\n`));
        
        workflow.status = 'running';
        workflow.startTime = new Date();
        
        const spinner = ora('Processing workflow...').start();
        
        try {
            // 各ステップを実行
            while (workflow.currentStep < workflow.steps.length) {
                const step = workflow.getNextStep();
                
                spinner.text = `Executing step ${workflow.currentStep + 1}/${workflow.steps.length}: ${step.description}`;
                
                // 依存関係をチェック
                await this.waitForDependencies(workflow, step);
                
                // Agentを取得
                const agent = this.agents.get(step.agent);
                if (!agent) {
                    throw new Error(`Agent ${step.agent} not found`);
                }
                
                // コンテキストを構築
                const context = this.buildContext(workflow, step);
                
                // タスク実行
                const result = await agent.execute(step, context);
                
                // 結果を記録
                workflow.completeStep(result);
                
                // 他のAgentに結果を共有
                if (result.needsCoordination) {
                    this.messageBus.publish(agent.name, result.needsCoordination, {
                        type: 'result_share',
                        result,
                        taskId: step.id
                    });
                }
            }
            
            spinner.succeed(`Workflow completed in ${workflow.getDuration()}ms`);
            
            return workflow;
            
        } catch (error) {
            spinner.fail(`Workflow failed: ${error.message}`);
            workflow.status = 'failed';
            throw error;
        }
    }

    async waitForDependencies(workflow, step) {
        for (const depId of step.dependencies) {
            // 依存するステップの完了を待つ
            while (!workflow.results[depId]) {
                await new Promise(resolve => setTimeout(resolve, 100));
            }
        }
    }

    buildContext(workflow, step) {
        const context = {};
        
        // 依存するステップの結果を含める
        for (const depId of step.dependencies) {
            const depStep = workflow.steps.find(s => s.id === depId);
            if (depStep && workflow.results[depId]) {
                context[depStep.agent] = workflow.results[depId];
                
                // API仕様がある場合は特別に処理
                if (workflow.results[depId].apiSpec) {
                    context.apiSpec = workflow.results[depId].apiSpec;
                }
            }
        }
        
        return context;
    }

    async assignAgentToWorkflow(agentName, workflowId, role) {
        const workflow = this.workflows.get(workflowId);
        const agent = this.agents.get(agentName);
        
        if (!workflow || !agent) {
            throw new Error('Workflow or agent not found');
        }
        
        // ワークフローのステップにAgentを割り当て
        const relevantSteps = workflow.steps.filter(step => 
            step.agent === agentName || step.requirements.includes(role)
        );
        
        for (const step of relevantSteps) {
            step.assignedAgent = agentName;
        }
        
        console.log(chalk.blue(`🔗 ${agentName} assigned to workflow ${workflow.name}`));
    }

    generateReport(workflowId) {
        const workflow = this.workflows.get(workflowId);
        if (!workflow) return null;
        
        const report = {
            workflow: {
                id: workflow.id,
                name: workflow.name,
                status: workflow.status,
                duration: workflow.getDuration(),
                steps: workflow.steps.length
            },
            execution: workflow.steps.map(step => ({
                step: step.description,
                agent: step.agent,
                result: workflow.results[step.id] || 'pending'
            })),
            messages: this.messageBus.getHistory()
        };
        
        return report;
    }
}

// デモ実行
async function demonstrateCoordination() {
    console.log(chalk.bold.cyan('\n🤝 Agent Coordination System Demo\n'));
    
    const coordinator = new AgentCoordinator();
    
    // Agentを登録
    coordinator.registerAgent(new APIAgent());
    coordinator.registerAgent(new NextAgent());
    coordinator.registerAgent(new QAAgent());
    
    // ワークフロー作成
    const workflow = await coordinator.createWorkflow(
        'User Management Feature',
        'Create a complete user management system with API endpoints and frontend interface'
    );
    
    console.log(chalk.yellow('\n📋 Workflow created:'));
    console.log(`  Name: ${workflow.name}`);
    console.log(`  Steps: ${workflow.steps.length}`);
    workflow.steps.forEach((step, i) => {
        console.log(`    ${i + 1}. [${step.agent}] ${step.description}`);
    });
    
    // ワークフロー実行
    console.log('');
    await coordinator.executeWorkflow(workflow.id);
    
    // レポート生成
    const report = coordinator.generateReport(workflow.id);
    
    console.log(chalk.bold('\n📊 Execution Report:\n'));
    console.log(`Status: ${report.workflow.status}`);
    console.log(`Duration: ${report.workflow.duration}ms`);
    console.log('\nStep Results:');
    report.execution.forEach((exec, i) => {
        console.log(`  ${i + 1}. ${exec.step}`);
        console.log(`     Agent: ${exec.agent}`);
        if (exec.result.steps) {
            exec.result.steps.forEach(s => console.log(`       ${s}`));
        }
    });
    
    // レポート保存
    const reportPath = `coordination/logs/report_${workflow.id}.json`;
    await fs.mkdir('coordination/logs', { recursive: true });
    await fs.writeFile(reportPath, JSON.stringify(report, null, 2));
    
    console.log(chalk.green(`\n✅ Report saved to: ${reportPath}`));
}

// CLI
const command = process.argv[2];

switch (command) {
    case 'demo':
        demonstrateCoordination().catch(console.error);
        break;
    case 'help':
    default:
        console.log(`
使用方法:
  node coordinator.js demo    - デモ実行
  node coordinator.js help    - ヘルプ表示
        `);
}

export { AgentCoordinator, Agent, Workflow, AgentMessageBus };
COORDINATOR_EOF

# 3. ワークフローテンプレート
cat > coordination/workflows/templates.json << 'TEMPLATES_EOF'
{
  "templates": [
    {
      "name": "full-stack-feature",
      "description": "フルスタック機能開発",
      "steps": [
        {
          "order": 1,
          "agent": "api",
          "parallel": false,
          "tasks": [
            "API設計",
            "データモデル定義",
            "エンドポイント実装",
            "バリデーション実装"
          ]
        },
        {
          "order": 2,
          "agent": "next",
          "parallel": true,
          "tasks": [
            "UIコンポーネント作成",
            "ページ実装",
            "API統合"
          ]
        },
        {
          "order": 2,
          "agent": "expo",
          "parallel": true,
          "tasks": [
            "モバイルUI作成",
            "ナビゲーション実装",
            "API統合"
          ]
        },
        {
          "order": 3,
          "agent": "qa",
          "parallel": false,
          "tasks": [
            "統合テスト",
            "E2Eテスト",
            "パフォーマンステスト"
          ]
        }
      ]
    },
    {
      "name": "api-only",
      "description": "APIのみの開発",
      "steps": [
        {
          "order": 1,
          "agent": "api",
          "tasks": [
            "API設計",
            "実装",
            "単体テスト"
          ]
        },
        {
          "order": 2,
          "agent": "qa",
          "tasks": [
            "APIテスト",
            "負荷テスト"
          ]
        }
      ]
    },
    {
      "name": "frontend-update",
      "description": "フロントエンド更新",
      "steps": [
        {
          "order": 1,
          "agent": "next",
          "parallel": true,
          "tasks": [
            "UI更新",
            "スタイリング"
          ]
        },
        {
          "order": 1,
          "agent": "expo",
          "parallel": true,
          "tasks": [
            "モバイルUI更新"
          ]
        },
        {
          "order": 2,
          "agent": "qa",
          "tasks": [
            "UIテスト",
            "クロスブラウザテスト"
          ]
        }
      ]
    },
    {
      "name": "security-audit",
      "description": "セキュリティ監査",
      "steps": [
        {
          "order": 1,
          "agent": "security",
          "tasks": [
            "脆弱性スキャン",
            "依存関係チェック"
          ]
        },
        {
          "order": 2,
          "agent": "api",
          "parallel": true,
          "tasks": [
            "セキュリティパッチ適用"
          ]
        },
        {
          "order": 2,
          "agent": "next",
          "parallel": true,
          "tasks": [
            "CSP設定更新"
          ]
        },
        {
          "order": 3,
          "agent": "qa",
          "tasks": [
            "セキュリティテスト"
          ]
        }
      ]
    }
  ]
}
TEMPLATES_EOF

# 4. 実行スクリプト
cat > coordination/run-workflow.sh << 'RUNWORKFLOW_EOF'
#!/usr/bin/env bash
# ワークフロー実行スクリプト
set -euo pipefail

WORKFLOW="${1:-demo}"

echo "🤝 ワークフロー実行: $WORKFLOW"

case "$WORKFLOW" in
    demo)
        node orchestrator/coordinator.js demo
        ;;
        
    fullstack)
        echo "フルスタック開発ワークフローを開始..."
        node orchestrator/coordinator.js execute full-stack-feature
        ;;
        
    api)
        echo "API開発ワークフローを開始..."
        node orchestrator/coordinator.js execute api-only
        ;;
        
    frontend)
        echo "フロントエンド更新ワークフローを開始..."
        node orchestrator/coordinator.js execute frontend-update
        ;;
        
    security)
        echo "セキュリティ監査ワークフローを開始..."
        node orchestrator/coordinator.js execute security-audit
        ;;
        
    *)
        echo "使用方法: $0 {demo|fullstack|api|frontend|security}"
        exit 1
        ;;
esac
RUNWORKFLOW_EOF

# 5. Package.json
cat > coordination/package.json << 'COORD_PACKAGE_EOF'
{
  "name": "subagent-coordination",
  "version": "1.0.0",
  "description": "Agent coordination system for SubAgent",
  "type": "module",
  "scripts": {
    "demo": "node orchestrator/coordinator.js demo",
    "workflow": "bash run-workflow.sh",
    "test": "node test-coordination.js"
  },
  "dependencies": {
    "uuid": "^9.0.1",
    "chalk": "^5.3.0",
    "ora": "^7.0.1"
  }
}
COORD_PACKAGE_EOF

chmod +x coordination/*.sh

echo "✅ Agent間自動協調システムのセットアップが完了しました！"
echo ""
echo "🤝 機能:"
echo "  - Agent間メッセージング"
echo "  - ワークフロー定義と実行"
echo "  - 依存関係管理"
echo "  - 並列実行サポート"
echo "  - 結果共有と協調"
echo ""
echo "📋 テンプレート:"
echo "  - full-stack-feature: フルスタック開発"
echo "  - api-only: API開発"
echo "  - frontend-update: フロント更新"
echo "  - security-audit: セキュリティ監査"
echo ""
echo "🚀 使い方:"
echo "  cd coordination && npm install"
echo "  npm run demo                    # デモ実行"
echo "  ./run-workflow.sh fullstack     # ワークフロー実行"