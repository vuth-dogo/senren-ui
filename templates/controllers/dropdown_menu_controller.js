import { Controller } from "@hotwired/stimulus"

// senren--dropdown-menu
// Local UI: toggle visibility, close on outside click and Escape, basic arrow nav.
//
// State lives in `openValue`. Actions assign it; openValueChanged performs
// every DOM change — including the `data-state` attributes the chevron styling
// reads — and owns the document listeners.
export default class extends Controller {
  static targets = ["trigger", "menu"]
  static values = { open: Boolean }

  connect() {
    this._onDocClick = this._onDocClick.bind(this)
    this._onKey = this._onKey.bind(this)
  }

  disconnect() {
    this._stopListening()
  }

  toggle(event) {
    event?.preventDefault()
    this.openValue = !this.openValue
  }

  close() {
    this.openValue = false
  }

  onTriggerKey(event) {
    if (["Enter", " ", "ArrowDown"].includes(event.key)) {
      event.preventDefault()
      this.openValue = true
      this._focusItem(0)
    }
  }

  onItemKey(event) {
    const items = this._items()
    const idx = items.indexOf(document.activeElement)
    if (event.key === "ArrowDown") { event.preventDefault(); this._focusItem((idx + 1) % items.length) }
    if (event.key === "ArrowUp") { event.preventDefault(); this._focusItem((idx - 1 + items.length) % items.length) }
    if (event.key === "Escape") { this.close(); this.triggerTarget?.focus?.() }
  }

  openValueChanged(isOpen) {
    const state = isOpen ? "open" : "closed"

    if (this.hasMenuTarget) this.menuTarget.hidden = !isOpen
    this.element.dataset.state = state

    if (this.hasTriggerTarget) {
      this.triggerTarget.dataset.state = state
      this.triggerTarget.setAttribute("aria-expanded", isOpen ? "true" : "false")

      const control = this._triggerControl()
      if (control && control !== this.triggerTarget) {
        control.dataset.state = state
        control.setAttribute("aria-expanded", isOpen ? "true" : "false")
      }

      this.triggerTarget.querySelectorAll("[data-senren-chevron]").forEach((chevron) => {
        chevron.dataset.state = state
      })
    }

    if (isOpen) {
      document.addEventListener("click", this._onDocClick)
      document.addEventListener("keydown", this._onKey)
      this.dispatch("opened")
      return
    }

    this._stopListening()
  }

  _stopListening() {
    document.removeEventListener("click", this._onDocClick)
    document.removeEventListener("keydown", this._onKey)
  }

  _triggerControl() {
    return this.triggerTarget.matches("button, a, [role='button']")
      ? this.triggerTarget
      : this.triggerTarget.querySelector("button, a, [role='button']")
  }

  _items() {
    return Array.from(this.menuTarget.querySelectorAll('[role="menuitem"]'))
  }

  _focusItem(i) {
    const items = this._items()
    items[i]?.focus()
  }

  _onDocClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  _onKey(event) {
    if (event.key === "Escape") this.close()
  }
}
