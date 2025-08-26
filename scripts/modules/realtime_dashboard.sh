#!/usr/bin/env bash
# リアルタイム監視ダッシュボードのセットアップ
set -euo pipefail

echo "📊 リアルタイム監視ダッシュボードをセットアップ中..."

# 1. ディレクトリ構造
mkdir -p monitor/{server,client,data,logs}

# 2. WebSocketサーバー
cat > monitor/server/monitor-server.js << 'MONITORSERVER_EOF'
#!/usr/bin/env node
/**
 * Real-time Monitoring Server
 * WebSocketによるリアルタイム監視
 */

import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import chokidar from 'chokidar';
import chalk from 'chalk';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

class MonitoringServer {
    constructor(port = 3333) {
        this.port = port;
        this.app = express();
        this.server = createServer(this.app);
        this.io = new Server(this.server, {
            cors: {
                origin: "*",
                methods: ["GET", "POST"]
            }
        });
        
        this.metrics = {
            agents: {},
            system: {},
            tasks: [],
            alerts: []
        };
        
        this.connections = new Set();
        this.watchers = [];
    }

    async initialize() {
        // 静的ファイル配信
        this.app.use(express.static(path.join(__dirname, '../client')));
        this.app.use(express.json());

        // APIエンドポイント
        this.setupAPI();

        // WebSocketハンドラー
        this.setupWebSocket();

        // ファイル監視
        this.setupFileWatchers();

        // メトリクス収集開始
        this.startMetricsCollection();

        // サーバー起動
        this.server.listen(this.port, () => {
            console.log(chalk.green(`✅ Monitoring server running at http://localhost:${this.port}`));
        });
    }

    setupAPI() {
        // メトリクス取得
        this.app.get('/api/metrics', (req, res) => {
            res.json(this.metrics);
        });

        // アラート追加
        this.app.post('/api/alert', (req, res) => {
            const alert = {
                ...req.body,
                timestamp: new Date().toISOString(),
                id: Date.now()
            };
            
            this.metrics.alerts.unshift(alert);
            if (this.metrics.alerts.length > 100) {
                this.metrics.alerts = this.metrics.alerts.slice(0, 100);
            }
            
            this.broadcast('alert', alert);
            res.json({ success: true });
        });

        // タスク追加
        this.app.post('/api/task', (req, res) => {
            const task = {
                ...req.body,
                timestamp: new Date().toISOString(),
                id: Date.now(),
                status: 'pending'
            };
            
            this.metrics.tasks.unshift(task);
            if (this.metrics.tasks.length > 50) {
                this.metrics.tasks = this.metrics.tasks.slice(0, 50);
            }
            
            this.broadcast('task', task);
            res.json({ success: true });
        });
    }

    setupWebSocket() {
        this.io.on('connection', (socket) => {
            console.log(chalk.blue(`👤 Client connected: ${socket.id}`));
            this.connections.add(socket);

            // 初期データ送信
            socket.emit('initial', this.metrics);

            // クライアントからのイベント
            socket.on('request-update', () => {
                socket.emit('metrics-update', this.metrics);
            });

            socket.on('execute-command', async (command) => {
                const result = await this.executeCommand(command);
                socket.emit('command-result', result);
            });

            socket.on('disconnect', () => {
                console.log(chalk.gray(`👤 Client disconnected: ${socket.id}`));
                this.connections.delete(socket);
            });
        });
    }

    setupFileWatchers() {
        // HISTORYファイルの監視
        const historyWatcher = chokidar.watch('docs/agents/*/HISTORY.md', {
            persistent: true,
            ignoreInitial: true
        });

        historyWatcher.on('change', async (filepath) => {
            const agent = path.basename(path.dirname(filepath));
            console.log(chalk.yellow(`📝 History updated: ${agent}`));
            
            await this.updateAgentMetrics(agent);
            this.broadcast('agent-update', {
                agent,
                metrics: this.metrics.agents[agent]
            });
        });

        this.watchers.push(historyWatcher);

        // ログファイルの監視
        const logWatcher = chokidar.watch('.claude/.claude/pm/logs/*.json', {
            persistent: true,
            ignoreInitial: true
        });

        logWatcher.on('add', async (filepath) => {
            console.log(chalk.cyan(`📋 New log: ${path.basename(filepath)}`));
            
            const content = await fs.readFile(filepath, 'utf-8');
            const logs = JSON.parse(content);
            
            this.broadcast('new-logs', logs);
        });

        this.watchers.push(logWatcher);
    }

