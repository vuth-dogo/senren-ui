import { Controller } from "@hotwired/stimulus"

// senren--tabs
// Local UI: tab activation plus arrow-key navigation.
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    event.preventDefault()
    this._activate(event.currentTarget)
  }

  onKey(event) {
    if (!["ArrowRight", "ArrowLeft", "Home", "End"].includes(event.key)) return
    event.preventDefault()
    const tabs = this.tabTargets
    const index = tabs.indexOf(event.currentTarget)
    const nextIndex = this._nextIndex(event.key, index, tabs.length)
    tabs[nextIndex]?.focus()
    this._activate(tabs[nextIndex])
  }

  _activate(tab) {
    const panelId = tab.dataset.panelId
    this.tabTargets.forEach((target) => {
      const selected = target === tab
      target.setAttribute("aria-selected", selected ? "true" : "false")
      target.tabIndex = selected ? 0 : -1
    })
    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.panelId !== panelId
    })
  }

  _nextIndex(key, index, length) {
    if (key === "Home") return 0
    if (key === "End") return length - 1
    if (key === "ArrowRight") return (index + 1) % length
    return (index - 1 + length) % length
  }
}
