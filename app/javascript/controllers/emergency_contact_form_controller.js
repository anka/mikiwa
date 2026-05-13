import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["userSection", "manualSection", "userSelect", "nameInput", "phoneInput", "modeRadio"]
  static values  = { linked: String }

  connect() {
    this.#applyMode(this.linkedValue === "true" ? "user" : "manual")
  }

  switchMode(event) {
    this.#applyMode(event.target.value)
  }

  #applyMode(mode) {
    const isUser = mode === "user"

    if (this.hasUserSectionTarget)   this.userSectionTarget.style.display   = isUser ? "" : "none"
    if (this.hasManualSectionTarget) this.manualSectionTarget.style.display = isUser ? "none" : ""

    if (isUser) {
      if (this.hasNameInputTarget)  { this.nameInputTarget.value = "";  this.nameInputTarget.removeAttribute("required") }
      if (this.hasPhoneInputTarget) { this.phoneInputTarget.value = ""; this.phoneInputTarget.removeAttribute("required") }
    } else {
      if (this.hasUserSelectTarget) this.userSelectTarget.value = ""
    }
  }
}
