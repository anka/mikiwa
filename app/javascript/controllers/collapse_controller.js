import { Controller } from "@hotwired/stimulus"

// F82: Generischer Collapse-Controller. Toggle eines Body-Targets via
// hidden-Attribut. Optionales Icon-Target wird per aria-expanded gedreht.
//
// Markup:
//   <section data-controller="collapse">
//     <button data-action="click->collapse#toggle"
//             data-collapse-target="trigger"
//             aria-expanded="false">
//       Stammdaten
//     </button>
//     <div data-collapse-target="body" hidden>…</div>
//   </section>
//
// Wenn das Element data-collapse-open-value="true" hat, startet es offen.
// F82: Auf Desktop (≥768px) ist der Body immer offen – das CSS-Override für
// `[hidden]` greift nicht zuverlässig gegen das HTML-spec-mandated `display: none`,
// deshalb forcieren wir es hier programmatisch.
const DESKTOP_MQ = "(min-width: 768px)"

export default class extends Controller {
  static targets = ["body", "trigger"]
  static values  = { open: Boolean }

  connect() {
    this.mql = window.matchMedia(DESKTOP_MQ)
    this.onResize = () => this.applyForViewport()
    this.mql.addEventListener("change", this.onResize)
    this.applyForViewport()
  }

  disconnect() {
    this.mql?.removeEventListener("change", this.onResize)
  }

  applyForViewport() {
    if (this.mql.matches) {
      this.apply(true)
    } else {
      this.apply(this.openValue)
    }
  }

  toggle(event) {
    event?.preventDefault()
    if (this.mql?.matches) return // Auf Desktop ist Toggle deaktiviert
    this.apply(this.bodyTarget.hidden)
  }

  apply(open) {
    this.bodyTarget.hidden = !open
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", open ? "true" : "false")
    }
  }
}
