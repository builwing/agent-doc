#!/usr/bin/env bash
# SubAgentメトリクス収集と分析システム
set -euo pipefail

echo "📊 メトリクス収集システムをセットアップ中..."

# 1. メトリクスディレクトリ構造
mkdir -p metrics/{collectors,analyzers,dashboards,reports}

# 2. メトリクス収集器
cat > metrics/collectors/agent-metrics.js << 'METRICS_EOF'
#!/usr/bin/env node
/**
 * SubAgent Metrics Collector
 * 各Agentのパフォーマンス・生産性メトリクスを収集
 */

import { promises as fs } from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import chalk from 'chalk';

class MetricsCollector {
    constructor() {
        this.metrics = {
            timestamp: new Date().toISOString(),
            agents: {},
            summary: {},
        };
    }

    async collectAll() {
        console.log(chalk.bold('\n📊 メトリクス収集開始\n'));
        
        const agents = ['api', 'logic', 'next', 'expo', 'infra', 'qa', 'uiux', 'security', 'docs'];
        
        for (const agent of agents) {
            await this.collectAgentMetrics(agent);
        }
        
        await this.collectGitMetrics();
        await this.collectSystemMetrics();
        await this.generateSummary();
        await this.saveMetrics();
        
        return this.metrics;
    }

    async collectAgentMetrics(agent) {
        console.log(`Collecting metrics for ${agent}...`);
        
        const metrics = {
            documentation: await this.getDocumentationMetrics(agent),
            history: await this.getHistoryMetrics(agent),
            codeMetrics: await this.getCodeMetrics(agent),
            testMetrics: await this.getTestMetrics(agent),
        };
        
        this.metrics.agents[agent] = metrics;
    }

