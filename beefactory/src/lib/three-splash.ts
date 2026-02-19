/**
 * BEE FACTORY Three.js splash animation.
 *
 * Sequence: golden particles → 5 bars assemble into hexagon → honey drop forms →
 * bee flies in → logo PNG fades over → scene dissolves.
 */
import * as THREE from 'three';

// ---- Colours ----
const RICH_GOLD = 0xe8c44a;
const DEEP_GOLD = 0x8b6914;
const BG = 0x0a0a0a;

// ---- Easing ----
function easeOutCubic(t: number) {
  return 1 - Math.pow(1 - t, 3);
}
function easeOutBack(t: number) {
  const c = 1.7;
  return 1 + (c + 1) * Math.pow(t - 1, 3) + c * Math.pow(t - 1, 2);
}
function easeInOutCubic(t: number) {
  return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
}

function clamp01(t: number) {
  return Math.max(0, Math.min(1, t));
}

// ---- Bar shapes ----
function roundedRect(w: number, h: number, r: number): THREE.Shape {
  const shape = new THREE.Shape();
  shape.moveTo(-w / 2 + r, -h / 2);
  shape.lineTo(w / 2 - r, -h / 2);
  shape.quadraticCurveTo(w / 2, -h / 2, w / 2, -h / 2 + r);
  shape.lineTo(w / 2, h / 2 - r);
  shape.quadraticCurveTo(w / 2, h / 2, w / 2 - r, h / 2);
  shape.lineTo(-w / 2 + r, h / 2);
  shape.quadraticCurveTo(-w / 2, h / 2, -w / 2, h / 2 - r);
  shape.lineTo(-w / 2, -h / 2 + r);
  shape.quadraticCurveTo(-w / 2, -h / 2, -w / 2 + r, -h / 2);
  return shape;
}

/** Create bar with optional entrance notch */
function makeBar(w: number, h: number, depth: number, notch: boolean): THREE.Shape {
  const r = h * 0.25;
  if (!notch) return roundedRect(w, h, r);

  // Bar with arch cutout in the centre
  const archR = h * 0.4;
  const shape = new THREE.Shape();
  shape.moveTo(-w / 2 + r, -h / 2);
  // Bottom edge up to left of arch
  shape.lineTo(-archR, -h / 2);
  // Arch cutout (semicircle going up)
  shape.absarc(0, -h / 2, archR, Math.PI, 0, true);
  // Continue bottom edge
  shape.lineTo(w / 2 - r, -h / 2);
  shape.quadraticCurveTo(w / 2, -h / 2, w / 2, -h / 2 + r);
  shape.lineTo(w / 2, h / 2 - r);
  shape.quadraticCurveTo(w / 2, h / 2, w / 2 - r, h / 2);
  shape.lineTo(-w / 2 + r, h / 2);
  shape.quadraticCurveTo(-w / 2, h / 2, -w / 2, h / 2 - r);
  shape.lineTo(-w / 2, -h / 2 + r);
  shape.quadraticCurveTo(-w / 2, -h / 2, -w / 2 + r, -h / 2);
  return shape;
}

