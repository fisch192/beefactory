import * as THREE from 'three';

export function initHeroScene(canvas: HTMLCanvasElement) {
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
    const renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

    // Lights
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.4);
    scene.add(ambientLight);

    const pointLight = new THREE.PointLight(0xd4a843, 1.5, 50);
    pointLight.position.set(5, 5, 5);
    scene.add(pointLight);

    // Honeycomb Grid
    const hexShape = new THREE.Shape();
    const size = 1;
    for (let i = 0; i < 6; i++) {
        const angle = (i / 6) * Math.PI * 2;
        const x = Math.cos(angle) * size;
        const y = Math.sin(angle) * size;
        if (i === 0) hexShape.moveTo(x, y);
        else hexShape.lineTo(x, y);
    }
    hexShape.closePath();

    const hexGeometry = new THREE.ExtrudeGeometry(hexShape, { depth: 0.1, bevelEnabled: true, bevelThickness: 0.05, bevelSize: 0.05 });
    const hexMaterial = new THREE.MeshStandardMaterial({ 
        color: 0x1a1a1a, 
        metalness: 0.5, 
        roughness: 0.8,
        transparent: true,
        opacity: 0.6
    });

    const gridGroup = new THREE.Group();
    const rows = 12;
    const cols = 15;
    const xStep = size * 1.5;
    const yStep = Math.sqrt(3) * size;

    const hexes: THREE.Mesh[] = [];

    for (let r = -rows/2; r < rows/2; r++) {
        for (let c = -cols/2; c < cols/2; c++) {
            const hex = new THREE.Mesh(hexGeometry, hexMaterial.clone());
            const x = c * xStep;
            const y = r * yStep + (c % 2 === 0 ? 0 : yStep / 2);
            hex.position.set(x, y, -5);
            hex.rotation.x = Math.PI / 2;
            gridGroup.add(hex);
            hexes.push(hex);
        }
    }
    scene.add(gridGroup);

    // Particles (Pollen)
    const particleCount = 200;
    const particlesGeometry = new THREE.BufferGeometry();
    const positions = new Float32Array(particleCount * 3);
    for (let i = 0; i < particleCount * 3; i++) {
        positions[i] = (Math.random() - 0.5) * 30;
    }
    particlesGeometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    const particlesMaterial = new THREE.PointsMaterial({ color: 0xd4a843, size: 0.04, transparent: true, opacity: 0.4 });
    const particles = new THREE.Points(particlesGeometry, particlesMaterial);
    scene.add(particles);

    camera.position.z = 12;

    let mouseX = 0;
    let mouseY = 0;
    const mouse = new THREE.Vector2();
    const raycaster = new THREE.Raycaster();

    window.addEventListener('mousemove', (e) => {
        mouseX = (e.clientX / window.innerWidth - 0.5) * 2;
        mouseY = (e.clientY / window.innerHeight - 0.5) * 2;
        mouse.x = (e.clientX / window.innerWidth) * 2 - 1;
        mouse.y = -(e.clientY / window.innerHeight) * 2 + 1;
    });

    function animate() {
        requestAnimationFrame(animate);

        gridGroup.rotation.x = THREE.MathUtils.lerp(gridGroup.rotation.x, mouseY * 0.1, 0.03);
        gridGroup.rotation.y = THREE.MathUtils.lerp(gridGroup.rotation.y, mouseX * 0.1, 0.03);

        // Interaction
        raycaster.setFromCamera(mouse, camera);
        const intersects = raycaster.intersectObjects(hexes);

        hexes.forEach(hex => {
            const mat = hex.material as THREE.MeshStandardMaterial;
            mat.emissive.lerp(new THREE.Color(0x000000), 0.05);
            hex.position.z = THREE.MathUtils.lerp(hex.position.z, -5, 0.05);
        });

        intersects.forEach(intersect => {
            const hex = intersect.object as THREE.Mesh;
            const mat = hex.material as THREE.MeshStandardMaterial;
            mat.emissive.lerp(new THREE.Color(0xd4a843), 0.3);
            hex.position.z = THREE.MathUtils.lerp(hex.position.z, -4.2, 0.1);
        });

        particles.rotation.y += 0.0005;
        particles.rotation.x += 0.0002;
        particles.position.y += Math.sin(Date.now() * 0.001) * 0.001;

        renderer.render(scene, camera);
    }

    animate();

    window.addEventListener('resize', () => {
        camera.aspect = window.innerWidth / window.innerHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(window.innerWidth, window.innerHeight);
    });
}
