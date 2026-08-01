import { Controller } from "@hotwired/stimulus"

// senren--sheet
// Side panel; behaves like a dialog.
//
// State lives in `openValue`. Actions assign it; openValueChanged performs every
// DOM change, so the panel can be opened from the server and survives a morph.
export default class extends Controller {
  static targets = ["overlay", "panel", "trigger"]
  static values = { open: Boolean }

  connect() {
    this._onKey = this._onKey.bind(this)
    this._onBeforeCache = this._onBeforeCache.bind(this)
    document.addEventListener("turbo:before-cache", this._onBeforeCache)
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKey)
    document.removeEventListener("turbo:before-cache", this._onBeforeCache)
    document.body.style.overflow = ""
  }

  open(event) {
    event?.preventDefault()
    this.openValue = true
  }

  close(event) {
    event?.preventDefault()
    this.openValue = false
  }

  openValueChanged(isOpen, wasOpen) {
    if (this.hasOverlayTarget) this.overlayTarget.hidden = !isOpen
    if (this.hasPanelTarget) {
      this.panelTarget.hidden = !isOpen
      this.panelTarget.dataset.open = isOpen ? "true" : "false"
    }

    if (isOpen) {
      document.addEventListener("keydown", this._onKey)
      document.body.style.overflow = "hidden"
      queueMicrotask(() => this.panelTarget?.focus())
      this.dispatch("opened")
      return
    }

    document.removeEventListener("keydown", this._onKey)
    document.body.style.overflow = ""
    if (wasOpen !== undefined) this.dispatch("closed")
  }

  _onKey(event) {
    if (event.key === "Escape") this.close()
  }

  // Turbo snapshots the page before navigating away; without this the scroll
  // lock is captured while applied and a back navigation restores a page that
  // cannot be scrolled.
  _onBeforeCache() {
    this.openValue = false
  }
}
