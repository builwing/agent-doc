#!/usr/bin/env bash
# MCP（Model Context Protocol）ツール連携のセットアップ
set -euo pipefail

echo "🔧 MCPツール連携をセットアップ中..."

# 1. MCPサーバー設定ディレクトリ
mkdir -p mcp/{servers,tools,configs}

# 2. ドキュメント読み取りMCPサーバー
cat > mcp/servers/doc-reader.js << 'DOCREADER_EOF'
#!/usr/bin/env node
/**
 * Document Reader MCP Server
 * SubAgent用のドキュメント読み取り・要約サーバー
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { promises as fs } from 'fs';
import path from 'path';
import { glob } from 'glob';

class DocReaderServer {
    constructor() {
        this.server = new Server(
            {
                name: 'doc-reader',
                version: '1.0.0',
            },
            {
                capabilities: {
                    tools: {},
                },
            }
        );
        
        this.setupTools();
    }

    setupTools() {
        // ツール1: ドキュメントインデックス取得
        this.server.setRequestHandler('tools/list', async () => ({
            tools: [
                {
                    name: 'doc_index',
                    description: 'Get index of all agent documentation',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            agent: {
                                type: 'string',
                                description: 'Agent name (api, next, expo, etc.) or "all"',
                            },
                            type: {
                                type: 'string',
                                enum: ['REQUIREMENTS', 'CHECKLIST', 'HISTORY', 'all'],
                                description: 'Document type to retrieve',
                            },
                        },
                        required: ['agent'],
                    },
                },
                {
                    name: 'doc_read',
                    description: 'Read specific agent documentation',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            path: {
                                type: 'string',
                                description: 'Path to document (e.g., docs/agents/api/REQUIREMENTS.md)',
                            },
                            section: {
                                type: 'string',
                                description: 'Specific section to extract (optional)',
                            },
                        },
                        required: ['path'],
                    },
                },
                {
                    name: 'doc_summarize',
                    description: 'Summarize agent documentation',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            agent: {
                                type: 'string',
                                description: 'Agent name',
                            },
                            max_lines: {
                                type: 'number',
                                description: 'Maximum lines for summary',
                                default: 10,
                            },
                        },
                        required: ['agent'],
                    },
                },
                {
                    name: 'doc_search',
                    description: 'Search across all documentation',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            query: {
                                type: 'string',
                                description: 'Search query',
                            },
                            agent: {
                                type: 'string',
                                description: 'Limit to specific agent (optional)',
                            },
                        },
                        required: ['query'],
                    },
                },
            ],
        }));

        // ツール実行ハンドラ
        this.server.setRequestHandler('tools/call', async (request) => {
            const { name, arguments: args } = request.params;

            try {
                switch (name) {
                    case 'doc_index':
                        return await this.getDocIndex(args);
                    case 'doc_read':
                        return await this.readDoc(args);
                    case 'doc_summarize':
                        return await this.summarizeDoc(args);
                    case 'doc_search':
                        return await this.searchDocs(args);
                    default:
                        throw new Error(`Unknown tool: ${name}`);
                }
            } catch (error) {
                return {
                    content: [
                        {
                            type: 'text',
                            text: `Error: ${error.message}`,
                        },
                    ],
                };
            }
        });
    }

    async getDocIndex(args) {
        const { agent = 'all', type = 'all' } = args;
        const basePath = 'docs/agents';
        
        let agents = agent === 'all' 
            ? ['api', 'logic', 'next', 'expo', 'infra', 'qa', 'uiux', 'security', 'docs']
            : [agent];
        
        let docTypes = type === 'all'
            ? ['REQUIREMENTS.md', 'CHECKLIST.md', 'HISTORY.md']
            : [`${type}.md`];
        
        const index = [];
        
        for (const ag of agents) {
            for (const dt of docTypes) {
                const filePath = path.join(basePath, ag, dt);
                try {
                    const stats = await fs.stat(filePath);
                    const content = await fs.readFile(filePath, 'utf-8');
                    const lines = content.split('\n');
                    
                    index.push({
                        agent: ag,
                        type: dt.replace('.md', ''),
                        path: filePath,
                        size: stats.size,
                        modified: stats.mtime,
                        lines: lines.length,
                        preview: lines.slice(0, 5).join('\n'),
                    });
                } catch (e) {
                    // ファイルが存在しない場合はスキップ
                }
            }
        }
        
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(index, null, 2),
                },
            ],
        };
    }

    async readDoc(args) {
        const { path: docPath, section } = args;
        
        try {
            const content = await fs.readFile(docPath, 'utf-8');
            
            if (section) {
                // セクション抽出
                const lines = content.split('\n');
                const sectionStart = lines.findIndex(line => 
                    line.trim().toLowerCase() === `# ${section.toLowerCase()}` ||
                    line.trim().toLowerCase() === `## ${section.toLowerCase()}`
                );
                
                if (sectionStart === -1) {
                    throw new Error(`Section "${section}" not found`);
                }
                
                const sectionEnd = lines.findIndex((line, idx) => 
                    idx > sectionStart && line.trim().startsWith('#')
                );
                
                const sectionContent = lines.slice(
                    sectionStart,
                    sectionEnd === -1 ? undefined : sectionEnd
                ).join('\n');
                
                return {
                    content: [
                        {
                            type: 'text',
                            text: sectionContent,
                        },
                    ],
                };
            }
            
            return {
                content: [
                    {
                        type: 'text',
                        text: content,
                    },
                ],
            };
        } catch (error) {
            throw new Error(`Failed to read ${docPath}: ${error.message}`);
        }
    }

    async summarizeDoc(args) {
        const { agent, max_lines = 10 } = args;
        const reqPath = path.join('docs/agents', agent, 'REQUIREMENTS.md');
        
        try {
            const content = await fs.readFile(reqPath, 'utf-8');
            const lines = content.split('\n');
            
            // 重要なセクションを抽出
            const summary = [];
            const importantSections = ['# 目的', '# 受け入れ基準', '# 技術スタック'];
            
            for (const section of importantSections) {
                const sectionIdx = lines.findIndex(line => line.trim() === section);
                if (sectionIdx !== -1) {
                    // セクションのヘッダーと最初の数行を取得
                    summary.push(lines[sectionIdx]);
                    for (let i = sectionIdx + 1; i < lines.length && i < sectionIdx + 4; i++) {
                        if (lines[i].trim().startsWith('#')) break;
                        if (lines[i].trim()) summary.push(lines[i]);
                    }
                }
            }
            
            // max_lines に収める
            const result = summary.slice(0, max_lines).join('\n');
            
            return {
                content: [
                    {
                        type: 'text',
                        text: result,
                    },
                ],
            };
        } catch (error) {
            throw new Error(`Failed to summarize ${agent}: ${error.message}`);
        }
    }

    async searchDocs(args) {
        const { query, agent } = args;
        const searchPattern = agent 
            ? `docs/agents/${agent}/*.md`
            : 'docs/agents/**/*.md';
        
        const files = await glob(searchPattern);
        const results = [];
        
        for (const file of files) {
            try {
                const content = await fs.readFile(file, 'utf-8');
                const lines = content.split('\n');
                
                lines.forEach((line, idx) => {
                    if (line.toLowerCase().includes(query.toLowerCase())) {
                        results.push({
                            file,
                            line: idx + 1,
                            content: line.trim(),
                            context: lines.slice(Math.max(0, idx - 1), idx + 2).join('\n'),
                        });
                    }
                });
            } catch (e) {
                // エラーは無視
            }
        }
        
        return {
            content: [
                {
                    type: 'text',
                    text: JSON.stringify(results.slice(0, 20), null, 2),
                },
            ],
        };
    }

    async run() {
        const transport = new StdioServerTransport();
        await this.server.connect(transport);
        console.error('Doc Reader MCP Server started');
    }
}

