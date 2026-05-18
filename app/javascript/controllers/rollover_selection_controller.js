import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "summaryCount", "selectAll"]

  connect() {
    this.refreshSelectAll()
    this.updateSummary()
  }

  selectAll(event) {
    event.preventDefault()
    this.checkboxTargets.forEach(cb => cb.checked = true)
    this.refreshSelectAll()
    this.updateSummary()
  }

  selectNone(event) {
    event.preventDefault()
    this.checkboxTargets.forEach(cb => cb.checked = false)
    this.refreshSelectAll()
    this.updateSummary()
  }

  invert(event) {
    event.preventDefault()
    this.checkboxTargets.forEach(cb => cb.checked = !cb.checked)
    this.refreshSelectAll()
    this.updateSummary()
  }

  toggleAll(event) {
    const target = event.currentTarget.checked
    event.currentTarget.indeterminate = false
    this.checkboxTargets.forEach(cb => cb.checked = target)
    this.updateSummary()
  }

  onChange() {
    this.refreshSelectAll()
    this.updateSummary()
  }

  refreshSelectAll() {
    if (!this.hasSelectAllTarget) return
    const total = this.checkboxTargets.length
    const checked = this.checkboxTargets.filter(cb => cb.checked).length
    this.selectAllTarget.checked = total > 0 && checked === total
    this.selectAllTarget.indeterminate = checked > 0 && checked < total
  }

  updateSummary() {
    if (!this.hasSummaryCountTarget) return
    const visibleSelected = this.checkboxTargets.filter(cb => cb.checked).length
    const hiddenSelected = this.element.querySelectorAll('input[type="hidden"][name="child_ids[]"]').length
    const total = visibleSelected + hiddenSelected
    const allVisible = this.checkboxTargets.length
    this.summaryCountTarget.textContent = `${total} von ${allVisible + hiddenSelected} ausgewählt`
  }
}
