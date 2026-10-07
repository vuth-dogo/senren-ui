import { Controller } from "@hotwired/stimulus"

// senren--clipboard
// Local UI: copy text to the clipboard and announce success.
export default class extends Controller {
  static targets = ["source", "button", "status"]
  static values = { copiedLabel: String, copiedStatus: String }

  async copy() {
    const value = this.sourceTarget.value || this.sourceTarget.textContent
    await navigator.clipboard.writeText(value)
    // The await is a suspension point: the element may be gone by now.
    if (!this.hasButtonTarget) return

    const original = this.buttonTarget.textContent
    if (this.copiedLabelValue) this.buttonTarget.textContent = this.copiedLabelValue
    if (this.hasStatusTarget) this.statusTarget.textContent = this.copiedStatusValue

    clearTimeout(this._resetTimer)
    this._resetTimer = setTimeout(() => {
      if (this.hasButtonTarget) this.buttonTarget.textContent = original
    }, 1200)
  }

  disconnect() {
    clearTimeout(this._resetTimer)
  }
}
