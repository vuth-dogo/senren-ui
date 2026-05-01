import { Controller } from "@hotwired/stimulus"

// senren--collapsible
// Local UI: toggle one content panel.
export default class extends Controller {
  static targets = ["trigger", "panel"]

  toggle() {
    const nextOpen = this.triggerTarget.getAttribute("aria-expanded") !== "true"
    this.triggerTarget.setAttribute("aria-expanded", nextOpen ? "true" : "false")
    this.panelTarget.hidden = !nextOpen
  }
}
