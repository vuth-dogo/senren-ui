import { Controller } from "@hotwired/stimulus"

// senren--masked-input
// Apply a simple character mask to an input. Mask DSL:
//   #  -> any digit
//   A  -> any letter
//   *  -> any character
// Other characters are literal.
export default class extends Controller {
  static values = { mask: String }

  connect() {
    this.element.addEventListener("input", this._onInput.bind(this))
  }

  _onInput(event) {
    if (!this.maskValue) return
    const raw = event.target.value.replace(/[^A-Za-z0-9]/g, "")
    let out = ""
    let i = 0
    for (const m of this.maskValue) {
      if (i >= raw.length) break
      if (m === "#" && /[0-9]/.test(raw[i]))      { out += raw[i++] }
      else if (m === "A" && /[A-Za-z]/.test(raw[i])) { out += raw[i++] }
      else if (m === "*")                          { out += raw[i++] }
      else                                          { out += m }
    }
    event.target.value = out
  }
}
