#!/usr/bin/env node

/**
 * OpenAPI Specification Validator
 * Validates OpenAPI specs and checks for platform-specific requirements
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

class SpecValidator {
  constructor(specFile) {
    this.specFile = specFile;
    this.spec = null;
    this.errors = [];
    this.warnings = [];
  }

  load() {
    try {
      const specContent = fs.readFileSync(this.specFile, 'utf8');
      this.spec = yaml.load(specContent);
      return true;
    } catch (error) {
      this.errors.push(`Failed to load spec file: ${error.message}`);
      return false;
    }
  }

  validateBasicStructure() {
    // Check OpenAPI version
    if (!this.spec.openapi) {
      this.errors.push('Missing OpenAPI version');
    } else if (!this.spec.openapi.startsWith('3.')) {
      this.warnings.push(`OpenAPI version ${this.spec.openapi} may not be fully supported`);
    }

    // Check info section
    if (!this.spec.info) {
      this.errors.push('Missing info section');
    } else {
      if (!this.spec.info.title) this.errors.push('Missing info.title');
      if (!this.spec.info.version) this.errors.push('Missing info.version');
    }

    // Check paths
    if (!this.spec.paths || Object.keys(this.spec.paths).length === 0) {
      this.warnings.push('No paths defined');
    }

    // Check components
    if (!this.spec.components?.schemas) {
      this.warnings.push('No schemas defined in components');
    }
  }

  validatePlatformExtensions() {
    // Check for Go-Zero extensions
    if (!this.spec['x-go-zero']) {
      this.warnings.push('Missing x-go-zero configuration for backend generation');
    } else {
      const goZero = this.spec['x-go-zero'];
      if (!goZero.service) this.warnings.push('Missing x-go-zero.service');
      if (!goZero.group) this.warnings.push('Missing x-go-zero.group');
    }

    // Validate each endpoint
    for (const [path, pathItem] of Object.entries(this.spec.paths || {})) {
      for (const [method, operation] of Object.entries(pathItem)) {
        if (['get', 'post', 'put', 'delete', 'patch'].includes(method)) {
          this.validateEndpoint(path, method, operation);
        }
      }
    }
  }

  validateEndpoint(path, method, operation) {
    const context = `${method.toUpperCase()} ${path}`;

    // Check operationId
    if (!operation.operationId) {
      this.errors.push(`${context}: Missing operationId`);
    }

    // Check summary
    if (!operation.summary) {
      this.warnings.push(`${context}: Missing summary`);
    }

    // Check Go-Zero metadata
    if (operation['x-go-zero']) {
      const goZero = operation['x-go-zero'];
      if (!goZero.handler) {
        this.warnings.push(`${context}: Missing x-go-zero.handler`);
      }
    }

    // Check frontend metadata
    if (operation['x-frontend']) {
      const frontend = operation['x-frontend'];
      if (method === 'get' && frontend.swr === undefined) {
        this.warnings.push(`${context}: Consider adding x-frontend.swr for GET endpoints`);
      }
    }

    // Check mobile metadata
    if (operation['x-mobile']) {
      const mobile = operation['x-mobile'];
      if (mobile.offline && !mobile.cacheTime) {
        this.warnings.push(`${context}: Offline enabled but no cacheTime specified`);
      }
    }

    // Validate request body
    if (operation.requestBody) {
      this.validateRequestBody(context, operation.requestBody);
    }

    // Validate responses
    if (!operation.responses) {
      this.errors.push(`${context}: Missing responses`);
    } else {
      this.validateResponses(context, operation.responses);
    }
  }

  validateRequestBody(context, requestBody) {
    if (!requestBody.content) {
      this.errors.push(`${context}: Request body missing content`);
      return;
    }

    const jsonContent = requestBody.content['application/json'];
    if (!jsonContent) {
      this.warnings.push(`${context}: Request body not application/json`);
      return;
    }

    if (!jsonContent.schema) {
      this.errors.push(`${context}: Request body missing schema`);
    }
  }

  validateResponses(context, responses) {
    // Check for success response
    if (!responses['200'] && !responses['201'] && !responses['204']) {
      this.warnings.push(`${context}: No success response defined`);
    }

    // Validate each response
    for (const [status, response] of Object.entries(responses)) {
      if (status !== '204' && response.content) {
        const jsonContent = response.content['application/json'];
        if (jsonContent && !jsonContent.schema) {
          this.errors.push(`${context}: Response ${status} missing schema`);
        }
      }
    }
  }

  validateSchemas() {
    if (!this.spec.components?.schemas) return;

    for (const [name, schema] of Object.entries(this.spec.components.schemas)) {
      this.validateSchema(name, schema);
    }
  }

  validateSchema(name, schema) {
    // Check for type
    if (!schema.type && !schema.$ref && !schema.allOf && !schema.oneOf && !schema.anyOf) {
      this.warnings.push(`Schema ${name}: Missing type`);
    }

    // Check required fields
    if (schema.required && schema.properties) {
      for (const field of schema.required) {
        if (!schema.properties[field]) {
          this.errors.push(`Schema ${name}: Required field '${field}' not in properties`);
        }
      }
    }

    // Check Go-Zero tags
    if (schema.properties) {
      for (const [propName, propSchema] of Object.entries(schema.properties)) {
        if (!propSchema['x-go-zero']?.tag) {
          this.warnings.push(`Schema ${name}.${propName}: Consider adding x-go-zero.tag`);
        }
      }
    }
  }

  validateSecurity() {
    // Check security schemes
    if (this.spec.components?.securitySchemes) {
      const hasBearer = Object.values(this.spec.components.securitySchemes)
        .some(scheme => scheme.type === 'http' && scheme.scheme === 'bearer');
      
      if (!hasBearer) {
        this.warnings.push('No bearer token authentication defined');
      }
    }

    // Check if protected endpoints have security
    for (const [path, pathItem] of Object.entries(this.spec.paths || {})) {
      for (const [method, operation] of Object.entries(pathItem)) {
        if (['post', 'put', 'delete'].includes(method)) {
          if (!operation.security && !operation['x-go-zero']?.noauth) {
            this.warnings.push(`${method.toUpperCase()} ${path}: Consider adding security`);
          }
        }
      }
    }
  }

  validateCrossReferences() {
    const definedSchemas = new Set(Object.keys(this.spec.components?.schemas || {}));
    const referencedSchemas = new Set();

    // Collect all $ref references
    const collectRefs = (obj) => {
      if (typeof obj !== 'object' || obj === null) return;
      
      if (obj.$ref) {
        const refName = obj.$ref.split('/').pop();
        referencedSchemas.add(refName);
      }
      
      for (const value of Object.values(obj)) {
        collectRefs(value);
      }
    };

    collectRefs(this.spec);

    // Check for undefined references
    for (const ref of referencedSchemas) {
      if (!definedSchemas.has(ref)) {
        this.errors.push(`Referenced schema '${ref}' is not defined`);
      }
    }

    // Check for unused schemas
    for (const schema of definedSchemas) {
      if (!referencedSchemas.has(schema) && !['BaseResponse', 'BaseErrorResponse'].includes(schema)) {
        this.warnings.push(`Schema '${schema}' is defined but never used`);
      }
    }
  }

  validateConsistency() {
    // Check naming conventions
    for (const [path, pathItem] of Object.entries(this.spec.paths || {})) {
      for (const [method, operation] of Object.entries(pathItem)) {
        if (['get', 'post', 'put', 'delete', 'patch'].includes(method)) {
          if (operation.operationId) {
            // Check operationId follows convention
            const expectedPrefix = method === 'get' ? 'get' : 
                                 method === 'post' ? 'create' :
                                 method === 'put' ? 'update' :
                                 method === 'delete' ? 'delete' : method;
            
            if (!operation.operationId.startsWith(expectedPrefix)) {
              this.warnings.push(`${method.toUpperCase()} ${path}: operationId '${operation.operationId}' doesn't follow naming convention (should start with '${expectedPrefix}')`);
            }
          }
        }
      }
    }
  }

  generateReport() {
    console.log('\n========================================');
    console.log(`Validation Report for: ${this.specFile}`);
    console.log('========================================\n');

    if (this.errors.length === 0 && this.warnings.length === 0) {
      console.log('✅ Specification is valid!');
      return true;
    }

    if (this.errors.length > 0) {
      console.log(`❌ Errors (${this.errors.length}):`);
      this.errors.forEach((error, i) => {
        console.log(`  ${i + 1}. ${error}`);
      });
      console.log('');
    }

    if (this.warnings.length > 0) {
      console.log(`⚠️  Warnings (${this.warnings.length}):`);
      this.warnings.forEach((warning, i) => {
        console.log(`  ${i + 1}. ${warning}`);
      });
      console.log('');
    }

    console.log('Summary:');
    console.log(`  - ${this.errors.length} error(s)`);
    console.log(`  - ${this.warnings.length} warning(s)`);
    
    return this.errors.length === 0;
  }

  validate() {
    if (!this.load()) {
      this.generateReport();
      return false;
    }

    this.validateBasicStructure();
    this.validatePlatformExtensions();
    this.validateSchemas();
    this.validateSecurity();
    this.validateCrossReferences();
    this.validateConsistency();

    return this.generateReport();
  }
}

// Main execution
if (require.main === module) {
  const [,, specFile] = process.argv;
  
  if (!specFile) {
    console.error('Usage: validate-spec.js <spec-file>');
    process.exit(1);
  }

  if (!fs.existsSync(specFile)) {
    console.error(`File not found: ${specFile}`);
    process.exit(1);
  }

  const validator = new SpecValidator(specFile);
  const isValid = validator.validate();
  
  process.exit(isValid ? 0 : 1);
}

module.exports = SpecValidator;