    async getDocumentationMetrics(agent) {
        const metrics = {
            requirements: { exists: false, lines: 0, lastUpdated: null },
            checklist: { exists: false, items: 0, completed: 0 },
            history: { exists: false, entries: 0, lastEntry: null },
        };
        
        try {
            // REQUIREMENTS.md
            const reqPath = path.join('docs/agents', agent, 'REQUIREMENTS.md');
            const reqContent = await fs.readFile(reqPath, 'utf-8');
            const reqStats = await fs.stat(reqPath);
            
            metrics.requirements = {
                exists: true,
                lines: reqContent.split('\n').length,
                lastUpdated: reqStats.mtime,
                acceptanceCriteria: (reqContent.match(/^[0-9]\./gm) || []).length,
            };
            
            // CHECKLIST.md
            const checkPath = path.join('docs/agents', agent, 'CHECKLIST.md');
            const checkContent = await fs.readFile(checkPath, 'utf-8');
            
            const totalItems = (checkContent.match(/- \[[ x]\]/gi) || []).length;
            const completedItems = (checkContent.match(/- \[x\]/gi) || []).length;
            
            metrics.checklist = {
                exists: true,
                items: totalItems,
                completed: completedItems,
                completionRate: totalItems > 0 ? (completedItems / totalItems * 100).toFixed(2) : 0,
            };
            
            // HISTORY.md
            const histPath = path.join('docs/agents', agent, 'HISTORY.md');
            const histContent = await fs.readFile(histPath, 'utf-8');
            
            const entries = (histContent.match(/^## \d{4}-\d{2}-\d{2}/gm) || []);
            const lastEntry = entries[entries.length - 1];
            
            metrics.history = {
                exists: true,
                entries: entries.length,
                lastEntry: lastEntry ? new Date(lastEntry.replace('## ', '')) : null,
            };
            
        } catch (e) {
            // ファイルが存在しない場合はデフォルト値を使用
        }
        
        return metrics;
    }

    async getHistoryMetrics(agent) {
        const metrics = {
            tasksLast7Days: 0,
            tasksLast30Days: 0,
            averageTasksPerDay: 0,
            mostProductiveDay: null,
        };
        
        try {
            const histPath = path.join('docs/agents', agent, 'HISTORY.md');
            const content = await fs.readFile(histPath, 'utf-8');
            
            const now = new Date();
            const entries = content.match(/^## (\d{4}-\d{2}-\d{2}T[\d:+-]+)/gm) || [];
            
            const dates = entries.map(e => new Date(e.replace('## ', '')));
            
            // 過去7日間
            const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
            metrics.tasksLast7Days = dates.filter(d => d >= sevenDaysAgo).length;
            
            // 過去30日間
            const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
            metrics.tasksLast30Days = dates.filter(d => d >= thirtyDaysAgo).length;
            
            // 平均タスク数/日
            if (dates.length > 0) {
                const oldestDate = dates[0];
                const daysDiff = Math.max(1, Math.floor((now - oldestDate) / (24 * 60 * 60 * 1000)));
                metrics.averageTasksPerDay = (dates.length / daysDiff).toFixed(2);
            }
            
            // 最も生産的な日
            const dayCount = {};
            dates.forEach(d => {
                const day = d.toISOString().split('T')[0];
                dayCount[day] = (dayCount[day] || 0) + 1;
            });
            
            const mostProductive = Object.entries(dayCount)
                .sort(([, a], [, b]) => b - a)[0];
            
            if (mostProductive) {
                metrics.mostProductiveDay = {
                    date: mostProductive[0],
                    tasks: mostProductive[1],
                };
            }
            
        } catch (e) {
            // エラーは無視
        }
        
        return metrics;
    }

    async getCodeMetrics(agent) {
        const metrics = {
            files: 0,
            lines: 0,
            coverage: null,
        };
        
        try {
            switch (agent) {
                case 'api':
                    // Go メトリクス
                    const goFiles = execSync('find . -name "*.go" -not -path "./vendor/*" | wc -l', { encoding: 'utf-8' });
                    metrics.files = parseInt(goFiles.trim());
                    
                    const goLines = execSync('find . -name "*.go" -not -path "./vendor/*" | xargs wc -l | tail -1', { encoding: 'utf-8' });
                    metrics.lines = parseInt(goLines.trim().split(' ')[0] || 0);
                    
                    // カバレッジ（存在する場合）
                    try {
                        const coverage = execSync('go test -cover ./... 2>/dev/null | grep -oP "coverage: \\K[0-9.]+%"', { encoding: 'utf-8' });
                        metrics.coverage = parseFloat(coverage.trim().replace('%', ''));
                    } catch (e) {
                        // カバレッジ取得失敗
                    }
                    break;
                    
                case 'next':
                    // Next.js メトリクス
                    const tsxFiles = execSync('find app -name "*.tsx" -o -name "*.ts" | wc -l', { encoding: 'utf-8' });
                    metrics.files = parseInt(tsxFiles.trim());
                    
                    const tsxLines = execSync('find app -name "*.tsx" -o -name "*.ts" | xargs wc -l | tail -1', { encoding: 'utf-8' });
                    metrics.lines = parseInt(tsxLines.trim().split(' ')[0] || 0);
                    break;
                    
                case 'expo':
                    // Expo メトリクス
                    const expoFiles = execSync('find mobile -name "*.tsx" -o -name "*.ts" | wc -l', { encoding: 'utf-8' });
                    metrics.files = parseInt(expoFiles.trim());
                    
                    const expoLines = execSync('find mobile -name "*.tsx" -o -name "*.ts" | xargs wc -l | tail -1', { encoding: 'utf-8' });
                    metrics.lines = parseInt(expoLines.trim().split(' ')[0] || 0);
                    break;
            }
        } catch (e) {
            // エラーは無視
        }
        
        return metrics;
    }

    async getTestMetrics(agent) {
        const metrics = {
            testFiles: 0,
            testCases: 0,
            lastTestRun: null,
            lastTestStatus: null,
        };
        
        try {
            // テストレポートから最新の結果を取得
            const reports = await fs.readdir('tests/reports').catch(() => []);
            const agentReports = reports.filter(r => r.startsWith(`${agent}_`));
            
            if (agentReports.length > 0) {
                const latestReport = agentReports.sort().reverse()[0];
                const reportPath = path.join('tests/reports', latestReport);
                const report = JSON.parse(await fs.readFile(reportPath, 'utf-8'));
                
                metrics.lastTestRun = report.timestamp;
                metrics.lastTestStatus = report.status;
            }
            
            // テストファイル数
            switch (agent) {
                case 'api':
                    const goTests = execSync('find . -name "*_test.go" | wc -l', { encoding: 'utf-8' });
                    metrics.testFiles = parseInt(goTests.trim());
                    break;
                case 'next':
                case 'expo':
                    const jsTests = execSync(`find ${agent === 'next' ? 'app' : 'mobile'} -name "*.test.ts*" -o -name "*.spec.ts*" | wc -l`, { encoding: 'utf-8' });
                    metrics.testFiles = parseInt(jsTests.trim());
                    break;
            }
        } catch (e) {
            // エラーは無視
        }
        
        return metrics;
    }

    async collectGitMetrics() {
        console.log('Collecting Git metrics...');
        
        try {
            const metrics = {
                totalCommits: 0,
                commitsLast7Days: 0,
                commitsLast30Days: 0,
                contributors: [],
                branches: 0,
            };
            
            // 総コミット数
            const totalCommits = execSync('git rev-list --count HEAD', { encoding: 'utf-8' });
            metrics.totalCommits = parseInt(totalCommits.trim());
            
            // 過去7日のコミット
            const commits7Days = execSync('git rev-list --count --since="7 days ago" HEAD', { encoding: 'utf-8' });
            metrics.commitsLast7Days = parseInt(commits7Days.trim());
            
            // 過去30日のコミット
            const commits30Days = execSync('git rev-list --count --since="30 days ago" HEAD', { encoding: 'utf-8' });
            metrics.commitsLast30Days = parseInt(commits30Days.trim());
            
            // コントリビューター
            const contributors = execSync('git shortlog -sn --no-merges', { encoding: 'utf-8' });
            metrics.contributors = contributors.trim().split('\n').map(line => {
                const match = line.trim().match(/^\s*(\d+)\s+(.+)$/);
                return match ? { commits: parseInt(match[1]), name: match[2] } : null;
            }).filter(Boolean);
            
            // ブランチ数
            const branches = execSync('git branch -r | wc -l', { encoding: 'utf-8' });
            metrics.branches = parseInt(branches.trim());
            
            this.metrics.git = metrics;
        } catch (e) {
            this.metrics.git = { error: 'Git metrics collection failed' };
        }
    }

    async collectSystemMetrics() {
        console.log('Collecting system metrics...');
        
        this.metrics.system = {
            collectionTime: new Date().toISOString(),
            nodeVersion: process.version,
            platform: process.platform,
            uptime: process.uptime(),
            memoryUsage: process.memoryUsage(),
        };
    }

    async generateSummary() {
        const agents = Object.keys(this.metrics.agents);
        
        // 生産性スコア計算
        const productivityScores = {};
        
        agents.forEach(agent => {
            const m = this.metrics.agents[agent];
            let score = 0;
            
            // ドキュメント完成度 (30点)
            if (m.documentation.requirements.exists) score += 10;
            if (m.documentation.checklist.exists) score += 10;
            if (m.documentation.history.exists) score += 10;
            
            // アクティビティ (40点)
            score += Math.min(20, m.history.tasksLast7Days * 4);
            score += Math.min(20, m.history.tasksLast30Days);
            
            // コード品質 (30点)
            if (m.codeMetrics.coverage !== null) {
                score += Math.min(20, m.codeMetrics.coverage / 5);
            }
            if (m.testMetrics.testFiles > 0) score += 10;
            
            productivityScores[agent] = Math.min(100, score);
        });
        
        // 最も活発なAgent
        const mostActive = agents.reduce((best, agent) => {
            const tasks = this.metrics.agents[agent].history.tasksLast7Days;
            return tasks > (this.metrics.agents[best]?.history.tasksLast7Days || 0) ? agent : best;
        }, agents[0]);
        
        // 総タスク数
        const totalTasks = agents.reduce((sum, agent) => 
            sum + this.metrics.agents[agent].history.tasksLast30Days, 0);
        
        this.metrics.summary = {
            totalAgents: agents.length,
            mostActiveAgent: mostActive,
            totalTasksLast30Days: totalTasks,
            averageProductivityScore: (Object.values(productivityScores).reduce((a, b) => a + b, 0) / agents.length).toFixed(2),
            productivityScores,
            healthStatus: this.calculateHealthStatus(productivityScores),
        };
    }

    calculateHealthStatus(scores) {
        const avg = Object.values(scores).reduce((a, b) => a + b, 0) / Object.values(scores).length;
        
        if (avg >= 80) return '🟢 Excellent';
        if (avg >= 60) return '🟡 Good';
        if (avg >= 40) return '🟠 Fair';
        return '🔴 Needs Attention';
    }

    async saveMetrics() {
        const timestamp = new Date().toISOString().split('T')[0];
        const metricsPath = path.join('metrics/reports', `metrics_${timestamp}.json`);
        
        await fs.mkdir('metrics/reports', { recursive: true });
        await fs.writeFile(metricsPath, JSON.stringify(this.metrics, null, 2));
        
        console.log(chalk.green(`\n✅ メトリクスを保存しました: ${metricsPath}`));
        
        // ダッシュボードHTML生成
        await this.generateDashboard();
    }

    async generateDashboard() {
        const dashboardPath = path.join('metrics/dashboards', 'index.html');
        
        const html = `
<!DOCTYPE html>
<html>
<head>
    <title>SubAgent Metrics Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 1400px; margin: 0 auto; }
        h1 { 
            color: white; 
            text-align: center; 
            margin-bottom: 30px;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .metric-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }
        .metric-card:hover {
            transform: translateY(-5px);
        }
        .metric-title {
            font-size: 0.9em;
            color: #666;
            margin-bottom: 8px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .metric-value {
            font-size: 2.5em;
            font-weight: bold;
            color: #333;
            margin-bottom: 10px;
        }
        .metric-label {
            font-size: 0.85em;
            color: #999;
        }
        .chart-container {
            background: white;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        .agent-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 30px;
        }
        .agent-card {
            background: white;
            border-radius: 8px;
            padding: 15px;
            text-align: center;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        .agent-name {
            font-weight: bold;
            margin-bottom: 10px;
            color: #333;
        }
        .progress-bar {
            width: 100%;
            height: 20px;
            background: #f0f0f0;
            border-radius: 10px;
            overflow: hidden;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea, #764ba2);
            transition: width 0.5s ease;
        }
        .score-label {
            margin-top: 5px;
            font-size: 0.9em;
            color: #666;
        }
        .timestamp {
            text-align: center;
            color: white;
            margin-top: 20px;
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 SubAgent Metrics Dashboard</h1>
        
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-title">Health Status</div>
                <div class="metric-value">${this.metrics.summary.healthStatus}</div>
                <div class="metric-label">System Health</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-title">Total Tasks (30d)</div>
                <div class="metric-value">${this.metrics.summary.totalTasksLast30Days}</div>
                <div class="metric-label">Completed Tasks</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-title">Most Active</div>
                <div class="metric-value">${this.metrics.summary.mostActiveAgent.toUpperCase()}</div>
                <div class="metric-label">Agent</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-title">Avg Productivity</div>
                <div class="metric-value">${this.metrics.summary.averageProductivityScore}%</div>
                <div class="metric-label">Score</div>
            </div>
        </div>
        
        <div class="chart-container">
            <h2 style="margin-bottom: 20px;">Agent Productivity Scores</h2>
            <canvas id="productivityChart"></canvas>
        </div>
        
        <div class="chart-container">
            <h2 style="margin-bottom: 20px;">Activity Timeline</h2>
            <canvas id="activityChart"></canvas>
        </div>
        
        <div class="agent-grid">
            ${Object.entries(this.metrics.summary.productivityScores).map(([agent, score]) => `
                <div class="agent-card">
                    <div class="agent-name">${agent.toUpperCase()}</div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${score}%"></div>
                    </div>
                    <div class="score-label">${score.toFixed(1)}%</div>
                </div>
            `).join('')}
        </div>
        
        <div class="timestamp">
            Last Updated: ${this.metrics.timestamp}
        </div>
    </div>
    
    <script>
        // Productivity Chart
        const productivityCtx = document.getElementById('productivityChart').getContext('2d');
        new Chart(productivityCtx, {
            type: 'bar',
            data: {
                labels: ${JSON.stringify(Object.keys(this.metrics.summary.productivityScores))},
                datasets: [{
                    label: 'Productivity Score',
                    data: ${JSON.stringify(Object.values(this.metrics.summary.productivityScores))},
                    backgroundColor: 'rgba(102, 126, 234, 0.8)',
                    borderColor: 'rgba(102, 126, 234, 1)',
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100
                    }
                }
            }
        });
        
        // Activity Chart
        const activityCtx = document.getElementById('activityChart').getContext('2d');
        new Chart(activityCtx, {
            type: 'line',
            data: {
                labels: ${JSON.stringify(Object.keys(this.metrics.agents))},
                datasets: [
                    {
                        label: 'Tasks (7 days)',
                        data: ${JSON.stringify(Object.values(this.metrics.agents).map(a => a.history.tasksLast7Days))},
                        borderColor: 'rgba(118, 75, 162, 1)',
                        backgroundColor: 'rgba(118, 75, 162, 0.2)',
                        tension: 0.4
                    },
                    {
                        label: 'Tasks (30 days)',
                        data: ${JSON.stringify(Object.values(this.metrics.agents).map(a => a.history.tasksLast30Days))},
                        borderColor: 'rgba(102, 126, 234, 1)',
                        backgroundColor: 'rgba(102, 126, 234, 0.2)',
                        tension: 0.4
                    }
                ]
            },
            options: {
                responsive: true,
                interaction: {
                    mode: 'index',
                    intersect: false,
                }
            }
        });
    </script>
</body>
</html>
        `;
        
        await fs.mkdir('metrics/dashboards', { recursive: true });
        await fs.writeFile(dashboardPath, html);
        
        console.log(chalk.blue(`📊 ダッシュボードを生成しました: ${dashboardPath}`));
    }
}

// CLI実行
async function main() {
    const collector = new MetricsCollector();
    const metrics = await collector.collectAll();
    
    // サマリー表示
    console.log('\n' + chalk.cyan('═'.repeat(50)));
    console.log(chalk.bold('\n📈 Metrics Summary\n'));
    
    console.log(`  Health Status: ${metrics.summary.healthStatus}`);
    console.log(`  Total Agents: ${metrics.summary.totalAgents}`);
    console.log(`  Most Active: ${metrics.summary.mostActiveAgent}`);
    console.log(`  Tasks (30d): ${metrics.summary.totalTasksLast30Days}`);
    console.log(`  Avg Score: ${metrics.summary.averageProductivityScore}%`);
    
    console.log('\n' + chalk.cyan('═'.repeat(50)));
}

if (process.argv[1] === new URL(import.meta.url).pathname) {
    main().catch(console.error);
}

export default MetricsCollector;
METRICS_EOF

# 3. 定期実行スケジューラー
cat > metrics/scheduler.sh << 'SCHEDULER_EOF'
#!/usr/bin/env bash
# メトリクス収集の定期実行
set -euo pipefail

ACTION="${1:-collect}"

case "$ACTION" in
    collect)
        echo "📊 メトリクス収集を実行中..."
        cd metrics && node collectors/agent-metrics.js
        ;;
        
    schedule)
        echo "⏰ crontabに登録中..."
        
