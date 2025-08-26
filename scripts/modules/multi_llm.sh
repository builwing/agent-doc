#!/usr/bin/env bash
# 複数LLMプロバイダー対応システム
set -euo pipefail

echo "🤖 複数LLMプロバイダー対応をセットアップ中..."

# 1. ディレクトリ構造
mkdir -p llm/{providers,strategies,config}

# 2. 統一LLMインターフェース
cat > llm/llm-manager.js << 'LLMMANAGER_EOF'
#!/usr/bin/env node
/**
 * Multi-LLM Provider Manager
 * 複数のLLMプロバイダーを統一インターフェースで管理
 */

import { Anthropic } from '@anthropic-ai/sdk';
import OpenAI from 'openai';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { HfInference } from '@huggingface/inference';
import Replicate from 'replicate';
import chalk from 'chalk';
import ora from 'ora';
import { promises as fs } from 'fs';

// プロバイダー基底クラス
class LLMProvider {
    constructor(name, config = {}) {
        this.name = name;
        this.config = config;
        this.metrics = {
            totalRequests: 0,
            totalTokens: 0,
            totalLatency: 0,
            errors: 0
        };
    }

    async complete(prompt, options = {}) {
        throw new Error('Subclass must implement complete()');
    }

    async embed(text) {
        throw new Error('Embedding not supported by this provider');
    }

    getMetrics() {
        return {
            ...this.metrics,
            avgLatency: this.metrics.totalRequests > 0 
                ? this.metrics.totalLatency / this.metrics.totalRequests 
                : 0
        };
    }

    recordMetrics(tokens, latency, error = false) {
        this.metrics.totalRequests++;
        this.metrics.totalTokens += tokens;
        this.metrics.totalLatency += latency;
        if (error) this.metrics.errors++;
    }
}

// Anthropic Claude プロバイダー
class ClaudeProvider extends LLMProvider {
    constructor(config) {
        super('Claude', config);
        this.client = new Anthropic({
            apiKey: config.apiKey || process.env.ANTHROPIC_API_KEY
        });
        this.models = {
            fast: 'claude-3-haiku-20240307',
            balanced: 'claude-3-sonnet-20240229',
            powerful: 'claude-3-opus-20240229'
        };
    }

    async complete(prompt, options = {}) {
        const startTime = Date.now();
        const model = this.models[options.quality || 'balanced'];

        try {
            const response = await this.client.messages.create({
                model,
                max_tokens: options.maxTokens || 1000,
                temperature: options.temperature || 0.7,
                messages: [{ role: 'user', content: prompt }],
                ...options.extra
            });

            const latency = Date.now() - startTime;
            const content = response.content[0].text;
            const tokens = response.usage?.total_tokens || 0;

            this.recordMetrics(tokens, latency);

            return {
                content,
                model,
                provider: this.name,
                usage: {
                    promptTokens: response.usage?.input_tokens || 0,
                    completionTokens: response.usage?.output_tokens || 0,
                    totalTokens: tokens
                },
                latency
            };
        } catch (error) {
            this.recordMetrics(0, Date.now() - startTime, true);
            throw error;
        }
    }
}

// OpenAI GPT プロバイダー
class OpenAIProvider extends LLMProvider {
    constructor(config) {
        super('OpenAI', config);
        this.client = new OpenAI({
            apiKey: config.apiKey || process.env.OPENAI_API_KEY
        });
        this.models = {
            fast: 'gpt-3.5-turbo',
            balanced: 'gpt-4-turbo-preview',
            powerful: 'gpt-4'
        };
    }

    async complete(prompt, options = {}) {
        const startTime = Date.now();
        const model = this.models[options.quality || 'balanced'];

        try {
            const response = await this.client.chat.completions.create({
                model,
                messages: [{ role: 'user', content: prompt }],
                max_tokens: options.maxTokens || 1000,
                temperature: options.temperature || 0.7,
                ...options.extra
            });

            const latency = Date.now() - startTime;
            const content = response.choices[0].message.content;
            const usage = response.usage;

            this.recordMetrics(usage?.total_tokens || 0, latency);

            return {
                content,
                model,
                provider: this.name,
                usage: {
                    promptTokens: usage?.prompt_tokens || 0,
                    completionTokens: usage?.completion_tokens || 0,
                    totalTokens: usage?.total_tokens || 0
                },
                latency
            };
        } catch (error) {
            this.recordMetrics(0, Date.now() - startTime, true);
            throw error;
        }
    }