    async startMetricsCollection() {
        // 初期メトリクス収集
        await this.collectAllMetrics();

        // 定期更新（10秒ごと）
        setInterval(async () => {
            await this.collectSystemMetrics();
            this.broadcast('system-metrics', this.metrics.system);
        }, 10000);

        // Agent メトリクス更新（1分ごと）
        setInterval(async () => {
            await this.collectAllMetrics();
            this.broadcast('metrics-update', this.metrics);
        }, 60000);
    }

    async collectAllMetrics() {
        const agents = ['api', 'logic', 'next', 'expo', 'infra', 'qa', 'uiux', 'security', 'docs'];
        
        for (const agent of agents) {
            await this.updateAgentMetrics(agent);
        }
        
        await this.collectSystemMetrics();
        await this.collectRecentTasks();
    }

    async updateAgentMetrics(agent) {
        const metrics = {
            name: agent,
            status: 'unknown',
            lastActivity: null,
            tasksToday: 0,
            tasksWeek: 0,
            health: 100,
            issues: []
        };

        try {
            // HISTORY.md から最新アクティビティを取得
            const historyPath = `docs/agents/${agent}/HISTORY.md`;
            const content = await fs.readFile(historyPath, 'utf-8');
            
            const entries = content.match(/^## (\d{4}-\d{2}-\d{2}T[\d:+-]+)/gm) || [];
            if (entries.length > 0) {
                const lastDate = new Date(entries[entries.length - 1].replace('## ', ''));
                metrics.lastActivity = lastDate.toISOString();
                
                const now = new Date();
                const today = new Date(now.toDateString());
                const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
                
                metrics.tasksToday = entries.filter(e => {
                    const date = new Date(e.replace('## ', ''));
                    return date >= today;
                }).length;
                
                metrics.tasksWeek = entries.filter(e => {
                    const date = new Date(e.replace('## ', ''));
                    return date >= weekAgo;
                }).length;
                
                // ステータス判定
                const hoursSinceLastActivity = (now - lastDate) / (1000 * 60 * 60);
                if (hoursSinceLastActivity < 24) {
                    metrics.status = 'active';
                } else if (hoursSinceLastActivity < 72) {
                    metrics.status = 'idle';
                } else {
                    metrics.status = 'inactive';
                    metrics.issues.push('3日以上アクティビティなし');
                    metrics.health -= 30;
                }
            }

            // CHECKLIST.md の完了状態を確認
            const checklistPath = `docs/agents/${agent}/CHECKLIST.md`;
            const checklist = await fs.readFile(checklistPath, 'utf-8');
            
            const totalChecks = (checklist.match(/- \[[ x]\]/gi) || []).length;
            const completedChecks = (checklist.match(/- \[x\]/gi) || []).length;
            
            if (totalChecks > 0) {
                const completionRate = completedChecks / totalChecks;
                if (completionRate < 0.5) {
                    metrics.issues.push(`チェックリスト完了率低 (${Math.round(completionRate * 100)}%)`);
                    metrics.health -= 20;
                }
            }

            // REQUIREMENTS.md の更新状態を確認
            const reqPath = `docs/agents/${agent}/REQUIREMENTS.md`;
            const reqStats = await fs.stat(reqPath);
            const daysSinceUpdate = (Date.now() - reqStats.mtime) / (1000 * 60 * 60 * 24);
            
            if (daysSinceUpdate > 30) {
                metrics.issues.push(`要件定義が${Math.round(daysSinceUpdate)}日間未更新`);
                metrics.health -= 10;
            }

        } catch (error) {
            metrics.status = 'error';
            metrics.issues.push('メトリクス収集エラー');
            metrics.health = 0;
        }

        this.metrics.agents[agent] = metrics;
    }

    async collectSystemMetrics() {
        const memUsage = process.memoryUsage();
        
        this.metrics.system = {
            timestamp: new Date().toISOString(),
            memory: {
                rss: Math.round(memUsage.rss / 1024 / 1024),
                heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024),
                heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024)
            },
            uptime: process.uptime(),
            connections: this.connections.size,
            cpu: process.cpuUsage()
        };

