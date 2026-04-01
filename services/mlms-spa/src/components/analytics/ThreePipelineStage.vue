<script setup lang="ts">
import * as THREE from 'three'
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'

const props = defineProps<{
  stage: string | null
}>()

const host = ref<HTMLDivElement | null>(null)

let renderer: THREE.WebGLRenderer | null = null
let scene: THREE.Scene | null = null
let camera: THREE.PerspectiveCamera | null = null
let mesh: THREE.Mesh | null = null
let frame: number | null = null

function stageColor(stage: string | null): THREE.Color {
  if (!stage) return new THREE.Color(0x4b5563)
  let h = 0
  for (let i = 0; i < stage.length; i++) h = (h + stage.charCodeAt(i) * 17) % 360
  const c = new THREE.Color()
  c.setHSL(h / 360, 0.55, 0.45)
  return c
}

function applyStage(stage: string | null) {
  if (!mesh) return
  const mat = mesh.material as THREE.MeshStandardMaterial
  mat.color.copy(stageColor(stage))
  mat.emissive.copy(stageColor(stage)).multiplyScalar(0.15)
}

function loop() {
  if (!renderer || !scene || !camera || !mesh) return
  mesh.rotation.y += 0.008
  mesh.rotation.x += 0.004
  renderer.render(scene, camera)
  frame = requestAnimationFrame(loop)
}

function mountThree() {
  const el = host.value
  if (!el) return

  const w = el.clientWidth || 320
  const h = 220

  scene = new THREE.Scene()
  scene.background = new THREE.Color(0x0f1117)

  camera = new THREE.PerspectiveCamera(45, w / h, 0.1, 100)
  camera.position.z = 3.2

  const geo = new THREE.BoxGeometry(1.1, 1.1, 1.1)
  const mat = new THREE.MeshStandardMaterial({
    color: stageColor(props.stage),
    metalness: 0.25,
    roughness: 0.45,
  })
  mesh = new THREE.Mesh(geo, mat)
  scene.add(mesh)

  const amb = new THREE.AmbientLight(0xffffff, 0.35)
  scene.add(amb)
  const dir = new THREE.DirectionalLight(0xffffff, 0.85)
  dir.position.set(2, 3, 4)
  scene.add(dir)

  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true })
  renderer.setSize(w, h)
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
  el.innerHTML = ''
  el.appendChild(renderer.domElement)

  applyStage(props.stage)
  loop()
}

let ro: ResizeObserver | null = null

onMounted(() => {
  mountThree()
  if (host.value) {
    ro = new ResizeObserver(() => {
      if (!renderer || !camera || !host.value) return
      const w = host.value.clientWidth || 320
      const h = 220
      camera.aspect = w / h
      camera.updateProjectionMatrix()
      renderer.setSize(w, h)
    })
    ro.observe(host.value)
  }
})

watch(
  () => props.stage,
  (s) => applyStage(s),
)

onBeforeUnmount(() => {
  if (frame != null) cancelAnimationFrame(frame)
  ro?.disconnect()
  renderer?.dispose()
  mesh?.geometry.dispose()
  ;(mesh?.material as THREE.Material)?.dispose()
  renderer = null
  scene = null
  camera = null
  mesh = null
})
</script>

<template>
  <div ref="host" class="three-host" />
</template>

<style scoped>
.three-host {
  width: 100%;
  min-height: 220px;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid var(--shell-border, #2e303a);
}
</style>
