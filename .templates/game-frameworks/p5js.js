// p5.js クリエイティブコーディングテンプレート
// インタラクティブなビジュアルアートとアニメーション開発用

// グローバル変数
let backgroundColor;
let particles = [];
let flowField;
let cols, rows;
let scale = 20;
let zOffset = 0;
let colorPalette;

// 初期設定 - 一度だけ実行される
function setup() {
    // キャンバスの作成
    createCanvas(windowWidth, windowHeight);
    
    // WebGLモードでの3D描画
    // createCanvas(windowWidth, windowHeight, WEBGL);
    
    // 色設定
    colorMode(HSB, 360, 100, 100, 100);
    backgroundColor = color(220, 30, 20);
    background(backgroundColor);
    
    // カラーパレットの初期化
    colorPalette = [
        color(0, 80, 100),    // 赤
        color(120, 80, 100),  // 緑
        color(240, 80, 100),  // 青
        color(60, 80, 100),   // 黄
        color(300, 80, 100)   // マゼンタ
    ];
    
    // フローフィールドの設定
    cols = floor(width / scale);
    rows = floor(height / scale);
    flowField = new Array(cols * rows);
    
    // パーティクルの初期化
    for (let i = 0; i < 500; i++) {
        particles.push(new Particle());
    }
    
    // フレームレートの設定
    frameRate(60);
    
    // その他の初期設定
    pixelDensity(1);
    smooth();
    
    // テキスト設定
    textAlign(CENTER, CENTER);
    textSize(32);
}

// 描画ループ - 毎フレーム実行される
function draw() {
    // 背景の半透明描画（軌跡効果）
    fill(backgroundColor);
    noStroke();
    rect(0, 0, width, height);
    
    // フローフィールドの更新
    updateFlowField();
    
    // パーティクルの更新と描画
    particles.forEach(particle => {
        particle.follow(flowField);
        particle.update();
        particle.edges();
        particle.show();
    });
    
    // UI要素の描画
    drawUI();
    
    // 3D要素の例（WEBGL使用時）
    // push();
    // rotateX(frameCount * 0.01);
    // rotateY(frameCount * 0.01);
    // box(100);
    // pop();
}

// パーティクルクラス
class Particle {
    constructor(x, y) {
        this.pos = createVector(x || random(width), y || random(height));
        this.vel = createVector(0, 0);
        this.acc = createVector(0, 0);
        this.maxSpeed = 4;
        this.color = random(colorPalette);
        this.size = random(2, 8);
        this.lifespan = 255;
    }
    
    follow(vectors) {
        let x = floor(this.pos.x / scale);
        let y = floor(this.pos.y / scale);
        let index = x + y * cols;
        let force = vectors[index];
        if (force) {
            this.applyForce(force);
        }
    }
    
    applyForce(force) {
        this.acc.add(force);
    }
    
    update() {
        this.vel.add(this.acc);
        this.vel.limit(this.maxSpeed);
        this.pos.add(this.vel);
        this.acc.mult(0);
        this.lifespan -= 2;
    }
    
    edges() {
        if (this.pos.x > width) this.pos.x = 0;
        if (this.pos.x < 0) this.pos.x = width;
        if (this.pos.y > height) this.pos.y = 0;
        if (this.pos.y < 0) this.pos.y = height;
    }
    
    show() {
        stroke(this.color);
        strokeWeight(this.size);
        point(this.pos.x, this.pos.y);
    }
    
    isDead() {
        return this.lifespan < 0;
    }
}

// フローフィールドの更新
function updateFlowField() {
    let yOffset = 0;
    for (let y = 0; y < rows; y++) {
        let xOffset = 0;
        for (let x = 0; x < cols; x++) {
            let index = x + y * cols;
            let angle = noise(xOffset, yOffset, zOffset) * TWO_PI * 4;
            let v = p5.Vector.fromAngle(angle);
            v.setMag(1);
            flowField[index] = v;
            xOffset += 0.1;
        }
        yOffset += 0.1;
    }
    zOffset += 0.003;
}