        // Git統計
        try {
            const { execSync } = await import('child_process');
            const commitCount = execSync('git rev-list --count HEAD', { encoding: 'utf-8' }).trim();
            const branch = execSync('git branch --show-current', { encoding: 'utf-8' }).trim();
            
            this.metrics.system.git = {
                commits: parseInt(commitCount),
                branch
            };
        } catch (e) {
            // Git統計は失敗しても続行
        }
    }

    async collectRecentTasks() {
        try {
            // 最新のPMログから取得
            const logsDir = '.claude/.claude/pm/logs';
            const files = await fs.readdir(logsDir);
            const jsonFiles = files.filter(f => f.endsWith('.json')).sort().reverse();
            
            if (jsonFiles.length > 0) {
                const latestLog = JSON.parse(
                    await fs.readFile(path.join(logsDir, jsonFiles[0]), 'utf-8')
                );
                
                // 配列かオブジェクトかチェック
                const logs = Array.isArray(latestLog) ? latestLog : [latestLog];
                
                this.metrics.tasks = logs.slice(0, 20).map(log => ({
                    timestamp: log.timestamp,
                    agent: log.result?.route || 'unknown',
                    task: log.message || log.normalized_task || 'Unknown task',
                    confidence: log.result?.confidence || 0,
                    status: log.result?.route === 'human_review' ? 'review' : 'routed'
                }));
            }
        } catch (e) {
            // エラーは無視
        }
    }

    async executeCommand(command) {
        console.log(chalk.magenta(`⚡ Executing: ${command.type}`));
        
        try {
            switch (command.type) {
                case 'refresh-metrics':
                    await this.collectAllMetrics();
                    return { success: true, message: 'Metrics refreshed' };
                    
                case 'clear-alerts':
                    this.metrics.alerts = [];
                    this.broadcast('alerts-cleared', {});
                    return { success: true, message: 'Alerts cleared' };
                    
                case 'trigger-test':
                    const testAlert = {
                        level: 'info',
                        message: 'Test alert triggered',
                        agent: 'system',
                        timestamp: new Date().toISOString(),
                        id: Date.now()
                    };
                    this.metrics.alerts.unshift(testAlert);
                    this.broadcast('alert', testAlert);
                    return { success: true, message: 'Test alert sent' };
                    
                default:
                    return { success: false, message: 'Unknown command' };
            }
        } catch (error) {
            return { success: false, message: error.message };
        }
    }

    broadcast(event, data) {
        this.io.emit(event, data);
    }

    async shutdown() {
        console.log(chalk.yellow('\n🛑 Shutting down monitoring server...'));
        
        // Watcherをクリーンアップ
        for (const watcher of this.watchers) {
            await watcher.close();
        }
        
        // WebSocket接続を閉じる
        this.io.close();
        
        // HTTPサーバーを閉じる
        this.server.close();
        
        console.log(chalk.green('✅ Server shutdown complete'));
    }
}

// メイン実行
const server = new MonitoringServer(process.env.MONITOR_PORT || 3333);

server.initialize().catch(console.error);

// グレースフルシャットダウン
process.on('SIGINT', async () => {
    await server.shutdown();
    process.exit(0);
});

process.on('SIGTERM', async () => {
    await server.shutdown();
    process.exit(0);
});
MONITORSERVER_EOF

