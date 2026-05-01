import { Controller } from "@hotwired/stimulus"

// senren--combobox
// Local UI: open, filter options, and write the selected value to a hidden input.
export default class extends Controller {
  static targets = ["button", "panel", "search", "option", "value", "label", "chevron"]

  connect() {
    this._onDocClick = this._onDocClick.bind(this)
    this.setOpenState(false)
  }

  disconnect() {
    document.removeEventListener("click", this._onDocClick)
  }

  toggle() {
    this.panelTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.setOpenState(true)
    document.addEventListener("click", this._onDocClick)
    queueMicrotask(() => this.searchTarget.focus())
  }

  close() {
    this.setOpenState(false)
    document.removeEventListener("click", this._onDocClick)
  }

  filter() {
    const query = this.searchTarget.value.toLowerCase()
    this.optionTargets.forEach((option) => {
      option.hidden = !option.dataset.label.toLowerCase().includes(query)
    })
  }

  choose(event) {
    const option = event.currentTarget
    this.valueTarget.value = option.dataset.value
    this.labelTarget.textContent = option.dataset.label
    this.close()
    this.buttonTarget.focus()
  }

  onKey(event) {
    if (event.key === "Escape") {
      this.close()
      this.buttonTarget.focus()
    }
  }

  setOpenState(open) {
    this.panelTarget.hidden = !open
    this.buttonTarget.setAttribute("aria-expanded", open ? "true" : "false")
    this.buttonTarget.dataset.state = open ? "open" : "closed"
    if (this.hasChevronTarget) this.chevronTarget.dataset.state = open ? "open" : "closed"
  }

  _onDocClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }
}
