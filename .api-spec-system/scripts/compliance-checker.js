#!/usr/bin/env node

/**
 * API Specification Compliance Checker
 * 仕様準拠を包括的にチェックするツール
 */

const fs = require('fs');
const yaml = require('js-yaml');
const { execSync } = require('child_process');

// path module fix - using dynamic import
const path = require('path');

class ComplianceChecker {
  constructor() {
    this.baseDir = path.resolve(__dirname, '..');
    this.specsDir = path.join(this.baseDir, 'specs');
    this.generatedDir = path.join(this.baseDir, 'generated');
    this.report = {
      timestamp: new Date().toISOString(),
      status: 'checking',
      violations: [],
      warnings: [],
      info: [],
      stats: {
        totalEndpoints: 0,
        implementedEndpoints: 0,
        missingEndpoints: 0,
        typeMatches: 0,
        typeMismatches: 0
      }
    };
  }

  // 1. 仕様ファイルの存在チェック
  checkSpecFiles() {
    console.log('📁 Checking specification files...');
    
    if (!fs.existsSync(this.specsDir)) {
      this.report.violations.push({
        type: 'MISSING_SPECS_DIR',
        message: 'Specifications directory not found',
        severity: 'critical'
      });
      return false;
    }

    const specFiles = this.findSpecFiles();
    if (specFiles.length === 0) {
      this.report.violations.push({
        type: 'NO_SPEC_FILES',
        message: 'No specification files found',
        severity: 'critical'
      });
      return false;
    }

    this.report.info.push(`Found ${specFiles.length} specification file(s)`);
    return true;
  }

  // 2. 生成されたコードの存在チェック
  checkGeneratedCode() {
    console.log('🔍 Checking generated code...');
    
    const platforms = ['backend', 'frontend', 'mobile'];
    const missing = [];

    for (const platform of platforms) {
      const platformDir = path.join(this.generatedDir, platform);
      if (!fs.existsSync(platformDir)) {
        missing.push(platform);
      }
    }

    if (missing.length > 0) {
      this.report.warnings.push({
        type: 'MISSING_GENERATED',
        message: `Generated code missing for: ${missing.join(', ')}`,
        severity: 'warning',
        fix: 'Run: make generate'
      });
    }

    return missing.length === 0;
  }

  // 3. 仕様と実装の一致チェック
  checkSpecImplementationMatch() {
    console.log('🔄 Checking spec-implementation match...');
    
    const specFiles = this.findSpecFiles();
    
    for (const specFile of specFiles) {
      const spec = yaml.load(fs.readFileSync(specFile, 'utf8'));
      
      if (spec.paths) {
        for (const [apiPath, pathItem] of Object.entries(spec.paths)) {
          for (const [method, operation] of Object.entries(pathItem)) {
            if (['get', 'post', 'put', 'delete', 'patch'].includes(method)) {
              this.report.stats.totalEndpoints++;
              this.checkEndpointImplementation(apiPath, method, operation);
            }
          }
        }
      }
    }

    const implementationRate = (this.report.stats.implementedEndpoints / this.report.stats.totalEndpoints) * 100;
    this.report.info.push(`Implementation coverage: ${implementationRate.toFixed(1)}%`);
  }

  // 4. エンドポイント実装チェック
  checkEndpointImplementation(apiPath, method, operation) {
    const operationId = operation.operationId;
    
    if (!operationId) {
      this.report.violations.push({
        type: 'MISSING_OPERATION_ID',
        message: `${method.toUpperCase()} ${apiPath}: Missing operationId`,
        severity: 'error'
      });
      return;
    }

    // バックエンド実装チェック
    if (operation['x-go-zero']) {
      const handler = operation['x-go-zero'].handler;
      const logic = operation['x-go-zero'].logic;
      
      const handlerFile = path.join(
        this.generatedDir,
        'backend/internal/handler',
        `${operationId.toLowerCase()}handler.go`
      );
      
      const logicFile = path.join(
        this.generatedDir,
        'backend/internal/logic',
        `${operationId.toLowerCase()}logic.go`
      );
      
      if (!fs.existsSync(handlerFile)) {
        this.report.violations.push({
          type: 'MISSING_HANDLER',
          message: `Missing handler for ${operationId}`,
          file: handlerFile,
          severity: 'error'
        });
        this.report.stats.missingEndpoints++;
      } else {
        this.report.stats.implementedEndpoints++;
      }
      
      if (!fs.existsSync(logicFile)) {
        this.report.violations.push({
          type: 'MISSING_LOGIC',
          message: `Missing logic for ${operationId}`,
          file: logicFile,
          severity: 'error'
        });
      }
    }

    // フロントエンド実装チェック
    if (operation['x-frontend']) {
      const apiClientFile = path.join(this.generatedDir, 'frontend/api-client.ts');
      
      if (fs.existsSync(apiClientFile)) {
        const content = fs.readFileSync(apiClientFile, 'utf8');
        if (!content.includes(`async ${operationId}(`)) {
          this.report.violations.push({
            type: 'MISSING_FRONTEND_METHOD',
            message: `Frontend method missing for ${operationId}`,
            severity: 'warning'
          });
        }
      }
    }

    // モバイル実装チェック
    if (operation['x-mobile']) {
      const apiServiceFile = path.join(this.generatedDir, 'mobile/api-service.ts');
      
      if (fs.existsSync(apiServiceFile)) {
        const content = fs.readFileSync(apiServiceFile, 'utf8');
        if (!content.includes(`async ${operationId}(`)) {
          this.report.violations.push({
            type: 'MISSING_MOBILE_METHOD',
            message: `Mobile method missing for ${operationId}`,
            severity: 'warning'
          });
        }
      }
    }
  }

