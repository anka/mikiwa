import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  preview() {
    const files = Array.from(this.inputTarget.files)
    this.previewTarget.innerHTML = ""
    files.forEach(file => {
      const reader = new FileReader()
      reader.onload = e => {
        const img = document.createElement("img")
        img.src = e.target.result
        img.className = "mw-gallery-dropzone__preview-thumb"
        img.alt = file.name
        this.previewTarget.appendChild(img)
      }
      reader.readAsDataURL(file)
    })
  }

  connect() {
    const dropzone = this.element
    dropzone.addEventListener("dragover", e => {
      e.preventDefault()
      dropzone.classList.add("mw-gallery-dropzone--active")
    })
    dropzone.addEventListener("dragleave", () => {
      dropzone.classList.remove("mw-gallery-dropzone--active")
    })
    dropzone.addEventListener("drop", e => {
      e.preventDefault()
      dropzone.classList.remove("mw-gallery-dropzone--active")
      const dt = new DataTransfer()
      Array.from(e.dataTransfer.files).forEach(f => dt.items.add(f))
      this.inputTarget.files = dt.files
      this.preview()
    })
  }
}
