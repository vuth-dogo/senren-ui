import { Controller } from "@hotwired/stimulus"

// senren--theme-toggle
// Local UI: toggles the document dark class and stores the preference.
export default class extends Controller {
  static targets = ["label", "icon"]

  connect() {
    this._sync()
  }

  toggle() {
    document.documentElement.classList.toggle("dark")
    localStorage.setItem("senren-theme", document.documentElement.classList.contains("dark") ? "dark" : "light")
    this._sync()
  }

  _sync() {
    const dark = document.documentElement.classList.contains("dark")
    this.element.setAttribute("aria-pressed", dark ? "true" : "false")
    if (this.hasLabelTarget) this.labelTarget.textContent = dark ? "Light theme" : "Dark theme"
    if (this.hasIconTarget) this.iconTarget.textContent = dark ? "L" : "D"
  }
}