  // 5. 型定義の一致チェック
  checkTypeConsistency() {
    console.log('🔢 Checking type consistency...');
    
    const specFiles = this.findSpecFiles();
    const schemas = new Map();
    
    // 仕様からスキーマを収集
    for (const specFile of specFiles) {
      const spec = yaml.load(fs.readFileSync(specFile, 'utf8'));
      
      if (spec.components?.schemas) {
        for (const [name, schema] of Object.entries(spec.components.schemas)) {
          schemas.set(name, schema);
        }
      }
    }
    
    // 各プラットフォームの型定義をチェック
    this.checkPlatformTypes('frontend', schemas);
    this.checkPlatformTypes('mobile', schemas);
    
    const typeAccuracy = (this.report.stats.typeMatches / 
      (this.report.stats.typeMatches + this.report.stats.typeMismatches)) * 100;
    
    if (!isNaN(typeAccuracy)) {
      this.report.info.push(`Type consistency: ${typeAccuracy.toFixed(1)}%`);
    }
  }

  // 6. プラットフォーム別型チェック
  checkPlatformTypes(platform, schemas) {
    const typesFile = path.join(this.generatedDir, platform, 'types.ts');
    
    if (!fs.existsSync(typesFile)) {
      this.report.warnings.push({
        type: 'MISSING_TYPES_FILE',
        message: `Types file missing for ${platform}`,
        severity: 'warning'
      });
      return;
    }
    
    const content = fs.readFileSync(typesFile, 'utf8');
    
    for (const [schemaName, schema] of schemas) {
      if (content.includes(`interface ${schemaName}`)) {
        this.report.stats.typeMatches++;
        
        // プロパティチェック
        if (schema.properties) {
          for (const propName of Object.keys(schema.properties)) {
            if (!content.includes(`${propName}:`)) {
              this.report.violations.push({
                type: 'MISSING_PROPERTY',
                message: `Property '${propName}' missing in ${schemaName} (${platform})`,
                severity: 'warning'
              });
              this.report.stats.typeMismatches++;
            }
          }
        }
      } else {
        this.report.violations.push({
          type: 'MISSING_TYPE',
          message: `Type '${schemaName}' not found in ${platform}`,
          severity: 'warning'
        });
        this.report.stats.typeMismatches++;
      }
    }
  }

  // 7. セキュリティチェック
  checkSecurity() {
    console.log('🔒 Checking security configuration...');
    
    const specFiles = this.findSpecFiles();
    let hasSecurityScheme = false;
    let protectedEndpoints = 0;
    let unprotectedEndpoints = 0;
    
    for (const specFile of specFiles) {
      const spec = yaml.load(fs.readFileSync(specFile, 'utf8'));
      
      if (spec.components?.securitySchemes) {
        hasSecurityScheme = true;
      }
      
      if (spec.paths) {
        for (const [apiPath, pathItem] of Object.entries(spec.paths)) {
          for (const [method, operation] of Object.entries(pathItem)) {
            if (['post', 'put', 'delete'].includes(method)) {
              if (operation.security || spec.security) {
                protectedEndpoints++;
              } else if (!operation['x-go-zero']?.noauth) {
                unprotectedEndpoints++;
                this.report.warnings.push({
                  type: 'UNPROTECTED_ENDPOINT',
                  message: `${method.toUpperCase()} ${apiPath} lacks security`,
                  severity: 'warning'
                });
              }
            }
          }
        }
      }
    }
    
    if (!hasSecurityScheme) {
      this.report.warnings.push({
        type: 'NO_SECURITY_SCHEME',
        message: 'No security scheme defined',
        severity: 'warning'
      });
    }
    
    this.report.info.push(`Security: ${protectedEndpoints} protected, ${unprotectedEndpoints} unprotected endpoints`);
  }

