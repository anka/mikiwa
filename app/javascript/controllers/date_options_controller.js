import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  add(event) {
    event.preventDefault()
    const index = Date.now()
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD_INDEX", index)
    const fragment = document.createRange().createContextualFragment(html)
    this.listTarget.appendChild(fragment)
    this.listTarget.lastElementChild?.querySelector("input[type=date]")?.focus()
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-date-options-row]")
    if (!row) return
    const persistedInput = row.querySelector("input[data-persisted]")
    if (persistedInput) {
      row.querySelector("input[data-destroy]").value = "1"
      row.querySelectorAll("input:not([type=hidden])").forEach(el => { el.disabled = true })
      row.hidden = true
    } else {
      row.remove()
    }
  }
}