    async embed(text) {
        const response = await this.client.embeddings.create({
            model: 'text-embedding-ada-002',
            input: text
        });

        return response.data[0].embedding;
    }
}

// Google Gemini プロバイダー
class GeminiProvider extends LLMProvider {
    constructor(config) {
        super('Gemini', config);
        this.client = new GoogleGenerativeAI(
            config.apiKey || process.env.GOOGLE_API_KEY
        );
        this.models = {
            fast: 'gemini-1.5-flash',
            balanced: 'gemini-1.5-pro',
            powerful: 'gemini-1.5-pro'
        };
    }

    async complete(prompt, options = {}) {
        const startTime = Date.now();
        const modelName = this.models[options.quality || 'balanced'];
        const model = this.client.getGenerativeModel({ model: modelName });

        try {
            const result = await model.generateContent(prompt);
            const response = await result.response;
            const content = response.text();
            const latency = Date.now() - startTime;

            this.recordMetrics(0, latency); // Geminiは使用量を返さない

            return {
                content,
                model: modelName,
                provider: this.name,
                usage: {
                    promptTokens: 0,
                    completionTokens: 0,
                    totalTokens: 0
                },
                latency
            };
        } catch (error) {
            this.recordMetrics(0, Date.now() - startTime, true);
            throw error;
        }
    }
}

// HuggingFace プロバイダー（オープンソースモデル）
class HuggingFaceProvider extends LLMProvider {
    constructor(config) {
        super('HuggingFace', config);
        this.client = new HfInference(
            config.apiKey || process.env.HUGGINGFACE_API_KEY
        );
        this.models = {
            fast: 'microsoft/phi-2',
            balanced: 'mistralai/Mixtral-8x7B-Instruct-v0.1',
            powerful: 'meta-llama/Llama-2-70b-chat-hf'
        };
    }

    async complete(prompt, options = {}) {
        const startTime = Date.now();
        const model = this.models[options.quality || 'balanced'];

        try {
            const response = await this.client.textGeneration({
                model,
                inputs: prompt,
                parameters: {
                    max_new_tokens: options.maxTokens || 1000,
                    temperature: options.temperature || 0.7,
                    ...options.extra
                }
            });

            const latency = Date.now() - startTime;
            const content = response.generated_text;

            this.recordMetrics(0, latency);

            return {
                content,
                model,
                provider: this.name,
                usage: {
                    promptTokens: 0,
                    completionTokens: 0,
                    totalTokens: 0
                },
                latency
            };
        } catch (error) {
            this.recordMetrics(0, Date.now() - startTime, true);
            throw error;
        }
    }
}

// ローカルLLMプロバイダー（Ollama）
class OllamaProvider extends LLMProvider {
    constructor(config) {
        super('Ollama', config);
        this.baseUrl = config.baseUrl || 'http://localhost:11434';
        this.models = {
            fast: 'phi',
            balanced: 'mistral',
            powerful: 'llama2:70b'
        };
    }

    async complete(prompt, options = {}) {
        const startTime = Date.now();
        const model = this.models[options.quality || 'balanced'];

        try {
            const response = await fetch(`${this.baseUrl}/api/generate`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model,
                    prompt,
                    stream: false,
                    options: {
                        temperature: options.temperature || 0.7,
                        num_predict: options.maxTokens || 1000
                    }
                })
            });

            const data = await response.json();
            const latency = Date.now() - startTime;

            this.recordMetrics(0, latency);

            return {
                content: data.response,
                model,
                provider: this.name,
                usage: {
                    promptTokens: 0,
                    completionTokens: 0,
                    totalTokens: 0
                },
                latency
            };
        } catch (error) {
            this.recordMetrics(0, Date.now() - startTime, true);
            throw error;
        }
    }
}