  // 8. Git状態チェック
  checkGitStatus() {
    console.log('📦 Checking git status...');
    
    try {
      const status = execSync('git status --porcelain', { cwd: this.baseDir }).toString();
      
      if (status.includes('generated/')) {
        const modifiedGenerated = status
          .split('\n')
          .filter(line => line.includes('generated/'))
          .map(line => line.trim());
        
        if (modifiedGenerated.length > 0) {
          this.report.warnings.push({
            type: 'UNCOMMITTED_GENERATED',
            message: 'Generated files have uncommitted changes',
            files: modifiedGenerated,
            severity: 'info',
            fix: 'Commit or discard changes in generated/'
          });
        }
      }
    } catch (error) {
      this.report.info.push('Git status check skipped (not a git repository)');
    }
  }

  // 9. 依存関係チェック
  checkDependencies() {
    console.log('📚 Checking dependencies...');
    
    const requiredTools = [
      { name: 'node', check: 'node --version' },
      { name: 'go', check: 'go version' },
      { name: 'make', check: 'make --version' }
    ];
    
    const missing = [];
    
    for (const tool of requiredTools) {
      try {
        execSync(tool.check, { stdio: 'ignore' });
      } catch {
        missing.push(tool.name);
      }
    }
    
    if (missing.length > 0) {
      this.report.violations.push({
        type: 'MISSING_DEPENDENCIES',
        message: `Required tools missing: ${missing.join(', ')}`,
        severity: 'error'
      });
    }
  }

  // ヘルパー関数
  findSpecFiles() {
    const files = [];
    
    function walk(dir) {
      if (!fs.existsSync(dir)) return;
      
      const items = fs.readdirSync(dir);
      for (const item of items) {
        const fullPath = path.join(dir, item);
        const stat = fs.statSync(fullPath);
        
        if (stat.isDirectory()) {
          walk(fullPath);
        } else if (item.endsWith('.yaml') || item.endsWith('.yml')) {
          files.push(fullPath);
        }
      }
    }
    
    walk(this.specsDir);
    return files;
  }

  // レポート生成
  generateReport() {
    const totalIssues = this.report.violations.length + this.report.warnings.length;
    
    if (totalIssues === 0) {
      this.report.status = 'compliant';
    } else if (this.report.violations.length > 0) {
      this.report.status = 'non-compliant';
    } else {
      this.report.status = 'compliant-with-warnings';
    }
    
    // コンソール出力
    console.log('\n========================================');
    console.log('📊 Compliance Check Report');
    console.log('========================================\n');
    
    // 統計情報
    console.log('📈 Statistics:');
    console.log(`  Total Endpoints: ${this.report.stats.totalEndpoints}`);
    console.log(`  Implemented: ${this.report.stats.implementedEndpoints}`);
    console.log(`  Missing: ${this.report.stats.missingEndpoints}`);
    console.log(`  Type Matches: ${this.report.stats.typeMatches}`);
    console.log(`  Type Mismatches: ${this.report.stats.typeMismatches}`);
    console.log('');
    
    // 違反
    if (this.report.violations.length > 0) {
      console.log(`❌ Violations (${this.report.violations.length}):`);
      for (const violation of this.report.violations) {
        console.log(`  - [${violation.type}] ${violation.message}`);
        if (violation.file) {
          console.log(`    File: ${violation.file}`);
        }
      }
      console.log('');
    }
    
    // 警告
    if (this.report.warnings.length > 0) {
      console.log(`⚠️  Warnings (${this.report.warnings.length}):`);
      for (const warning of this.report.warnings) {
        console.log(`  - [${warning.type}] ${warning.message}`);
        if (warning.fix) {
          console.log(`    Fix: ${warning.fix}`);
        }
      }
      console.log('');
    }
    
    // 情報
    if (this.report.info.length > 0) {
      console.log('ℹ️  Information:');
      for (const info of this.report.info) {
        console.log(`  - ${info}`);
      }
      console.log('');
    }
    
    // 最終ステータス
    const statusEmoji = {
      'compliant': '✅',
      'compliant-with-warnings': '⚠️',
      'non-compliant': '❌'
    };
    
    console.log('========================================');
    console.log(`${statusEmoji[this.report.status]} Status: ${this.report.status.toUpperCase()}`);
    console.log('========================================\n');
    
    // JSONレポート保存
    const reportFile = path.join(this.baseDir, 'compliance-report.json');
    fs.writeFileSync(reportFile, JSON.stringify(this.report, null, 2));
    console.log(`📄 Full report saved to: ${reportFile}`);
    
    return this.report.status === 'compliant';
  }

  // メイン実行
  run() {
    console.log('🚀 Starting API Specification Compliance Check...\n');
    
    this.checkSpecFiles();
    this.checkGeneratedCode();
    this.checkSpecImplementationMatch();
    this.checkTypeConsistency();
    this.checkSecurity();
    this.checkGitStatus();
    this.checkDependencies();
    
    const isCompliant = this.generateReport();
    
    return isCompliant ? 0 : 1;
  }
}

// メイン実行
if (require.main === module) {
  const checker = new ComplianceChecker();
  const exitCode = checker.run();
  process.exit(exitCode);
}

module.exports = ComplianceChecker;