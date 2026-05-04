import { Controller } from "@hotwired/stimulus"

// F30: Mobile-Drawer (Burger-Menü). Wird vom Topbar-Burger getoggelt.
// Schließt sich bei Klick außerhalb, beim Klick auf einen Link oder
// per Escape-Taste.
export default class extends Controller {
  static targets = ["panel", "scrim", "trigger"]

  connect() {
    this.escHandler = (e) => { if (e.key === "Escape") this.close() }
    document.addEventListener("keydown", this.escHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escHandler)
  }

  toggle(event) {
    if (event) event.preventDefault()
    this.element.dataset.open === "true" ? this.close() : this.open()
  }

  open() {
    this.element.dataset.open = "true"
    if (this.hasTriggerTarget) this.triggerTarget.setAttribute("aria-expanded", "true")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.element.dataset.open = "false"
    if (this.hasTriggerTarget) this.triggerTarget.setAttribute("aria-expanded", "false")
    document.body.style.overflow = ""
  }

  closeOnLink(event) {
    if (event.target.closest("a, button[type=submit]")) this.close()
  }
}
