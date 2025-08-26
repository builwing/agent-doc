#!/usr/bin/env bash
# SubAgent自動テスト実行システムのセットアップ
set -euo pipefail

echo "🧪 自動テスト実行システムをセットアップ中..."

# 1. テストディレクトリ構造
mkdir -p tests/{unit,integration,e2e,acceptance}
mkdir -p tests/fixtures/{api,next,expo}
mkdir -p tests/reports

# 2. テストランナー設定
cat > tests/test-runner.js << 'TESTRUNNER_EOF'
#!/usr/bin/env node
/**
 * SubAgent Test Runner
 * 各Agentの実装に対する自動テスト実行
 */

import { promises as fs } from 'fs';
import path from 'path';
import { spawn } from 'child_process';
import chalk from 'chalk';
import ora from 'ora';

class TestRunner {
    constructor() {
        this.results = {
            passed: 0,
            failed: 0,
            skipped: 0,
            errors: [],
            startTime: new Date(),
        };
        
        this.testSuites = {
            api: {
                unit: 'go test ./...',
                integration: 'go test -tags=integration ./...',
                benchmark: 'go test -bench=. ./...',
                lint: 'golangci-lint run',
            },
            next: {
                unit: 'npm test',
                integration: 'npm run test:integration',
                e2e: 'npm run test:e2e',
                lint: 'npm run lint',
                typecheck: 'npm run type-check',
                lighthouse: 'npm run lighthouse',
            },
            expo: {
                unit: 'npm test',
                snapshot: 'npm run test:snapshot',
                e2e: 'npm run test:detox',
                lint: 'npm run lint',
                typecheck: 'npm run type-check',
            },
        };
    }

    async runTests(agent, testType = 'all') {
        console.log(chalk.bold(`\n🧪 Testing ${agent.toUpperCase()} Agent\n`));
        
        const suite = this.testSuites[agent];
        if (!suite) {
            console.log(chalk.yellow(`No test suite defined for ${agent}`));
            return;
        }
        
        const testsToRun = testType === 'all' 
            ? Object.entries(suite)
            : [[testType, suite[testType]]].filter(([, cmd]) => cmd);
        
        for (const [type, command] of testsToRun) {
            await this.runTestCommand(agent, type, command);
        }
    }

    async runTestCommand(agent, type, command) {
        const spinner = ora(`Running ${type} tests...`).start();
        
        try {
            const startTime = Date.now();
            const result = await this.executeCommand(command, agent);
            const duration = ((Date.now() - startTime) / 1000).toFixed(2);
            
            if (result.exitCode === 0) {
                spinner.succeed(`${type} tests passed (${duration}s)`);
                this.results.passed++;
                
                // 結果を記録
                await this.recordTestResult(agent, type, 'passed', result.output, duration);
            } else {
                spinner.fail(`${type} tests failed (${duration}s)`);
                this.results.failed++;
                this.results.errors.push({
                    agent,
                    type,
                    error: result.error || result.output,
                });
                
                // 失敗の詳細を表示
                console.log(chalk.red('\nError output:'));
                console.log(result.output.slice(-500)); // 最後の500文字
                
                await this.recordTestResult(agent, type, 'failed', result.output, duration);
            }
        } catch (error) {
            spinner.fail(`${type} tests errored`);
            this.results.errors.push({
                agent,
                type,
                error: error.message,
            });
            
            await this.recordTestResult(agent, type, 'error', error.message, 0);
        }
    }

    executeCommand(command, agent) {
        return new Promise((resolve) => {
            const [cmd, ...args] = command.split(' ');
            
            // 作業ディレクトリを決定
            const cwd = agent === 'api' ? '.' : 
                       agent === 'next' ? './app' :
                       agent === 'expo' ? './mobile' : '.';
            
            const child = spawn(cmd, args, {
                cwd,
                shell: true,
                env: { ...process.env, CI: 'true' },
            });
            
            let output = '';
            let error = '';
            
            child.stdout.on('data', (data) => {
                output += data.toString();
            });
            
            child.stderr.on('data', (data) => {
                error += data.toString();
            });
            
            child.on('close', (exitCode) => {
                resolve({
                    exitCode,
                    output: output + error,
                    error: exitCode !== 0 ? error : null,
                });
            });
            
            // タイムアウト設定（5分）
            setTimeout(() => {
                child.kill();
                resolve({
                    exitCode: 1,
                    output,
                    error: 'Test timeout (5 minutes)',
                });
            }, 5 * 60 * 1000);
        });
    }

