import { Controller } from "@hotwired/stimulus"

// senren--sheet
// Side panel; behaves like a dialog.
export default class extends Controller {
  static targets = ["overlay", "panel", "trigger"]

  connect()    { this._onKey = this._onKey.bind(this) }
  disconnect() {
    document.removeEventListener("keydown", this._onKey)
    document.body.style.overflow = ""
  }

  open(event) {
    event?.preventDefault()
    this.overlayTarget.hidden = false
    this.panelTarget.hidden   = false
    this.panelTarget.dataset.open = "true"
    document.addEventListener("keydown", this._onKey)
    document.body.style.overflow = "hidden"
    queueMicrotask(() => this.panelTarget?.focus())
  }

  close(event) {
    event?.preventDefault()
    this.overlayTarget.hidden = true
    this.panelTarget.hidden   = true
    this.panelTarget.dataset.open = "false"
    document.removeEventListener("keydown", this._onKey)
    document.body.style.overflow = ""
  }

  _onKey(event) { if (event.key === "Escape") this.close() }
}
