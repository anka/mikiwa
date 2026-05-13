import { Controller } from "@hotwired/stimulus"

// Backs the "add new item" form on the shopping list editor: focuses the name
// input after Turbo replaces the form with a fresh one and provides a small
// thumbnail preview before the file is uploaded.
export default class extends Controller {
  static targets = ["name", "photo", "preview", "previewImg"]

  connect() {
    if (this.element.dataset.focusOnConnect === "true") {
      queueMicrotask(() => this.nameTarget?.focus())
      delete this.element.dataset.focusOnConnect
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
