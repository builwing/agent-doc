// Phaser.js ゲーム開発テンプレート
// 最新のPhaser 3を使用した2Dゲーム開発の基本構造

// ゲーム設定
const config = {
    type: Phaser.AUTO,
    width: 800,
    height: 600,
    parent: 'game-container',
    backgroundColor: '#2d2d2d',
    
    // 物理エンジン設定
    physics: {
        default: 'arcade',
        arcade: {
            gravity: { y: 300 },
            debug: false
        }
    },
    
    // シーン設定
    scene: {
        preload: preload,
        create: create,
        update: update
    }
};

// ゲーム変数
let player;
let platforms;
let cursors;
let score = 0;
let scoreText;

// アセットの事前読み込み
function preload() {
    // 画像アセットの読み込み
    // this.load.image('sky', 'assets/sky.png');
    // this.load.image('ground', 'assets/platform.png');
    // this.load.image('star', 'assets/star.png');
    
    // スプライトシートの読み込み
    // this.load.spritesheet('player', 'assets/player.png', {
    //     frameWidth: 32,
    //     frameHeight: 48
    // });
    
    // 音声ファイルの読み込み
    // this.load.audio('jump', 'assets/jump.mp3');
    // this.load.audio('collect', 'assets/collect.mp3');
    
    // プログレスバーの表示
    this.load.on('progress', (value) => {
        console.log('Loading:', Math.floor(value * 100) + '%');
    });
}

// ゲームオブジェクトの作成
function create() {
    // 背景の追加
    // this.add.image(400, 300, 'sky');
    
    // 静的な物理グループの作成（プラットフォーム）
    platforms = this.physics.add.staticGroup();
    
    // 地面の作成
    platforms.create(400, 568, 'ground').setScale(2, 1).refreshBody();
    
    // 追加のプラットフォーム
    // platforms.create(600, 400, 'ground');
    // platforms.create(50, 250, 'ground');
    // platforms.create(750, 220, 'ground');
    
    // プレイヤーの作成
    player = this.physics.add.sprite(100, 450, 'player');
    player.setBounce(0.2);
    player.setCollideWorldBounds(true);
    
    // プレイヤーアニメーションの定義
    this.anims.create({
        key: 'left',
        frames: this.anims.generateFrameNumbers('player', { start: 0, end: 3 }),
        frameRate: 10,
        repeat: -1
    });
    
    this.anims.create({
        key: 'turn',
        frames: [ { key: 'player', frame: 4 } ],
        frameRate: 20
    });
    
    this.anims.create({
        key: 'right',
        frames: this.anims.generateFrameNumbers('player', { start: 5, end: 8 }),
        frameRate: 10,
        repeat: -1
    });
    
    // カーソルキーの設定
    cursors = this.input.keyboard.createCursorKeys();
    
    // WASDキーの追加
    this.wasd = this.input.keyboard.addKeys('W,S,A,D');
    
    // スコアテキストの表示
    scoreText = this.add.text(16, 16, 'Score: 0', {
        fontSize: '32px',
        fill: '#FFF'
    });
    
    // プレイヤーとプラットフォームの衝突判定
    this.physics.add.collider(player, platforms);
    
    // パーティクルエフェクトの設定
    const particles = this.add.particles(0, 0, 'star', {
        speed: { min: 100, max: 200 },
        scale: { start: 1, end: 0 },
        blendMode: 'ADD'
    });
    
    // タイマーイベントの例
    this.time.addEvent({
        delay: 2000,
        callback: () => {
            console.log('2秒経過');
        },
        loop: true
    });
    
    // カメラの設定
    this.cameras.main.setBounds(0, 0, 800, 600);
    this.cameras.main.startFollow(player);
    
    // タッチ/マウス入力の設定
    this.input.on('pointerdown', (pointer) => {
        console.log('Clicked at:', pointer.x, pointer.y);
    });
}

// ゲームの更新ループ
function update(time, delta) {
    // ゲームオーバー判定
    if (player.y > 600) {
        this.scene.restart();
    }
    
    // プレイヤーの移動処理
    if (cursors.left.isDown || this.wasd.A.isDown) {
        player.setVelocityX(-160);
        player.anims.play('left', true);
    }
    else if (cursors.right.isDown || this.wasd.D.isDown) {
        player.setVelocityX(160);
        player.anims.play('right', true);
    }
    else {
        player.setVelocityX(0);
        player.anims.play('turn');
    }
    
    // ジャンプ処理
    if ((cursors.up.isDown || this.wasd.W.isDown) && player.body.touching.down) {
        player.setVelocityY(-330);
    }
}

// カスタムシーンクラスの例
class MenuScene extends Phaser.Scene {
    constructor() {
        super({ key: 'MenuScene' });
    }
    
