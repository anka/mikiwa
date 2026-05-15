import { Controller } from "@hotwired/stimulus"

// F80: Foto-Upload für Einkaufsliste-Import.
// - Klick auf den Trigger-Button öffnet das versteckte File-Input (native Kamera/Datei-Dialog)
// - Bei Auswahl wird das Form sofort abgeschickt; Button wird disabled, Spinner sichtbar
// - Schutz gegen Doppel-Submit über `submitting`-Flag und disabled-State
export default class extends Controller {
  static targets = ["form", "input", "trigger", "status"]

  connect() {
    this.submitting = false
  }

  open(event) {
    event.preventDefault()
    if (this.submitting) return
    this.inputTarget.click()
  }

  fileSelected() {
    if (this.submitting) return
    if (!this.inputTarget.files || this.inputTarget.files.length === 0) return
    this.submitting = true
    this.triggerTarget.disabled = true
    this.element.classList.add("mw-photo-upload--busy")
    if (this.hasStatusTarget) this.statusTarget.hidden = false
    this.formTarget.requestSubmit()
  }
}
