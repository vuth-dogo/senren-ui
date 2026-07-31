import { Controller } from "@hotwired/stimulus"

// senren--clipboard
// Local UI: copy text to the clipboard and announce success.
export default class extends Controller {
  static targets = ["source", "button", "status"]
  static values = { copiedLabel: String }

  async copy() {
    const value = this.sourceTarget.value || this.sourceTarget.textContent
    await navigator.clipboard.writeText(value)
    // The await is a suspension point: the element may be gone by now.
    if (!this.hasButtonTarget) return

    const original = this.buttonTarget.textContent
    this.buttonTarget.textContent = this.copiedLabelValue || "Copied"
    if (this.hasStatusTarget) this.statusTarget.textContent = "Copied to clipboard"

    clearTimeout(this._resetTimer)
    this._resetTimer = setTimeout(() => {
      if (this.hasButtonTarget) this.buttonTarget.textContent = original
    }, 1200)
  }

  disconnect() {
    clearTimeout(this._resetTimer)
  }
}
