import { Controller } from "@hotwired/stimulus"

// senren--carousel
// Local UI: previous/next controls, dots, and arrow-key navigation.
export default class extends Controller {
  static targets = ["slide", "dot", "status"]

  connect() {
    this.index = 0
    this.show(0)
  }

  previous() {
    this.show(this.index - 1)
  }

  next() {
    this.show(this.index + 1)
  }

  goTo(event) {
    this.show(Number(event.currentTarget.dataset.index || 0))
  }

  onKey(event) {
    if (event.key === "ArrowLeft") {
      event.preventDefault()
      this.previous()
    }
    if (event.key === "ArrowRight") {
      event.preventDefault()
      this.next()
    }
  }

  show(index) {
    const count = this.slideTargets.length
    if (count === 0) return

    this.index = (index + count) % count
    this.slideTargets.forEach((slide, slideIndex) => {
      slide.hidden = slideIndex !== this.index
      slide.classList.toggle("hidden", slideIndex !== this.index)
    })
    this.dotTargets.forEach((dot, dotIndex) => {
      dot.setAttribute("aria-current", dotIndex === this.index ? "true" : "false")
    })
    if (this.hasStatusTarget) this.statusTarget.textContent = `Slide ${this.index + 1} of ${count}`
  }
}