# 3. クライアント（ダッシュボード）
cat > monitor/client/index.html << 'DASHBOARD_EOF'
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SubAgent Monitoring Dashboard</title>
    <script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: #fff;
            min-height: 100vh;
        }
        
        .header {
            background: rgba(0,0,0,0.3);
            padding: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            backdrop-filter: blur(10px);
        }
        
        .header h1 {
            font-size: 24px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .status-indicator {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #4ade80;
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        
        .connection-status {
            padding: 8px 16px;
            background: rgba(74, 222, 128, 0.2);
            border: 1px solid #4ade80;
            border-radius: 20px;
            font-size: 14px;
        }
        
        .connection-status.disconnected {
            background: rgba(248, 113, 113, 0.2);
            border-color: #f87171;
        }
        
        .dashboard {
            padding: 20px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
        
        .card {
            background: rgba(255,255,255,0.1);
            backdrop-filter: blur(10px);
            border-radius: 12px;
            padding: 20px;
            border: 1px solid rgba(255,255,255,0.2);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        }
        
        .card h2 {
            font-size: 18px;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .agent-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
            gap: 10px;
        }
        
        .agent-card {
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 8px;
            padding: 12px;
            text-align: center;
            transition: all 0.3s ease;
            cursor: pointer;
        }
        
        .agent-card:hover {
            background: rgba(255,255,255,0.1);
            transform: scale(1.05);
        }
        
        .agent-name {
            font-weight: bold;
            text-transform: uppercase;
            margin-bottom: 8px;
        }
        
        .agent-status {
            display: inline-block;
            width: 8px;
            height: 8px;
            border-radius: 50%;
            margin-right: 4px;
        }
        
        .status-active { background: #4ade80; }
        .status-idle { background: #facc15; }
        .status-inactive { background: #f87171; }
        .status-error { background: #991b1b; }
        
        .metric-value {
            font-size: 24px;
            font-weight: bold;
            margin: 10px 0;
        }
        
        .metric-label {
            font-size: 12px;
            opacity: 0.8;
        }
        
        .task-list {
            max-height: 300px;
            overflow-y: auto;
        }
        
        .task-item {
            background: rgba(255,255,255,0.05);
            border-radius: 6px;
            padding: 10px;
            margin-bottom: 8px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 14px;
        }
        
        .task-agent {
            background: rgba(255,255,255,0.2);
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 12px;
        }
        
        .alert-list {
            max-height: 200px;
            overflow-y: auto;
        }
        
        .alert-item {
            padding: 10px;
            margin-bottom: 8px;
            border-radius: 6px;
            font-size: 14px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .alert-info {
            background: rgba(96, 165, 250, 0.2);
            border-left: 3px solid #60a5fa;
        }
        
        .alert-warning {
            background: rgba(251, 191, 36, 0.2);
            border-left: 3px solid #fbbf24;
        }
        
        .alert-error {
            background: rgba(248, 113, 113, 0.2);
            border-left: 3px solid #f87171;
        }
        
        .controls {
            display: flex;
            gap: 10px;
            margin-top: 15px;
        }
        
        .btn {
            background: rgba(255,255,255,0.2);
            border: 1px solid rgba(255,255,255,0.3);
            color: white;
            padding: 8px 16px;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.3s ease;
            font-size: 14px;
        }
        
        .btn:hover {
            background: rgba(255,255,255,0.3);
            transform: translateY(-2px);
        }
        
        .chart-container {
            position: relative;
            height: 200px;
            margin-top: 15px;
        }
        
        .grid-full {
            grid-column: 1 / -1;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            margin-top: 15px;
        }
        
        .stat-box {
            text-align: center;
            padding: 15px;
            background: rgba(255,255,255,0.05);
            border-radius: 8px;
        }
        
        .health-bar {
            width: 100%;
            height: 8px;
            background: rgba(255,255,255,0.1);
            border-radius: 4px;
            overflow: hidden;
            margin-top: 5px;
        }
        
        .health-fill {
            height: 100%;
            transition: width 0.5s ease;
        }
        
        .health-good { background: #4ade80; }
        .health-warning { background: #facc15; }
        .health-critical { background: #f87171; }
        
        .time-display {
            font-family: 'Courier New', monospace;
            font-size: 14px;
            opacity: 0.8;
        }

        /* スクロールバーのスタイリング */
        ::-webkit-scrollbar {
            width: 8px;
            height: 8px;
        }
        
        ::-webkit-scrollbar-track {
            background: rgba(255,255,255,0.1);
            border-radius: 4px;
        }
        
        ::-webkit-scrollbar-thumb {
            background: rgba(255,255,255,0.3);
            border-radius: 4px;
        }
        
        ::-webkit-scrollbar-thumb:hover {
            background: rgba(255,255,255,0.5);
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>
            <span class="status-indicator"></span>
            SubAgent Monitoring Dashboard
        </h1>
        <div class="connection-status" id="connectionStatus">
            🟢 Connected
        </div>
    </div>

    <div class="dashboard">
        <!-- System Overview -->
        <div class="card grid-full">
            <h2>📊 System Overview</h2>
            <div class="stats-grid">
                <div class="stat-box">
                    <div class="metric-label">Active Agents</div>
                    <div class="metric-value" id="activeAgents">0</div>
                </div>
                <div class="stat-box">
                    <div class="metric-label">Tasks Today</div>
                    <div class="metric-value" id="tasksToday">0</div>
                </div>
                <div class="stat-box">
                    <div class="metric-label">System Health</div>
                    <div class="metric-value" id="systemHealth">100%</div>
                    <div class="health-bar">
                        <div class="health-fill health-good" id="healthBar" style="width: 100%"></div>
                    </div>
                </div>
                <div class="stat-box">
                    <div class="metric-label">Uptime</div>
                    <div class="metric-value time-display" id="uptime">00:00:00</div>
                </div>
            </div>
        </div>

        <!-- Agents Status -->
        <div class="card grid-full">
            <h2>🤖 Agents Status</h2>
            <div class="agent-grid" id="agentGrid">
                <!-- Dynamically populated -->
            </div>
        </div>

        <!-- Recent Tasks -->
        <div class="card">
            <h2>📋 Recent Tasks</h2>
            <div class="task-list" id="taskList">
                <!-- Dynamically populated -->
            </div>
        </div>

        <!-- Alerts -->
        <div class="card">
            <h2>🔔 Alerts</h2>
            <div class="alert-list" id="alertList">
                <!-- Dynamically populated -->
            </div>
            <div class="controls">
                <button class="btn" onclick="clearAlerts()">Clear All</button>
                <button class="btn" onclick="testAlert()">Test Alert</button>
            </div>
        </div>

        <!-- Activity Chart -->
        <div class="card grid-full">
            <h2>📈 Activity Timeline</h2>
            <div class="chart-container">
                <canvas id="activityChart"></canvas>
            </div>
        </div>

        <!-- System Metrics -->
        <div class="card">
            <h2>💻 System Metrics</h2>
            <div class="chart-container">
                <canvas id="memoryChart"></canvas>
            </div>
        </div>

        <!-- Controls -->
        <div class="card">
            <h2>⚙️ Controls</h2>
            <div class="controls">
                <button class="btn" onclick="refreshMetrics()">🔄 Refresh</button>
                <button class="btn" onclick="exportData()">📥 Export</button>
                <button class="btn" onclick="toggleAutoRefresh()">⏸️ Auto Refresh</button>
            </div>
            <div style="margin-top: 15px; font-size: 12px; opacity: 0.7;">
                Last Update: <span id="lastUpdate" class="time-display">-</span>
            </div>
        </div>
    </div>

    <script>
        // WebSocket接続
        const socket = io('http://localhost:3333');
        
        // グローバル状態
        let metrics = {};
        let autoRefresh = true;
        let charts = {};

        // 初期化
        socket.on('connect', () => {
            console.log('Connected to monitoring server');
            updateConnectionStatus(true);
        });

        socket.on('disconnect', () => {
            console.log('Disconnected from monitoring server');
            updateConnectionStatus(false);
        });

        socket.on('initial', (data) => {
            metrics = data;
            updateDashboard();
            initCharts();
        });

        socket.on('metrics-update', (data) => {
            metrics = data;
            updateDashboard();
        });

        socket.on('agent-update', (data) => {
            if (metrics.agents) {
                metrics.agents[data.agent] = data.metrics;
                updateAgentGrid();
            }
        });

        socket.on('alert', (alert) => {
            if (!metrics.alerts) metrics.alerts = [];
            metrics.alerts.unshift(alert);
            updateAlerts();
            showNotification(alert);
        });

        socket.on('task', (task) => {
            if (!metrics.tasks) metrics.tasks = [];
            metrics.tasks.unshift(task);
            updateTasks();
        });

        socket.on('system-metrics', (data) => {
            metrics.system = data;
            updateSystemMetrics();
        });

        // UI更新関数
        function updateDashboard() {
            updateOverview();
            updateAgentGrid();
            updateTasks();
            updateAlerts();
            updateSystemMetrics();
            updateCharts();
            
            document.getElementById('lastUpdate').textContent = 
                new Date().toLocaleTimeString();
        }

        function updateOverview() {
            if (!metrics.agents) return;

            const agents = Object.values(metrics.agents);
            const activeAgents = agents.filter(a => a.status === 'active').length;
            const tasksToday = agents.reduce((sum, a) => sum + (a.tasksToday || 0), 0);
            const avgHealth = agents.reduce((sum, a) => sum + (a.health || 0), 0) / agents.length;

            document.getElementById('activeAgents').textContent = activeAgents;
            document.getElementById('tasksToday').textContent = tasksToday;
            document.getElementById('systemHealth').textContent = Math.round(avgHealth) + '%';
            
            const healthBar = document.getElementById('healthBar');
            healthBar.style.width = avgHealth + '%';
            healthBar.className = 'health-fill ' + 
                (avgHealth >= 70 ? 'health-good' : 
                 avgHealth >= 40 ? 'health-warning' : 'health-critical');

            if (metrics.system?.uptime) {
                const uptime = Math.floor(metrics.system.uptime);
                const hours = Math.floor(uptime / 3600);
                const minutes = Math.floor((uptime % 3600) / 60);
                const seconds = uptime % 60;
                document.getElementById('uptime').textContent = 
                    `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
            }
        }

        function updateAgentGrid() {
            const grid = document.getElementById('agentGrid');
            if (!metrics.agents) return;

            grid.innerHTML = Object.entries(metrics.agents).map(([name, agent]) => `
                <div class="agent-card" onclick="showAgentDetails('${name}')">
                    <div class="agent-name">
                        <span class="agent-status status-${agent.status}"></span>
                        ${name}
                    </div>
                    <div style="font-size: 20px; margin: 8px 0;">
                        ${agent.tasksWeek || 0}
                    </div>
                    <div class="metric-label">tasks/week</div>
                    <div class="health-bar">
                        <div class="health-fill ${agent.health >= 70 ? 'health-good' : agent.health >= 40 ? 'health-warning' : 'health-critical'}" 
                             style="width: ${agent.health}%"></div>
                    </div>
                </div>
            `).join('');
        }

        function updateTasks() {
            const list = document.getElementById('taskList');
            if (!metrics.tasks || metrics.tasks.length === 0) {
                list.innerHTML = '<div style="opacity: 0.5; text-align: center;">No recent tasks</div>';
                return;
            }

            list.innerHTML = metrics.tasks.slice(0, 10).map(task => `
                <div class="task-item">
                    <div>
                        <div>${task.task ? task.task.substring(0, 50) + '...' : 'Unknown task'}</div>
                        <div style="font-size: 11px; opacity: 0.7;">
                            ${new Date(task.timestamp).toLocaleTimeString()}
                        </div>
                    </div>
                    <div class="task-agent">${task.agent}</div>
                </div>
            `).join('');
        }

        function updateAlerts() {
            const list = document.getElementById('alertList');
            if (!metrics.alerts || metrics.alerts.length === 0) {
                list.innerHTML = '<div style="opacity: 0.5; text-align: center;">No alerts</div>';
                return;
            }

            list.innerHTML = metrics.alerts.slice(0, 5).map(alert => `
                <div class="alert-item alert-${alert.level || 'info'}">
                    <div>
                        <div>${alert.message}</div>
                        <div style="font-size: 11px; opacity: 0.7;">
                            ${new Date(alert.timestamp).toLocaleTimeString()}
                            ${alert.agent ? ` - ${alert.agent}` : ''}
                        </div>
                    </div>
                </div>
            `).join('');
        }

        function updateSystemMetrics() {
            if (!metrics.system) return;

            // メモリチャート更新
            if (charts.memory) {
                const data = charts.memory.data;
                const now = new Date().toLocaleTimeString();
                
                if (data.labels.length > 10) {
                    data.labels.shift();
                    data.datasets[0].data.shift();
                    data.datasets[1].data.shift();
                }
                
                data.labels.push(now);
                data.datasets[0].data.push(metrics.system.memory.heapUsed);
                data.datasets[1].data.push(metrics.system.memory.heapTotal);
                
                charts.memory.update();
            }
        }

        function initCharts() {
            // Activity Chart
            const activityCtx = document.getElementById('activityChart').getContext('2d');
            charts.activity = new Chart(activityCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Tasks',
                        data: [],
                        borderColor: 'rgba(74, 222, 128, 1)',
                        backgroundColor: 'rgba(74, 222, 128, 0.1)',
                        tension: 0.4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            labels: { color: 'white' }
                        }
                    },
                    scales: {
                        x: {
                            grid: { color: 'rgba(255,255,255,0.1)' },
                            ticks: { color: 'white' }
                        },
                        y: {
                            grid: { color: 'rgba(255,255,255,0.1)' },
                            ticks: { color: 'white' }
                        }
                    }
                }
            });

            // Memory Chart
            const memoryCtx = document.getElementById('memoryChart').getContext('2d');
            charts.memory = new Chart(memoryCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [
                        {
                            label: 'Heap Used',
                            data: [],
                            borderColor: 'rgba(96, 165, 250, 1)',
                            backgroundColor: 'rgba(96, 165, 250, 0.1)',
                            tension: 0.4
                        },
                        {
                            label: 'Heap Total',
                            data: [],
                            borderColor: 'rgba(251, 191, 36, 1)',
                            backgroundColor: 'rgba(251, 191, 36, 0.1)',
                            tension: 0.4
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            labels: { color: 'white' }
                        }
                    },
                    scales: {
                        x: {
                            grid: { color: 'rgba(255,255,255,0.1)' },
                            ticks: { color: 'white' }
                        },
                        y: {
                            grid: { color: 'rgba(255,255,255,0.1)' },
                            ticks: { color: 'white' }
                        }
                    }
                }
            });
        }

        function updateCharts() {
            if (!metrics.agents) return;

            // Activity chart update
            if (charts.activity) {
                const agents = Object.keys(metrics.agents);
                const tasksData = agents.map(agent => 
                    metrics.agents[agent].tasksWeek || 0
                );

                charts.activity.data.labels = agents;
                charts.activity.data.datasets[0].data = tasksData;
                charts.activity.update();
            }
        }

        function updateConnectionStatus(connected) {
            const status = document.getElementById('connectionStatus');
            if (connected) {
                status.textContent = '🟢 Connected';
                status.className = 'connection-status';
            } else {
                status.textContent = '🔴 Disconnected';
                status.className = 'connection-status disconnected';
            }
        }

        function showNotification(alert) {
            if ('Notification' in window && Notification.permission === 'granted') {
                new Notification('SubAgent Alert', {
                    body: alert.message,
                    icon: '/favicon.ico'
                });
            }
        }

        function showAgentDetails(agent) {
            const details = metrics.agents[agent];
            if (!details) return;

            alert(`
Agent: ${agent.toUpperCase()}
Status: ${details.status}
Health: ${details.health}%
Tasks Today: ${details.tasksToday}
Tasks This Week: ${details.tasksWeek}
Last Activity: ${details.lastActivity ? new Date(details.lastActivity).toLocaleString() : 'Never'}
Issues: ${details.issues.length > 0 ? details.issues.join(', ') : 'None'}
            `);
        }

        // Control functions
        function refreshMetrics() {
            socket.emit('request-update');
        }

        function clearAlerts() {
            socket.emit('execute-command', { type: 'clear-alerts' });
            metrics.alerts = [];
            updateAlerts();
        }

        function testAlert() {
            socket.emit('execute-command', { type: 'trigger-test' });
        }

        function toggleAutoRefresh() {
            autoRefresh = !autoRefresh;
            console.log('Auto refresh:', autoRefresh);
        }

        function exportData() {
            const dataStr = JSON.stringify(metrics, null, 2);
            const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);
            
            const exportFileDefaultName = `metrics_${new Date().toISOString()}.json`;
            
            const linkElement = document.createElement('a');
            linkElement.setAttribute('href', dataUri);
            linkElement.setAttribute('download', exportFileDefaultName);
            linkElement.click();
        }

        // 通知権限リクエスト
        if ('Notification' in window && Notification.permission === 'default') {
            Notification.requestPermission();
        }

        // 自動更新
        setInterval(() => {
            if (autoRefresh) {
                socket.emit('request-update');
            }
        }, 30000); // 30秒ごと
    </script>
</body>
</html>
DASHBOARD_EOF

# 4. Package.json
cat > monitor/package.json << 'MONITOR_PACKAGE_EOF'
{
  "name": "subagent-monitor",
  "version": "1.0.0",
  "description": "Real-time monitoring dashboard for SubAgent",
  "type": "module",
  "scripts": {
    "start": "node server/monitor-server.js",
    "dev": "node --watch server/monitor-server.js",
    "open": "open http://localhost:3333"
  },
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.6.1",
    "chokidar": "^3.5.3",
    "chalk": "^5.3.0"
  }
}
MONITOR_PACKAGE_EOF

# 5. 起動スクリプト
cat > monitor/start-monitor.sh << 'STARTMONITOR_EOF'
#!/usr/bin/env bash
# 監視ダッシュボード起動
set -euo pipefail

echo "🚀 監視ダッシュボードを起動中..."

# ポート設定
PORT="${MONITOR_PORT:-3333}"

# Node.js確認
if ! command -v node &> /dev/null; then
    echo "❌ Node.jsがインストールされていません"
    exit 1
fi

# 依存関係インストール
if [[ ! -d "node_modules" ]]; then
    echo "📦 依存関係をインストール中..."
    npm install
fi

# サーバー起動
echo "✅ サーバーを起動します (Port: $PORT)"
echo "📊 ダッシュボード: http://localhost:$PORT"
echo ""
echo "停止: Ctrl+C"
echo ""

MONITOR_PORT=$PORT node server/monitor-server.js
STARTMONITOR_EOF

chmod +x monitor/*.sh

echo "✅ リアルタイム監視ダッシュボードのセットアップが完了しました！"
echo ""
echo "📊 機能:"
echo "  - リアルタイムAgent状態監視"
echo "  - タスク追跡とアラート"
echo "  - システムメトリクス可視化"
echo "  - WebSocketによるライブ更新"
echo ""
echo "🚀 起動方法:"
echo "  cd monitor && npm install"
echo "  npm start                # サーバー起動"
echo "  npm run open            # ブラウザで開く"
echo ""
echo "📱 アクセス:"
echo "  http://localhost:3333"