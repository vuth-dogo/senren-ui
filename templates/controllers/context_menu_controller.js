import { Controller } from "@hotwired/stimulus"

// senren--context-menu
// Opens on right-click within the trigger; closes on outside click or Escape.
//
// State lives in `openValue`. The pointer position is transient and belongs to
// the opening event, so it is applied in the action; everything else — the
// visibility and the document listeners — is driven by the value.
export default class extends Controller {
  static targets = ["trigger", "menu"]
  static values = { open: Boolean }

  connect() {
    this._onDocClick = this._onDocClick.bind(this)
    this._onKey = this._onKey.bind(this)
  }

  disconnect() {
    this._stopListening()
  }

  open(event) {
    event.preventDefault()

    if (this.hasMenuTarget) {
      const rect = this.element.getBoundingClientRect()
      this.menuTarget.style.top = `${event.clientY - rect.top}px`
      this.menuTarget.style.left = `${event.clientX - rect.left}px`
    }

    this.openValue = true
  }

  close() {
    this.openValue = false
  }

  openValueChanged(isOpen) {
    if (this.hasMenuTarget) this.menuTarget.hidden = !isOpen

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
    if (!this.menuTarget.contains(event.target)) this.close()
  }

  _onKey(event) {
    if (event.key === "Escape") this.close()
  }
}
