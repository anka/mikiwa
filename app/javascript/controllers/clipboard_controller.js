import { Controller } from "@hotwired/stimulus"

// F77: Kopiert data-clipboard-text-value ins Clipboard und zeigt kurzes
// "Kopiert"-Feedback am ausgelösten Button. Fallback via execCommand für
// Browser ohne sicheren Clipboard-Kontext (http im LAN, ältere Mobile-Browser).
export default class extends Controller {
  static values  = { text: String }
  static targets = ["label"]

  async copy(event) {
    event.preventDefault()
    const text = this.textValue
    if (!text) return

    const ok = await this.writeText(text)
    this.flash(ok ? "Kopiert" : "Fehler")
  }

  async writeText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      try {
        await navigator.clipboard.writeText(text)
        return true
      } catch (_) {}
    }
    return this.execCommandFallback(text)
  }

  execCommandFallback(text) {
    const ta = document.createElement("textarea")
    ta.value = text
    ta.setAttribute("readonly", "")
    ta.style.position = "absolute"
    ta.style.left = "-9999px"
    document.body.appendChild(ta)
    ta.select()
    let ok = false
    try { ok = document.execCommand("copy") } catch (_) {}
    document.body.removeChild(ta)
    return ok
  }

  flash(text) {
    if (!this.hasLabelTarget) return
    const original = this.labelTarget.textContent
    this.labelTarget.textContent = text
    clearTimeout(this.flashTimer)
    this.flashTimer = setTimeout(() => {
      this.labelTarget.textContent = original
    }, 1600)
  }
}
