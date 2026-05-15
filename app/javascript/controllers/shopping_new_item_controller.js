import { Controller } from "@hotwired/stimulus"

// Backs the "add new item" form on the shopping list editor: focuses the name
// input after Turbo replaces the form with a fresh one and provides a small
// thumbnail preview before the file is uploaded.
export default class extends Controller {
  static targets = ["name", "photo", "preview", "previewImg", "details", "toggle"]

  connect() {
    // F82: Details-Block auf Desktop immer offen (CSS-Override gegen `[hidden]`
    // greift nicht zuverlässig — Stimulus forciert programmatisch).
    this.mql = window.matchMedia("(min-width: 768px)")
    this.applyDetailsForViewport = () => {
      if (!this.hasDetailsTarget) return
      if (this.mql.matches) this.detailsTarget.hidden = false
    }
    this.mql.addEventListener("change", this.applyDetailsForViewport)
    this.applyDetailsForViewport()

    if (this.element.dataset.focusOnConnect === "true") {
      // Doppel-rAF stellt sicher, dass der Fokus nach Turbo-Stream-Replace
      // verlässlich gesetzt wird (microtask greift zu früh, der Browser springt
      // sonst zum nächsten focusable Element).
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          this.nameTarget?.focus()
          this.nameTarget?.setSelectionRange?.(0, 0)
        })
      })
      delete this.element.dataset.focusOnConnect
    }
  }

  disconnect() {
    this.mql?.removeEventListener("change", this.applyDetailsForViewport)
  }

  // F82: 'Mehr Details' Toggle (Mobile only — auf Desktop ist der Block
  // via CSS-Override immer sichtbar, der Toggle versteckt).
  toggleDetails(event) {
    event?.preventDefault()
    if (!this.hasDetailsTarget) return
    const open = this.detailsTarget.hidden
    this.detailsTarget.hidden = !open
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", open ? "true" : "false")
    }
  }

  previewPhoto() {
    const file = this.photoTarget.files?.[0]
    if (!file) {
      this.clearPreview()
      return
    }
    const url = URL.createObjectURL(file)
    this.previewImgTarget.src = url
    this.previewTarget.hidden = false
  }

  clearPhoto(event) {
    event?.preventDefault()
    this.photoTarget.value = ""
    this.clearPreview()
  }

  clearPreview() {
    if (this.previewImgTarget.src) URL.revokeObjectURL(this.previewImgTarget.src)
    this.previewImgTarget.removeAttribute("src")
    this.previewTarget.hidden = true
  }
}
