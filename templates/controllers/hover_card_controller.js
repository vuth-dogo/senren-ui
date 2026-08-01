import { Controller } from "@hotwired/stimulus"

// senren--hover-card
// Show/hide a small content panel on hover or focus, with a 100ms delay.
export default class extends Controller {
  static targets = ["panel"]

  show() {
    clearTimeout(this._hideTimer)
    this._showTimer = setTimeout(() => { if (this.hasPanelTarget) this.panelTarget.hidden = false }, 80)
  }

  hide() {
    clearTimeout(this._showTimer)
    this._hideTimer = setTimeout(() => { if (this.hasPanelTarget) this.panelTarget.hidden = true }, 120)
  }

  // Either timer can still be pending when a Turbo navigation removes the
  // element, which retains this controller and its detached subtree until it
  // fires.
  disconnect() {
    clearTimeout(this._showTimer)
    clearTimeout(this._hideTimer)
  }
}
