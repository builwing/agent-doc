// Three.js 3Dグラフィックステンプレート
// WebGLを使用した3Dシーン、アニメーション、インタラクション開発用

import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';

// グローバル変数
let scene, camera, renderer;
let controls;
let composer;
let clock;
let mixer;
let stats;

// オブジェクトコンテナ
const objects = [];
const lights = [];
const particles = [];

// 初期化
function init() {
    // シーンの作成
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x000000);
    scene.fog = new THREE.Fog(0x000000, 1, 1000);
    
    // カメラの設定
    const aspect = window.innerWidth / window.innerHeight;
    camera = new THREE.PerspectiveCamera(75, aspect, 0.1, 1000);
    camera.position.set(0, 5, 10);
    camera.lookAt(0, 0, 0);
    
    // レンダラーの設定
    renderer = new THREE.WebGLRenderer({ 
        antialias: true,
        alpha: true
    });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.2;
    document.body.appendChild(renderer.domElement);
    
    // コントロールの設定
    controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controls.minDistance = 3;
    controls.maxDistance = 100;
    controls.maxPolarAngle = Math.PI / 2;
    
    // クロックの初期化
    clock = new THREE.Clock();
    
    // ライティングの設定
    setupLighting();
    
    // 基本的なオブジェクトの作成
    createObjects();
    
    // ポストプロセッシングの設定
    setupPostProcessing();
    
    // イベントリスナーの設定
    setupEventListeners();
    
    // アニメーションループの開始
    animate();
}

// ライティングの設定
function setupLighting() {
    // 環境光
    const ambientLight = new THREE.AmbientLight(0x404040, 0.5);
    scene.add(ambientLight);
    lights.push(ambientLight);
    
    // 指向性ライト
    const directionalLight = new THREE.DirectionalLight(0xffffff, 1);
    directionalLight.position.set(5, 10, 5);
    directionalLight.castShadow = true;
    
    // シャドウマップの設定
    directionalLight.shadow.camera.near = 0.1;
    directionalLight.shadow.camera.far = 50;
    directionalLight.shadow.camera.left = -10;
    directionalLight.shadow.camera.right = 10;
    directionalLight.shadow.camera.top = 10;
    directionalLight.shadow.camera.bottom = -10;
    directionalLight.shadow.mapSize.width = 2048;
    directionalLight.shadow.mapSize.height = 2048;
    
    scene.add(directionalLight);
    lights.push(directionalLight);
    
    // ポイントライト
    const pointLight = new THREE.PointLight(0xff0000, 1, 100);
    pointLight.position.set(10, 10, 10);
    scene.add(pointLight);
    lights.push(pointLight);
    
    // スポットライト
    const spotLight = new THREE.SpotLight(0x00ff00, 1);
    spotLight.position.set(-10, 10, -10);
    spotLight.angle = Math.PI / 6;
    spotLight.penumbra = 0.1;
    spotLight.decay = 2;
    spotLight.distance = 100;
    spotLight.castShadow = true;
    scene.add(spotLight);
    lights.push(spotLight);
    
    // ヘルパーの追加（デバッグ用）
    // const helper = new THREE.DirectionalLightHelper(directionalLight, 5);
    // scene.add(helper);
}

// オブジェクトの作成
function createObjects() {
    // 地面
    const groundGeometry = new THREE.PlaneGeometry(100, 100);
    const groundMaterial = new THREE.MeshStandardMaterial({ 
        color: 0x808080,
        roughness: 0.8,
        metalness: 0.2
    });
    const ground = new THREE.Mesh(groundGeometry, groundMaterial);
    ground.rotation.x = -Math.PI / 2;
    ground.receiveShadow = true;
    scene.add(ground);
    
    // キューブ
    const cubeGeometry = new THREE.BoxGeometry(2, 2, 2);
    const cubeMaterial = new THREE.MeshPhongMaterial({ 
        color: 0x00ff00,
        emissive: 0x002200,
        shininess: 100
    });
    const cube = new THREE.Mesh(cubeGeometry, cubeMaterial);
    cube.position.set(0, 1, 0);
    cube.castShadow = true;
    cube.receiveShadow = true;
    scene.add(cube);
    objects.push(cube);
    
    // 球体
    const sphereGeometry = new THREE.SphereGeometry(1, 32, 32);
    const sphereMaterial = new THREE.MeshStandardMaterial({ 
        color: 0xff0000,
        metalness: 0.5,
        roughness: 0.5
    });
    const sphere = new THREE.Mesh(sphereGeometry, sphereMaterial);
    sphere.position.set(5, 1, 0);
    sphere.castShadow = true;
    scene.add(sphere);
    objects.push(sphere);
    
    // トーラス
    const torusGeometry = new THREE.TorusGeometry(1, 0.4, 16, 100);
    const torusMaterial = new THREE.MeshPhysicalMaterial({ 
        color: 0x0000ff,
        metalness: 0.3,
        roughness: 0.4,
        clearcoat: 1.0,
        clearcoatRoughness: 0.1
    });
    const torus = new THREE.Mesh(torusGeometry, torusMaterial);
    torus.position.set(-5, 1, 0);
    torus.castShadow = true;
    scene.add(torus);
    objects.push(torus);
    
    // パーティクルシステム
    createParticleSystem();
    
    // カスタムシェーダーメッシュ
    createCustomShaderMesh();
}