// LLMマネージャー
class LLMManager {
    constructor() {
        this.providers = new Map();
        this.strategies = {
            failover: new FailoverStrategy(),
            loadBalance: new LoadBalanceStrategy(),
            costOptimize: new CostOptimizeStrategy(),
            quality: new QualityFirstStrategy(),
            speed: new SpeedFirstStrategy()
        };
        this.currentStrategy = 'failover';
        this.history = [];
    }

    async initialize(config = {}) {
        const spinner = ora('LLMプロバイダーを初期化中...').start();

        try {
            // 設定ファイル読み込み
            const configPath = config.configPath || 'llm/config/providers.json';
            const providersConfig = JSON.parse(
                await fs.readFile(configPath, 'utf-8').catch(() => '{}')
            );

            // プロバイダー初期化
            if (providersConfig.claude?.enabled) {
                this.addProvider('claude', new ClaudeProvider(providersConfig.claude));
            }
            if (providersConfig.openai?.enabled) {
                this.addProvider('openai', new OpenAIProvider(providersConfig.openai));
            }
            if (providersConfig.gemini?.enabled) {
                this.addProvider('gemini', new GeminiProvider(providersConfig.gemini));
            }
            if (providersConfig.huggingface?.enabled) {
                this.addProvider('huggingface', new HuggingFaceProvider(providersConfig.huggingface));
            }
            if (providersConfig.ollama?.enabled) {
                this.addProvider('ollama', new OllamaProvider(providersConfig.ollama));
            }

            // デフォルトプロバイダー（モック）
            if (this.providers.size === 0) {
                this.addProvider('mock', new MockProvider());
            }

            spinner.succeed(`${this.providers.size} プロバイダーを初期化しました`);
        } catch (error) {
            spinner.fail('初期化エラー');
            throw error;
        }
    }

    addProvider(name, provider) {
        this.providers.set(name, provider);
    }

    setStrategy(strategyName) {
        if (!this.strategies[strategyName]) {
            throw new Error(`Unknown strategy: ${strategyName}`);
        }
        this.currentStrategy = strategyName;
    }

    async complete(prompt, options = {}) {
        const strategy = this.strategies[this.currentStrategy];
        const provider = await strategy.selectProvider(this.providers, options);

        if (!provider) {
            throw new Error('No available providers');
        }

        console.log(chalk.gray(`Using ${provider.name} with ${this.currentStrategy} strategy`));

        const result = await provider.complete(prompt, options);

        // 履歴記録
        this.history.push({
            timestamp: new Date().toISOString(),
            provider: provider.name,
            strategy: this.currentStrategy,
            latency: result.latency,
            tokens: result.usage.totalTokens
        });

        return result;
    }

    async compareProviders(prompt, options = {}) {
        console.log(chalk.bold('\n🔬 プロバイダー比較:\n'));

        const results = [];

        for (const [name, provider] of this.providers) {
            try {
                console.log(`Testing ${name}...`);
                const result = await provider.complete(prompt, options);
                results.push(result);
                
                console.log(chalk.green(`✓ ${name}: ${result.latency}ms`));
            } catch (error) {
                console.log(chalk.red(`✗ ${name}: ${error.message}`));
            }
        }

        return results;
    }

    getMetrics() {
        const metrics = {};

        for (const [name, provider] of this.providers) {
            metrics[name] = provider.getMetrics();
        }

        return metrics;
    }
}

// ストラテジー基底クラス
class Strategy {
    async selectProvider(providers, options) {
        throw new Error('Subclass must implement selectProvider()');
    }
}

// フェイルオーバー戦略
class FailoverStrategy extends Strategy {
    async selectProvider(providers, options) {
        const priority = options.priority || ['claude', 'openai', 'gemini', 'huggingface', 'ollama', 'mock'];

        for (const name of priority) {
            const provider = providers.get(name);
            if (provider) {
                return provider;
            }
        }

        return providers.values().next().value;
    }
}

// 負荷分散戦略
class LoadBalanceStrategy extends Strategy {
    constructor() {
        super();
        this.index = 0;
    }

    async selectProvider(providers) {
        const providerArray = Array.from(providers.values());
        const provider = providerArray[this.index % providerArray.length];
        this.index++;
        return provider;
    }
}

