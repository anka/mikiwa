import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "image", "caption"]

  connect() {
    const items = Array.from(this.element.querySelectorAll("[data-lightbox-src]"))
    this.srcs     = items.map(el => el.dataset.lightboxSrc)
    this.captions = items.map(el => el.dataset.lightboxCaption || "")
    this.current  = 0
  }

  open(event) {
    this.current = parseInt(event.params.index, 10)
    this.render()
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  prev() {
    this.current = (this.current - 1 + this.srcs.length) % this.srcs.length
    this.render()
  }

  next() {
    this.current = (this.current + 1) % this.srcs.length
    this.render()
  }

  render() {
    this.imageTarget.src = this.srcs[this.current]
    if (!this.hasCaptionTarget) return
    const caption = this.captions[this.current] || ""
    this.captionTarget.textContent = caption
    this.captionTarget.hidden = caption.length === 0
  }
}
