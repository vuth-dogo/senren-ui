import { Controller } from "@hotwired/stimulus"

// senren--invite-member-dialog
export default class extends Controller {
  static targets = ["trigger", "overlay", "panel"]

  connect() {
    this.closeOnEscape = this.closeOnEscape.bind(this)
  }

  // open() registers a document-level listener; without this the listener and
  // the detached subtree survive every Turbo navigation made while open.
  disconnect() {
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  open() {
    this.overlayTarget.hidden = false
    this.panelTarget.hidden = false
    document.addEventListener("keydown", this.closeOnEscape)
    queueMicrotask(() => this.panelTarget.focus())
  }

  close() {
    this.overlayTarget.hidden = true
    this.panelTarget.hidden = true
    document.removeEventListener("keydown", this.closeOnEscape)
    if (this.hasTriggerTarget) this.triggerTarget.focus()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