// パーティクルシステムの作成
function createParticleSystem() {
    const particleCount = 1000;
    const geometry = new THREE.BufferGeometry();
    const positions = [];
    const colors = [];
    
    for (let i = 0; i < particleCount; i++) {
        positions.push(
            (Math.random() - 0.5) * 50,
            Math.random() * 50,
            (Math.random() - 0.5) * 50
        );
        
        colors.push(
            Math.random(),
            Math.random(),
            Math.random()
        );
    }
    
    geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
    geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
    
    const material = new THREE.PointsMaterial({
        size: 0.5,
        vertexColors: true,
        transparent: true,
        opacity: 0.8,
        blending: THREE.AdditiveBlending
    });
    
    const particleSystem = new THREE.Points(geometry, material);
    scene.add(particleSystem);
    particles.push(particleSystem);
}

// カスタムシェーダーメッシュの作成
function createCustomShaderMesh() {
    const vertexShader = `
        varying vec2 vUv;
        varying vec3 vNormal;
        
        void main() {
            vUv = uv;
            vNormal = normalize(normalMatrix * normal);
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    `;
    
    const fragmentShader = `
        uniform float time;
        uniform vec3 color;
        varying vec2 vUv;
        varying vec3 vNormal;
        
        void main() {
            vec3 light = normalize(vec3(1.0, 1.0, 1.0));
            float intensity = dot(vNormal, light) * 0.5 + 0.5;
            
            vec3 finalColor = color * intensity;
            finalColor += sin(time + vUv.x * 10.0) * 0.1;
            finalColor += cos(time + vUv.y * 10.0) * 0.1;
            
            gl_FragColor = vec4(finalColor, 1.0);
        }
    `;
    
    const shaderMaterial = new THREE.ShaderMaterial({
        uniforms: {
            time: { value: 0 },
            color: { value: new THREE.Color(0xffff00) }
        },
        vertexShader: vertexShader,
        fragmentShader: fragmentShader
    });
    
    const geometry = new THREE.IcosahedronGeometry(1.5, 0);
    const mesh = new THREE.Mesh(geometry, shaderMaterial);
    mesh.position.set(0, 3, -5);
    scene.add(mesh);
    objects.push(mesh);
}

// ポストプロセッシングの設定
function setupPostProcessing() {
    composer = new EffectComposer(renderer);
    
    const renderPass = new RenderPass(scene, camera);
    composer.addPass(renderPass);
    
    const bloomPass = new UnrealBloomPass(
        new THREE.Vector2(window.innerWidth, window.innerHeight),
        1.5,  // 強度
        0.4,  // 半径
        0.85  // しきい値
    );
    composer.addPass(bloomPass);
}

// GLTFモデルのロード
function loadGLTFModel(url) {
    const loader = new GLTFLoader();
    
    loader.load(
        url,
        (gltf) => {
            const model = gltf.scene;
            model.traverse((child) => {
                if (child.isMesh) {
                    child.castShadow = true;
                    child.receiveShadow = true;
                }
            });
            
            scene.add(model);
            
            // アニメーションがある場合
            if (gltf.animations && gltf.animations.length) {
                mixer = new THREE.AnimationMixer(model);
                const action = mixer.clipAction(gltf.animations[0]);
                action.play();
            }
        },
        (progress) => {
            console.log('Loading progress:', (progress.loaded / progress.total * 100) + '%');
        },
        (error) => {
            console.error('Error loading model:', error);
        }
    );
}

// テクスチャのロード
function loadTextures() {
    const textureLoader = new THREE.TextureLoader();
    
    // 通常テクスチャ
    const diffuseTexture = textureLoader.load('path/to/diffuse.jpg');
    
    // 法線マップ
    const normalTexture = textureLoader.load('path/to/normal.jpg');
    
    // 環境マップ
    const cubeTextureLoader = new THREE.CubeTextureLoader();
    const environmentMap = cubeTextureLoader.load([
        'path/to/px.jpg', 'path/to/nx.jpg',
        'path/to/py.jpg', 'path/to/ny.jpg',
        'path/to/pz.jpg', 'path/to/nz.jpg'
    ]);
    
    scene.environment = environmentMap;
}

// レイキャスティング（マウスインタラクション）
const raycaster = new THREE.Raycaster();
const mouse = new THREE.Vector2();

function onMouseMove(event) {
    mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
}