// 実行
const server = new DocReaderServer();
server.run().catch(console.error);
DOCREADER_EOF

# 3. 作業記録MCPサーバー
cat > mcp/servers/history-logger.js << 'LOGGER_EOF'
#!/usr/bin/env node
/**
 * History Logger MCP Server
 * SubAgent作業履歴の自動記録
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { promises as fs } from 'fs';
import path from 'path';
import { execSync } from 'child_process';

class HistoryLoggerServer {
    constructor() {
        this.server = new Server(
            {
                name: 'history-logger',
                version: '1.0.0',
            },
            {
                capabilities: {
                    tools: {},
                },
            }
        );
        
        this.setupTools();
    }

    setupTools() {
        this.server.setRequestHandler('tools/list', async () => ({
            tools: [
                {
                    name: 'log_task',
                    description: 'Log completed task to agent history',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            agent: {
                                type: 'string',
                                description: 'Agent name',
                            },
                            task: {
                                type: 'string',
                                description: 'Task description',
                            },
                            refs: {
                                type: 'array',
                                items: { type: 'string' },
                                description: 'Reference documents or files',
                            },
                            commits: {
                                type: 'array',
                                items: { type: 'string' },
                                description: 'Git commit hashes',
                            },
                            notes: {
                                type: 'string',
                                description: 'Additional notes',
                            },
                            metrics: {
                                type: 'object',
                                description: 'Performance metrics',
                            },
                        },
                        required: ['agent', 'task'],
                    },
                },
                {
                    name: 'get_history',
                    description: 'Retrieve agent work history',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            agent: {
                                type: 'string',
                                description: 'Agent name',
                            },
                            days: {
                                type: 'number',
                                description: 'Number of days to retrieve',
                                default: 7,
                            },
                        },
                        required: ['agent'],
                    },
                },
                {
                    name: 'generate_report',
                    description: 'Generate work report for agents',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            period: {
                                type: 'string',
                                enum: ['daily', 'weekly', 'monthly'],
                                description: 'Report period',
                            },
                            agents: {
                                type: 'array',
                                items: { type: 'string' },
                                description: 'Agents to include (empty for all)',
                            },
                        },
                        required: ['period'],
                    },
                },
            ],
        }));

        this.server.setRequestHandler('tools/call', async (request) => {
            const { name, arguments: args } = request.params;

            try {
                switch (name) {
                    case 'log_task':
                        return await this.logTask(args);
                    case 'get_history':
                        return await this.getHistory(args);
                    case 'generate_report':
                        return await this.generateReport(args);
                    default:
                        throw new Error(`Unknown tool: ${name}`);
                }
            } catch (error) {
                return {
                    content: [
                        {
                            type: 'text',
                            text: `Error: ${error.message}`,
                        },
                    ],
                };
            }
        });
    }

    async logTask(args) {
        const { agent, task, refs = [], commits = [], notes = '', metrics = {} } = args;
        const historyPath = path.join('docs/agents', agent, 'HISTORY.md');
        
        // タイムスタンプ生成
        const timestamp = new Date().toISOString();
        
        // エントリ作成
        let entry = `\n## ${timestamp} by ${agent}\n`;
        entry += `- task: "${task}"\n`;
        
        if (refs.length > 0) {
            entry += `- refs:\n`;
            refs.forEach(ref => {
                entry += `  - ${ref}\n`;
            });
        }
        
        if (commits.length > 0) {
            entry += `- commits:\n`;
            commits.forEach(commit => {
                entry += `  - ${commit}\n`;
            });
        }
        
        if (notes) {
            entry += `- notes:\n  - ${notes}\n`;
        }
        
        if (Object.keys(metrics).length > 0) {
            entry += `- metrics:\n`;
            Object.entries(metrics).forEach(([key, value]) => {
                entry += `  - ${key}: ${value}\n`;
            });
        }
        
        entry += '\n';
        
        // ファイルに追記
        await fs.appendFile(historyPath, entry);
        
        // Git commit も実行（オプション）
        if (commits.length > 0) {
            try {
                execSync(`git add ${historyPath}`, { stdio: 'pipe' });
            } catch (e) {
                // Git操作は失敗しても続行
            }
        }
        
        return {
            content: [
                {
                    type: 'text',
                    text: `Task logged successfully for ${agent}:\n${entry}`,
                },
            ],
        };
    }

    async getHistory(args) {
        const { agent, days = 7 } = args;
        const historyPath = path.join('docs/agents', agent, 'HISTORY.md');
        
        try {
            const content = await fs.readFile(historyPath, 'utf-8');
            const lines = content.split('\n');
            
            // 日付でフィルタリング
            const cutoff = new Date();
            cutoff.setDate(cutoff.getDate() - days);
            
            const entries = [];
            let currentEntry = null;
            
            for (const line of lines) {
                if (line.startsWith('## ')) {
                    // 新しいエントリの開始
                    const dateStr = line.match(/## ([\d\-T:+]+)/)?.[1];
                    if (dateStr) {
                        const entryDate = new Date(dateStr);
                        if (entryDate >= cutoff) {
                            if (currentEntry) entries.push(currentEntry);
                            currentEntry = [line];
                        } else {
                            currentEntry = null;
                        }
                    }
                } else if (currentEntry) {
                    currentEntry.push(line);
                }
            }
            
            if (currentEntry) entries.push(currentEntry);
            
            const result = entries.map(e => e.join('\n')).join('\n\n');
            
            return {
                content: [
                    {
                        type: 'text',
                        text: result || `No history found for ${agent} in the last ${days} days`,
                    },
                ],
            };
        } catch (error) {
            throw new Error(`Failed to read history for ${agent}: ${error.message}`);
        }
    }

    async generateReport(args) {
        const { period, agents = [] } = args;
        
        const allAgents = agents.length > 0 
            ? agents 
            : ['api', 'logic', 'next', 'expo', 'infra', 'qa', 'uiux', 'security', 'docs'];
        
        const days = period === 'daily' ? 1 : period === 'weekly' ? 7 : 30;
        const report = [];
        
        report.push(`# SubAgent Activity Report - ${period.toUpperCase()}`);
        report.push(`Generated: ${new Date().toISOString()}`);
        report.push(`Period: Last ${days} days\n`);
        
        for (const agent of allAgents) {
            try {
                const history = await this.getHistory({ agent, days });
                const entries = history.content[0].text.split('## ').filter(e => e.trim());
                
                if (entries.length > 0) {
                    report.push(`## ${agent.toUpperCase()} Agent`);
                    report.push(`- Tasks completed: ${entries.length}`);
                    
                    // タスクリスト
                    const tasks = entries.map(e => {
                        const taskMatch = e.match(/- task: "([^"]+)"/);
                        return taskMatch ? taskMatch[1] : 'Unknown task';
                    });
                    
                    report.push('- Recent tasks:');
                    tasks.slice(0, 5).forEach(t => {
                        report.push(`  - ${t}`);
                    });
                    report.push('');
                }
            } catch (e) {
                // エラーは無視
            }
        }
        
        // レポートを保存
        const reportPath = `.claude/pm/logs/report_${period}_${new Date().toISOString().split('T')[0]}.md`;
        await fs.mkdir('.claude/.claude/pm/logs', { recursive: true });
        await fs.writeFile(reportPath, report.join('\n'));
        
        return {
            content: [
                {
                    type: 'text',
                    text: report.join('\n'),
                },
            ],
        };
    }

    async run() {
        const transport = new StdioServerTransport();
        await this.server.connect(transport);
        console.error('History Logger MCP Server started');
    }
}

const server = new HistoryLoggerServer();
server.run().catch(console.error);
LOGGER_EOF

# 4. MCP設定ファイル
cat > mcp/configs/claude_desktop_config.json << 'CONFIG_EOF'
{
  "mcpServers": {
    "doc-reader": {
      "command": "node",
      "args": ["mcp/servers/doc-reader.js"],
      "env": {}
    },
    "history-logger": {
      "command": "node",
      "args": ["mcp/servers/history-logger.js"],
      "env": {}
    }
  }
}
CONFIG_EOF

# 5. package.json for MCP servers
cat > mcp/package.json << 'MCP_PACKAGE_EOF'
{
  "name": "subagent-mcp-tools",
  "version": "1.0.0",
  "description": "MCP tools for SubAgent system",
  "type": "module",
  "scripts": {
    "start:doc-reader": "node servers/doc-reader.js",
    "start:history-logger": "node servers/history-logger.js",
    "test": "node test-mcp.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^0.5.0",
    "glob": "^10.3.10"
  }
}
MCP_PACKAGE_EOF

# 6. MCP統合スクリプト
cat > scripts/mcp_integrate.sh << 'MCP_INTEGRATE_EOF'
#!/usr/bin/env bash
# MCP サーバーをClaudeと統合
set -euo pipefail

echo "🔌 MCP統合を設定中..."

# Claude Desktop の設定ディレクトリを検出
if [[ "$OSTYPE" == "darwin"* ]]; then
    CONFIG_DIR="$HOME/Library/Application Support/Claude"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CONFIG_DIR="$HOME/.config/Claude"
else
    echo "⚠️  サポートされていないOS: $OSTYPE"
    exit 1
fi

# 設定ファイルをコピー
if [[ -d "$CONFIG_DIR" ]]; then
    echo "📁 Claude設定ディレクトリ: $CONFIG_DIR"
    
    # バックアップ作成
    if [[ -f "$CONFIG_DIR/claude_desktop_config.json" ]]; then
        cp "$CONFIG_DIR/claude_desktop_config.json" "$CONFIG_DIR/claude_desktop_config.backup.json"
        echo "📋 既存設定をバックアップしました"
    fi
    
    # 設定マージ（手動で行う必要がある）
    echo ""
    echo "⚠️  以下の設定を $CONFIG_DIR/claude_desktop_config.json に追加してください:"
    echo ""
    cat mcp/configs/claude_desktop_config.json
    echo ""
    echo "または、以下のコマンドで自動マージ:"
    echo "  jq -s '.[0] * .[1]' \"$CONFIG_DIR/claude_desktop_config.json\" mcp/configs/claude_desktop_config.json > temp.json && mv temp.json \"$CONFIG_DIR/claude_desktop_config.json\""
else
    echo "❌ Claude設定ディレクトリが見つかりません"
    echo "Claude Desktopがインストールされていることを確認してください"
fi

echo ""
echo "📝 MCP サーバーの起動方法:"
echo "  cd mcp && npm install"
echo "  npm run start:doc-reader    # ドキュメント読み取りサーバー"
echo "  npm run start:history-logger # 履歴記録サーバー"
echo ""
echo "Claude Desktopを再起動してMCPツールを有効化してください"
MCP_INTEGRATE_EOF

chmod +x scripts/mcp_integrate.sh
chmod +x mcp/servers/*.js

echo "✅ MCPツール連携のセットアップが完了しました！"
echo ""
echo "📝 作成されたMCPサーバー:"
echo "  - mcp/servers/doc-reader.js     : ドキュメント読み取り"
echo "  - mcp/servers/history-logger.js : 履歴自動記録"
echo ""
echo "🔧 セットアップ手順:"
echo "  1. cd mcp && npm install"
echo "  2. ./scripts/mcp_integrate.sh"
echo "  3. Claude Desktopを再起動"
echo ""
echo "使用可能なMCPツール:"
echo "  - doc_index: ドキュメント一覧取得"
echo "  - doc_read: ドキュメント読み取り"
echo "  - doc_summarize: ドキュメント要約"
echo "  - doc_search: ドキュメント検索"
echo "  - log_task: タスク履歴記録"
echo "  - get_history: 履歴取得"
echo "  - generate_report: レポート生成"