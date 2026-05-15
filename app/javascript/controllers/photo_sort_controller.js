import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// F73: Drag&Drop-Sortierung der Foto-Kacheln einer Galerie.
// Auf jedem Drop wird die neue photo_ids[]-Reihenfolge per PATCH an
// den Reorder-Endpoint geschickt; bei Fehler stellen wir den
// Pre-Drag-DOM-Snapshot wieder her und zeigen einen Toast.
export default class extends Controller {
  static values = { reorderUrl: String }

  connect() {
    this.snapshot = null
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      delay: 150,
      delayOnTouchOnly: true,
      touchStartThreshold: 5,
      ghostClass: "mw-photo-grid__item--ghost",
      draggable: ".mw-photo-grid__item",
      onStart: () => this.captureSnapshot(),
      onEnd: () => this.persist()
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  captureSnapshot() {
    this.snapshot = Array.from(this.element.children)
  }

  async persist() {
    const items = Array.from(this.element.querySelectorAll(".mw-photo-grid__item"))
    const photoIds = items.map(el => el.dataset.photoId).filter(Boolean)

    const params = new URLSearchParams()
    photoIds.forEach(id => params.append("photo_ids[]", id))

    try {
      const response = await fetch(this.reorderUrlValue, {
        method: "PATCH",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken(),
          "Content-Type": "application/x-www-form-urlencoded"
        },
        body: params.toString()
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      this.snapshot = null
    } catch (error) {
      console.error("photo-sort persist failed", error)
      this.rollback()
      this.flashError("Sortierung konnte nicht gespeichert werden.")
    }
  }

  rollback() {
    if (!this.snapshot) return
    this.snapshot.forEach(node => this.element.appendChild(node))
    this.snapshot = null
  }

  flashError(message) {
    const flash = document.createElement("div")
    flash.className = "mw-flash mw-flash--error"
    flash.textContent = message
    flash.style.marginTop = "1rem"
    this.element.parentElement?.insertBefore(flash, this.element)
    setTimeout(() => flash.remove(), 5000)
  }

  csrfToken() {
    const meta = document.querySelector("meta[name='csrf-token']")
    return meta ? meta.content : ""
  }
}
