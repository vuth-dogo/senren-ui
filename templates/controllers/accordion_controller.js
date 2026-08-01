import { Controller } from "@hotwired/stimulus"

// senren--accordion
// Local UI: expand/collapse one or multiple panels.
export default class extends Controller {
  static targets = ["trigger", "panel"]
  static values = { multiple: Boolean }

  toggle(event) {
    const trigger = event.currentTarget
    const panel = this._panelFor(trigger.dataset.panelId)
    const nextOpen = trigger.getAttribute("aria-expanded") !== "true"

    if (!this.multipleValue) this._closeAll()
    trigger.setAttribute("aria-expanded", nextOpen ? "true" : "false")
    if (panel) panel.hidden = !nextOpen
  }

  _closeAll() {
    this.triggerTargets.forEach((trigger) => { trigger.setAttribute("aria-expanded", "false") })
    this.panelTargets.forEach((panel) => { panel.hidden = true })
  }

  _panelFor(id) {
    return this.panelTargets.find((panel) => panel.dataset.panelId === id)
  }
}
