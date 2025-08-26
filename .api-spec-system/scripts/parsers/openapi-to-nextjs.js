#!/usr/bin/env node

/**
 * OpenAPI to Next.js 15 Code Generator
 * Converts OpenAPI specifications to Next.js TypeScript code
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

class OpenAPIToNextJS {
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
    const templateDir = path.join(__dirname, '../../templates/nextjs');
    this.templates.apiClient = fs.readFileSync(path.join(templateDir, 'api-client.tpl'), 'utf8');
    this.templates.hooks = fs.readFileSync(path.join(templateDir, 'hooks.tpl'), 'utf8');
    this.templates.serverActions = fs.readFileSync(path.join(templateDir, 'server-actions.tpl'), 'utf8');
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
            Validation: propSchema['x-validation']?.frontend || {}
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
          const frontendMeta = operation['x-frontend'] || {};
          
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
            SWR: frontendMeta.swr ? {
              Enabled: true,
              RevalidateOnFocus: frontendMeta.revalidateOnFocus !== false,
              RevalidateOnReconnect: frontendMeta.revalidateOnReconnect !== false,
              RefreshInterval: frontendMeta.revalidate ? frontendMeta.revalidate * 1000 : 0
            } : null,
            InvalidatesCache: frontendMeta.invalidatesCache || [],
            ServerAction: frontendMeta.serverAction || false,
            CacheTime: frontendMeta.cacheTime || 3600,
            NextCache: frontendMeta.cache || null,
            RevalidatePaths: frontendMeta.revalidatePaths || [],
            RevalidateTags: frontendMeta.revalidateTags || []
          };

          // Parse request fields for server actions
          if (endpoint.ServerAction && operation.requestBody) {
            const schema = operation.requestBody.content?.['application/json']?.schema;
            if (schema?.$ref) {
              const refName = schema.$ref.split('/').pop();
              const refSchema = this.spec.components.schemas[refName];
              endpoint.RequestFields = Object.keys(refSchema.properties || {}).map(name => ({
                Name: name,
                Type: this.getTsType(refSchema.properties[name])
              }));
            }
          }

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

  generateApiClient() {
    const template = Handlebars.compile(this.templates.apiClient);
    
    const data = {
      SpecFile: this.specFile,
      Schemas: this.parseSchemas(),
      Endpoints: this.parseEndpoints()
    };

    const content = template(data);
    const outputFile = path.join(this.outputDir, 'api-client.ts');
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

  generateServerActions() {
    const template = Handlebars.compile(this.templates.serverActions);
    
    const endpoints = this.parseEndpoints();
    const data = {
      Endpoints: endpoints,
      NextCache: this.spec['x-frontend']?.cache || {}
    };

    const content = template(data);
    const outputFile = path.join(this.outputDir, 'server-actions.ts');
    fs.writeFileSync(outputFile, content);
    console.log(`Generated: ${outputFile}`);
  }

  generateTypes() {
    // Generate TypeScript type definitions
    let typeDefinitions = '// Auto-generated TypeScript types\n\n';
    
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

  async generate() {
    await this.load();
    
    // Create output directory if it doesn't exist
    if (!fs.existsSync(this.outputDir)) {
      fs.mkdirSync(this.outputDir, { recursive: true });
    }

    this.generateApiClient();
    this.generateHooks();
    this.generateServerActions();
    this.generateTypes();
    
    console.log('Next.js code generation completed!');
  }
}

// Main execution
if (require.main === module) {
  const [,, specFile, outputDir] = process.argv;
  
  if (!specFile || !outputDir) {
    console.error('Usage: openapi-to-nextjs.js <spec-file> <output-dir>');
    process.exit(1);
  }

  const generator = new OpenAPIToNextJS(specFile, outputDir);
  generator.generate().catch(console.error);
}

module.exports = OpenAPIToNextJS;