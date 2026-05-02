import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "image"]

  connect() {
    this.srcs = Array.from(this.element.querySelectorAll("[data-lightbox-src]"))
                     .map(el => el.dataset.lightboxSrc)
    this.current = 0
  }

  open(event) {
    this.current = parseInt(event.params.index, 10)
    this.imageTarget.src = this.srcs[this.current]
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  prev() {
    this.current = (this.current - 1 + this.srcs.length) % this.srcs.length
    this.imageTarget.src = this.srcs[this.current]
  }

  next() {
    this.current = (this.current + 1) % this.srcs.length
    this.imageTarget.src = this.srcs[this.current]
  }
}
