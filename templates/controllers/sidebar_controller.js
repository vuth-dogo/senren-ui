import { Controller } from "@hotwired/stimulus"

// senren--sidebar
// Local UI: compact/expanded visual state only.
export default class extends Controller {
  toggle() {
    this.element.classList.toggle("w-20")
    this.element.classList.toggle("w-64")
  }
}
