import { Controller } from "@hotwired/stimulus"

// senren--theme-toggle
// Local UI: toggles the document dark class and stores the preference.
export default class extends Controller {
  static targets = ["label", "iconLight", "iconDark"]

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

    // The icon names the theme the click switches *to*, matching the label: in
    // light mode the label reads "Dark theme", so the moon is showing. Showing
    // the current state instead would have icon and label contradict each other.
    //
    // Swapping visibility rather than rewriting one element's text also means
    // the icons are markup the server rendered, so the right one is on screen
    // before this controller connects.
    if (this.hasIconLightTarget) this.iconLightTarget.hidden = !dark
    if (this.hasIconDarkTarget) this.iconDarkTarget.hidden = dark
  }
}