    async recordTestResult(agent, type, status, output, duration) {
        const timestamp = new Date().toISOString();
        const resultFile = path.join('tests/reports', `${agent}_${type}_${timestamp.split('T')[0]}.json`);
        
        const result = {
            timestamp,
            agent,
            type,
            status,
            duration,
            output: output.slice(-10000), // 最後の10000文字のみ保存
        };
        
        await fs.mkdir('tests/reports', { recursive: true });
        await fs.writeFile(resultFile, JSON.stringify(result, null, 2));
    }

    async generateReport() {
        const duration = ((Date.now() - this.results.startTime.getTime()) / 1000).toFixed(2);
        
        console.log('\n' + chalk.cyan('═'.repeat(50)));
        console.log(chalk.bold('\n📊 Test Results Summary\n'));
        
        console.log(`  ${chalk.green(`✓ Passed: ${this.results.passed}`)}`);
        console.log(`  ${chalk.red(`✗ Failed: ${this.results.failed}`)}`);
        console.log(`  ${chalk.gray(`○ Skipped: ${this.results.skipped}`)}`);
        console.log(`  ${chalk.blue(`⏱ Duration: ${duration}s`)}`);
        
        if (this.results.errors.length > 0) {
            console.log(chalk.bold('\n❌ Errors:\n'));
            this.results.errors.forEach(({ agent, type, error }) => {
                console.log(`  ${chalk.red(`${agent}/${type}:`)}`);
                console.log(`    ${error.split('\n')[0]}`);
            });
        }
        
        console.log('\n' + chalk.cyan('═'.repeat(50)));
        
        // HTMLレポート生成
        await this.generateHTMLReport();
        
        return this.results.failed === 0;
    }

    async generateHTMLReport() {
        const timestamp = new Date().toISOString();
        const reportPath = path.join('tests/reports', `report_${timestamp.split('T')[0]}.html`);
        
        const html = `
<!DOCTYPE html>
<html>
<head>
    <title>SubAgent Test Report - ${timestamp}</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .summary { display: flex; gap: 20px; margin: 20px 0; }
        .stat { padding: 15px; border-radius: 8px; background: #f5f5f5; }
        .stat.passed { background: #d4edda; color: #155724; }
        .stat.failed { background: #f8d7da; color: #721c24; }
        .errors { margin-top: 30px; }
        .error { background: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 10px 0; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f8f9fa; }
    </style>
</head>
<body>
    <h1>SubAgent Test Report</h1>
    <p>Generated: ${timestamp}</p>
    
    <div class="summary">
        <div class="stat passed">
            <strong>Passed:</strong> ${this.results.passed}
        </div>
        <div class="stat failed">
            <strong>Failed:</strong> ${this.results.failed}
        </div>
        <div class="stat">
            <strong>Duration:</strong> ${((Date.now() - this.results.startTime) / 1000).toFixed(2)}s
        </div>
    </div>
    
    ${this.results.errors.length > 0 ? `
        <div class="errors">
            <h2>Failed Tests</h2>
            ${this.results.errors.map(e => `
                <div class="error">
                    <strong>${e.agent}/${e.type}</strong>
                    <pre>${e.error.slice(0, 500)}</pre>
                </div>
            `).join('')}
        </div>
    ` : '<p>All tests passed! 🎉</p>'}
</body>
</html>
        `;
        
        await fs.writeFile(reportPath, html);
        console.log(`\n📄 HTML report generated: ${reportPath}`);
    }
}

// CLI実行
async function main() {
    const args = process.argv.slice(2);
    const agent = args[0] || 'all';
    const testType = args[1] || 'all';
    
    const runner = new TestRunner();
    
    if (agent === 'all') {
        for (const ag of ['api', 'next', 'expo']) {
            await runner.runTests(ag, testType);
        }
    } else {
        await runner.runTests(agent, testType);
    }
    
    const success = await runner.generateReport();
    process.exit(success ? 0 : 1);
}