        # 現在のcrontabを取得
        crontab -l > /tmp/current_cron 2>/dev/null || true
        
        # 新しいジョブを追加（毎日午前9時と午後6時）
        SCRIPT_PATH="$(pwd)/metrics/scheduler.sh"
        echo "0 9,18 * * * cd $(pwd) && $SCRIPT_PATH collect" >> /tmp/current_cron
        
        # crontabを更新
        crontab /tmp/current_cron
        rm /tmp/current_cron
        
        echo "✅ スケジュール登録完了（毎日9:00, 18:00）"
        crontab -l | grep scheduler.sh
        ;;
        
    unschedule)
        echo "🗑️ スケジュールを削除中..."
        crontab -l | grep -v scheduler.sh | crontab -
        echo "✅ 削除完了"
        ;;
        
    report)
        echo "📄 最新レポートを開いています..."
        LATEST=$(ls -t metrics/reports/metrics_*.json | head -1)
        if [[ -n "$LATEST" ]]; then
            echo "Latest: $LATEST"
            cat "$LATEST" | python3 -m json.tool
        else
            echo "レポートが見つかりません"
        fi
        ;;
        
    dashboard)
        echo "🌐 ダッシュボードを開いています..."
        if command -v open &> /dev/null; then
            open metrics/dashboards/index.html
        elif command -v xdg-open &> /dev/null; then
            xdg-open metrics/dashboards/index.html
        else
            echo "ブラウザで開いてください: metrics/dashboards/index.html"
        fi
        ;;
        
    *)
        echo "使用方法: $0 {collect|schedule|unschedule|report|dashboard}"
        exit 1
        ;;
