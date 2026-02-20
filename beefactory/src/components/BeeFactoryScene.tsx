import { h } from 'preact';
import { useEffect, useRef, useState } from 'preact/hooks';
import * as THREE from 'three';
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/examples/jsm/postprocessing/UnrealBloomPass.js';
import { OutputPass } from 'three/examples/jsm/postprocessing/OutputPass.js';
import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

const FilmGrainShader = {
  uniforms: {
    "tDiffuse": { value: null },
    "time": { value: 0.0 },
    "amount": { value: 0.0008 }
  },
  vertexShader: `
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
  fragmentShader: `
    uniform sampler2D tDiffuse;
    uniform float time;
    uniform float amount;
    varying vec2 vUv;
    
    float rand(vec2 co) {
      return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
    }

    void main() {
      vec4 color = texture2D(tDiffuse, vUv);
      float noise = (rand(vUv + time) - 0.5) * amount;
      gl_FragColor = vec4(color.rgb + noise, color.a);
    }
  `
};

interface SceneState {
  phase: 'greeting' | 'flying' | 'entering' | 'inside';
}

export default function BeeFactoryScene() {
  const mountRef = useRef<HTMLDivElement>(null);
  const [sceneState, setSceneState] = useState<SceneState>({ phase: 'greeting' });

  useEffect(() => {
    if (!mountRef.current) return;

    const canvas = document.createElement('canvas');
    const gl = canvas.getContext('webgl2', { 
      powerPreference: 'high-performance',
      antialias: true,
      alpha: false,
      stencil: false,
      depth: true
    });

    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0xf3fbff);
    scene.fog = new THREE.FogExp2(0xf3fbff, 0.0065);

    const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.01, 500);
    camera.position.set(20, 7.5, 24);

    const renderer = new THREE.WebGLRenderer({ 
      antialias: true, 
      powerPreference: "high-performance",
      canvas
    });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 0.82;
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    mountRef.current.appendChild(renderer.domElement);

    // Lightweight "outdoor" IBL: a simple sky/horizon canvas used as background + reflections.
    const pmremGenerator = new THREE.PMREMGenerator(renderer);
    pmremGenerator.compileEquirectangularShader();

    const envCanvas = document.createElement('canvas');
    envCanvas.width = 1024;
    envCanvas.height = 512;
    const envCtx = envCanvas.getContext('2d')!;
    const skyGrad = envCtx.createLinearGradient(0, 0, 0, envCanvas.height);
    skyGrad.addColorStop(0.0, '#cfeeff');
    skyGrad.addColorStop(0.42, '#f9fcff');
    skyGrad.addColorStop(0.62, '#fff1d6');
    skyGrad.addColorStop(0.78, '#d9f0cc');
    skyGrad.addColorStop(1.0, '#2f5f2b');
    envCtx.fillStyle = skyGrad;
    envCtx.fillRect(0, 0, envCanvas.width, envCanvas.height);

    const sunX = envCanvas.width * 0.72;
    const sunY = envCanvas.height * 0.28;
    const sunR = envCanvas.height * 0.075;
    const sunGlow = envCtx.createRadialGradient(sunX, sunY, 0, sunX, sunY, sunR);
    sunGlow.addColorStop(0.0, 'rgba(255,255,255,0.28)');
    sunGlow.addColorStop(0.35, 'rgba(255,246,225,0.15)');
    sunGlow.addColorStop(1.0, 'rgba(255,246,225,0)');
    envCtx.fillStyle = sunGlow;
    envCtx.beginPath();
    envCtx.arc(sunX, sunY, sunR, 0, Math.PI * 2);
    envCtx.fill();

    const envTexture = new THREE.CanvasTexture(envCanvas);
    envTexture.colorSpace = THREE.SRGBColorSpace;
    envTexture.mapping = THREE.EquirectangularReflectionMapping;
    envTexture.anisotropy = 8;

    const envRT = pmremGenerator.fromEquirectangular(envTexture);
    scene.background = envTexture;
    scene.environment = envRT.texture;
    pmremGenerator.dispose();

    const composer = new EffectComposer(renderer, undefined, {
      frameBufferType: THREE.HalfFloatType
    });
    composer.addPass(new RenderPass(scene, camera));

    const bloom = new UnrealBloomPass(new THREE.Vector2(window.innerWidth, window.innerHeight), 0.03, 0.35, 0.97);
    composer.addPass(bloom);
    
    const grainPass = new ShaderPass(FilmGrainShader);
    composer.addPass(grainPass);
    composer.addPass(new OutputPass());

    // Natural daylight (kept soft; reflections come from scene.environment).
    const ambient = new THREE.AmbientLight(0xfff3dd, 0.18);
    scene.add(ambient);

    // Golden hour sun
    const sunLight = new THREE.DirectionalLight(0xffe2c6, 0.78);
    sunLight.position.set(25, 35, 30);
    sunLight.castShadow = true;
    sunLight.shadow.mapSize.width = 3072;
    sunLight.shadow.mapSize.height = 3072;
    sunLight.shadow.camera.near = 1;
    sunLight.shadow.camera.far = 100;
    sunLight.shadow.camera.left = -30;
    sunLight.shadow.camera.right = 30;
    sunLight.shadow.camera.top = 30;
    sunLight.shadow.camera.bottom = -30;
    sunLight.shadow.bias = -0.00005;
    sunLight.shadow.normalBias = 0.02;
    scene.add(sunLight);

    // Cool rim light
    const rimLight = new THREE.DirectionalLight(0x83a4c0, 0.1);
    rimLight.position.set(-20, 15, -15);
    scene.add(rimLight);

    // Warm bounce
    const bounceLight = new THREE.PointLight(0xffc79b, 0.28, 35);
    bounceLight.position.set(-12, 8, 18);
    scene.add(bounceLight);

    // Sky/ground
    const hemiLight = new THREE.HemisphereLight(0x88b6d6, 0x594636, 0.30);
    scene.add(hemiLight);

    // === TERRAIN ===
    const terrainGeo = new THREE.PlaneGeometry(180, 180, 128, 128);
    const terrainPos = terrainGeo.attributes.position.array as Float32Array;
    for (let i = 0; i < terrainPos.length; i += 3) {
      const x = terrainPos[i];
      const y = terrainPos[i + 1];
      const dist = Math.sqrt(x * x + y * y);
      terrainPos[i + 2] = Math.sin(x * 0.1) * Math.cos(y * 0.1) * 0.5 + Math.random() * 0.3 - dist * 0.01;
    }
    terrainGeo.computeVertexNormals();
    
    const terrainMat = new THREE.MeshStandardMaterial({
      color: 0x4e7436,
      roughness: 0.92,
      metalness: 0.0,
      flatShading: false
    });
    const terrain = new THREE.Mesh(terrainGeo, terrainMat);
    terrain.rotation.x = -Math.PI / 2;
    terrain.position.y = -4;
    terrain.receiveShadow = true;
    scene.add(terrain);

    // === GRASS ===
    const grassGroup = new THREE.Group();
    const grassColors = [0x2a4518, 0x3a5520, 0x1f3510, 0x3d5a25];
    
    const grassGeom = new THREE.BufferGeometry();
    const grassCount = 5000;
    const grassPositions = new Float32Array(grassCount * 6);
    const grassColorsAttr = new Float32Array(grassCount * 6);
    
    for (let i = 0; i < grassCount; i++) {
      const x = (Math.random() - 0.5) * 80;
      const z = (Math.random() - 0.5) * 80;
      const dist = Math.sqrt(x * x + z * z);
      
      if (dist < 7) continue;
      
      const height = 0.3 + Math.random() * 0.5;
      const colorIdx = Math.floor(Math.random() * 4);
      const color = new THREE.Color(grassColors[colorIdx]);
      
      grassPositions[i * 6] = x;
      grassPositions[i * 6 + 1] = -3.8;
      grassPositions[i * 6 + 2] = z;
      grassPositions[i * 6 + 3] = x;
      grassPositions[i * 6 + 4] = -3.8 + height;
      grassPositions[i * 6 + 5] = z;
      
      grassColorsAttr[i * 6] = color.r;
      grassColorsAttr[i * 6 + 1] = color.g;
      grassColorsAttr[i * 6 + 2] = color.b;
      grassColorsAttr[i * 6 + 3] = color.r * 0.8;
      grassColorsAttr[i * 6 + 4] = color.g * 0.8;
      grassColorsAttr[i * 6 + 5] = color.b * 0.8;
    }
    
    grassGeom.setAttribute('position', new THREE.BufferAttribute(grassPositions, 3));
    grassGeom.setAttribute('color', new THREE.BufferAttribute(grassColorsAttr, 3));
    
    const grassMat = new THREE.MeshBasicMaterial({
      vertexColors: true,
      side: THREE.DoubleSide
    });
    
    const grass = new THREE.LineSegments(grassGeom, grassMat);
    scene.add(grass);

    // === FLOWERS ===
    const flowerColors = [0xffdd77, 0xff6699, 0xaa77ff, 0xffaaaa, 0xffddaa];
    for (let i = 0; i < 300; i++) {
      const x = (Math.random() - 0.5) * 65;
      const z = (Math.random() - 0.5) * 65;
      if (Math.sqrt(x*x + z*z) < 6) continue;
      
      const flowerMat = new THREE.MeshStandardMaterial({
        color: flowerColors[Math.floor(Math.random() * flowerColors.length)],
        roughness: 0.5,
        emissive: flowerColors[Math.floor(Math.random() * flowerColors.length)],
        emissiveIntensity: 0.1
      });
      const flower = new THREE.Mesh(
        new THREE.SphereGeometry(0.1 + Math.random() * 0.08, 8, 6),
        flowerMat
      );
      flower.position.set(x, -3.65, z);
      scene.add(flower);
    }

    // === TREES ===
    const treeGroup = new THREE.Group();
    const trunkMat = new THREE.MeshStandardMaterial({ color: 0x2d1a10, roughness: 0.95 });
    
    for (let i = 0; i < 25; i++) {
      const tree = new THREE.Group();
      
      const trunkH = 5 + Math.random() * 5;
      const trunk = new THREE.Mesh(
        new THREE.CylinderGeometry(0.2, 0.35, trunkH, 10),
        trunkMat
      );
      trunk.position.y = trunkH / 2 - 4;
      trunk.castShadow = true;
      tree.add(trunk);

      const leafColors = [0x142810, 0x1f3512, 0x1a3010];
      const leafMat = new THREE.MeshStandardMaterial({ 
        color: leafColors[Math.floor(Math.random() * leafColors.length)], 
        roughness: 0.88,
        flatShading: true
      });
      
      for (let j = 0; j < 4; j++) {
        const foliage = new THREE.Mesh(
          new THREE.ConeGeometry(3 - j * 0.6, 3.5 - j * 0.7, 9),
          leafMat
        );
        foliage.position.y = trunkH + j * 2 - 4;
        foliage.castShadow = true;
        foliage.receiveShadow = true;
        tree.add(foliage);
      }

      const angle = Math.random() * Math.PI * 2;
      const radius = 22 + Math.random() * 28;
      tree.position.set(
        Math.cos(angle) * radius,
        -4,
        Math.sin(angle) * radius
      );
      treeGroup.add(tree);
    }
    scene.add(treeGroup);

    // === HIVE STRUCTURE ===
    const hiveGroup = new THREE.Group();
    const hiveEntrance = new THREE.Vector3(3.05, -2.95, 0);
    const hiveInsideCenter = new THREE.Vector3(hiveEntrance.x - 1.35, hiveEntrance.y + 0.95, hiveEntrance.z);

    // Shadow
    const hiveShadow = new THREE.Mesh(
      new THREE.PlaneGeometry(12, 12),
      new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.18 })
    );
    hiveShadow.rotation.x = -Math.PI / 2;
    hiveShadow.position.y = -3.97;
    scene.add(hiveShadow);

    // Platform
    const platformMat = new THREE.MeshStandardMaterial({ color: 0x6b4a2a, roughness: 0.9 });
    const platform = new THREE.Mesh(new THREE.BoxGeometry(7, 0.3, 6), platformMat);
    platform.position.y = -3.85;
    platform.castShadow = true;
    platform.receiveShadow = true;
    hiveGroup.add(platform);

    // Posts
    const postMat = new THREE.MeshStandardMaterial({ color: 0x5b3a1f, roughness: 0.9 });
    [[3, -2, 2.5], [-3, -2, 2.5], [3, -2, -2.5], [-3, -2, -2.5]].forEach(pos => {
      const post = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.22, 3.5, 8), postMat);
      post.position.set(pos[0], pos[1], pos[2]);
      post.castShadow = true;
      hiveGroup.add(post);
    });

    // === BEEKEEPER HIVE (BEE HOUSE STYLE) ===
    const createBeekeeperHive = (): THREE.Group => {
      const hive = new THREE.Group();

      const woodMat = new THREE.MeshPhysicalMaterial({
        color: 0xb47b40,
        metalness: 0.0,
        roughness: 0.72,
        clearcoat: 0.25,
        clearcoatRoughness: 0.35
      });

      const woodPaintMat = new THREE.MeshPhysicalMaterial({
        color: 0xf7f2e8,
        metalness: 0.0,
        roughness: 0.78,
        clearcoat: 0.18,
        clearcoatRoughness: 0.45
      });

	      const metalMat = new THREE.MeshStandardMaterial({
	        color: 0xcdd5db,
	        roughness: 0.68,
	        metalness: 0.65
	      });

      const base = new THREE.Mesh(new THREE.BoxGeometry(6.4, 0.25, 5.6), woodMat);
      base.position.y = -3.55;
      base.castShadow = true;
      base.receiveShadow = true;
      hive.add(base);

      const brood = new THREE.Mesh(new THREE.BoxGeometry(6.0, 2.25, 5.2), woodPaintMat);
      brood.position.y = -2.3;
      brood.castShadow = true;
      brood.receiveShadow = true;
      hive.add(brood);

      const superBox = new THREE.Mesh(new THREE.BoxGeometry(6.0, 1.7, 5.2), woodPaintMat);
      superBox.position.y = -0.35;
      superBox.castShadow = true;
      superBox.receiveShadow = true;
      hive.add(superBox);

      const innerCover = new THREE.Mesh(new THREE.BoxGeometry(6.2, 0.12, 5.4), woodMat);
      innerCover.position.y = 0.55;
      innerCover.castShadow = true;
      innerCover.receiveShadow = true;
      hive.add(innerCover);

      const roof = new THREE.Mesh(new THREE.BoxGeometry(6.7, 0.55, 5.9), metalMat);
      roof.position.y = 0.88;
      roof.castShadow = true;
      roof.receiveShadow = true;
      hive.add(roof);

      // Simple handles to sell the "beekeeper gear" vibe.
      const handleMat = new THREE.MeshStandardMaterial({ color: 0x1a1410, roughness: 0.75, metalness: 0.1 });
      const handleGeo = new THREE.BoxGeometry(0.65, 0.22, 0.12);
      const addHandles = (y: number) => {
        const h1 = new THREE.Mesh(handleGeo, handleMat);
        h1.position.set(0, y, 2.62);
        h1.castShadow = true;
        hive.add(h1);
        const h2 = h1.clone();
        h2.position.z = -2.62;
        hive.add(h2);
      };
      addHandles(-2.25);
      addHandles(-0.35);

      // Entrance reducer + landing board.
      const reducer = new THREE.Mesh(new THREE.BoxGeometry(1.55, 0.16, 3.0), woodMat);
      reducer.position.set(3.05, -3.12, 0);
      reducer.castShadow = true;
      reducer.receiveShadow = true;
      hive.add(reducer);

      const landing = new THREE.Mesh(new THREE.BoxGeometry(1.8, 0.06, 2.6), woodMat);
      landing.position.set(3.35, -3.25, 0);
      landing.castShadow = true;
      landing.receiveShadow = true;
      hive.add(landing);

      const entranceDark = new THREE.Mesh(
        new THREE.PlaneGeometry(1.05, 0.24),
        new THREE.MeshBasicMaterial({ color: 0x070503 })
      );
      entranceDark.position.set(hiveEntrance.x + 0.02, hiveEntrance.y, hiveEntrance.z);
      entranceDark.rotation.y = Math.PI / 2;
      hive.add(entranceDark);

      return hive;
    };

    hiveGroup.add(createBeekeeperHive());

	    // Logo
	    const logoLoader = new THREE.TextureLoader();
	    const logoTex = logoLoader.load('/images/bee_factory_logo.svg');
	    logoTex.colorSpace = THREE.SRGBColorSpace;
	    logoTex.anisotropy = 16;
	    // Matches beefactory/public/images/logo.png (1184x864).
	    const LOGO_ASPECT = 1184 / 864;
	    
	    const logoMat = new THREE.MeshStandardMaterial({
	      map: logoTex,
	      transparent: true,
	      opacity: 0.98,
	      roughness: 0.65,
	      metalness: 0.0,
	      side: THREE.DoubleSide
	    });

	    // Inner logo gets a tiny emissive boost so it's clearly readable inside the hive
	    // without looking like a light source.
	    const innerLogoMat = logoMat.clone();
	    (innerLogoMat as THREE.MeshStandardMaterial).emissive = new THREE.Color(0xffffff);
	    (innerLogoMat as THREE.MeshStandardMaterial).emissiveMap = logoTex;
	    (innerLogoMat as THREE.MeshStandardMaterial).emissiveIntensity = 0.55;

	    const plaqueMat = new THREE.MeshStandardMaterial({ color: 0xf7f2e8, roughness: 0.9, metalness: 0.0 });
	    const plaque = new THREE.Mesh(new THREE.PlaneGeometry(2.55, 1.55), plaqueMat);
	    plaque.position.set(hiveEntrance.x + 0.035, hiveEntrance.y + 1.05, hiveEntrance.z);
	    plaque.rotation.y = Math.PI / 2;
	    plaque.castShadow = true;
	    plaque.receiveShadow = true;
	    hiveGroup.add(plaque);

	    const outerLogoH = 1.35;
	    const outerLogoW = outerLogoH * LOGO_ASPECT;
	    const logo = new THREE.Mesh(new THREE.PlaneGeometry(outerLogoW, outerLogoH), logoMat);
	    logo.position.set(plaque.position.x + 0.01, plaque.position.y, plaque.position.z);
	    logo.rotation.y = Math.PI / 2;
	    hiveGroup.add(logo);

    // === BEEKEEPER APIARY HOUSE (BIENENHAUS) ===
    const createBienenhaus = (): THREE.Group => {
      const house = new THREE.Group();

      const woodMat = new THREE.MeshPhysicalMaterial({
        color: 0x9a6a3a,
        metalness: 0.0,
        roughness: 0.78,
        clearcoat: 0.12,
        clearcoatRoughness: 0.55
      });

      const woodDarkMat = new THREE.MeshStandardMaterial({
        color: 0x6d4a2c,
        roughness: 0.9,
        metalness: 0.0
      });

      const roofMat = new THREE.MeshStandardMaterial({
        color: 0x8b3b2c,
        roughness: 0.75,
        metalness: 0.0
      });

      // Open-front working hut: walls + roof + bench.
      const floor = new THREE.Mesh(new THREE.BoxGeometry(15, 0.3, 8.5), woodDarkMat);
      floor.position.y = -3.85;
      floor.castShadow = true;
      floor.receiveShadow = true;
      house.add(floor);

      const wallH = 4.6;
      const wallY = -3.7 + wallH / 2;
      const wallBack = new THREE.Mesh(new THREE.BoxGeometry(15, wallH, 0.22), woodMat);
      wallBack.position.set(0, wallY, -4.25);
      wallBack.castShadow = true;
      wallBack.receiveShadow = true;
      house.add(wallBack);

      const wallSideGeo = new THREE.BoxGeometry(0.22, wallH, 8.5);
      const wallLeft = new THREE.Mesh(wallSideGeo, woodMat);
      wallLeft.position.set(-7.5, wallY, 0);
      wallLeft.castShadow = true;
      wallLeft.receiveShadow = true;
      house.add(wallLeft);

      const wallRight = wallLeft.clone();
      wallRight.position.x = 7.5;
      house.add(wallRight);

      const roof = new THREE.Mesh(new THREE.BoxGeometry(16, 0.55, 9.2), roofMat);
      roof.position.set(0, 1.35, 0.1);
      roof.rotation.x = -0.18;
      roof.castShadow = true;
      roof.receiveShadow = true;
      house.add(roof);

      const benchTop = new THREE.Mesh(new THREE.BoxGeometry(6.4, 0.18, 1.9), woodDarkMat);
      benchTop.position.set(-2.1, -2.3, 2.4);
      benchTop.castShadow = true;
      benchTop.receiveShadow = true;
      house.add(benchTop);

      const legGeo = new THREE.BoxGeometry(0.22, 1.35, 0.22);
      const legPositions = [
        [-5.1, -3.0, 1.6],
        [-5.1, -3.0, 3.2],
        [0.9, -3.0, 1.6],
        [0.9, -3.0, 3.2]
      ];
      legPositions.forEach((p) => {
        const leg = new THREE.Mesh(legGeo, woodDarkMat);
        leg.position.set(p[0], p[1], p[2]);
        leg.castShadow = true;
        house.add(leg);
      });

      // A spare stack of boxes and frames (simplified).
      const spareBox = new THREE.Mesh(new THREE.BoxGeometry(3.2, 1.15, 2.8), woodMat);
      spareBox.position.set(4.6, -2.9, 2.2);
      spareBox.castShadow = true;
      spareBox.receiveShadow = true;
      house.add(spareBox);

      const frameMat = new THREE.MeshStandardMaterial({ color: 0xf2e6d2, roughness: 0.85 });
      for (let i = 0; i < 7; i++) {
        const frame = new THREE.Mesh(new THREE.BoxGeometry(0.14, 0.95, 2.35), frameMat);
        frame.position.set(4.6 + (Math.random() - 0.5) * 0.15, -2.55, 2.2 + (i - 3) * 0.28);
        frame.castShadow = true;
        house.add(frame);
      }

      const smokerMat = new THREE.MeshStandardMaterial({ color: 0x8f9aa2, metalness: 0.75, roughness: 0.35 });
      const smoker = new THREE.Mesh(new THREE.CylinderGeometry(0.25, 0.32, 0.75, 14), smokerMat);
      smoker.position.set(-0.2, -2.05, 2.4);
      smoker.castShadow = true;
      house.add(smoker);

      return house;
    };

    const bienenhaus = createBienenhaus();
    bienenhaus.position.set(-16, 0, 10);
    bienenhaus.rotation.y = 0.85;
    scene.add(bienenhaus);

    scene.add(hiveGroup);

    // === HONEYCOMB INTERIOR ===
    const interior = new THREE.Group();
    interior.position.copy(hiveInsideCenter);

	    // Matte wax (avoid glossy/translucent look that reads as "lit up").
	    const waxMat = new THREE.MeshStandardMaterial({
	      color: 0xc9972a,
	      metalness: 0.0,
	      roughness: 0.78
	    });

	    const honeyMat = new THREE.MeshPhysicalMaterial({
	      color: 0xffb02e,
	      metalness: 0.0,
	      roughness: 0.22,
	      transmission: 0.35,
	      thickness: 0.25,
	      clearcoat: 0.7,
	      clearcoatRoughness: 0.14,
	      ior: 1.47,
	      transparent: true,
	      opacity: 0.88
	    });

    const cellR = 0.26;
    const cellDepth = 0.56;
    const rows = 7;
    const cols = 8;
    const zSpacing = cellR * 1.5;
    const ySpacing = Math.sqrt(3) * cellR;

    const cellGeo = new THREE.CylinderGeometry(cellR, cellR, cellDepth, 6, 1, true);
    cellGeo.rotateZ(Math.PI / 2);
    const honeyCapGeo = new THREE.CircleGeometry(cellR * 0.92, 6);
    honeyCapGeo.rotateY(-Math.PI / 2);

    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        const y = (row - (rows - 1) / 2) * ySpacing + 0.85;
        const z = (col - (cols - 1) / 2) * zSpacing + (row % 2 ? zSpacing / 2 : 0);
        const x = -0.75;

        const tube = new THREE.Mesh(cellGeo, waxMat);
        tube.position.set(x, y, z);
        interior.add(tube);

	        if (Math.random() < 0.15) {
	          const honey = new THREE.Mesh(honeyCapGeo, honeyMat);
	          honey.position.set(x - cellDepth / 2 + 0.01, y, z);
	          interior.add(honey);
	        }
      }
    }

	    // Subtle entrance fill (avoid a "spotlight" look).
	    const entranceFill = new THREE.PointLight(0xfff1d2, 0.55, 6, 2.0);
	    entranceFill.position.set(hiveEntrance.x + 0.45, hiveEntrance.y + 0.35, hiveEntrance.z + 0.3);
	    hiveGroup.add(entranceFill);

	    // Soft logo fill: tiny warm light just in front of the inner badge so the logo
	    // is always readable regardless of scene exposure.
	    const logoFill = new THREE.PointLight(0xfff5e8, 1.2, 2.8, 1.5);
	    logoFill.position.set(hiveInsideCenter.x + 1.2, hiveInsideCenter.y + 0.35, hiveInsideCenter.z);
	    hiveGroup.add(logoFill);

	    // Interior logo badge: centered + 3D plaque so it feels "real" without being overly bright.
	    const innerBadge = new THREE.Group();
	    innerBadge.position.set(0.0, 0.35, 0.0);
	    innerBadge.rotation.y = Math.PI / 2; // face the incoming camera (+X)

	    // Hex plaque (extruded) like a wax/wood emblem.
	    const hex = new THREE.Shape();
	    const hexR = 0.92;
	    for (let i = 0; i < 6; i++) {
	      const a = (Math.PI / 3) * i + Math.PI / 6;
	      const px = Math.cos(a) * hexR;
	      const py = Math.sin(a) * hexR;
	      if (i === 0) hex.moveTo(px, py);
	      else hex.lineTo(px, py);
	    }
	    hex.closePath();

	    const plaqueGeo = new THREE.ExtrudeGeometry(hex, {
	      depth: 0.11,
	      bevelEnabled: true,
	      bevelThickness: 0.03,
	      bevelSize: 0.03,
	      bevelOffset: 0,
	      bevelSegments: 3,
	      curveSegments: 12,
	      steps: 1
	    });
	    // Center the geometry around the origin and orient its depth forward (+Z).
	    plaqueGeo.center();

	    const plaque3DMat = new THREE.MeshPhysicalMaterial({
	      color: 0xf0e7d6,
	      roughness: 0.85,
	      metalness: 0.0,
	      clearcoat: 0.18,
	      clearcoatRoughness: 0.45
	    });
	    const plaque3D = new THREE.Mesh(plaqueGeo, plaque3DMat);
	    plaque3D.castShadow = true;
	    plaque3D.receiveShadow = true;
	    innerBadge.add(plaque3D);

	    // Raised logo block (gives real 3D depth + shadow).
	    const innerLogoH = 0.85;
	    const innerLogoW = innerLogoH * LOGO_ASPECT;
	    const logoDepth = 0.08;
	    const logoBoxGeo = new THREE.BoxGeometry(innerLogoW, innerLogoH, logoDepth);

	    const logoSideMat = new THREE.MeshStandardMaterial({ color: 0x2b1c12, roughness: 0.9, metalness: 0.0 });
	    const logoBackMat = new THREE.MeshStandardMaterial({ color: 0xe8decc, roughness: 0.95, metalness: 0.0 });
	    const logoFrontMat = innerLogoMat;

	    // BoxGeometry material order: right, left, top, bottom, front, back
	    const innerLogo = new THREE.Mesh(logoBoxGeo, [
	      logoSideMat,
	      logoSideMat,
	      logoSideMat,
	      logoSideMat,
	      logoFrontMat,
	      logoBackMat
	    ]);
	    innerLogo.position.z = 0.11 / 2 + logoDepth / 2 + 0.015;
	    innerLogo.castShadow = true;
	    innerLogo.receiveShadow = true;
	    innerBadge.add(innerLogo);

	    interior.add(innerBadge);

    hiveGroup.add(interior);

    // === PHOTOREALISTIC BEE ===
    type BeeQuality = 'hero' | 'mid' | 'low';

	    const createBee = (scale = 1, quality?: BeeQuality): THREE.Group => {
	      const q: BeeQuality = quality ?? (scale >= 1.05 ? 'hero' : scale >= 0.6 ? 'mid' : 'low');
	      const cast = q !== 'low';
	      const bee = new THREE.Group();
	      bee.userData.quality = q;

	      // Keep the body "fuzzy" (sheen + high roughness), avoid plastic shine.
	      const thoraxMat = new THREE.MeshPhysicalMaterial({
	        color: 0x171310,
	        metalness: 0.0,
	        roughness: 0.9,
	        sheen: 1.0,
	        sheenRoughness: 0.95,
	        sheenColor: new THREE.Color(0x2b241f),
	        clearcoat: 0.05,
	        clearcoatRoughness: 0.6
	      });

	      const abdomenYellowMat = new THREE.MeshPhysicalMaterial({
	        color: 0xd1a03a,
	        metalness: 0.0,
	        roughness: 0.58,
	        clearcoat: 0.08,
	        clearcoatRoughness: 0.45,
	        sheen: 0.55,
	        sheenRoughness: 0.85,
	        sheenColor: new THREE.Color(0xffe1b8)
	      });

	      const abdomenBlackMat = new THREE.MeshPhysicalMaterial({
	        color: 0x1a1410,
	        metalness: 0.0,
	        roughness: 0.52,
	        clearcoat: 0.1,
	        clearcoatRoughness: 0.5
	      });

	      const wingMat = new THREE.MeshPhysicalMaterial({
	        color: 0xffffff,
	        metalness: 0.0,
	        roughness: 0.18,
	        transparent: true,
	        opacity: 0.45,
	        transmission: 0.9,
	        thickness: 0.004,
	        ior: 1.1,
	        clearcoat: 0.4,
	        clearcoatRoughness: 0.25,
	        iridescence: 0.45,
	        iridescenceIOR: 1.15,
	        iridescenceThicknessRange: [200, 700],
	        side: THREE.DoubleSide,
	        depthWrite: false
	      });

      const veinMat = new THREE.MeshBasicMaterial({
        color: 0x7f9cab,
        transparent: true,
        opacity: 0.22,
        side: THREE.DoubleSide,
        depthWrite: false
	      });

	      // Fuzz / hairs (instanced for better perf)
	      const fuzzCount = q === 'hero' ? 220 : q === 'mid' ? 110 : 16;
	      const fuzzH = (q === 'hero' ? 0.018 : q === 'mid' ? 0.015 : 0.012) * scale;
	      const fuzzGeo = new THREE.ConeGeometry(0.0023 * scale, fuzzH, 4);
	      const fuzzMat = new THREE.MeshStandardMaterial({ color: 0x120d0a, roughness: 1.0, metalness: 0.0 });
	      const fuzz = new THREE.InstancedMesh(fuzzGeo, fuzzMat, fuzzCount);
	      fuzz.castShadow = cast;

      const dummy = new THREE.Object3D();
      const normal = new THREE.Vector3();
      const up = new THREE.Vector3(0, 1, 0);
      const fuzzRadius = 0.13 * scale;
      let written = 0;
      for (let i = 0; i < fuzzCount * 2 && written < fuzzCount; i++) {
        const theta = Math.random() * Math.PI * 2;
        const u = Math.random() * 2 - 1;
        const phi = Math.acos(u);
        const r = fuzzRadius * (0.75 + Math.random() * 0.3);

        const x = Math.sin(phi) * Math.cos(theta) * r * 0.95;
        const y = Math.cos(phi) * r * 0.72 + 0.02 * scale;
        const z = Math.sin(phi) * Math.sin(theta) * r * 0.82 - 0.04 * scale;

        // Keep hairs mostly on head/thorax (not the shiny abdomen).
        if (z < -0.11 * scale) continue;

	        dummy.position.set(x, y, z);
	        normal.set(x, y * 0.9, z + 0.05 * scale).normalize();
	        dummy.quaternion.setFromUnitVectors(up, normal);
	        dummy.rotation.y += (Math.random() - 0.5) * 0.8;
	        // Slight per-hair variation (short, fluffy look).
	        const s = 0.75 + Math.random() * 0.55;
	        dummy.scale.set(1, s, 1);
	        dummy.updateMatrix();
	        fuzz.setMatrixAt(written, dummy.matrix);
	        written++;
	      }
      fuzz.count = written;
      fuzz.instanceMatrix.needsUpdate = true;
      bee.add(fuzz);

      // Thorax
      const thorax = new THREE.Mesh(
        new THREE.SphereGeometry(0.118 * scale, q === 'hero' ? 20 : 14, q === 'hero' ? 18 : 14),
        thoraxMat
      );
      thorax.scale.set(1, 0.86, 0.78);
      thorax.castShadow = cast;
      thorax.receiveShadow = cast;
      bee.add(thorax);

      // Abdomen (slightly glossier)
      const abdomen = new THREE.Group();
	      const abd = new THREE.Mesh(
	        new THREE.CapsuleGeometry(0.095 * scale, 0.285 * scale, 10, q === 'hero' ? 18 : 14),
	        abdomenYellowMat
	      );
	      // Three.js capsules are built along +Y; rotate so the bee faces +Z.
	      abd.rotation.x = Math.PI / 2;
	      abd.castShadow = cast;
	      abd.receiveShadow = cast;
	      abdomen.add(abd);

	      for (let i = 0; i < 4; i++) {
	        const stripe = new THREE.Mesh(
	          new THREE.TorusGeometry(0.092 * scale, 0.0105 * scale, 8, 18),
	          abdomenBlackMat
	        );
	        stripe.position.z = -0.09 * scale + i * 0.085 * scale;
	        stripe.castShadow = cast;
	        abdomen.add(stripe);
	      }

      const tip = new THREE.Mesh(new THREE.ConeGeometry(0.07 * scale, 0.1 * scale, 10), abdomenBlackMat);
      tip.position.z = -0.265 * scale;
      tip.rotation.x = -Math.PI / 2;
      tip.castShadow = cast;
      abdomen.add(tip);

      abdomen.position.set(0, 0, -0.19 * scale);
      bee.add(abdomen);

      // Head
      const head = new THREE.Mesh(
        new THREE.SphereGeometry(0.086 * scale, q === 'hero' ? 18 : 12, q === 'hero' ? 16 : 12),
        thoraxMat
      );
      head.scale.set(1.1, 0.95, 0.9);
      head.position.set(0, 0.015 * scale, 0.145 * scale);
      head.castShadow = cast;
      head.receiveShadow = cast;
      bee.add(head);

      // Eyes (a bit glossier)
      const eyeMat = new THREE.MeshPhysicalMaterial({
        color: 0x0a0705,
        roughness: 0.14,
        metalness: 0.22,
        clearcoat: 1.0,
        clearcoatRoughness: 0.07
      });
      const eyeGeo = new THREE.SphereGeometry(0.034 * scale, q === 'hero' ? 14 : 10, q === 'hero' ? 12 : 10);

      const leftEye = new THREE.Mesh(eyeGeo, eyeMat);
      leftEye.position.set(0.056 * scale, 0.027 * scale, 0.175 * scale);
      leftEye.castShadow = cast;
      bee.add(leftEye);

      const rightEye = leftEye.clone();
      rightEye.position.x = -0.056 * scale;
      bee.add(rightEye);

      // Wings with subtle iridescence and veins
      const createWing = (isLeft: boolean) => {
        const wing = new THREE.Group();
        wing.userData.isWing = true;
        wing.userData.side = isLeft ? 'left' : 'right';

        const shape = new THREE.Shape();
        shape.moveTo(0, 0);
        shape.quadraticCurveTo(0.19 * scale, 0.205 * scale, 0.44 * scale, 0.09 * scale);
        shape.quadraticCurveTo(0.5 * scale, 0, 0.44 * scale, -0.075 * scale);
        shape.quadraticCurveTo(0.19 * scale, -0.115 * scale, 0, 0);

        const wMesh = new THREE.Mesh(new THREE.ShapeGeometry(shape), wingMat);
        wMesh.castShadow = false;
        wing.add(wMesh);

        // Second wing (hindwing) for a more realistic silhouette.
        const wMesh2 = wMesh.clone();
        wMesh2.scale.set(0.82, 0.82, 1);
        wMesh2.position.set(-0.035 * scale, -0.04 * scale, -0.001);
        wing.add(wMesh2);

        for (let i = 0; i < 5; i++) {
          const vein = new THREE.Mesh(new THREE.PlaneGeometry(0.4 * scale, 0.002 * scale), veinMat);
          vein.position.set(0.19 * scale, 0.04 * scale - i * 0.036 * scale, 0.001);
          vein.rotation.z = -0.18 + i * 0.09;
          wing.add(vein);
        }

        wing.position.set(isLeft ? 0.12 * scale : -0.12 * scale, 0.06 * scale, -0.05 * scale);
        wing.rotation.z = isLeft ? 0.1 : -0.1;

        return wing;
      };

      const leftWing = createWing(true);
      const rightWing = createWing(false);
      bee.add(leftWing);
      bee.add(rightWing);
      bee.userData.wings = [leftWing, rightWing];

      // Antennae
      const antennaMat = new THREE.MeshStandardMaterial({ color: 0x1a1410, roughness: 0.75, metalness: 0.0 });
      const createAntenna = (isLeft: boolean) => {
        const ant = new THREE.Group();
        const seg1 = new THREE.Mesh(new THREE.CylinderGeometry(0.0035 * scale, 0.0045 * scale, 0.07 * scale, 4), antennaMat);
        seg1.position.y = 0.035 * scale;
        seg1.castShadow = cast;
        ant.add(seg1);

        const seg2 = new THREE.Mesh(new THREE.CylinderGeometry(0.0025 * scale, 0.0035 * scale, 0.11 * scale, 4), antennaMat);
        seg2.position.y = 0.105 * scale;
        seg2.rotation.x = -0.55;
        seg2.castShadow = cast;
        ant.add(seg2);

        ant.position.set(isLeft ? 0.035 * scale : -0.035 * scale, 0.095 * scale, 0.15 * scale);
        ant.rotation.z = isLeft ? 0.55 : -0.55;

        return ant;
      };

      bee.add(createAntenna(true));
      bee.add(createAntenna(false));

      // Legs (simple, but helps realism; skip on tiny background bees)
      if (q !== 'low') {
        const legMat = new THREE.MeshStandardMaterial({ color: 0x1a1410, roughness: 0.85, metalness: 0.0 });
        const upperGeo = new THREE.CylinderGeometry(0.0042 * scale, 0.0048 * scale, 0.12 * scale, 5);
        const lowerGeo = new THREE.CylinderGeometry(0.0031 * scale, 0.0036 * scale, 0.16 * scale, 5);

        const addLeg = (x: number, z: number, bend: number) => {
          const leg = new THREE.Group();
          leg.position.set(x, -0.02 * scale, z);
          leg.rotation.x = 0.4;

          const upper = new THREE.Mesh(upperGeo, legMat);
          upper.position.y = -0.06 * scale;
          upper.rotation.z = bend;
          upper.castShadow = cast;
          leg.add(upper);

          const lower = new THREE.Mesh(lowerGeo, legMat);
          lower.position.set(Math.sign(x) * 0.025 * scale, -0.16 * scale, 0);
          lower.rotation.z = bend * 0.7;
          lower.castShadow = cast;
          leg.add(lower);

          bee.add(leg);
        };

        const xS = 0.08 * scale;
        addLeg(xS, 0.03 * scale, 0.65);
        addLeg(xS, -0.03 * scale, 0.35);
        addLeg(xS, -0.09 * scale, 0.2);
        addLeg(-xS, 0.03 * scale, -0.65);
        addLeg(-xS, -0.03 * scale, -0.35);
        addLeg(-xS, -0.09 * scale, -0.2);
      }

      // Pollen baskets
      const pollenMat = new THREE.MeshStandardMaterial({ color: 0xb58a00, roughness: 0.55, metalness: 0.0 });
      const basket = new THREE.Mesh(new THREE.CapsuleGeometry(0.022 * scale, 0.045 * scale, 4, 6), pollenMat);
      basket.position.set(0.07 * scale, -0.07 * scale, -0.13 * scale);
      basket.rotation.z = 0.28;
      basket.castShadow = cast;
      bee.add(basket);

      const basket2 = basket.clone();
      basket2.position.x = -0.07 * scale;
      basket2.rotation.z = -0.28;
      bee.add(basket2);

      return bee;
    };

	    // Greeting composition: close enough to feel personal, not so close that it looks like a giant toy.
	    const greetCamPos = new THREE.Vector3(20, 7.6, 24.4);
	    const greetBeePos = new THREE.Vector3(19.2, 7.25, 22.15);

    const beePath = new THREE.CatmullRomCurve3(
      [
        greetBeePos,
        new THREE.Vector3(14.5, 6.0, 15.2),
        new THREE.Vector3(9.4, 3.5, 8.2),
        new THREE.Vector3(hiveEntrance.x + 6.8, hiveEntrance.y + 3.0, hiveEntrance.z + 1.6),
        new THREE.Vector3(hiveEntrance.x + 2.0, hiveEntrance.y + 0.65, hiveEntrance.z + 0.45),
        new THREE.Vector3(hiveEntrance.x + 0.15, hiveEntrance.y + 0.05, hiveEntrance.z),
        hiveInsideCenter
      ],
      false,
      'catmullrom',
      0.55
    );

    // Main bee (hero LOD)
	    const mainBee = createBee(1.05, 'hero');
	    mainBee.position.copy(greetBeePos);
	    mainBee.scale.setScalar(2.15);
	    scene.add(mainBee);

	    // Worker bees (inside)
	    const workers: { mesh: THREE.Group; data: { offset: number; speed: number; r: number; yOff: number; mode: 'work' | 'inout' } }[] = [];
	    const workerCenterX = hiveInsideCenter.x - 0.75; // keep the middle clear for the inner logo badge
	    for (let i = 0; i < 18; i++) {
	      const wBee = createBee(0.55 + Math.random() * 0.35, 'low');
	      const ang = Math.random() * Math.PI * 2;
	      const r = 0.45 + Math.random() * 1.1;
	      const yOff = (Math.random() - 0.5) * 1.2;
	      
	      wBee.position.set(
	        workerCenterX + Math.cos(ang) * r,
	        hiveInsideCenter.y + yOff,
	        hiveInsideCenter.z + Math.sin(ang) * r * 0.7
	      );
	      hiveGroup.add(wBee);
	      workers.push({
        mesh: wBee,
        data: {
          offset: Math.random() * Math.PI * 2,
          speed: 0.22 + Math.random() * 0.35,
          r,
          yOff,
          mode: Math.random() > 0.35 ? 'work' : 'inout'
        }
      });
    }

    // Flying bees (outside)
    const flyers: { mesh: THREE.Group; data: { offset: number; speed: number; r: number; yR: number; pat: string } }[] = [];
    for (let i = 0; i < 26; i++) {
      const bee = createBee(0.32 + Math.random() * 0.38, 'low');
      const ang = Math.random() * Math.PI * 2;
      const r = 6 + Math.random() * 16;
      
      bee.position.set(Math.cos(ang) * r, -1.2 + (Math.random() - 0.25) * 8.5, Math.sin(ang) * r);
      bee.rotation.y = Math.random() * Math.PI * 2;
      scene.add(bee);
      flyers.push({
        mesh: bee,
        data: { offset: Math.random() * Math.PI * 2, speed: 0.12 + Math.random() * 0.32, r, yR: 1.8 + Math.random() * 4.2, pat: Math.random() > 0.55 ? '8' : 'circ' }
      });
    }

    // Pollen particles
    const particleGeo = new THREE.BufferGeometry();
    const particleCount = 600;
    const particlePos = new Float32Array(particleCount * 3);
    for (let i = 0; i < particleCount * 3; i += 3) {
      particlePos[i] = (Math.random() - 0.5) * 55;
      particlePos[i + 1] = (Math.random() - 0.5) * 28;
      particlePos[i + 2] = (Math.random() - 0.5) * 40;
    }
    particleGeo.setAttribute('position', new THREE.BufferAttribute(particlePos, 3));
    
    const particles = new THREE.Points(particleGeo, new THREE.PointsMaterial({
      color: 0xddcc77,
      size: 0.1,
      transparent: true,
      opacity: 0.45,
      sizeAttenuation: true
    }));
    scene.add(particles);

    // === SIGNS ===
    const createSign = () => {
      const sg = new THREE.Group();
      
      const boardMat = new THREE.MeshStandardMaterial({ color: 0x5a4535, roughness: 0.88 });
      const board = new THREE.Mesh(new THREE.BoxGeometry(5.5, 1.6, 0.2), boardMat);
      board.castShadow = true;
      sg.add(board);
      
      // Text
      const c = document.createElement('canvas');
      c.width = 720;
      c.height = 210;
      const ctx = c.getContext('2d')!;
      ctx.fillStyle = '#5a4535';
      ctx.fillRect(0, 0, 720, 210);
      ctx.fillStyle = '#151008';
      ctx.font = 'bold 62px Georgia, serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('BEEFACTORY.SHOP', 360, 105);
      
      const tex = new THREE.CanvasTexture(c);
      tex.colorSpace = THREE.SRGBColorSpace;
      
      const txt = new THREE.Mesh(new THREE.PlaneGeometry(5.2, 1.5), new THREE.MeshBasicMaterial({ map: tex, transparent: true }));
      txt.position.z = 0.11;
      sg.add(txt);
      
      const postMat = new THREE.MeshStandardMaterial({ color: 0x3d2515, roughness: 0.92 });
      const postGeo = new THREE.CylinderGeometry(0.11, 0.14, 3.2, 8);
      
      const p1 = new THREE.Mesh(postGeo, postMat);
      p1.position.set(2.4, -2.4, 0);
      p1.castShadow = true;
      sg.add(p1);
      
      const p2 = p1.clone();
      p2.position.x = -2.4;
      sg.add(p2);
      
      return sg;
    };
    
    const shopSign = createSign();
    shopSign.position.set(11, -2, 9);
    shopSign.rotation.y = -0.45;
    scene.add(shopSign);
    
    const smallSign = createSign();
    smallSign.scale.setScalar(0.42);
    smallSign.position.set(-5.5, -3.2, 5.5);
    smallSign.rotation.y = 0.65;
    scene.add(smallSign);

    // Controls
    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.035;
    controls.enableZoom = true;
    controls.enablePan = false;
    controls.minDistance = 0.8;
    controls.maxDistance = 22;
    controls.target.copy(hiveInsideCenter);
    controls.enabled = false;

	    const clock = new THREE.Clock();
	    let animTime = 0;
	    let scrollY = window.scrollY;
	    const onScroll = () => { scrollY = window.scrollY; };
	    window.addEventListener('scroll', onScroll, { passive: true });

    let currentPhase: SceneState['phase'] = 'greeting';
    const setPhase = (phase: SceneState['phase']) => {
      if (phase === currentPhase) return;
      currentPhase = phase;
      setSceneState({ phase });
    };

    const wingFlap = (beeGroup: THREE.Group, spd: number, off: number) => {
      const wings = beeGroup.userData?.wings as THREE.Group[] | undefined;
      const rz = Math.sin(animTime * spd + off) * 0.22;
      if (Array.isArray(wings) && wings.length >= 2) {
        wings[0].rotation.z = 0.1 + rz;
        wings[1].rotation.z = -0.1 - rz;
        return;
      }

      // Fallback for any older/unknown bee meshes.
      beeGroup.children.forEach(ch => {
        if (ch.type !== 'Group') return;
        if (ch.userData?.isWing === true && ch.userData?.side === 'left') ch.rotation.z = 0.1 + rz;
        else if (ch.userData?.isWing === true && ch.userData?.side === 'right') ch.rotation.z = -0.1 - rz;
      });
    };

    const vZero = new THREE.Vector3();
    const vUp = new THREE.Vector3(0, 1, 0);
    const tmpBeePos = new THREE.Vector3();
    const tmpOrbitPos = new THREE.Vector3();
    const tmpTangent = new THREE.Vector3();
	    const tmpCamPos = new THREE.Vector3();
	    const tmpLookPos = new THREE.Vector3();
	    const tmpLogoPos = new THREE.Vector3();
	    const rotMat = new THREE.Matrix4();
	    const rotQuat = new THREE.Quaternion();

    // Animation loop using setAnimationLoop
	    renderer.setAnimationLoop(() => {
	      animTime = clock.getElapsedTime();
	      const t = animTime;

	      // Travel can be scroll-driven, but also auto-plays on first view so the user
	      // immediately experiences the "follow the bee into the hive" story.
	      const scrollF = Math.min(scrollY / 650, 1);
	      const scrollTravelRaw = Math.max(0, (scrollF - 0.08) / 0.92);
	      const autoHold = 1.25; // seconds
	      const autoDuration = 7.8; // seconds from takeoff to "inside"
	      const autoTravelRaw = THREE.MathUtils.clamp((t - autoHold) / autoDuration, 0, 1);
	      const travelRaw = Math.max(scrollTravelRaw, autoTravelRaw);
	      const travel = travelRaw * travelRaw * (3 - 2 * travelRaw); // smoothstep

	      const isGreeting = travelRaw < 0.001;

	      if (isGreeting) setPhase('greeting');
	      else if (travelRaw < 0.78) setPhase('flying');
	      else if (travelRaw < 0.98) setPhase('entering');
	      else setPhase('inside');

	      const controlsActive = travelRaw >= 0.98;
	      controls.enabled = controlsActive;
	      if (controlsActive) {
	        innerLogo.getWorldPosition(tmpLogoPos);
	        controls.target.lerp(tmpLogoPos, 0.1);
	      }

	      // Greeting: big hero bee looks at the user.
	      if (isGreeting) {
	        mainBee.position.copy(greetBeePos);
	        mainBee.position.x += Math.sin(t * 1.8) * 0.18;
	        mainBee.position.y += Math.cos(t * 1.6) * 0.13;
	        mainBee.position.z += Math.sin(t * 1.3) * 0.14;
	        mainBee.scale.setScalar(2.15);

        camera.position.lerp(greetCamPos, 0.08);
        camera.lookAt(mainBee.position);

        tmpTangent.copy(camera.position).sub(mainBee.position).normalize();
        rotMat.lookAt(tmpTangent, vZero, vUp);
        rotQuat.setFromRotationMatrix(rotMat);
        mainBee.quaternion.slerp(rotQuat, 0.18);

        wingFlap(mainBee, 110, 0);
      } else {
        beePath.getPointAt(travel, tmpBeePos);
        beePath.getTangentAt(travel, tmpTangent).normalize();

        // Subtle flight wobble (stronger early, calmer near the entrance).
        const wobble = (1 - travelRaw) * 0.12 + 0.04;
        tmpBeePos.x += Math.sin(t * 5.5) * wobble;
        tmpBeePos.y += Math.cos(t * 4.2) * wobble * 0.65;
        tmpBeePos.z += Math.sin(t * 4.8) * wobble * 0.8;

        // Once we are inside, let her hover around other bees.
        const insideBlend = THREE.MathUtils.smoothstep(travelRaw, 0.94, 1.0);
        tmpOrbitPos.set(
          hiveInsideCenter.x - 0.7 + Math.cos(t * 0.55) * 0.95,
          hiveInsideCenter.y + 0.25 + Math.sin(t * 0.9) * 0.28,
          hiveInsideCenter.z + Math.sin(t * 0.55) * 0.7
        );
        tmpBeePos.lerp(tmpOrbitPos, insideBlend);

        mainBee.position.copy(tmpBeePos);
	        mainBee.scale.setScalar(THREE.MathUtils.lerp(2.15, 0.86, travel));

        rotMat.lookAt(tmpTangent, vZero, vUp);
        rotQuat.setFromRotationMatrix(rotMat);
        mainBee.quaternion.slerp(rotQuat, 0.12);

        wingFlap(mainBee, 125, 0);

	        // Camera: follow until we hand off to OrbitControls inside the hive.
	        if (!controlsActive) {
	          const insideT = THREE.MathUtils.smoothstep(travelRaw, 0.72, 1.0);
	          const backDist = THREE.MathUtils.lerp(5.6, 1.1, insideT);
	          const upDist = THREE.MathUtils.lerp(2.0, 0.75, insideT);

          tmpCamPos.copy(tmpTangent).multiplyScalar(-backDist).add(tmpBeePos);
          tmpCamPos.y += upDist;
          camera.position.lerp(tmpCamPos, 0.08);

	          const lookAhead = THREE.MathUtils.lerp(2.35, 1.4, insideT);
	          tmpLookPos.copy(tmpTangent).multiplyScalar(lookAhead).add(tmpBeePos);

	          // As we enter the hive, bias the camera towards the integrated inner logo
	          // so it's clearly visible during the "fly inside" moment.
	          const logoBias = THREE.MathUtils.smoothstep(travelRaw, 0.8, 0.97);
	          if (logoBias > 0.001) {
	            innerLogo.getWorldPosition(tmpLogoPos);
	            tmpLookPos.lerp(tmpLogoPos, logoBias * 0.78);
	          }
	          camera.lookAt(tmpLookPos);
	        }
	      }

      // Workers
	      workers.forEach((w, i) => {
	        if (w.data.mode === 'work') {
	          const ang = t * w.data.speed + w.data.offset;
	          w.mesh.position.x = workerCenterX + Math.cos(ang) * w.data.r;
	          w.mesh.position.z = hiveInsideCenter.z + Math.sin(ang) * w.data.r * 0.7;
	          w.mesh.position.y = hiveInsideCenter.y + w.data.yOff + Math.sin(t * 1.6 + i) * 0.12;
	        } else {
	          const ent = (Math.sin(t * 0.38 + w.data.offset) + 1) / 2;
          w.mesh.position.x = THREE.MathUtils.lerp(hiveInsideCenter.x, hiveEntrance.x + 0.55, ent);
          w.mesh.position.y = THREE.MathUtils.lerp(hiveInsideCenter.y, hiveEntrance.y + 0.15, ent);
          w.mesh.position.z = THREE.MathUtils.lerp(hiveInsideCenter.z, hiveEntrance.z, ent);
        }
        w.mesh.lookAt(hiveInsideCenter.x - 2.0, hiveInsideCenter.y, hiveInsideCenter.z);
        wingFlap(w.mesh, 52 + i * 2.5, i * 0.4);
      });

      // Flyers
      flyers.forEach((f, i) => {
        const ang = t * f.data.speed + f.data.offset;
        
        if (f.data.pat === '8') {
          f.mesh.position.x = Math.cos(ang) * f.data.r;
          f.mesh.position.z = Math.sin(ang * 2) * f.data.r * 0.45;
          f.mesh.position.y = -1.8 + Math.sin(ang) * f.data.yR;
        } else {
          f.mesh.position.x = Math.cos(ang) * f.data.r;
          f.mesh.position.z = Math.sin(ang) * f.data.r * 0.65;
          f.mesh.position.y = -1.2 + Math.sin(ang * 1.4) * f.data.yR * 0.45;
        }
        
        f.mesh.rotation.y = -ang + Math.PI / 2;
        wingFlap(f.mesh, 60 + i * 1.8, i * 0.28);
      });

      // Environment
      grass.rotation.x = -Math.PI / 2;
      grass.position.y = -3.8 + Math.sin(t * 0.35) * 0.03;
      
      particles.rotation.y = t * 0.012;
      particles.position.y = Math.sin(t * 0.07) * 0.25;

      hiveGroup.rotation.y = 0;
      hiveGroup.position.y = 0;

      if (controls.enabled) controls.update();

      grainPass.uniforms.time.value = t;

      composer.render();
    });

    const onResize = () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
      composer.setSize(window.innerWidth, window.innerHeight);
    };
    window.addEventListener('resize', onResize);

    return () => {
      window.removeEventListener('resize', onResize);
      window.removeEventListener('scroll', onScroll);
      if (mountRef.current && renderer.domElement.parentNode) {
        mountRef.current.removeChild(renderer.domElement);
      }
      envRT.dispose();
      envTexture.dispose();
      renderer.dispose();
      controls.dispose();
      composer.dispose();
    };
  }, []);

  return (
    <div className="relative w-full h-full">
      <div ref={mountRef} className="absolute inset-0 z-0" />
      
      {sceneState.phase === 'greeting' && (
        <div className="absolute inset-0 flex items-center justify-center z-10 pointer-events-none">
          <div className="text-black/80 text-2xl tracking-wide bg-white/65 px-10 py-5 rounded-full backdrop-blur-md shadow-[0_10px_40px_rgba(0,0,0,0.18)]">
            Welcome. Follow the bee.
          </div>
        </div>
      )}
      
      {sceneState.phase === 'flying' && (
        <div className="absolute bottom-14 left-1/2 -translate-x-1/2 z-10 pointer-events-none">
          <div className="text-black/75 text-sm tracking-widest bg-white/60 px-5 py-2.5 rounded-full backdrop-blur-sm shadow-[0_10px_30px_rgba(0,0,0,0.14)]">
            Scroll to fly to the hive
          </div>
        </div>
      )}
      
      {sceneState.phase === 'entering' && (
        <div className="absolute bottom-10 left-1/2 -translate-x-1/2 z-10 pointer-events-none">
          <p className="text-black/70 text-xs tracking-widest bg-white/65 px-4 py-2 rounded-full backdrop-blur-sm shadow-[0_10px_30px_rgba(0,0,0,0.14)]">
            Entering the hive
          </p>
        </div>
      )}
      
      {sceneState.phase === 'inside' && (
        <div className="absolute top-5 left-1/2 -translate-x-1/2 z-10 pointer-events-none">
          <p className="text-black/70 text-xs tracking-widest bg-white/65 px-4 py-2 rounded-full backdrop-blur-sm shadow-[0_10px_30px_rgba(0,0,0,0.14)]">
            Inside the hive • Drag to look around
          </p>
        </div>
      )}
    </div>
  );
}