// コスト最適化戦略
class CostOptimizeStrategy extends Strategy {
    async selectProvider(providers, options) {
        // 品質要求に応じて最も安いプロバイダーを選択
        const quality = options.quality || 'fast';
        
        if (quality === 'fast') {
            // 安くて速いプロバイダーを優先
            return providers.get('ollama') || 
                   providers.get('huggingface') || 
                   providers.get('gemini') ||
                   providers.values().next().value;
        }
        
        return providers.get('claude') || 
               providers.get('openai') || 
               providers.values().next().value;
    }
}

// 品質優先戦略
class QualityFirstStrategy extends Strategy {
    async selectProvider(providers) {
        return providers.get('claude') || 
               providers.get('openai') || 
               providers.get('gemini') ||
               providers.values().next().value;
    }
}

// 速度優先戦略
class SpeedFirstStrategy extends Strategy {
    async selectProvider(providers) {
        // ローカルモデルを優先
        return providers.get('ollama') || 
               providers.get('huggingface') || 
               providers.values().next().value;
    }
}

// モックプロバイダー（テスト用）
class MockProvider extends LLMProvider {
    constructor() {
        super('Mock', {});
    }

    async complete(prompt, options = {}) {
        const startTime = Date.now();
        
        // 擬似的な遅延
        await new Promise(resolve => setTimeout(resolve, 100));
        
        const latency = Date.now() - startTime;
        
        this.recordMetrics(100, latency);

        return {
            content: `Mock response for: ${prompt.substring(0, 50)}...`,
            model: 'mock-model',
            provider: this.name,
            usage: {
                promptTokens: 50,
                completionTokens: 50,
                totalTokens: 100
            },
            latency
        };
    }
}

// CLI
async function main() {
    const manager = new LLMManager();
    await manager.initialize();

    const command = process.argv[2];
    const prompt = process.argv.slice(3).join(' ');

    switch (command) {
        case 'complete':
            const result = await manager.complete(prompt);
            console.log('\n' + chalk.green('Response:'));
            console.log(result.content);
            console.log(chalk.gray(`\n[${result.provider}/${result.model}] ${result.latency}ms`));
            break;

        case 'compare':
            await manager.compareProviders(prompt);
            break;

        case 'metrics':
            const metrics = manager.getMetrics();
            console.log('\n' + chalk.bold('Provider Metrics:'));
            console.log(JSON.stringify(metrics, null, 2));
            break;

        default:
            console.log(`
使用方法:
  node llm-manager.js complete <prompt>  - LLM補完
  node llm-manager.js compare <prompt>   - プロバイダー比較
  node llm-manager.js metrics            - メトリクス表示
            `);
    }
}

if (process.argv[1] === new URL(import.meta.url).pathname) {
    main().catch(console.error);
}

export default LLMManager;
LLMMANAGER_EOF

# 3. プロバイダー設定ファイル
cat > llm/config/providers.json << 'LLMCONFIG_EOF'
{
  "claude": {
    "enabled": false,
    "apiKey": "${ANTHROPIC_API_KEY}",
    "models": {
      "fast": "claude-3-haiku-20240307",
      "balanced": "claude-3-sonnet-20240229",
      "powerful": "claude-3-opus-20240229"
    },
    "costPerMillion": {
      "input": 0.25,
      "output": 1.25
    }
  },
  "openai": {
    "enabled": false,
    "apiKey": "${OPENAI_API_KEY}",
    "models": {
      "fast": "gpt-3.5-turbo",
      "balanced": "gpt-4-turbo-preview",
      "powerful": "gpt-4"
    },
    "costPerMillion": {
      "input": 0.50,
      "output": 1.50
    }
  },
  "gemini": {
    "enabled": false,
    "apiKey": "${GOOGLE_API_KEY}",
    "models": {
      "fast": "gemini-1.5-flash",
      "balanced": "gemini-1.5-pro",
      "powerful": "gemini-1.5-pro"
    },
    "costPerMillion": {
      "input": 0.00,
      "output": 0.00
    }
  },
  "huggingface": {
    "enabled": false,
    "apiKey": "${HUGGINGFACE_API_KEY}",
    "models": {
      "fast": "microsoft/phi-2",
      "balanced": "mistralai/Mixtral-8x7B-Instruct-v0.1",
      "powerful": "meta-llama/Llama-2-70b-chat-hf"
    }
  },
  "ollama": {
    "enabled": true,
    "baseUrl": "http://localhost:11434",
    "models": {
      "fast": "phi",
      "balanced": "mistral",
      "powerful": "llama2:70b"
    }
  }
}
LLMCONFIG_EOF

