import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { pct: Number }

  connect() {
    const pct = Math.max(0, Math.min(100, this.pctValue || 0))
    this.element.style.width = `${pct}%`
  }
}
