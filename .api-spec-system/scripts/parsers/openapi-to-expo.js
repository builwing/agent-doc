#!/usr/bin/env node

/**
 * OpenAPI to Expo/React Native Code Generator
 * Converts OpenAPI specifications to Expo TypeScript code with offline support
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const Handlebars = require('handlebars');

// Register Handlebars helpers
Handlebars.registerHelper('title', (str) => {
  if (!str) return '';
  return str.charAt(0).toUpperCase() + str.slice(1);
});

Handlebars.registerHelper('camelCase', (str) => {
  if (!str) return '';
  return str.replace(/-([a-z])/g, (g) => g[1].toUpperCase());
});

Handlebars.registerHelper('zodType', (type, format) => {
  const typeMap = {
    'string': format === 'email' ? 'string().email()' : 
              format === 'uuid' ? 'string().uuid()' : 
              format === 'uri' ? 'string().url()' : 
              format === 'date-time' ? 'string().datetime()' : 'string()',
    'integer': 'number().int()',
    'number': 'number()',
    'boolean': 'boolean()',
    'array': 'array()',
    'object': 'object()'
  };
  return typeMap[type] || 'unknown()';
});

Handlebars.registerHelper('tsType', (type, format) => {
  const typeMap = {
    'string': 'string',
    'integer': 'number',
    'number': 'number',
    'boolean': 'boolean',
    'array': 'any[]',
    'object': 'Record<string, any>'
  };
  return typeMap[type] || 'any';
});

Handlebars.registerHelper('default', (value, defaultValue) => {
  return value || defaultValue;
});

class OpenAPIToExpo {
  constructor(specFile, outputDir) {
    this.specFile = specFile;
    this.outputDir = outputDir;
    this.spec = null;
    this.templates = {};
  }

  async load() {
    // Load OpenAPI specification
    const specContent = fs.readFileSync(this.specFile, 'utf8');
    this.spec = yaml.load(specContent);

    // Load templates
    const templateDir = path.join(__dirname, '../../templates/expo');
    this.templates.apiService = fs.readFileSync(path.join(templateDir, 'api-service.tpl'), 'utf8');
    this.templates.hooks = fs.readFileSync(path.join(templateDir, 'hooks.tpl'), 'utf8');
  }

  parseSchemas() {
    const schemas = [];
    if (!this.spec.components?.schemas) return schemas;

    for (const [name, schema] of Object.entries(this.spec.components.schemas)) {
      const properties = [];
      
      if (schema.properties) {
        for (const [propName, propSchema] of Object.entries(schema.properties)) {
          const required = schema.required?.includes(propName);
          properties.push({
            Name: propName,
            ZodType: this.getZodType(propSchema),
            TsType: this.getTsType(propSchema),
            Optional: !required,
            Validation: propSchema['x-validation']?.mobile || {}
          });
        }
      }

      // Handle allOf compositions
      if (schema.allOf) {
        schema.allOf.forEach(item => {
          if (item.$ref) {
            const refName = item.$ref.split('/').pop();
            properties.push({
              Name: '_extends',
              ZodType: `${refName}Schema`,
              TsType: refName,
              Optional: false
            });
          }
        });
      }

      schemas.push({
        Name: name,
        Properties: properties
      });
    }

    return schemas;
  }

  parseEndpoints() {
    const endpoints = [];
    
    for (const [path, pathItem] of Object.entries(this.spec.paths)) {
      for (const [method, operation] of Object.entries(pathItem)) {
        if (['get', 'post', 'put', 'delete', 'patch'].includes(method)) {
          const mobileMeta = operation['x-mobile'] || {};
          
          const endpoint = {
            Method: method.toUpperCase(),
            Path: path,
            OperationId: operation.operationId,
            Summary: operation.summary || '',
            HasRequest: !!operation.requestBody,
            HasParams: !!operation.parameters,
            RequestType: this.getRequestType(operation),
            ResponseType: this.getResponseType(operation),
            HasValidation: !!operation.requestBody,
            Mobile: {
              Offline: mobileMeta.offline || false,
              CacheTime: mobileMeta.cacheTime || 0,
              Background: mobileMeta.background || false,
              SyncPriority: mobileMeta.syncPriority || 'normal'
            },
            InvalidatesCache: mobileMeta.invalidatesCache || []
          };

          // Parse parameters
          if (operation.parameters) {
            endpoint.ParamsType = `{ ${operation.parameters.map(p => 
              `${p.name}${p.required ? '' : '?'}: ${this.getTsType(p.schema)}`
            ).join(', ')} }`;
          }

          endpoints.push(endpoint);
        }
      }
    }

    return endpoints;
  }

  parseWebSockets() {
    const websockets = [];
    
    if (this.spec['x-websocket']) {
      for (const [path, wsConfig] of Object.entries(this.spec['x-websocket'])) {
        const mobileMeta = wsConfig['x-mobile'] || {};
        
        websockets.push({
          Path: path,
          Description: wsConfig.description || '',
          Background: mobileMeta.background || false,
          Reconnect: mobileMeta.reconnect !== false,
          Heartbeat: mobileMeta.heartbeat || 30,
          Messages: wsConfig.messages || []
        });
      }
    }

    return websockets;
  }

  getZodType(schema) {
    if (schema.$ref) {
      const refName = schema.$ref.split('/').pop();
      return `${refName}Schema`;
    }

    let zodType = 'z.';
    
    switch (schema.type) {
      case 'string':
        zodType += 'string()';
        if (schema.format === 'email') zodType += '.email()';
        if (schema.format === 'uuid') zodType += '.uuid()';
        if (schema.format === 'uri') zodType += '.url()';
        if (schema.format === 'date-time') zodType += '.datetime()';
        if (schema.minLength) zodType += `.min(${schema.minLength})`;
        if (schema.maxLength) zodType += `.max(${schema.maxLength})`;
        break;
      case 'integer':
        zodType += 'number().int()';
        if (schema.minimum !== undefined) zodType += `.min(${schema.minimum})`;
        if (schema.maximum !== undefined) zodType += `.max(${schema.maximum})`;
        break;
      case 'number':
        zodType += 'number()';
        if (schema.minimum !== undefined) zodType += `.min(${schema.minimum})`;
        if (schema.maximum !== undefined) zodType += `.max(${schema.maximum})`;
        break;
      case 'boolean':
        zodType += 'boolean()';
        break;
      case 'array':
        zodType += `array(${this.getZodType(schema.items || {})})`;
        break;
      case 'object':
        zodType += 'object({})';
        break;
      default:
        zodType += 'unknown()';
    }

    return zodType;
  }

  getTsType(schema) {
    if (!schema) return 'any';
    
    if (schema.$ref) {
      return schema.$ref.split('/').pop();
    }

    const typeMap = {
      'string': 'string',
      'integer': 'number',
      'number': 'number',
      'boolean': 'boolean',
      'array': schema.items ? `${this.getTsType(schema.items)}[]` : 'any[]',
      'object': 'Record<string, any>'
    };

    return typeMap[schema.type] || 'any';
  }

  getRequestType(operation) {
    if (operation.requestBody?.content?.['application/json']?.schema?.$ref) {
      return operation.requestBody.content['application/json'].schema.$ref.split('/').pop();
    }
    if (operation.requestBody?.content?.['application/json']?.schema) {
      return 'RequestBody';
    }
    return null;
  }

  getResponseType(operation) {
    const response = operation.responses?.['200'] || operation.responses?.['201'];
    if (response?.content?.['application/json']?.schema?.$ref) {
      return response.content['application/json'].schema.$ref.split('/').pop();
    }
    if (response?.content?.['application/json']?.schema) {
      return 'ResponseBody';
    }
    return 'any';
  }

  generateApiService() {
    const template = Handlebars.compile(this.templates.apiService);
    
    const data = {
      SpecFile: this.specFile,
      Schemas: this.parseSchemas(),
      Endpoints: this.parseEndpoints(),
      WebSockets: this.parseWebSockets()
    };

    const content = template(data);
    const outputFile = path.join(this.outputDir, 'api-service.ts');
    fs.writeFileSync(outputFile, content);
    console.log(`Generated: ${outputFile}`);
  }

  generateHooks() {
    const template = Handlebars.compile(this.templates.hooks);
    
    const data = {
      Endpoints: this.parseEndpoints()
    };

    const content = template(data);
    const outputFile = path.join(this.outputDir, 'hooks.ts');
    fs.writeFileSync(outputFile, content);
    console.log(`Generated: ${outputFile}`);
  }

  generateOfflineSync() {
    // Generate offline sync manager
    const syncManager = `// Auto-generated Offline Sync Manager
import AsyncStorage from '@react-native-async-storage/async-storage';
import NetInfo from '@react-native-community/netinfo';
import BackgroundTask from 'react-native-background-task';

export class OfflineSyncManager {
  private static instance: OfflineSyncManager;
  private syncQueue: Map<string, any> = new Map();
  
  static getInstance(): OfflineSyncManager {
    if (!this.instance) {
      this.instance = new OfflineSyncManager();
    }
    return this.instance;
  }

  async initialize() {
    // Setup background task
    BackgroundTask.define(async () => {
      await this.syncPendingRequests();
      BackgroundTask.finish();
    });

    // Schedule background sync
    BackgroundTask.schedule({
      period: 900, // 15 minutes
    });

    // Listen for network changes
    NetInfo.addEventListener(state => {
      if (state.isConnected) {
        this.syncPendingRequests();
      }
    });
  }

  async queueRequest(request: any) {
    const id = Date.now().toString();
    this.syncQueue.set(id, request);
    await this.persistQueue();
    return id;
  }

  private async syncPendingRequests() {
    const queue = Array.from(this.syncQueue.entries());
    
    for (const [id, request] of queue) {
      try {
        // Attempt to sync
        await this.executeRequest(request);
        this.syncQueue.delete(id);
      } catch (error) {
        console.error(\`Failed to sync request \${id}:\`, error);
      }
    }
    
    await this.persistQueue();
  }

  private async executeRequest(request: any) {
    // Execute the actual API request
    const response = await fetch(request.url, request.options);
    if (!response.ok) {
      throw new Error(\`Request failed: \${response.status}\`);
    }
    return response.json();
  }

  private async persistQueue() {
    const data = Array.from(this.syncQueue.entries());
    await AsyncStorage.setItem('offline_sync_queue', JSON.stringify(data));
  }

  async loadQueue() {
    const data = await AsyncStorage.getItem('offline_sync_queue');
    if (data) {
      const entries = JSON.parse(data);
      this.syncQueue = new Map(entries);
    }
  }
}

export const offlineSyncManager = OfflineSyncManager.getInstance();
`;

    const outputFile = path.join(this.outputDir, 'offline-sync.ts');
    fs.writeFileSync(outputFile, syncManager);
    console.log(`Generated: ${outputFile}`);
  }

  generateTypes() {
    // Generate TypeScript type definitions
    let typeDefinitions = '// Auto-generated TypeScript types for Expo\n\n';
    
    const schemas = this.parseSchemas();
    schemas.forEach(schema => {
      typeDefinitions += `export interface ${schema.Name} {\n`;
      schema.Properties.forEach(prop => {
        if (prop.Name !== '_extends') {
          typeDefinitions += `  ${prop.Name}${prop.Optional ? '?' : ''}: ${prop.TsType};\n`;
        }
      });
      typeDefinitions += '}\n\n';
    });

    const outputFile = path.join(this.outputDir, 'types.ts');
    fs.writeFileSync(outputFile, typeDefinitions);
    console.log(`Generated: ${outputFile}`);
  }

  generateWebSocketClient() {
    if (!this.spec['x-websocket']) return;

    const wsClient = `// Auto-generated WebSocket Client
export class WebSocketClient {
  private ws: WebSocket | null = null;
  private url: string;
  private reconnectTimeout: NodeJS.Timeout | null = null;
  private heartbeatInterval: NodeJS.Timeout | null = null;
  private listeners: Map<string, Set<Function>> = new Map();

  constructor(url: string) {
    this.url = url;
  }

  connect() {
    this.ws = new WebSocket(this.url);
    
    this.ws.onopen = () => {
      console.log('WebSocket connected');
      this.startHeartbeat();
    };

    this.ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      this.emit(data.type, data);
    };

    this.ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    this.ws.onclose = () => {
      console.log('WebSocket disconnected');
      this.stopHeartbeat();
      this.reconnect();
    };
  }

  private reconnect() {
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout);
    }
    
    this.reconnectTimeout = setTimeout(() => {
      console.log('Attempting to reconnect...');
      this.connect();
    }, 5000);
  }

  private startHeartbeat() {
    this.heartbeatInterval = setInterval(() => {
      if (this.ws?.readyState === WebSocket.OPEN) {
        this.send({ type: 'ping' });
      }
    }, 30000);
  }

  private stopHeartbeat() {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
    }
  }

  send(data: any) {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(data));
    } else {
      console.warn('WebSocket not connected, queuing message');
      // Queue message for later
    }
  }

  on(event: string, callback: Function) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(callback);
  }

  off(event: string, callback: Function) {
    this.listeners.get(event)?.delete(callback);
  }

  private emit(event: string, data: any) {
    this.listeners.get(event)?.forEach(callback => callback(data));
  }

  disconnect() {
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout);
    }
    this.stopHeartbeat();
    this.ws?.close();
  }
}
`;

    const outputFile = path.join(this.outputDir, 'websocket-client.ts');
    fs.writeFileSync(outputFile, wsClient);
    console.log(`Generated: ${outputFile}`);
  }

  async generate() {
    await this.load();
    
    // Create output directory if it doesn't exist
    if (!fs.existsSync(this.outputDir)) {
      fs.mkdirSync(this.outputDir, { recursive: true });
    }

    this.generateApiService();
    this.generateHooks();
    this.generateOfflineSync();
    this.generateTypes();
    this.generateWebSocketClient();
    
    console.log('Expo code generation completed!');
  }
}

// Main execution
if (require.main === module) {
  const [,, specFile, outputDir] = process.argv;
  
  if (!specFile || !outputDir) {
    console.error('Usage: openapi-to-expo.js <spec-file> <output-dir>');
    process.exit(1);
  }

  const generator = new OpenAPIToExpo(specFile, outputDir);
  generator.generate().catch(console.error);
}

module.exports = OpenAPIToExpo;