// UI要素の描画
function drawUI() {
    // FPS表示
    push();
    fill(255);
    noStroke();
    textAlign(LEFT, TOP);
    textSize(16);
    text(`FPS: ${floor(frameRate())}`, 10, 10);
    text(`Particles: ${particles.length}`, 10, 30);
    pop();
}

// ウィンドウサイズ変更時の処理
function windowResized() {
    resizeCanvas(windowWidth, windowHeight);
    cols = floor(width / scale);
    rows = floor(height / scale);
    flowField = new Array(cols * rows);
}

// マウスクリック時の処理
function mousePressed() {
    // クリック位置に新しいパーティクルを追加
    for (let i = 0; i < 10; i++) {
        particles.push(new Particle(mouseX, mouseY));
    }
}

// マウスドラッグ時の処理
function mouseDragged() {
    // ドラッグで線を描画
    stroke(0, 80, 100);
    strokeWeight(3);
    line(mouseX, mouseY, pmouseX, pmouseY);
}

// キー押下時の処理
function keyPressed() {
    switch(key) {
        case 's':
        case 'S':
            // 画像を保存
            saveCanvas('myCanvas', 'png');
            break;
        case 'c':
        case 'C':
            // キャンバスをクリア
            background(backgroundColor);
            break;
        case 'r':
        case 'R':
            // リセット
            particles = [];
            for (let i = 0; i < 500; i++) {
                particles.push(new Particle());
            }
            break;
        case ' ':
            // 一時停止/再開
            if (isLooping()) {
                noLoop();
            } else {
                loop();
            }
            break;
    }
    
    // 矢印キーでの制御
    if (keyCode === UP_ARROW) {
        scale = min(scale + 5, 50);
    } else if (keyCode === DOWN_ARROW) {
        scale = max(scale - 5, 10);
    }
}

// ベクトル場の可視化
function drawVectorField() {
    stroke(255, 20);
    strokeWeight(1);
    
    for (let y = 0; y < rows; y++) {
        for (let x = 0; x < cols; x++) {
            let index = x + y * cols;
            let v = flowField[index];
            if (v) {
                push();
                translate(x * scale, y * scale);
                rotate(v.heading());
                line(0, 0, scale, 0);
                pop();
            }
        }
    }
}

// 波形アニメーションの例
class Wave {
    constructor(amplitude, period, phase) {
        this.amplitude = amplitude;
        this.period = period;
        this.phase = phase;
        this.offset = 0;
    }
    
    calculate(x) {
        return sin((x / this.period) + this.phase + this.offset) * this.amplitude;
    }
    
    update() {
        this.offset += 0.05;
    }
    
    draw() {
        stroke(200, 80, 100);
        strokeWeight(2);
        noFill();
        beginShape();
        for (let x = 0; x < width; x += 5) {
            let y = height / 2 + this.calculate(x);
            vertex(x, y);
        }
        endShape();
    }
}

// フラクタル描画の例
function drawFractal(x, y, size, depth) {
    if (depth === 0) return;
    
    // 円を描画
    noFill();
    stroke(map(depth, 0, 5, 0, 360), 80, 100);
    circle(x, y, size);
    
    // 再帰的に小さな円を描画
    let newSize = size * 0.5;
    let angle = TWO_PI / 6;
    
    for (let i = 0; i < 6; i++) {
        let newX = x + cos(angle * i) * size * 0.5;
        let newY = y + sin(angle * i) * size * 0.5;
        drawFractal(newX, newY, newSize, depth - 1);
    }
}

// パーリンノイズを使った地形生成
class Terrain {
    constructor(scl, w, h) {
        this.scl = scl;
        this.w = w;
        this.h = h;
        this.cols = w / scl;
        this.rows = h / scl;
        this.terrain = [];
        this.flying = 0;
    }
    
