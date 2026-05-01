import { Controller } from "@hotwired/stimulus"

// senren--dialog
// Local UI: open/close, focus trap, Escape to close, body scroll lock.
export default class extends Controller {
  static targets = ["overlay", "panel", "trigger"]
  static values  = { open: Boolean }

  connect() {
    this._onKey = this._onKey.bind(this)
    if (this.openValue) this._show()
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKey)
    document.body.style.overflow = ""
  }

  open(event) {
    event?.preventDefault()
    this._show()
  }

  close(event) {
    event?.preventDefault()
    this._hide()
  }

  _show() {
    this.openValue = true
    if (this.hasOverlayTarget) this.overlayTarget.hidden = false
    if (this.hasPanelTarget)   this.panelTarget.hidden   = false
    document.addEventListener("keydown", this._onKey)
    document.body.style.overflow = "hidden"
    queueMicrotask(() => this.panelTarget?.focus())
  }

  _hide() {
    this.openValue = false
    if (this.hasOverlayTarget) this.overlayTarget.hidden = true
    if (this.hasPanelTarget)   this.panelTarget.hidden   = true
    document.removeEventListener("keydown", this._onKey)
    document.body.style.overflow = ""
    this.triggerTarget?.focus?.()
  }

  _onKey(event) {
    if (event.key === "Escape") this._hide()
  }
}