// ---- Particle system ----
function createParticles(count: number): THREE.Points {
  const positions = new Float32Array(count * 3);
  const velocities = new Float32Array(count * 3);
  for (let i = 0; i < count; i++) {
    positions[i * 3] = (Math.random() - 0.5) * 12;
    positions[i * 3 + 1] = (Math.random() - 0.5) * 8;
    positions[i * 3 + 2] = (Math.random() - 0.5) * 4;
    velocities[i * 3] = (Math.random() - 0.5) * 0.02;
    velocities[i * 3 + 1] = (Math.random() - 0.5) * 0.02;
    velocities[i * 3 + 2] = (Math.random() - 0.5) * 0.01;
  }
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geo.userData.velocities = velocities;
  const mat = new THREE.PointsMaterial({
    color: RICH_GOLD,
    size: 0.04,
    transparent: true,
    opacity: 0.8,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  return new THREE.Points(geo, mat);
}

function updateParticles(pts: THREE.Points, dt: number, convergeFactor: number) {
  const pos = pts.geometry.getAttribute('position') as THREE.BufferAttribute;
  const vel = pts.geometry.userData.velocities as Float32Array;
  for (let i = 0; i < pos.count; i++) {
    let x = pos.getX(i) + vel[i * 3];
    let y = pos.getY(i) + vel[i * 3 + 1];
    let z = pos.getZ(i) + vel[i * 3 + 2];
    // Converge towards centre
    x += (0 - x) * convergeFactor * dt;
    y += (0 - y) * convergeFactor * dt;
    z += (0 - z) * convergeFactor * dt;
    pos.setXYZ(i, x, y, z);
  }
  pos.needsUpdate = true;
}

// ---- Gold material ----
function goldMaterial(): THREE.MeshStandardMaterial {
  return new THREE.MeshStandardMaterial({
    color: RICH_GOLD,
    metalness: 0.9,
    roughness: 0.1,
    emissive: DEEP_GOLD,
    emissiveIntensity: 0.1,
  });
}

// ---- Honey drop ----
function createDrop(): THREE.Mesh {
  // Lathe profile: teardrop
  const pts: THREE.Vector2[] = [];
  for (let i = 0; i <= 20; i++) {
    const t = i / 20;
    const angle = t * Math.PI;
    const r = Math.sin(angle) * 0.18 * (1 - t * 0.3);
    const y = -t * 0.5;
    pts.push(new THREE.Vector2(r, y));
  }
  pts.push(new THREE.Vector2(0, -0.55)); // tip
  const geo = new THREE.LatheGeometry(pts, 24);
  const mat = new THREE.MeshStandardMaterial({
    color: 0xf0b830,
    metalness: 0.4,
    roughness: 0.15,
    transparent: true,
    opacity: 0.9,
  });
  return new THREE.Mesh(geo, mat);
}

// ---- Bee ----
function createBee(): THREE.Group {
  const bee = new THREE.Group();

  // Body (thorax + abdomen)
  const thorax = new THREE.Mesh(
    new THREE.SphereGeometry(0.12, 12, 12),
    new THREE.MeshStandardMaterial({ color: 0x3a2a00, roughness: 0.6 }),
  );
  bee.add(thorax);

  const abdomen = new THREE.Mesh(
    new THREE.SphereGeometry(0.15, 12, 12),
    new THREE.MeshStandardMaterial({ color: 0xf0a500, roughness: 0.5 }),
  );
  abdomen.position.set(-0.2, 0, 0);
  abdomen.scale.set(1.3, 1, 1);
  bee.add(abdomen);

  // Stripes
  for (let s = 0; s < 3; s++) {
    const stripe = new THREE.Mesh(
      new THREE.TorusGeometry(0.14, 0.02, 6, 16),
      new THREE.MeshStandardMaterial({ color: 0x1a1000 }),
    );
    stripe.position.set(-0.15 - s * 0.08, 0, 0);
    stripe.rotation.y = Math.PI / 2;
    bee.add(stripe);
  }

  // Wings
  const wingGeo = new THREE.PlaneGeometry(0.25, 0.1);
  const wingMat = new THREE.MeshStandardMaterial({
    color: 0xffffff,
    transparent: true,
    opacity: 0.35,
    side: THREE.DoubleSide,
    metalness: 0.2,
    roughness: 0.1,
  });
  const wingL = new THREE.Mesh(wingGeo, wingMat);
  wingL.position.set(0, 0.1, 0.08);
  wingL.rotation.x = 0.3;
  bee.add(wingL);
  const wingR = new THREE.Mesh(wingGeo, wingMat);
  wingR.position.set(0, 0.1, -0.08);
  wingR.rotation.x = -0.3;
  bee.add(wingR);

  // Eyes
  const eyeGeo = new THREE.SphereGeometry(0.04, 8, 8);
  const eyeMat = new THREE.MeshStandardMaterial({ color: 0x000000, metalness: 0.8, roughness: 0.2 });
  const eyeL = new THREE.Mesh(eyeGeo, eyeMat);
  eyeL.position.set(0.1, 0.04, 0.06);
  bee.add(eyeL);
  const eyeR = new THREE.Mesh(eyeGeo, eyeMat);
  eyeR.position.set(0.1, 0.04, -0.06);
  bee.add(eyeR);

  bee.scale.setScalar(0.8);
  return bee;
}

// ---- Logo overlay ----
function createLogoPlane(
  texture: THREE.Texture,
  aspect: number,
): THREE.Mesh {
  const h = 5.0;
  const w = h * aspect;
  const geo = new THREE.PlaneGeometry(w, h);
  const mat = new THREE.MeshBasicMaterial({
    map: texture,
    transparent: true,
    opacity: 0,
    depthTest: false,
  });
  return new THREE.Mesh(geo, mat);
}

// ---- Timeline constants (seconds) ----
const T_PARTICLES_CONVERGE = 0.0;
const T_BARS_START = 0.6;
const T_BARS_DUR = 1.2;
const T_DROP_START = 1.6;
const T_DROP_DUR = 0.6;
const T_BEE_START = 1.8;
const T_BEE_DUR = 1.2;
const T_LOGO_FADE_START = 3.2;
const T_LOGO_FADE_DUR = 0.6;
const T_TOTAL = 4.4;

// ---- Main entry ----
export function initSplashScene(
  canvas: HTMLCanvasElement,
  onComplete: () => void,
  logoUrl: string,
) {
  const renderer = new THREE.WebGLRenderer({
    canvas,
    antialias: true,
    alpha: false,
  });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.setSize(canvas.clientWidth, canvas.clientHeight);
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 0.88;

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(BG);

  const camera = new THREE.PerspectiveCamera(
    40,
    canvas.clientWidth / canvas.clientHeight,
    0.1,
    50,
  );
  camera.position.set(0, 0, 8);

  // ---- Lights ----
  const ambientLight = new THREE.AmbientLight(0xfff3e0, 0.22);
  scene.add(ambientLight);

  const spotLight = new THREE.SpotLight(0xffe0a0, 1.4, 20, Math.PI / 5, 0.4);
  spotLight.position.set(2, 4, 6);
  scene.add(spotLight);

  const fillLight = new THREE.PointLight(0xffd080, 0.7, 15);
  fillLight.position.set(-3, -2, 4);
  scene.add(fillLight);

  const topLight = new THREE.PointLight(RICH_GOLD, 0.5, 12);
  topLight.position.set(0, 3, 2);
  scene.add(topLight);

  // ---- Particles ----
  const particles = createParticles(300);
  scene.add(particles);

  // ---- Bars (5 bars forming hexagonal shape) ----
  // widths: narrower at top/bottom, wider in middle
  const barConfigs = [
    { w: 1.6, y: 1.1, notch: false },  // top
    { w: 2.2, y: 0.55, notch: false }, // upper-mid
    { w: 2.4, y: 0.0, notch: true },   // centre (with entrance)
    { w: 2.2, y: -0.55, notch: false }, // lower-mid
    { w: 1.6, y: -1.1, notch: false },  // bottom
  ];
  const barHeight = 0.35;
  const barDepth = 0.35;
  const extrudeSettings: THREE.ExtrudeGeometryOptions = {
    depth: barDepth,
    bevelEnabled: true,
    bevelThickness: 0.04,
    bevelSize: 0.04,
    bevelSegments: 3,
  };

  const bars: THREE.Mesh[] = [];
  const barTargetY: number[] = [];
  const barStartX: number[] = [];

  barConfigs.forEach((cfg, i) => {
    const shape = makeBar(cfg.w, barHeight, barDepth, cfg.notch);
    const geo = new THREE.ExtrudeGeometry(shape, extrudeSettings);
    geo.center();
    const mesh = new THREE.Mesh(geo, goldMaterial());
    mesh.position.y = cfg.y;
    // Start positions: bars slide in from alternating sides
    const startX = i % 2 === 0 ? -6 : 6;
    mesh.position.x = startX;
    mesh.rotation.z = (i % 2 === 0 ? 1 : -1) * 0.3;
    scene.add(mesh);
    bars.push(mesh);
    barTargetY.push(cfg.y);
    barStartX.push(startX);
  });

  // ---- Honey drop ----
  const drop = createDrop();
  drop.position.set(0, -0.2, 0.2);
  drop.scale.setScalar(0);
  scene.add(drop);

  // ---- Bee ----
  const bee = createBee();
  bee.position.set(4, 2, 1);
  bee.visible = false;
  scene.add(bee);

  // ---- Logo overlay ----
  let logoPlane: THREE.Mesh | null = null;
  const loader = new THREE.TextureLoader();
  loader.load(logoUrl, (texture) => {
    const aspect = texture.image.width / texture.image.height;
    logoPlane = createLogoPlane(texture, aspect);
    logoPlane.position.z = 1;
    scene.add(logoPlane);
  });

  // ---- Warm glow circle ----
  const glowGeo = new THREE.CircleGeometry(2.5, 32);
  const glowMat = new THREE.MeshBasicMaterial({
    color: RICH_GOLD,
    transparent: true,
    opacity: 0,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  const glow = new THREE.Mesh(glowGeo, glowMat);
  glow.position.z = -1;
  scene.add(glow);

  // ---- Animation loop ----
  const clock = new THREE.Clock();
  let done = false;

  function animate() {
    if (done) return;
    requestAnimationFrame(animate);

    const elapsed = clock.getElapsedTime();
    const dt = clock.getDelta() || 0.016;

    // Camera subtle drift
    camera.position.x = Math.sin(elapsed * 0.15) * 0.15;
    camera.position.y = Math.cos(elapsed * 0.12) * 0.1;
    camera.lookAt(0, 0, 0);

    // Particles: converge over time
    const converge = clamp01(elapsed / 2.0) * 2.0;
    updateParticles(particles, dt, converge);
    const pMat = particles.material as THREE.PointsMaterial;
    // Fade particles out as bars appear
    pMat.opacity = Math.max(0, 1 - clamp01((elapsed - 1.5) / 1.5));

    // Glow ramp
    glowMat.opacity = clamp01(elapsed / 2.0) * 0.08;

    // Bars slide in
    bars.forEach((bar, i) => {
      const t = clamp01((elapsed - T_BARS_START - i * 0.08) / T_BARS_DUR);
      const ease = easeOutCubic(t);
      bar.position.x = barStartX[i] * (1 - ease);
      bar.rotation.z = (i % 2 === 0 ? 1 : -1) * 0.3 * (1 - ease);
    });

    // Honey drop
    {
      const t = clamp01((elapsed - T_DROP_START) / T_DROP_DUR);
      const ease = easeOutBack(t);
      drop.scale.setScalar(ease);
      drop.position.y = -0.2 - ease * 0.15;
    }

    // Bee flies in (arc path)
    if (elapsed >= T_BEE_START) {
      bee.visible = true;
      const t = clamp01((elapsed - T_BEE_START) / T_BEE_DUR);
      const ease = easeInOutCubic(t);
      // Fly from upper-right to land on top-right of hive
      const landX = 1.2;
      const landY = 0.9;
      bee.position.x = 4 + (landX - 4) * ease;
      bee.position.y = 2 + (landY - 2) * ease + Math.sin(ease * Math.PI) * 0.5;
      bee.position.z = 1 * (1 - ease) + 0.25 * ease;
      bee.rotation.z = -0.2 * (1 - ease);
      // Wing flutter
      const wings = bee.children.filter(
        (c) => c instanceof THREE.Mesh && (c.material as THREE.MeshStandardMaterial).transparent,
      );
      wings.forEach((w, wi) => {
        w.rotation.x = Math.sin(elapsed * 30 + wi) * 0.3 * (1 - t * 0.8);
      });
    }

    // Logo fade-in
    if (logoPlane) {
      const t = clamp01((elapsed - T_LOGO_FADE_START) / T_LOGO_FADE_DUR);
      (logoPlane.material as THREE.MeshBasicMaterial).opacity = t;
    }

    // Point light pulse
    topLight.intensity = 0.5 + Math.sin(elapsed * 2) * 0.12;

    renderer.render(scene, camera);

    // Done
    if (elapsed >= T_TOTAL && !done) {
      done = true;
      onComplete();
    }
  }

  animate();

  // Resize handler
  const onResize = () => {
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    renderer.setSize(w, h);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  };
  window.addEventListener('resize', onResize);

  return () => {
    done = true;
    window.removeEventListener('resize', onResize);
    renderer.dispose();
  };
}

// ---- Mini replay (scroll-to-top) ----
export function playMiniReplay(
  canvas: HTMLCanvasElement,
  onComplete: () => void,
) {
  const renderer = new THREE.WebGLRenderer({
    canvas,
    antialias: true,
    alpha: true,
  });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.setSize(canvas.clientWidth, canvas.clientHeight);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(
    40,
    canvas.clientWidth / canvas.clientHeight,
    0.1,
    50,
  );
  camera.position.set(0, 0, 8);

  scene.add(new THREE.AmbientLight(0xfff3e0, 0.5));
  const light = new THREE.PointLight(RICH_GOLD, 2, 15);
  light.position.set(2, 3, 5);
  scene.add(light);

  // Particles only for mini replay
  const particles = createParticles(150);
  scene.add(particles);

  const clock = new THREE.Clock();
  const duration = 1.8;
  let done = false;

  function animate() {
    if (done) return;
    requestAnimationFrame(animate);
    const elapsed = clock.getElapsedTime();
    const dt = clock.getDelta() || 0.016;

    updateParticles(particles, dt, elapsed * 1.5);

    const pMat = particles.material as THREE.PointsMaterial;
    pMat.opacity = elapsed < 1.0 ? 0.8 : Math.max(0, 0.8 - (elapsed - 1.0) * 1.5);

    renderer.render(scene, camera);

    if (elapsed >= duration && !done) {
      done = true;
      renderer.dispose();
      onComplete();
    }
  }

  animate();
}
