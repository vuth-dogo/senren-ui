import { Controller } from "@hotwired/stimulus"

// senren--context-menu
// Opens on right-click within the trigger; closes on outside click or Escape.
export default class extends Controller {
  static targets = ["trigger", "menu"]

  connect() {
    this._onDocClick = this._onDocClick.bind(this)
    this._onKey = this._onKey.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this._onDocClick)
    document.removeEventListener("keydown", this._onKey)
  }

  open(event) {
    event.preventDefault()
    const rect = this.element.getBoundingClientRect()
    this.menuTarget.style.top = (event.clientY - rect.top) + "px"
    this.menuTarget.style.left = (event.clientX - rect.left) + "px"
    this.menuTarget.hidden = false
    document.addEventListener("click", this._onDocClick)
    document.addEventListener("keydown", this._onKey)
  }

  close() {
    this.menuTarget.hidden = true
    document.removeEventListener("click", this._onDocClick)
    document.removeEventListener("keydown", this._onKey)
  }

  _onDocClick(event) { if (!this.menuTarget.contains(event.target)) this.close() }
  _onKey(event)      { if (event.key === "Escape") this.close() }
}
