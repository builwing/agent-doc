#!/usr/bin/env node

/**
 * OpenAPI to Go-Zero Code Generator
 * Converts OpenAPI specifications to Go-Zero API definitions
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const Handlebars = require('handlebars');

// Register Handlebars helpers
Handlebars.registerHelper('title', (str) => {
  return str.charAt(0).toUpperCase() + str.slice(1);
});

Handlebars.registerHelper('goType', (type, format) => {
  const typeMap = {
    'string': format === 'uuid' ? 'string' : 'string',
    'integer': 'int64',
    'number': 'float64',
    'boolean': 'bool',
    'array': '[]',
    'object': 'interface{}'
  };
  return typeMap[type] || 'interface{}';
});

class OpenAPIToGoZero {
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
    const templateDir = path.join(__dirname, '../../templates/go-zero');
    this.templates.api = fs.readFileSync(path.join(templateDir, 'api.tpl'), 'utf8');
    this.templates.handler = fs.readFileSync(path.join(templateDir, 'handler.tpl'), 'utf8');
    this.templates.logic = fs.readFileSync(path.join(templateDir, 'logic.tpl'), 'utf8');
  }

  parseSchemas() {
    const schemas = [];
    if (!this.spec.components?.schemas) return schemas;

    for (const [name, schema] of Object.entries(this.spec.components.schemas)) {
      const properties = [];
      
      if (schema.properties) {
        for (const [propName, propSchema] of Object.entries(schema.properties)) {
          const goZeroMeta = propSchema['x-go-zero'] || {};
          properties.push({
            Name: propName,
            Type: this.getGoType(propSchema),
            JsonTag: goZeroMeta.tag || `json:"${propName}"`,
            Validate: goZeroMeta.validate || ''
          });
        }
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
          const goZeroMeta = operation['x-go-zero'] || {};
          
          endpoints.push({
            Method: method.toUpperCase(),
            Path: path,
            OperationId: operation.operationId,
            Summary: operation.summary || '',
            Handler: goZeroMeta.handler || `${operation.operationId}Handler`,
            LogicName: goZeroMeta.logic || `${operation.operationId}Logic`,
            Request: this.getRequestType(operation),
            Response: this.getResponseType(operation),
            HasAuth: !!operation.security,
            Cache: goZeroMeta.cache || {}
          });
        }
      }
    }

    return endpoints;
  }

  getGoType(schema) {
    if (schema.$ref) {
      const refName = schema.$ref.split('/').pop();
      return `*${refName}`;
    }

    const typeMap = {
      'string': 'string',
      'integer': 'int64',
      'number': 'float64',
      'boolean': 'bool',
      'array': '[]' + this.getGoType(schema.items || {}),
      'object': 'map[string]interface{}'
    };

    return typeMap[schema.type] || 'interface{}';
  }

  getRequestType(operation) {
    if (operation.requestBody?.content?.['application/json']?.schema?.$ref) {
      return operation.requestBody.content['application/json'].schema.$ref.split('/').pop();
    }
    return 'EmptyRequest';
  }

  getResponseType(operation) {
    const response = operation.responses?.['200'] || operation.responses?.['201'];
    if (response?.content?.['application/json']?.schema?.$ref) {
      return response.content['application/json'].schema.$ref.split('/').pop();
    }
    return 'BaseResponse';
  }

  generateAPIFile() {
    const template = Handlebars.compile(this.templates.api);
    const goZeroConfig = this.spec['x-go-zero'] || {};
    
    const data = {
      SpecFile: this.specFile,
      Info: this.spec.info,
      ServiceName: goZeroConfig.service || 'api-service',
      Group: goZeroConfig.group || 'api',
      Prefix: '/api/v1',
      Middleware: goZeroConfig.middleware?.join(', ') || '',
      Security: goZeroConfig.jwt?.enabled,
      Schemas: this.parseSchemas(),
      Endpoints: this.parseEndpoints()
    };

    const apiContent = template(data);
    const apiFile = path.join(this.outputDir, 'api.api');
    fs.writeFileSync(apiFile, apiContent);
    console.log(`Generated: ${apiFile}`);
  }

  generateHandlers() {
    const template = Handlebars.compile(this.templates.handler);
    const handlersDir = path.join(this.outputDir, 'internal', 'handler');
    
    if (!fs.existsSync(handlersDir)) {
      fs.mkdirSync(handlersDir, { recursive: true });
    }

    for (const endpoint of this.parseEndpoints()) {
      const data = {
        ProjectPath: 'api-service',
        HandlerName: endpoint.Handler,
        LogicName: endpoint.LogicName.replace('Logic', ''),
        LogicMethod: endpoint.OperationId,
        Method: endpoint.Method,
        Path: endpoint.Path,
        HasRequest: endpoint.Request !== 'EmptyRequest',
        RequestType: endpoint.Request,
        HasValidation: true
      };

      const handlerContent = template(data);
      const handlerFile = path.join(handlersDir, `${endpoint.OperationId.toLowerCase()}handler.go`);
      fs.writeFileSync(handlerFile, handlerContent);
      console.log(`Generated: ${handlerFile}`);
    }
  }

  generateLogic() {
    const template = Handlebars.compile(this.templates.logic);
    const logicDir = path.join(this.outputDir, 'internal', 'logic');
    
    if (!fs.existsSync(logicDir)) {
      fs.mkdirSync(logicDir, { recursive: true });
    }

    for (const endpoint of this.parseEndpoints()) {
      const data = {
        ProjectPath: 'api-service',
        LogicName: endpoint.LogicName,
        LogicMethod: endpoint.OperationId,
        Summary: endpoint.Summary,
        HasRequest: endpoint.Request !== 'EmptyRequest',
        RequestType: endpoint.Request,
        ResponseType: endpoint.Response,
        Cache: endpoint.Cache,
        HasDatabase: true,
        HasWebSocket: false
      };

      const logicContent = template(data);
      const logicFile = path.join(logicDir, `${endpoint.OperationId.toLowerCase()}logic.go`);
      fs.writeFileSync(logicFile, logicContent);
      console.log(`Generated: ${logicFile}`);
    }
  }

  async generate() {
    await this.load();
    this.generateAPIFile();
    this.generateHandlers();
    this.generateLogic();
    console.log('Go-Zero code generation completed!');
  }
}

// Main execution
if (require.main === module) {
  const [,, specFile, outputDir] = process.argv;
  
  if (!specFile || !outputDir) {
    console.error('Usage: openapi-to-gozero.js <spec-file> <output-dir>');
    process.exit(1);
  }

  const generator = new OpenAPIToGoZero(specFile, outputDir);
  generator.generate().catch(console.error);
}

module.exports = OpenAPIToGoZero;