import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  add(event) {
    event.preventDefault()
    const index = Date.now()
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD_INDEX", index)
    const fragment = document.createRange().createContextualFragment(html)
    this.listTarget.appendChild(fragment)
    this.listTarget.lastElementChild?.querySelector("input[type=text]")?.focus()
    this.updatePositions()
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-poll-options-row]")
    if (!row) return
    const idInput = row.querySelector("input[data-persisted]")
    if (idInput) {
      row.querySelector("input[data-destroy]").value = "1"
      // Disable visible inputs so required validation doesn't block submission
      row.querySelectorAll("input:not([type=hidden]), textarea, select").forEach(el => {
        el.disabled = true
      })
      row.hidden = true
    } else {
      row.remove()
    }
    this.updatePositions()
  }

  updatePositions() {
    const rows = this.listTarget.querySelectorAll("[data-poll-options-row]:not([hidden])")
    rows.forEach((row, idx) => {
      const pos = row.querySelector("input[data-position]")
      if (pos) pos.value = idx + 1
    })
  }
}
