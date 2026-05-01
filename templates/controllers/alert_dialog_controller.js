import { Controller } from "@hotwired/stimulus"

// senren--alert-dialog
// Same shape as dialog, but role=alertdialog. Triggered by external buttons that include
// data-action="click->senren--alert-dialog#open" pointing at the controller scope.
export default class extends Controller {
  static targets = ["overlay", "panel", "trigger"]

  connect() {
    this._onKey = this._onKey.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKey)
    document.body.style.overflow = ""
  }

  open(event) {
    event?.preventDefault()
    this.overlayTarget.hidden = false
    this.panelTarget.hidden = false
    document.addEventListener("keydown", this._onKey)
    document.body.style.overflow = "hidden"
    queueMicrotask(() => this.panelTarget?.focus())
  }

  close(event) {
    event?.preventDefault()
    this.overlayTarget.hidden = true
    this.panelTarget.hidden = true
    document.removeEventListener("keydown", this._onKey)
    document.body.style.overflow = ""
  }

  _onKey(event) {
    if (event.key === "Escape") this.close()
  }
}
