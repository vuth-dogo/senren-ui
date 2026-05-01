import { Controller } from "@hotwired/stimulus"

// senren--dropdown-menu
// Local UI: toggle visibility, close on outside click and Escape, basic arrow nav.
export default class extends Controller {
  static targets = ["trigger", "menu"]

  connect() {
    this._onDocClick = this._onDocClick.bind(this)
    this._onKey = this._onKey.bind(this)
    this._setOpenState(false)
  }

  disconnect() {
    document.removeEventListener("click", this._onDocClick)
    document.removeEventListener("keydown", this._onKey)
  }

  toggle(event) {
    event?.preventDefault()
    this.menuTarget.hidden ? this._show() : this.close()
  }

  close() {
    this._setOpenState(false)
    document.removeEventListener("click", this._onDocClick)
    document.removeEventListener("keydown", this._onKey)
  }

  onTriggerKey(event) {
    if (["Enter", " ", "ArrowDown"].includes(event.key)) {
      event.preventDefault()
      this._show()
      this._focusItem(0)
    }
  }

  onItemKey(event) {
    const items = this._items()
    const idx = items.indexOf(document.activeElement)
    if (event.key === "ArrowDown") { event.preventDefault(); this._focusItem((idx + 1) % items.length) }
    if (event.key === "ArrowUp")   { event.preventDefault(); this._focusItem((idx - 1 + items.length) % items.length) }
    if (event.key === "Escape")    { this.close(); this.triggerTarget?.focus?.() }
  }

  _show() {
    this._setOpenState(true)
    document.addEventListener("click", this._onDocClick)
    document.addEventListener("keydown", this._onKey)
  }

  _setOpenState(open) {
    const state = open ? "open" : "closed"
    this.menuTarget.hidden = !open
    this.element.dataset.state = state
    this.triggerTarget.dataset.state = state
    this.triggerTarget.setAttribute("aria-expanded", open ? "true" : "false")

    const triggerControl = this._triggerControl()
    if (triggerControl && triggerControl !== this.triggerTarget) {
      triggerControl.dataset.state = state
      triggerControl.setAttribute("aria-expanded", open ? "true" : "false")
    }

    this.triggerTarget.querySelectorAll("[data-senren-chevron]").forEach((chevron) => {
      chevron.dataset.state = state
    })
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
