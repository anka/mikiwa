import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "mikiwa.theme"

export default class extends Controller {
  static targets = ["icon"]

  connect() {
    this.applyIcon(this.currentTheme())
    this.mql = window.matchMedia("(prefers-color-scheme: dark)")
    this.mqlListener = () => {
      if (!localStorage.getItem(STORAGE_KEY)) {
        const theme = this.mql.matches ? "dark" : "light"
        this.applyTheme(theme, false)
      }
    }
    this.mql.addEventListener("change", this.mqlListener)
  }

  disconnect() {
    if (this.mql) this.mql.removeEventListener("change", this.mqlListener)
  }

  toggle() {
    const next = this.currentTheme() === "dark" ? "light" : "dark"
    this.applyTheme(next, true)
  }

  currentTheme() {
    return document.documentElement.getAttribute("data-theme") || "light"
  }

  applyTheme(theme, persist) {
    document.documentElement.setAttribute("data-theme", theme)
    if (persist) localStorage.setItem(STORAGE_KEY, theme)
    this.applyIcon(theme)
  }

  applyIcon(theme) {
    if (!this.hasIconTarget) return
    this.iconTarget.dataset.theme = theme
  }
}
