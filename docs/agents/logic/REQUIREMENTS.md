# logic エージェント要件定義書

## 基本情報
- **エージェント名**: logic
- **説明**: ビジネスロジック実装
- **優先度**: High
- **専門領域**: ドメイン駆動設計、ビジネスルール
- **更新日**: 2025-08-26

## 参照ドキュメント
- [REQUIREMENTS.md](../../../REQUIREMENTS.md) - ビジネス要件
- [SPECIFICATIONS.md](../../../SPECIFICATIONS.md) - 技術仕様
- [AGENT_DEFINITIONS.md](../../../AGENT_DEFINITIONS.md) - エージェント定義

## エージェント固有要件

### ゲームロジック詳細機能要件

#### 1. ゲームエンジンコア機能
```typescript
// 必須実装すべきコア機能
interface GameEngine {
  // ゲーム状態管理
  initializeGame(difficulty: Difficulty): GameState;
  makeGuess(guess: number, state: GameState): GuessResult;
  updateGameState(result: GuessResult, state: GameState): GameState;
  
  // ゲーム終了判定
  checkWinCondition(state: GameState): boolean;
  checkLoseCondition(state: GameState): boolean;
  
  // スコア計算
  calculateScore(state: GameState, completionTime: number): ScoreResult;
  calculateBonus(state: GameState, completionTime: number): BonusPoints;
  
  // ヒント生成
  generateHint(state: GameState, hintType: HintType): Hint;
  canUseHint(state: GameState, hintType: HintType): boolean;
}
```

#### 2. 乱数生成とバランス調整
* **乱数品質要件**:
  - 暗号学的強度は不要、Math.random()で十分
  - 同じシード値での再現性は不要（真のランダム性を重視）
  - 各難易度での数値分布の均等性保証

* **難易度バランス要件**:
```typescript
const DIFFICULTY_CONFIG = {
  easy: {
    range: [1, 30],
    maxAttempts: 10,
    timeLimit: null, // 無制限
    hintsAvailable: 3,
    scoreMultiplier: 1.0,
    hintTypes: ['range', 'parity']
  },
  normal: {
    range: [1, 50], 
    maxAttempts: 8,
    timeLimit: 90, // 90秒
    hintsAvailable: 2,
    scoreMultiplier: 1.5,
    hintTypes: ['range', 'parity', 'comparison']
  },
  hard: {
    range: [1, 100],
    maxAttempts: 7,
    timeLimit: 60, // 60秒 
    hintsAvailable: 1,
    scoreMultiplier: 2.0,
    hintTypes: ['range'] // 範囲ヒントのみ
  }
};
```

#### 3. ユーザー入力検証ロジック
```typescript
interface InputValidator {
  validateGuess(input: string, gameState: GameState): ValidationResult;
  sanitizeInput(input: string): number | null;
  checkInputHistory(guess: number, gameState: GameState): boolean;
}

// 実装必須の検証ルール
const VALIDATION_RULES = {
  // 数値形式チェック
  isNumeric: true,
  // 範囲チェック
  isInRange: true, 
  // 重複チェック
  isDuplicate: true,
  // 小数点・負数の扱い
  allowDecimals: false,
  allowNegative: false,
  // 最大桁数制限
  maxDigits: 3
};
```

#### 4. スコア計算システム詳細
```typescript
interface ScoreCalculator {
  calculateBaseScore(state: GameState): number;
  calculateTimeBonus(remainingTime: number, difficulty: Difficulty): number;
  calculateAttemptBonus(remainingAttempts: number, difficulty: Difficulty): number;
  calculateHintPenalty(hintsUsed: number, difficulty: Difficulty): number;
  applyDifficultyMultiplier(score: number, difficulty: Difficulty): number;
}

// スコア計算式の実装要件
const SCORE_FORMULA = {
  baseCompletionBonus: 1000,
  attemptBonusRate: 100, // 残り試行回数 × 100
  timeBonusRate: 10,     // 残り時間(秒) × 10
  hintPenalty: 150,      // ヒント使用1回につき-150
  specialBonuses: {
    perfectGame: 1000,    // 3回以内クリア
    speedRun: 500,        // 残り時間50%以上
    noHint: 500,         // ヒント未使用
    consecutive: 200      // 連続クリア（2回目以降）
  }
};
```

#### 5. ヒントシステム実装要件
```typescript
interface HintGenerator {
  generateRangeHint(target: number, guesses: number[], accuracy: 'precise' | 'rough'): RangeHint;
  generateParityHint(target: number): ParityHint; 
  generateComparisonHint(target: number, lastGuess: number): ComparisonHint;
  
  // ヒントの精度制御
  calculateHintAccuracy(difficulty: Difficulty): 'precise' | 'rough';
  
  // ヒント使用可能性判定
  isHintAllowed(state: GameState, hintType: HintType): boolean;
}
```

### 技術要件

#### アーキテクチャ要件
* **Clean Architecture準拠**: ビジネスロジックをUIや外部依存から分離
* **関数型プログラミング**: 純粋関数での実装を優先、副作用を最小化
* **型安全性**: TypeScriptの厳密な型チェックを活用
* **テスタビリティ**: 依存性注入とモックを活用した単体テスト

#### パフォーマンス要件
* **ゲーム初期化**: 50ms以内
* **推測処理**: 10ms以内
* **スコア計算**: 20ms以内
* **ヒント生成**: 30ms以内
* **メモリ使用量**: 1ゲーム状態あたり1KB未満

#### エラーハンドリング要件
```typescript
// 必須実装すべきエラータイプ
enum GameError {
  INVALID_INPUT = 'INVALID_INPUT',
  OUT_OF_RANGE = 'OUT_OF_RANGE', 
  DUPLICATE_GUESS = 'DUPLICATE_GUESS',
  GAME_ALREADY_FINISHED = 'GAME_ALREADY_FINISHED',
  HINT_NOT_AVAILABLE = 'HINT_NOT_AVAILABLE',
  TIME_LIMIT_EXCEEDED = 'TIME_LIMIT_EXCEEDED'
}

// エラーハンドリングの実装要件
interface GameErrorHandler {
  handleInputError(error: GameError, context?: any): ErrorResult;
  validateGameState(state: GameState): ValidationResult;
  recoverFromError(error: GameError, state: GameState): GameState;
}
```

### 品質要件
* **単体テストカバレッジ**: 95%以上（ビジネスロジックの重要性を考慮）
* **統合テストカバレッジ**: 80%以上
* **レスポンス時間**: 上記パフォーマンス要件に準拠
* **エラー率**: 0.1%未満（ゲームロジックの高品質を要求）
* **コードの複雑度**: Cyclomatic Complexity 10未満/関数

## 成功基準
- [ ] 3つのマークダウンファイルの要件を満たす
- [ ] OpenAPI仕様に準拠（該当する場合）
- [ ] テストが実装され、合格している
- [ ] ドキュメントが完成している
- [ ] コードレビューを通過

## 変更履歴
| 日付 | バージョン | 変更内容 |
|------|-----------|----------|
| 2025-08-26 | 1.0.0 | 初版作成（3ファイル統合版） |