# 4. 統合スクリプト
cat > llm/setup-providers.sh << 'SETUP_EOF'
#!/usr/bin/env bash
# LLMプロバイダーのセットアップ
set -euo pipefail

echo "🤖 LLMプロバイダーをセットアップ中..."

# 環境変数チェック
check_env() {
    local var=$1
    local name=$2
    
    if [[ -n "${!var:-}" ]]; then
        echo "✅ $name: 設定済み"
        return 0
    else
        echo "⚠️  $name: 未設定 (export $var=your-key)"
        return 1
    fi
}

echo ""
echo "環境変数チェック:"
check_env "ANTHROPIC_API_KEY" "Claude" || true
check_env "OPENAI_API_KEY" "OpenAI" || true
check_env "GOOGLE_API_KEY" "Gemini" || true
check_env "HUGGINGFACE_API_KEY" "HuggingFace" || true

# Ollamaチェック
echo ""
echo "ローカルLLMチェック:"
if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo "✅ Ollama: 起動中"
    echo "  利用可能なモデル:"
    curl -s http://localhost:11434/api/tags | python3 -m json.tool | grep '"name"' | head -5
else
    echo "⚠️  Ollama: 未起動"
    echo "  インストール: https://ollama.ai"
    echo "  起動: ollama serve"
    echo "  モデル取得: ollama pull mistral"
fi

# 設定ファイル更新
echo ""
read -p "設定ファイルを環境変数で更新しますか? (y/N): " update
if [[ "$update" == "y" ]]; then
    # 環境変数を設定ファイルに反映
    envsubst < config/providers.json > config/providers.json.tmp
    mv config/providers.json.tmp config/providers.json
    echo "✅ 設定ファイルを更新しました"
fi

echo ""
echo "セットアップ完了！"
echo "テスト: node llm-manager.js complete 'Hello, world!'"
SETUP_EOF

# 5. package.json
cat > llm/package.json << 'LLM_PACKAGE_EOF'
{
  "name": "subagent-multi-llm",
  "version": "1.0.0",
  "description": "Multi-LLM provider support for SubAgent",
  "type": "module",
  "scripts": {
    "setup": "bash setup-providers.sh",
    "test": "node llm-manager.js complete 'Test prompt'",
    "compare": "node llm-manager.js compare",
    "metrics": "node llm-manager.js metrics"
  },
  "dependencies": {
    "@anthropic-ai/sdk": "^0.20.0",
    "openai": "^4.28.0",
    "@google/generative-ai": "^0.7.1",
    "@huggingface/inference": "^2.6.4",
    "replicate": "^0.29.1",
    "chalk": "^5.3.0",
    "ora": "^7.0.1"
  }
}
LLM_PACKAGE_EOF

chmod +x llm/*.sh

echo "✅ 複数LLMプロバイダー対応のセットアップが完了しました！"
echo ""
echo "🤖 対応プロバイダー:"
echo "  - Claude (Anthropic)"
echo "  - GPT (OpenAI)"
echo "  - Gemini (Google)"
echo "  - HuggingFace"
echo "  - Ollama (ローカル)"
echo ""
echo "🎯 戦略:"
echo "  - failover: フェイルオーバー"
echo "  - loadBalance: 負荷分散"
echo "  - costOptimize: コスト最適化"
echo "  - quality: 品質優先"
echo "  - speed: 速度優先"
echo ""
echo "🚀 使い方:"
echo "  cd llm && npm install"
echo "  npm run setup                    # プロバイダー設定"
echo "  npm test                         # テスト実行"
echo "  npm run compare -- 'プロンプト'  # プロバイダー比較"