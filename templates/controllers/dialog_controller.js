import { Controller } from "@hotwired/stimulus"

// senren--dialog
// Local UI: open/close, Escape to close, body scroll lock.
//
// State lives in `openValue`, not in the DOM nodes this controller touches.
// Actions only assign the value; every DOM change happens in openValueChanged.
//
// That inversion is what makes the state server-renderable (render
// open-value="true" and the dialog is open with no JavaScript), survivable
// across a Turbo morph, and reachable from a Turbo Stream that changes a single
// attribute. It is the pattern every stateful Senren controller follows.
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
    this._releaseScroll()
  }

  open(event) {
    event?.preventDefault()
    this.openValue = true
  }

  close(event) {
    event?.preventDefault()
    this.openValue = false
  }

  // Stimulus calls this during initialization too, so the server-rendered value
  // paints the first frame.
  openValueChanged(isOpen, wasOpen) {
    if (this.hasOverlayTarget) this.overlayTarget.hidden = !isOpen
    if (this.hasPanelTarget) this.panelTarget.hidden = !isOpen

    if (isOpen) {
      document.addEventListener("keydown", this._onKey)
      document.body.style.overflow = "hidden"
      queueMicrotask(() => this.panelTarget?.focus())
      this.dispatch("opened")
      return
    }

    document.removeEventListener("keydown", this._onKey)
    this._releaseScroll()
    // Only return focus on a real close, not on the initial render.
    if (wasOpen !== undefined) {
      this.triggerTarget?.focus?.()
      this.dispatch("closed")
    }
  }

  _onKey(event) {
    if (event.key === "Escape") this.close()
  }

  // Turbo snapshots the page before navigating away. Without this the scroll
  // lock is captured while still applied, and a back navigation restores a page
  // that cannot be scrolled.
  _onBeforeCache() {
    this.openValue = false
  }

  _releaseScroll() {
    document.body.style.overflow = ""
  }
}