    generate() {
        this.flying -= 0.02;
        let yoff = this.flying;
        
        for (let y = 0; y < this.rows; y++) {
            let xoff = 0;
            this.terrain[y] = [];
            for (let x = 0; x < this.cols; x++) {
                this.terrain[y][x] = map(noise(xoff, yoff), 0, 1, -100, 100);
                xoff += 0.2;
            }
            yoff += 0.2;
        }
    }
    
    draw() {
        for (let y = 0; y < this.rows - 1; y++) {
            beginShape(TRIANGLE_STRIP);
            for (let x = 0; x < this.cols; x++) {
                let v1 = this.terrain[y][x];
                let v2 = this.terrain[y + 1][x];
                
                fill(map(v1, -100, 100, 0, 360), 80, 100);
                vertex(x * this.scl, y * this.scl, v1);
                vertex(x * this.scl, (y + 1) * this.scl, v2);
            }
            endShape();
        }
    }
}

// オーディオビジュアライザーの例（p5.soundライブラリ使用）
class AudioVisualizer {
    constructor() {
        this.mic = null;
        this.fft = null;
        this.spectrum = [];
        this.waveform = [];
    }
    
    setup() {
        // マイク入力の初期化
        // this.mic = new p5.AudioIn();
        // this.mic.start();
        // this.fft = new p5.FFT();
        // this.fft.setInput(this.mic);
    }
    
    analyze() {
        // this.spectrum = this.fft.analyze();
        // this.waveform = this.fft.waveform();
    }
    
    drawSpectrum() {
        noStroke();
        for (let i = 0; i < this.spectrum.length; i++) {
            let x = map(i, 0, this.spectrum.length, 0, width);
            let h = map(this.spectrum[i], 0, 255, 0, height);
            let c = map(i, 0, this.spectrum.length, 0, 360);
            fill(c, 80, 100);
            rect(x, height - h, width / this.spectrum.length, h);
        }
    }
    
    drawWaveform() {
        noFill();
        stroke(255);
        strokeWeight(2);
        beginShape();
        for (let i = 0; i < this.waveform.length; i++) {
            let x = map(i, 0, this.waveform.length, 0, width);
            let y = map(this.waveform[i], -1, 1, 0, height);
            vertex(x, y);
        }
        endShape();
    }
}

// 画像処理の例
class ImageProcessor {
    constructor(img) {
        this.img = img;
        this.pixels = [];
    }
    
    pixelate(size) {
        this.img.loadPixels();
        for (let y = 0; y < this.img.height; y += size) {
            for (let x = 0; x < this.img.width; x += size) {
                let index = (x + y * this.img.width) * 4;
                let r = this.img.pixels[index];
                let g = this.img.pixels[index + 1];
                let b = this.img.pixels[index + 2];
                
                fill(r, g, b);
                noStroke();
                rect(x, y, size, size);
            }
        }
    }
    
    glitch() {
        this.img.loadPixels();
        for (let i = 0; i < this.img.pixels.length; i += 4) {
            if (random() < 0.01) {
                this.img.pixels[i] = random(255);
                this.img.pixels[i + 1] = random(255);
                this.img.pixels[i + 2] = random(255);
            }
        }
        this.img.updatePixels();
    }
}

// タッチ操作の処理（モバイル対応）
function touchStarted() {
    // タッチ開始時の処理
    particles.push(new Particle(touchX, touchY));
    return false; // デフォルトの動作を防ぐ
}

function touchMoved() {
    // タッチ移動時の処理
    stroke(180, 80, 100);
    strokeWeight(2);
    line(touchX, touchY, ptouchX, ptouchY);
    return false;
}

function touchEnded() {
    // タッチ終了時の処理
    return false;
}

// データ保存と読み込み
function saveData() {
    let data = {
        particles: particles.length,
        scale: scale,
        timestamp: new Date().toISOString()
    };
    saveJSON(data, 'sketch_data.json');
}

function loadData() {
    loadJSON('sketch_data.json', (data) => {
        console.log('Loaded data:', data);
        scale = data.scale;
        // データの復元処理
    });
}