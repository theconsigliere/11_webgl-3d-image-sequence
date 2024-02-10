import * as THREE from "three"
import { REVISION } from "three"
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js"
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js"
import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader.js"
import fragment from "./shader/fragment.glsl"
import vertex from "./shader/vertex.glsl"
import GUI from "lil-gui"
import gsap from "gsap"
import { KTX2Loader } from "three/examples/jsm/loaders/KTX2Loader.js"

import tDiffuse from "../img/gameboy_diffuse-high.png.ktx2?url"
import tPosition from "../img/gameboy_position-high.png.ktx2?url"
import tMV from "../img/gameboy_mv-high.png.ktx2?url"
import tData from "../img/gameboy_data-high.png.ktx2?url"

export default class Sketch {
  constructor(options) {
    this.scene = new THREE.Scene()

    this.container = options.dom
    this.width = this.container.offsetWidth
    this.height = this.container.offsetHeight
    this.renderer = new THREE.WebGLRenderer()
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    this.renderer.setSize(this.width, this.height)
    this.renderer.setClearColor(0xfed703, 1)

    this.container.appendChild(this.renderer.domElement)

    this.camera = new THREE.PerspectiveCamera(
      70,
      this.width / this.height,
      0.01,
      1000
    )

    // let frustumSize = 10;
    // let aspect = this.width / this.height;
    // this.camera = new THREE.OrthographicCamera( frustumSize * aspect / - 2, frustumSize * aspect / 2, frustumSize / 2, frustumSize / - 2, -1000, 1000 );
    this.camera.position.set(0, 0, 0.8)
    this.controls = new OrbitControls(this.camera, this.renderer.domElement)
    this.time = 0

    const THREE_PATH = `https://unpkg.com/three@0.${REVISION}.x`
    this.dracoLoader = new DRACOLoader(
      new THREE.LoadingManager()
    ).setDecoderPath(`${THREE_PATH}/examples/jsm/libs/draco/gltf/`)
    this.gltfLoader = new GLTFLoader()
    this.gltfLoader.setDRACOLoader(this.dracoLoader)

    this.basisloader = new KTX2Loader()

    this.basisloader.setTranscoderPath(`${THREE_PATH}/examples/jsm/libs/basis/`)
    this.basisloader.detectSupport(this.renderer)

    this.isPlaying = true
    this.setUpSettings()
    this.addObjects()
    this.resize()
    this.render()
    this.setupResize()
    this.addMouseEvents()
  }

  addMouseEvents() {
    document.body.addEventListener("mousemove", (e) => {
      this.material.uniforms.uMouse.value = e.clientX / window.innerWidth
    })
  }

  setUpSettings() {
    this.settings = {
      progress: 0,
      uDisplacementStrength: 0.0025,
    }
    this.gui = new GUI()
    this.gui.add(this.settings, "progress", 0, 1, 0.01).onChange((val) => {
      this.material.uniforms.progress.value = val
    })

    this.gui
      .add(this.settings, "uDisplacementStrength", 0, 0.01, 0.0001)
      .onChange((val) => {
        this.material.uniforms.uDisplacementStrength.value = val
      })
  }

  setupResize() {
    window.addEventListener("resize", this.resize.bind(this))
  }

  resize() {
    this.width = this.container.offsetWidth
    this.height = this.container.offsetHeight
    this.renderer.setSize(this.width, this.height)
    this.camera.aspect = this.width / this.height
    this.camera.updateProjectionMatrix()
  }

  addObjects() {
    this.material = new THREE.ShaderMaterial({
      extensions: {
        derivatives: "#extension GL_OES_standard_derivatives : enable",
      },
      side: THREE.DoubleSide,
      uniforms: {
        uDisplacementStrength: { value: this.settings.uDisplacementStrength },
        time: { value: 0 },
        progress: { value: 0 },
        uMouse: { value: 0 },
        uDiffuse: { value: null },
        uPosition: { value: null },
        uMotion: { value: null },
        uData: { value: null },
        resolution: { value: new THREE.Vector4() },
      },
      // wireframe: true,
      transparent: true,
      vertexShader: vertex,
      fragmentShader: fragment,
    })

    this.geometry = new THREE.PlaneGeometry(1, 1, 1, 1)

    this.plane = new THREE.Mesh(this.geometry, this.material)
    this.scene.add(this.plane)

    this.basisloader.load(tDiffuse, (texture) => {
      this.material.uniforms.uDiffuse.value = texture
      texture.colorSpace = THREE.LinearSRGBColorSpace
      texture.needsUpdate = true
    })

    this.basisloader.load(tData, (texture) => {
      this.material.uniforms.uData.value = texture
      texture.colorSpace = THREE.LinearSRGBColorSpace
      texture.needsUpdate = true
    })

    this.basisloader.load(tPosition, (texture) => {
      this.material.uniforms.uPosition.value = texture
      texture.colorSpace = THREE.LinearSRGBColorSpace
      texture.needsUpdate = true
    })

    this.basisloader.load(tMV, (texture) => {
      this.material.uniforms.uMotion.value = texture
      texture.colorSpace = THREE.LinearSRGBColorSpace
      texture.needsUpdate = true
    })
  }

  render() {
    if (!this.isPlaying) return
    this.time += 0.05
    this.material.uniforms.time.value = this.time
    requestAnimationFrame(this.render.bind(this))
    this.renderer.render(this.scene, this.camera)
  }
}

new Sketch({
  dom: document.getElementById("container"),
})
