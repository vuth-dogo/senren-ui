import { Controller } from "@hotwired/stimulus"

// senren--cart
// Local UI only: quantity steppers and the displayed subtotal. The server owns
// the cart, so nothing here talks to it — a host app persists changes by
// listening for senren--cart:changed, or by submitting the surrounding form.
//
// State lives in `subtotalCentsValue`, following the pattern in
// .senren/conventions.md: actions assign values, and subtotalCentsValueChanged
// performs the DOM work. A server-rendered subtotal therefore paints the first
// frame, survives a Turbo morph, and can be corrected by a Turbo Stream that
// changes one attribute.
export default class extends Controller {
  static targets = ["line", "quantity", "lineTotal", "subtotal", "count"]
  static values = { currency: String, subtotalCents: Number }

  increment(event) {
    this._step(event, +1)
  }

  decrement(event) {
    this._step(event, -1)
  }

  remove(event) {
    const line = event.currentTarget.closest("[data-senren--cart-target~='line']")
    if (!line) return

    const id = line.dataset.lineId
    line.remove()
    this._recalculate()
    this.dispatch("removed", { detail: { id, subtotalCents: this.subtotalCentsValue } })
  }

  // The value is the state; this renders it. Called on initialization too, so
  // whatever the server rendered is what shows.
  subtotalCentsValueChanged(cents) {
    if (this.hasSubtotalTarget) this.subtotalTarget.textContent = this.format(cents)
  }

  format(cents) {
    return `${this.currencyValue || "$"}${(Number(cents) / 100).toFixed(2)}`
  }

  _step(event, delta) {
    const line = event.currentTarget.closest("[data-senren--cart-target~='line']")
    if (!line) return

    const output = line.querySelector("[data-senren--cart-target~='quantity']")
    if (!output) return

    // Never below one: removing is a separate, explicit action, so a stepper
    // that reaches zero would leave a line the user cannot see the price of.
    const next = Math.max(1, Number(output.textContent.trim() || 1) + delta)
    output.textContent = String(next)

    this._recalculate()
    this.dispatch("changed", {
      detail: { id: line.dataset.lineId, quantity: next, subtotalCents: this.subtotalCentsValue }
    })
  }

  _recalculate() {
    let cents = 0
    let count = 0

    this.lineTargets.forEach((line) => {
      const price = Number(line.dataset.priceCents || 0)
      const output = line.querySelector("[data-senren--cart-target~='quantity']")
      const quantity = Number(output?.textContent.trim() || 0)
      const total = price * quantity

      cents += total
      count += quantity

      const lineTotal = line.querySelector("[data-senren--cart-target~='lineTotal']")
      if (lineTotal) lineTotal.textContent = this.format(total)
    })

    if (this.hasCountTarget) this.countTarget.textContent = String(count)
    this.subtotalCentsValue = cents
  }
}
