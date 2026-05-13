import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "summaryCount"]

  selectAll(event) {
    event.preventDefault()
    this.checkboxTargets.forEach(cb => cb.checked = true)
    this.updateSummary()
  }

  invert(event) {
    event.preventDefault()
    this.checkboxTargets.forEach(cb => cb.checked = !cb.checked)
    this.updateSummary()
  }

  updateSummary() {
    if (!this.hasSummaryCountTarget) return
    const visibleSelected = this.checkboxTargets.filter(cb => cb.checked).length
    const hiddenSelected = this.element.querySelectorAll('input[type="hidden"][name="child_ids[]"]').length
    const total = visibleSelected + hiddenSelected
    this.summaryCountTarget.textContent = `${total} ausgewählt`
  }
}
