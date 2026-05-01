import { Controller } from "@hotwired/stimulus"

// senren--date-picker
// Local UI: small helpers around native date input.
export default class extends Controller {
  static targets = ["input"]

  today() {
    this.inputTarget.value = new Date().toISOString().slice(0, 10)
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  clear() {
    this.inputTarget.value = ""
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
