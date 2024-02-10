import * as THREE from "three"
import { REVISION } from "three"

import gui from "lil-gui"
import gsap from "gsap"

import fragment from "./shader/fragment.glsl"
import vertex from "./shader/vertex.glsl"

import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js"
import { KTX2Loader } from "three/addons/loaders/KTX2Loader.js"

import tDiffuse from "../img/gameboy_diffuse-high.png.ktx2?url"
import tPosition from "../img/gameboy_position-high.png.ktx2?url"
import tMotion from "../img/gameboy_mv-high.png.ktx2?url"
import tData from "../img/gameboy_data-high.png.ktx2?url"

export default class Sketch {
  constructor(options) {
    this.scene = new THREE.Scene()

    this.container = options.dom
    this.width = this.container.offsetWidth
    this.height = this.container.offsetHeight
    this.renderer = new THREE.WebGLRenderer()
    this.renderer.setPixelRatio(window.devicePixelRatio)
    this.renderer.setSize(this.width, this.height)
    this.renderer.setClearColor(0xfed703, 1)

    this.renderer.outputColorSpace = THREE.SRGBColorSpace

    this.container.appendChild(this.renderer.domElement)

    this.camera = new THREE.PerspectiveCamera(
      70,
      window.innerWidth / window.innerHeight,
      0.001,
      1000
    )

    // var frustumSize = 10;
    // var aspect = window.innerWidth / window.innerHeight;
    // this.camera = new THREE.OrthographicCamera( frustumSize * aspect / - 2, frustumSize * aspect / 2, frustumSize / 2, frustumSize / - 2, -1000, 1000 );
    this.camera.position.set(0, 0, 1.2)
    // this.controls = new OrbitControls(this.camera, this.renderer.domElement)
    this.time = 0

    this.isPlaying = true

    const THREE_PATH = `https://unpkg.com/three@0.${REVISION}.x`
    this.basisLoader = new KTX2Loader()
    this.basisLoader.setTranscoderPath(`${THREE_PATH}/examples/jsm/libs/basis/`)
    this.basisLoader.detectSupport(this.renderer)

    this.addObjects()
    this.resize()
    this.render()
    this.setupResize()
    this.addMouseEvents()
    this.settings()
  }

  addMouseEvents() {
    window.addEventListener("mousemove", (e) => {
      // e.clientX / window.innerWidth = returns value between 0 & 1
      this.material.uniforms.uMouse.value = e.clientX / window.innerWidth
    })
  }

  settings() {
    this.settings = {
      progress: 0.29,
      uDisplacementStrength: 0.0025,
    }
    this.gui = new gui()
    this.gui.add(this.settings, "progress", 0, 1, 0.01).onChange((value) => {
      this.material.uniforms.progress.value = value
    })

    this.gui
      .add(this.settings, "uDisplacementStrength", 0, 0.01, 0.0001)
      .onChange((value) => {
        this.material.uniforms.uDisplacementStrength.value = value
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
        time: { type: "f", value: 0 },
        progress: { value: 0.29 },
        uDiffuse: { value: null },
        uDisplacementStrength: { value: 0 },
        uMouse: { value: 0 },
        uPosition: { value: null },
        uMotion: { value: null },
        uData: { value: null },
        resolution: { type: "v4", value: new THREE.Vector4() },
      },
      // wireframe: true,
      transparent: true,
      vertexShader: vertex,
      fragmentShader: fragment,
    })

    this.geometry = new THREE.PlaneGeometry(1, 1, 1, 1)

    this.plane = new THREE.Mesh(this.geometry, this.material)
    this.scene.add(this.plane)

    // this.basisLoader.load(tDiffuse, (texture) => {
    //   this.material.uniforms.uDiffuse.value = texture
    // })

    // write a promise to load all textures

    this.uniforms = [tDiffuse, tPosition, tMotion, tData]

    // load all textures in with this handy user helper function
    const loadFile = (url) => {
      return new Promise((resolve, reject) => {
        this.basisLoader.load(
          url,
          (texture) => resolve(texture),
          undefined,
          (error) => reject(error)
        )
      })
    }

    Promise.all(this.uniforms.map(loadFile))
      .then((textures) => {
        console.log(textures) // array of loaded textures
        this.material.uniforms.uDiffuse.value = textures[0]
        this.material.uniforms.uPosition.value = textures[1]
        this.material.uniforms.uMotion.value = textures[2]
        this.material.uniforms.uData.value = textures[3]

        textures.map((texture) => {
          texture.colorSpace = THREE.LinearSRGBColorSpace
          texture.needsUpdate = true
        })
      })
      .catch((error) => {
        console.error("An error occurred while loading files:", error)
      })
  }

  stop() {
    this.isPlaying = false
  }

  play() {
    if (!this.isPlaying) {
      this.render()
      this.isPlaying = true
    }
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