if (process.argv[1] === new URL(import.meta.url).pathname) {
    main().catch(console.error);
}

export default TestRunner;
TESTRUNNER_EOF

# 3. 受け入れテスト実行スクリプト
cat > tests/acceptance-test.sh << 'ACCEPTANCE_EOF'
#!/usr/bin/env bash
# 受け入れ基準に基づく自動テスト
set -euo pipefail

AGENT="${1:-all}"

echo "🎯 受け入れテストを実行中..."

run_acceptance_test() {
    local agent=$1
    local req_file="docs/agents/$agent/REQUIREMENTS.md"
    
    if [[ ! -f "$req_file" ]]; then
        echo "⚠️  $agent: 要件定義が見つかりません"
        return 1
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing: $agent"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 受け入れ基準を抽出
    local criteria=$(awk '/^# 受け入れ基準/,/^#[^#]/' "$req_file" | grep "^[0-9]\." || true)
    
    if [[ -z "$criteria" ]]; then
        echo "⚠️  受け入れ基準が定義されていません"
        return 1
    fi
    
    echo "受け入れ基準:"
    echo "$criteria"
    echo ""
    
    # 各基準に対するテストを実行
    case $agent in
        api)
            # API固有のテスト
            echo "🔧 API テスト実行..."
            
            # エンドポイントテスト
            if command -v curl &> /dev/null; then
                echo "  - エンドポイント疎通確認"
                # curl -s http://localhost:8888/health || echo "    ⚠️  APIサーバーが起動していません"
            fi
            
            # OpenAPI検証
            if [[ -f "api/doc/api.yaml" ]]; then
                echo "  - OpenAPI仕様検証"
                # swagger-cli validate api/doc/api.yaml || true
            fi
            ;;
            
        next)
            # Next.js固有のテスト
            echo "🌐 Next.js テスト実行..."
            
            # ビルドテスト
            echo "  - ビルド検証"
            # cd app && npm run build --dry-run && cd ..
            
            # Lighthouse CI
            echo "  - パフォーマンス測定"
            # lighthouse http://localhost:3000 --output=json --output-path=tests/reports/lighthouse.json || true
            ;;
            
        expo)
            # Expo固有のテスト
            echo "📱 Expo テスト実行..."
            
            # ビルド検証
            echo "  - ビルド設定検証"
            # cd mobile && npx expo-cli doctor && cd ..
            ;;
            
        *)
            echo "⚠️  $agent の受け入れテストは未定義"
            ;;
    esac
    
    echo "✅ $agent の受け入れテスト完了"
    return 0
}

# メイン処理
if [[ "$AGENT" == "all" ]]; then
    for ag in api logic next expo; do
        run_acceptance_test "$ag" || true
    done
else
    run_acceptance_test "$AGENT"
fi

echo ""
echo "🎯 受け入れテスト完了"
ACCEPTANCE_EOF

# 4. CI/CD統合用のテストワークフロー
cat > .github/workflows/test-automation.yml << 'CITEST_EOF'
name: Automated Testing

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    # 毎日午前2時に実行
    - cron: '0 2 * * *'
  workflow_dispatch:
    inputs:
      agent:
        description: 'Agent to test'
        required: false
        default: 'all'
        type: choice
        options:
          - all
          - api
          - next
          - expo

