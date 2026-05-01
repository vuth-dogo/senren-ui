import { Controller } from "@hotwired/stimulus"

// senren--api-key-field
export default class extends Controller {
  static targets = ["input", "revealButton", "status"]
  static values = {
    revealLabel: String,
    hideLabel: String,
    copyLabel: String
  }

  connect() {
    this.hidden = true
  }

  toggle() {
    this.hidden = !this.hidden
    this.inputTarget.type = this.hidden ? "password" : "text"
    this.revealButtonTarget.textContent = this.hidden ? this.revealLabelValue : this.hideLabelValue
  }

  async copy() {
    const value = this.inputTarget.value
    if (!value) return

    if (navigator.clipboard) {
      await navigator.clipboard.writeText(value)
    } else {
      this.inputTarget.select()
      try { document.execCommand("copy") } catch (_) {}
      this.inputTarget.setSelectionRange(0, 0)
    }

    if (this.hasStatusTarget) this.statusTarget.textContent = `${this.copyLabelValue} complete`
  }
}
