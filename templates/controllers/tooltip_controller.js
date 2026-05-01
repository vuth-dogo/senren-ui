import { Controller } from "@hotwired/stimulus"

// senren--tooltip
// Show/hide a small tooltip bubble on hover or focus.
export default class extends Controller {
  static targets = ["bubble"]

  show()  { if (this.hasBubbleTarget) this.bubbleTarget.hidden = false }
  hide()  { if (this.hasBubbleTarget) this.bubbleTarget.hidden = true }
}
