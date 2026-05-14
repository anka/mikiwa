import { Controller } from "@hotwired/stimulus"

// Navigates the page to a target URL when a <input type="date"> changes.
// Reads `data-date-jump-base-url-value` for the base path and replaces or
// adds the `date` query-param. Existing query params (e.g. group_id) are
// preserved.
export default class extends Controller {
  static values = { baseUrl: String }

  go(event) {
    const value = event.target.value
    if (!value) return

    const base = this.baseUrlValue || window.location.pathname + window.location.search
    const url = new URL(base, window.location.origin)
    url.searchParams.set("date", value)
    window.location.href = url.toString()
  }
}
