import * as THREE from 'three';

export function initSplashScene(canvas: HTMLCanvasElement, onComplete: () => void) {
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
  const renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

  // Lights
  const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
  scene.add(ambientLight);

  const pointLight = new THREE.PointLight(0xd4a843, 2, 100);
  pointLight.position.set(5, 5, 5);
  scene.add(pointLight);

  const spotLight = new THREE.SpotLight(0xffffff, 1);
  spotLight.position.set(0, 10, 0);
  scene.add(spotLight);

  // Hexagon Logo
  const hexShape = new THREE.Shape();
  const size = 2;
  for (let i = 0; i < 6; i++) {
    const angle = (i / 6) * Math.PI * 2;
    const x = Math.cos(angle) * size;
    const y = Math.sin(angle) * size;
    if (i === 0) hexShape.moveTo(x, y);
    else hexShape.lineTo(x, y);
  }
  hexShape.closePath();

  const extrudeSettings = { depth: 0.2, bevelEnabled: true, bevelThickness: 0.1, bevelSize: 0.1, bevelSegments: 3 };
  const geometry = new THREE.ExtrudeGeometry(hexShape, extrudeSettings);
  const material = new THREE.MeshStandardMaterial({ 
    color: 0xd4a843, 
    metalness: 0.7, 
    roughness: 0.2,
    emissive: 0xd4a843,
    emissiveIntensity: 0.2
  });
  const hexagon = new THREE.Mesh(geometry, material);
  hexagon.rotation.x = Math.PI / 2;
  hexagon.scale.set(0, 0, 0);
  scene.add(hexagon);

  // Inner Hexagon (Wireframe)
  const innerHexGeometry = new THREE.RingGeometry(1.2, 1.3, 6);
  const innerHexMaterial = new THREE.MeshBasicMaterial({ color: 0xffffff, side: THREE.DoubleSide, transparent: true, opacity: 0.5 });
  const innerHex = new THREE.Mesh(innerHexGeometry, innerHexMaterial);
  innerHex.rotation.x = Math.PI / 2;
  innerHex.position.z = 0.15;
  innerHex.scale.set(0, 0, 0);
  scene.add(innerHex);

  // Stylized Bee
  const beeGroup = new THREE.Group();
  
  // Body
  const bodyGeom = new THREE.SphereGeometry(0.4, 32, 32);
  bodyGeom.scale(1.2, 0.8, 0.8);
  const bodyMat = new THREE.MeshStandardMaterial({ color: 0xd4a843 });
  const body = new THREE.Mesh(bodyGeom, bodyMat);
  beeGroup.add(body);

  // Stripes
  const stripeGeom = new THREE.TorusGeometry(0.38, 0.05, 16, 100);
  const stripeMat = new THREE.MeshStandardMaterial({ color: 0x111111 });
  for (let i = -1; i <= 1; i++) {
    const stripe = new THREE.Mesh(stripeGeom, stripeMat);
    stripe.position.x = i * 0.2;
    stripe.rotation.y = Math.PI / 2;
    beeGroup.add(stripe);
  }

  // Wings
  const wingGeom = new THREE.EllipseCurve(0, 0, 0.5, 0.3, 0, Math.PI * 2, false, 0).getPoints(50);
  const wingShape = new THREE.Shape(wingGeom);
  const wingGeometry = new THREE.ShapeGeometry(wingShape);
  const wingMat = new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.4, side: THREE.DoubleSide });
  
  const leftWing = new THREE.Mesh(wingGeometry, wingMat);
  leftWing.position.set(0, 0.3, 0.1);
  leftWing.rotation.x = Math.PI / 2;
  beeGroup.add(leftWing);

  const rightWing = new THREE.Mesh(wingGeometry, wingMat);
  rightWing.position.set(0, 0.3, -0.1);
  rightWing.rotation.x = -Math.PI / 2;
  beeGroup.add(rightWing);

  beeGroup.position.set(10, 5, -10);
  scene.add(beeGroup);

  camera.position.z = 8;

  // Animation State
  let startTime = Date.now();
  let state = 'flying-in'; // flying-in, circling, settling, finished

  const honeyDrops: THREE.Mesh[] = [];
  const dropGeometry = new THREE.SphereGeometry(0.05, 16, 16);
  const dropMaterial = new THREE.MeshStandardMaterial({ color: 0xd4a843, transparent: true, opacity: 0.8 });

  function animate() {
    const elapsed = (Date.now() - startTime) / 1000;
    requestAnimationFrame(animate);

    // Wing flapping
    leftWing.rotation.z = Math.sin(elapsed * 60) * 0.6;
    rightWing.rotation.z = -Math.sin(elapsed * 60) * 0.6;

    if (state === 'flying-in') {
      // S-curve flight path
      beeGroup.position.x = 10 - elapsed * 7;
      beeGroup.position.y = Math.sin(elapsed * 3) * 2;
      beeGroup.position.z = -10 + elapsed * 9;
      beeGroup.lookAt(beeGroup.position.x - 1, Math.sin((elapsed + 0.1) * 3) * 2, beeGroup.position.z + 1);
      
      if (elapsed > 2) state = 'circling';
    } else if (state === 'circling') {
      const angle = (elapsed - 2) * 2.5;
      const radius = 3 + Math.sin(elapsed) * 0.5;
      beeGroup.position.x = Math.cos(angle) * radius;
      beeGroup.position.z = Math.sin(angle) * radius + 2;
      beeGroup.position.y = Math.cos(elapsed * 2) * 0.5;
      beeGroup.lookAt(0, 0, 2);

      // Scale up logo with "elastic" effect
      const progress = Math.min(1, (elapsed - 2) * 1.5);
      const elastic = 1 - Math.cos(progress * Math.PI * 1.5) * Math.exp(-progress * 3);
      hexagon.scale.set(elastic, elastic, elastic);
      hexagon.rotation.z = elapsed * 0.5;
      innerHex.scale.set(elastic * 1.1, elastic * 1.1, elastic * 1.1);
      innerHex.rotation.z = -elapsed * 0.3;

      // Spawn honey particles
      if (Math.random() > 0.8 && elapsed < 5) {
          const drop = new THREE.Mesh(dropGeometry, dropMaterial);
          drop.position.copy(beeGroup.position);
          scene.add(drop);
          honeyDrops.push(drop);
      }

      if (elapsed > 5.5) state = 'settling';
    } else if (state === 'settling') {
      beeGroup.position.lerp(new THREE.Vector3(-1.8, 0.5, 3), 0.08);
      beeGroup.rotation.y = THREE.MathUtils.lerp(beeGroup.rotation.y, Math.PI / 4, 0.08);
      
      if (elapsed > 7.5) {
        state = 'finished';
        onComplete();
      }
    }

    // Animate honey drops
    for (let i = honeyDrops.length - 1; i >= 0; i--) {
        const drop = honeyDrops[i];
        drop.position.y -= 0.02;
        drop.scale.multiplyScalar(0.98);
        if (drop.scale.x < 0.01) {
            scene.remove(drop);
            honeyDrops.splice(i, 1);
        }
    }

    // Subtle breathing for hexagon
    const pulse = 1 + Math.sin(elapsed * 2) * 0.02;
    hexagon.scale.multiplyScalar(pulse);

    renderer.render(scene, camera);
  }

  animate();

  // Handle Resize
  window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });
}