esac
SCHEDULER_EOF

# 4. Weekly/Monthly レポート生成
cat > metrics/generate-report.js << 'REPORT_EOF'
#!/usr/bin/env node
/**
 * 週次・月次レポート生成
 */

import { promises as fs } from 'fs';
import path from 'path';

async function generateReport(period = 'weekly') {
    const reports = await fs.readdir('metrics/reports');
    const jsonReports = reports.filter(r => r.endsWith('.json'));
    
    // 期間に応じてフィルタリング
    const now = new Date();
    const cutoff = new Date(now);
    
    if (period === 'weekly') {
        cutoff.setDate(cutoff.getDate() - 7);
    } else if (period === 'monthly') {
        cutoff.setMonth(cutoff.getMonth() - 1);
    }
    
    const relevantReports = [];
    
    for (const report of jsonReports) {
        const date = report.match(/metrics_(\d{4}-\d{2}-\d{2})/)?.[1];
        if (date && new Date(date) >= cutoff) {
            const content = JSON.parse(
                await fs.readFile(path.join('metrics/reports', report), 'utf-8')
            );
            relevantReports.push(content);
        }
    }
    
    if (relevantReports.length === 0) {
        console.log('No reports found for the period');
        return;
    }
    
    // 集計
    const summary = {
        period,
        startDate: cutoff.toISOString(),
        endDate: now.toISOString(),
        reportCount: relevantReports.length,
        agents: {},
    };
    
    // Agent別集計
    const agents = ['api', 'logic', 'next', 'expo', 'infra', 'qa', 'uiux', 'security', 'docs'];
    
    for (const agent of agents) {
        const agentData = relevantReports
            .map(r => r.agents[agent])
            .filter(Boolean);
        
        if (agentData.length > 0) {
            const totalTasks = agentData
                .reduce((sum, d) => sum + (d.history?.tasksLast7Days || 0), 0);
            
            const avgProductivity = relevantReports
                .map(r => r.summary?.productivityScores?.[agent] || 0)
                .reduce((sum, score) => sum + score, 0) / relevantReports.length;
            
            summary.agents[agent] = {
                totalTasks,
                avgProductivity: avgProductivity.toFixed(2),
                reportCount: agentData.length,
            };
        }
    }
    
    // Markdown レポート生成
    const markdown = `# SubAgent ${period === 'weekly' ? '週次' : '月次'}レポート

## 期間
- 開始: ${cutoff.toLocaleDateString()}
- 終了: ${now.toLocaleDateString()}
- レポート数: ${relevantReports.length}

## Agent別サマリー

| Agent | タスク数 | 平均生産性 | アクティブ日数 |
|-------|---------|-----------|-------------|
${agents.map(agent => {
    const data = summary.agents[agent];
    if (!data) return null;
    return `| ${agent.toUpperCase()} | ${data.totalTasks} | ${data.avgProductivity}% | ${data.reportCount} |`;
}).filter(Boolean).join('\n')}

## 推奨事項
${generateRecommendations(summary)}

---
*Generated: ${now.toISOString()}*
`;
    
    const reportPath = `metrics/reports/${period}_report_${now.toISOString().split('T')[0]}.md`;
    await fs.writeFile(reportPath, markdown);
    
    console.log(`✅ ${period}レポートを生成しました: ${reportPath}`);
}