function onMouseClick(event) {
    raycaster.setFromCamera(mouse, camera);
    const intersects = raycaster.intersectObjects(objects);
    
    if (intersects.length > 0) {
        const object = intersects[0].object;
        
        // クリックされたオブジェクトのアニメーション
        gsap.to(object.scale, {
            x: 1.5,
            y: 1.5,
            z: 1.5,
            duration: 0.3,
            yoyo: true,
            repeat: 1
        });
    }
}

// イベントリスナーの設定
function setupEventListeners() {
    window.addEventListener('resize', onWindowResize, false);
    window.addEventListener('mousemove', onMouseMove, false);
    window.addEventListener('click', onMouseClick, false);
    
    // キーボードイベント
    document.addEventListener('keydown', onKeyDown, false);
}

// ウィンドウリサイズ処理
function onWindowResize() {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    
    renderer.setSize(window.innerWidth, window.innerHeight);
    
    if (composer) {
        composer.setSize(window.innerWidth, window.innerHeight);
    }
}

// キーボード入力処理
function onKeyDown(event) {
    switch(event.key) {
        case 'w':
            camera.position.z -= 1;
            break;
        case 's':
            camera.position.z += 1;
            break;
        case 'a':
            camera.position.x -= 1;
            break;
        case 'd':
            camera.position.x += 1;
            break;
        case ' ':
            // スペースキーでオブジェクトを追加
            addRandomObject();
            break;
    }
}

// ランダムオブジェクトの追加
function addRandomObject() {
    const geometries = [
        new THREE.BoxGeometry(1, 1, 1),
        new THREE.SphereGeometry(0.5, 32, 32),
        new THREE.ConeGeometry(0.5, 1, 32),
        new THREE.CylinderGeometry(0.5, 0.5, 1, 32)
    ];
    
    const geometry = geometries[Math.floor(Math.random() * geometries.length)];
    const material = new THREE.MeshPhongMaterial({
        color: Math.random() * 0xffffff
    });
    
    const mesh = new THREE.Mesh(geometry, material);
    mesh.position.set(
        (Math.random() - 0.5) * 10,
        Math.random() * 5,
        (Math.random() - 0.5) * 10
    );
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    
    scene.add(mesh);
    objects.push(mesh);
}

// アニメーションループ
function animate() {
    requestAnimationFrame(animate);
    
    const delta = clock.getDelta();
    const time = clock.getElapsedTime();
    
    // コントロールの更新
    controls.update();
    
    // アニメーションミキサーの更新
    if (mixer) {
        mixer.update(delta);
    }
    
    // オブジェクトのアニメーション
    objects.forEach((object, index) => {
        if (object.isMesh) {
            object.rotation.x += 0.01;
            object.rotation.y += 0.01;
            
            // カスタムシェーダーのユニフォーム更新
            if (object.material.uniforms && object.material.uniforms.time) {
                object.material.uniforms.time.value = time;
            }
        }
    });
    
    // パーティクルのアニメーション
    particles.forEach((particleSystem) => {
        particleSystem.rotation.y += 0.001;
    });
    
    // ライトのアニメーション
    if (lights[2]) { // ポイントライト
        lights[2].position.x = Math.sin(time) * 10;
        lights[2].position.z = Math.cos(time) * 10;
    }
    
    // レンダリング
    if (composer) {
        composer.render();
    } else {
        renderer.render(scene, camera);
    }
    
    // Stats更新（パフォーマンス監視）
    if (stats) {
        stats.update();
    }
}

// 物理エンジンの統合例（Cannon.js）
class PhysicsWorld {
    constructor() {
        this.world = new CANNON.World();
        this.world.gravity.set(0, -9.82, 0);
        this.world.broadphase = new CANNON.NaiveBroadphase();
        this.world.solver.iterations = 10;
        
        this.bodies = [];
        this.meshes = [];
    }
    
    addBox(mesh, mass = 1) {
        const shape = new CANNON.Box(new CANNON.Vec3(
            mesh.geometry.parameters.width / 2,
            mesh.geometry.parameters.height / 2,
            mesh.geometry.parameters.depth / 2
        ));
        
        const body = new CANNON.Body({
            mass: mass,
            shape: shape,
            position: new CANNON.Vec3(
                mesh.position.x,
                mesh.position.y,
                mesh.position.z
            )
        });
        
        this.world.add(body);
        this.bodies.push(body);
        this.meshes.push(mesh);
    }
    
    update(deltaTime) {
        this.world.step(deltaTime);
        
        for (let i = 0; i < this.bodies.length; i++) {
            this.meshes[i].position.copy(this.bodies[i].position);
            this.meshes[i].quaternion.copy(this.bodies[i].quaternion);
        }
    }
}

// VRサポート
function setupVR() {
    // VRButton.createButton(renderer);
    renderer.xr.enabled = true;
    
    // VRコントローラーの設定
    const controller1 = renderer.xr.getController(0);
    scene.add(controller1);
    
    const controller2 = renderer.xr.getController(1);
    scene.add(controller2);
    
    // VRアニメーションループ
    renderer.setAnimationLoop(() => {
        renderer.render(scene, camera);
    });
}

// 初期化の実行
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}