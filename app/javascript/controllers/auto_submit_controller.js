import { Controller } from "@hotwired/stimulus"

// Submit a form whenever a tracked field changes. Optional debounce avoids
// hammering the server while the user is still typing.
export default class extends Controller {
  static values = { debounce: { type: Number, default: 0 } }

  initialize() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  submit(event) {
    if (event.type === "blur" && !this.element.checkValidity()) return
    if (this.debounceValue > 0) {
      if (this.timeout) clearTimeout(this.timeout)
      this.timeout = setTimeout(() => this.requestSubmit(), this.debounceValue)
    } else {
      this.requestSubmit()
    }
  }

  requestSubmit() {
    if (typeof this.element.requestSubmit === "function") {
      this.element.requestSubmit()
    } else {
      this.element.submit()
    }
  }
}
