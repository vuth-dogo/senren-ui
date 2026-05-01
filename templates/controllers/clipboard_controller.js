import { Controller } from "@hotwired/stimulus"

// senren--clipboard
// Local UI: copy text to the clipboard and announce success.
export default class extends Controller {
  static targets = ["source", "button", "status"]
  static values = { copiedLabel: String }

  async copy() {
    const value = this.sourceTarget.value || this.sourceTarget.textContent
    await navigator.clipboard.writeText(value)
    const original = this.buttonTarget.textContent
    this.buttonTarget.textContent = this.copiedLabelValue || "Copied"
    if (this.hasStatusTarget) this.statusTarget.textContent = "Copied to clipboard"
    window.setTimeout(() => { this.buttonTarget.textContent = original }, 1200)
  }
}