function generateRecommendations(summary) {
    const recommendations = [];
    
    Object.entries(summary.agents).forEach(([agent, data]) => {
        if (data.avgProductivity < 50) {
            recommendations.push(`- **${agent}**: 生産性向上が必要（現在: ${data.avgProductivity}%）`);
        }
        if (data.totalTasks === 0) {
            recommendations.push(`- **${agent}**: アクティビティが検出されません`);
        }
    });
    
    if (recommendations.length === 0) {
        recommendations.push('- すべてのAgentが良好に稼働しています');
    }
    
    return recommendations.join('\n');
}

// CLI実行
const period = process.argv[2] || 'weekly';
generateReport(period).catch(console.error);
REPORT_EOF

# 5. package.json
cat > metrics/package.json << 'METRICS_PACKAGE_EOF'
{
  "name": "subagent-metrics",
  "version": "1.0.0",
  "description": "Metrics collection and analysis for SubAgent system",
  "type": "module",
  "scripts": {
    "collect": "node collectors/agent-metrics.js",
    "report:weekly": "node generate-report.js weekly",
    "report:monthly": "node generate-report.js monthly",
    "dashboard": "./scripts/scheduler.sh dashboard",
    "schedule": "./scripts/scheduler.sh schedule"
  },
  "dependencies": {
    "chalk": "^5.3.0"
  }
}
METRICS_PACKAGE_EOF

chmod +x metrics/*.sh
chmod +x metrics/collectors/*.js
chmod +x metrics/*.js

echo "✅ メトリクス収集システムのセットアップが完了しました！"
echo ""
echo "📊 機能一覧:"
echo "  - 自動メトリクス収集"
echo "  - 生産性スコア計算"
echo "  - インタラクティブダッシュボード"
echo "  - 週次/月次レポート生成"
echo ""
echo "🚀 使い方:"
echo "  cd metrics && npm install"
echo "  npm run collect          # メトリクス収集"
echo "  npm run dashboard        # ダッシュボード表示"
echo "  npm run report:weekly    # 週次レポート"
echo "  npm run schedule         # 自動実行設定"
echo ""
echo "📈 ダッシュボード:"
echo "  metrics/dashboards/index.html をブラウザで開く"