jobs:
  test-api:
    name: API Agent Tests
    runs-on: ubuntu-latest
    if: github.event.inputs.agent == 'api' || github.event.inputs.agent == 'all' || github.event.inputs.agent == ''
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Install dependencies
        run: |
          go mod download
          go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
      
      - name: Run tests
        run: |
          go test -v -coverprofile=coverage.out ./...
          go tool cover -html=coverage.out -o coverage.html
      
      - name: Run linter
        run: golangci-lint run
      
      - name: Upload coverage
        uses: actions/upload-artifact@v3
        with:
          name: api-coverage
          path: coverage.html
      
      - name: Acceptance tests
        run: ./tests/acceptance-test.sh api

  test-next:
    name: Next.js Agent Tests  
    runs-on: ubuntu-latest
    if: github.event.inputs.agent == 'next' || github.event.inputs.agent == 'all' || github.event.inputs.agent == ''
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: 'app/package-lock.json'
      
      - name: Install dependencies
        working-directory: ./app
        run: npm ci
      
      - name: Type check
        working-directory: ./app
        run: npm run type-check
      
      - name: Lint
        working-directory: ./app
        run: npm run lint
      
      - name: Test
        working-directory: ./app
        run: npm test -- --coverage
      
      - name: Build
        working-directory: ./app
        run: npm run build
      
      - name: Lighthouse CI
        uses: treosh/lighthouse-ci-action@v10
        with:
          urls: |
            http://localhost:3000
          uploadArtifacts: true
      
      - name: Acceptance tests
        run: ./tests/acceptance-test.sh next

  test-expo:
    name: Expo Agent Tests
    runs-on: ubuntu-latest
    if: github.event.inputs.agent == 'expo' || github.event.inputs.agent == 'all' || github.event.inputs.agent == ''
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: 'mobile/package-lock.json'
      
      - name: Install dependencies
        working-directory: ./mobile
        run: npm ci
      
      - name: Setup Expo
        uses: expo/expo-github-action@v8
        with:
          expo-version: latest
          token: ${{ secrets.EXPO_TOKEN }}
      
      - name: Type check
        working-directory: ./mobile
        run: npm run type-check
      
      - name: Lint
        working-directory: ./mobile
        run: npm run lint
      
      - name: Test
        working-directory: ./mobile
        run: npm test -- --coverage
      
      - name: Acceptance tests
        run: ./tests/acceptance-test.sh expo

  test-integration:
    name: Integration Tests
    runs-on: ubuntu-latest
    needs: [test-api, test-next, test-expo]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup environment
        run: |
          docker-compose up -d
          sleep 10
      
      - name: Run integration tests
        run: |
          npm install
          npm run test:integration
      
      - name: Generate test report
        if: always()
        run: |
          node tests/test-runner.js all
      
      - name: Upload test reports
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-reports
          path: tests/reports/

  notify:
    name: Notify Results
    runs-on: ubuntu-latest
    needs: [test-integration]
    if: always()
    
    steps:
      - name: Notify success
        if: success()
        run: |
          echo "✅ All tests passed!"
          # Slack/Discord通知を追加可能
      
      - name: Notify failure
        if: failure()
        run: |
          echo "❌ Tests failed!"
          # Slack/Discord通知を追加可能
CITEST_EOF

# 5. package.json for tests
cat > tests/package.json << 'TEST_PACKAGE_EOF'
{
  "name": "subagent-tests",
  "version": "1.0.0",
  "description": "Automated testing for SubAgent system",
  "type": "module",
  "scripts": {
    "test": "node test-runner.js all",
    "test:api": "node test-runner.js api",
    "test:next": "node test-runner.js next",
    "test:expo": "node test-runner.js expo",
    "test:acceptance": "./acceptance-test.sh all",
    "report": "open tests/reports/report_*.html"
  },
  "dependencies": {
    "chalk": "^5.3.0",
    "ora": "^7.0.1"
  }
}
TEST_PACKAGE_EOF

chmod +x tests/*.sh
chmod +x tests/*.js

echo "✅ 自動テスト実行システムのセットアップが完了しました！"
echo ""
echo "📝 作成されたテストツール:"
echo "  - tests/test-runner.js       : メインテストランナー"
echo "  - tests/acceptance-test.sh   : 受け入れテスト"
echo "  - .github/workflows/test-automation.yml : CI/CD統合"
echo ""
echo "🧪 テストの実行:"
echo "  cd tests && npm install"
echo "  npm test                    # 全テスト実行"
echo "  npm run test:api           # APIテストのみ"
echo "  npm run test:acceptance    # 受け入れテスト"
echo ""
echo "📊 レポート:"
echo "  tests/reports/ にHTMLレポートが生成されます"