    preload() {
        // メニュー用のアセット読み込み
    }
    
    create() {
        // タイトルテキスト
        this.add.text(400, 200, 'ゲームタイトル', {
            fontSize: '48px',
            fill: '#FFF'
        }).setOrigin(0.5);
        
        // スタートボタン
        const startButton = this.add.text(400, 350, 'START', {
            fontSize: '32px',
            fill: '#0f0'
        })
        .setOrigin(0.5)
        .setInteractive()
        .on('pointerdown', () => {
            this.scene.start('GameScene');
        })
        .on('pointerover', () => {
            startButton.setStyle({ fill: '#ff0' });
        })
        .on('pointerout', () => {
            startButton.setStyle({ fill: '#0f0' });
        });
    }
}

// ゲームシーンクラス
class GameScene extends Phaser.Scene {
    constructor() {
        super({ key: 'GameScene' });
    }
    
    create() {
        // ゲーム本編のロジック
    }
    
    update(time, delta) {
        // ゲームループの処理
    }
}

// 複数シーンを使用する場合の設定
const multiSceneConfig = {
    type: Phaser.AUTO,
    width: 800,
    height: 600,
    physics: {
        default: 'arcade',
        arcade: {
            gravity: { y: 300 },
            debug: false
        }
    },
    scene: [MenuScene, GameScene]
};

// ゲームインスタンスの作成
const game = new Phaser.Game(config);

// ユーティリティ関数の例

// ランダムな整数を生成
function getRandomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

// 距離計算
function getDistance(x1, y1, x2, y2) {
    return Math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2);
}

// 角度計算
function getAngle(x1, y1, x2, y2) {
    return Math.atan2(y2 - y1, x2 - x1);
}

// グループ管理の例
function createEnemyGroup(scene) {
    const enemies = scene.physics.add.group({
        key: 'enemy',
        repeat: 11,
        setXY: { x: 12, y: 0, stepX: 70 }
    });
    
    enemies.children.entries.forEach((enemy) => {
        enemy.setBounceY(Phaser.Math.FloatBetween(0.4, 0.8));
    });
    
    return enemies;
}

// サウンドマネージャーの例
class SoundManager {
    constructor(scene) {
        this.scene = scene;
        this.sounds = {};
    }
    
    add(key, config = {}) {
        this.sounds[key] = this.scene.sound.add(key, config);
        return this.sounds[key];
    }
    
    play(key) {
        if (this.sounds[key]) {
            this.sounds[key].play();
        }
    }
    
    stop(key) {
        if (this.sounds[key]) {
            this.sounds[key].stop();
        }
    }
}

// 状態管理の例
class GameState {
    constructor() {
        this.score = 0;
        this.lives = 3;
        this.level = 1;
        this.highScore = localStorage.getItem('highScore') || 0;
    }
    
    addScore(points) {
        this.score += points;
        if (this.score > this.highScore) {
            this.highScore = this.score;
            localStorage.setItem('highScore', this.highScore);
        }
    }
    
    reset() {
        this.score = 0;
        this.lives = 3;
        this.level = 1;
    }
}

// オブジェクトプールの例
class ObjectPool {
    constructor(scene, classType, size) {
        this.scene = scene;
        this.classType = classType;
        this.pool = [];
        
        for (let i = 0; i < size; i++) {
            const obj = new classType(scene);
            obj.setActive(false);
            obj.setVisible(false);
            this.pool.push(obj);
        }
    }
    
    get() {
        for (let obj of this.pool) {
            if (!obj.active) {
                obj.setActive(true);
                obj.setVisible(true);
                return obj;
            }
        }
        
        // プールが空の場合、新しいオブジェクトを作成
        const newObj = new this.classType(this.scene);
        this.pool.push(newObj);
        return newObj;
    }
    
    release(obj) {
        obj.setActive(false);
        obj.setVisible(false);
    }
}

// WebSocket通信の例（マルチプレイヤー用）
class NetworkManager {
    constructor(url) {
        this.socket = new WebSocket(url);
        this.setupEventHandlers();
    }
    
    setupEventHandlers() {
        this.socket.onopen = () => {
            console.log('Connected to server');
        };
        
        this.socket.onmessage = (event) => {
            const data = JSON.parse(event.data);
            this.handleMessage(data);
        };
        
        this.socket.onclose = () => {
            console.log('Disconnected from server');
        };
    }
    
    handleMessage(data) {
        switch(data.type) {
            case 'playerMove':
                // 他プレイヤーの移動処理
                break;
            case 'score':
                // スコア更新処理
                break;
        }
    }
    
    send(data) {
        if (this.socket.readyState === WebSocket.OPEN) {
            this.socket.send(JSON.stringify(data));
        }
    }
}