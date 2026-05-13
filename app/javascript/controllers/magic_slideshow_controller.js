import { Controller } from "@hotwired/stimulus"

// F53: Vollbild-Diashow mit randomisierten Übergangs-Effekten.
// Eigene Mini-Implementation (kein Swiper) – minimiert Bundle-Größe und
// vermeidet CSP-Probleme durch externe Libraries. Effekte über CSS-Klassen.
const EFFECTS = ["fade", "slide-left", "zoom", "flip"]
const REDUCED_MOTION_EFFECT = "fade"

export default class extends Controller {
  static targets = ["srcs"]

  open(event) {
    event?.preventDefault()
    this.srcs = Array.from(this.srcsTargets[0].querySelectorAll("[data-magic-slideshow-src]"))
                     .map(el => el.dataset.magicSlideshowSrc)
    if (this.srcs.length === 0) return

    this.index = 0
    this.paused = false
    this.lastEffect = null
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.delay = this.reducedMotion ? 6000 : 4000

    this.buildOverlay()
    this.bindControls()
    this.show()
    this.requestFs()
    this.startAutoplay()
  }

  buildOverlay() {
    this.overlay = document.createElement("div")
    this.overlay.className = "mw-magic-slideshow"
    this.overlay.setAttribute("role", "dialog")
    this.overlay.setAttribute("aria-label", "Slideshow")

    this.imgEl = document.createElement("img")
    this.imgEl.className = "mw-magic-slideshow__img"
    this.imgEl.alt = ""

    this.toolbar = document.createElement("div")
    this.toolbar.className = "mw-magic-slideshow__toolbar"
    this.toolbar.innerHTML = `
      <button type="button" class="mw-magic-slideshow__btn" data-act="prev" aria-label="Zurück">‹</button>
      <button type="button" class="mw-magic-slideshow__btn" data-act="toggle" aria-label="Pause/Play">⏸</button>
      <button type="button" class="mw-magic-slideshow__btn" data-act="next" aria-label="Vor">›</button>
      <button type="button" class="mw-magic-slideshow__btn mw-magic-slideshow__btn--close" data-act="close" aria-label="Schließen">×</button>
    `

    this.overlay.appendChild(this.imgEl)
    this.overlay.appendChild(this.toolbar)
    document.body.appendChild(this.overlay)
    document.body.classList.add("mw-no-scroll")
  }

  bindControls() {
    this.toolbar.addEventListener("click", e => {
      const btn = e.target.closest("[data-act]")
      if (!btn) return
      const act = btn.dataset.act
      if (act === "prev") this.prev()
      else if (act === "next") this.next()
      else if (act === "toggle") this.togglePause()
      else if (act === "close") this.close()
    })

    this.keyHandler = e => {
      if (e.key === "Escape") this.close()
      else if (e.key === "ArrowRight") { this.next(); this.pauseAndResume() }
      else if (e.key === "ArrowLeft")  { this.prev(); this.pauseAndResume() }
      else if (e.key === " ") { e.preventDefault(); this.togglePause() }
    }
    document.addEventListener("keydown", this.keyHandler)

    this.toolbarFadeTimer = null
    this.activityHandler = () => {
      this.toolbar.classList.remove("mw-magic-slideshow__toolbar--faded")
      clearTimeout(this.toolbarFadeTimer)
      this.toolbarFadeTimer = setTimeout(() => {
        this.toolbar.classList.add("mw-magic-slideshow__toolbar--faded")
      }, 3000)
    }
    this.overlay.addEventListener("mousemove", this.activityHandler)
    this.overlay.addEventListener("touchstart", this.activityHandler)
    this.activityHandler()
  }

  show() {
    const effect = this.pickEffect()
    this.imgEl.classList.remove(...EFFECTS.map(e => `mw-magic-slideshow__img--${e}`))
    void this.imgEl.offsetWidth
    this.imgEl.classList.add(`mw-magic-slideshow__img--${effect}`)
    this.imgEl.src = this.srcs[this.index]
    this.lastEffect = effect
  }

  pickEffect() {
    if (this.reducedMotion) return REDUCED_MOTION_EFFECT
    const choices = EFFECTS.filter(e => e !== this.lastEffect)
    return choices[Math.floor(Math.random() * choices.length)]
  }

  next() {
    this.index = (this.index + 1) % this.srcs.length
    this.show()
  }

  prev() {
    this.index = (this.index - 1 + this.srcs.length) % this.srcs.length
    this.show()
  }

  togglePause() {
    this.paused = !this.paused
    if (this.paused) this.stopAutoplay()
    else this.startAutoplay()
  }

  pauseAndResume() {
    this.stopAutoplay()
    clearTimeout(this.resumeTimer)
    this.resumeTimer = setTimeout(() => { if (!this.paused) this.startAutoplay() }, 8000)
  }

  startAutoplay() {
    this.stopAutoplay()
    this.autoplayTimer = setInterval(() => this.next(), this.delay)
  }

  stopAutoplay() {
    clearInterval(this.autoplayTimer)
  }

  requestFs() {
    if (this.overlay.requestFullscreen) {
      this.overlay.requestFullscreen().catch(() => {})
    }
  }

  close() {
    this.stopAutoplay()
    clearTimeout(this.resumeTimer)
    clearTimeout(this.toolbarFadeTimer)
    document.removeEventListener("keydown", this.keyHandler)
    if (document.fullscreenElement) document.exitFullscreen().catch(() => {})
    this.overlay?.remove()
    document.body.classList.remove("mw-no-scroll")
  }
}
