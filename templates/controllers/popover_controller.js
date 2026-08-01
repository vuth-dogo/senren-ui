import { Controller } from "@hotwired/stimulus"

// senren--popover
// Toggles a small panel; closes on outside click and Escape.
//
// State lives in `openValue`. Actions assign it; openValueChanged performs
// every DOM change and owns the document listeners, so the open state is
// server-renderable and survives a Turbo morph.
export default class extends Controller {
  static targets = ["trigger", "panel"]
  static values = { open: Boolean }

  connect() {
    this._onDocClick = this._onDocClick.bind(this)
    this._onKey = this._onKey.bind(this)
  }

  disconnect() {
    this._stopListening()
  }

  toggle(event) {
    event?.preventDefault()
    this.openValue = !this.openValue
  }

  close() {
    this.openValue = false
  }

  openValueChanged(isOpen) {
    if (this.hasPanelTarget) this.panelTarget.hidden = !isOpen
    if (this.hasTriggerTarget) this.triggerTarget.setAttribute("aria-expanded", isOpen ? "true" : "false")

    if (isOpen) {
      document.addEventListener("click", this._onDocClick)
      document.addEventListener("keydown", this._onKey)
      this.dispatch("opened")
      return
    }

    this._stopListening()
  }

  _stopListening() {
    document.removeEventListener("click", this._onDocClick)
    document.removeEventListener("keydown", this._onKey)
  }

  _onDocClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  _onKey(event) {
    if (event.key === "Escape") this.close()
  }
}
