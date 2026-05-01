import { Controller } from "@hotwired/stimulus"

// senren--popover
// Toggles a small panel; closes on outside click and Escape.
export default class extends Controller {
  static targets = ["trigger", "panel"]

  connect() {
    this._onDocClick = this._onDocClick.bind(this)
    this._onKey = this._onKey.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this._onDocClick)
    document.removeEventListener("keydown", this._onKey)
  }

  toggle(event) {
    event?.preventDefault()
    this.panelTarget.hidden ? this._show() : this.close()
  }

  close() {
    this.panelTarget.hidden = true
    document.removeEventListener("click", this._onDocClick)
    document.removeEventListener("keydown", this._onKey)
  }

  _show() {
    this.panelTarget.hidden = false
    document.addEventListener("click", this._onDocClick)
    document.addEventListener("keydown", this._onKey)
  }

  _onDocClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  _onKey(event) {
    if (event.key === "Escape") this.close()
  }
}
