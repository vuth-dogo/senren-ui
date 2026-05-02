import { Controller } from "@hotwired/stimulus"

// senren--sidebar
// Local UI: compact/expanded visual state only.
export default class extends Controller {
  static targets = ["brand", "footer", "toggleButton", "link", "linkLabel", "linkInitial"]

  connect() {
    this.syncState()
  }

  toggle() {
    const isCompact = this.element.classList.contains("w-20")
    this.element.classList.toggle("w-20", !isCompact)
    this.element.classList.toggle("w-64", isCompact)
    this.syncState()
  }

  syncState() {
    const isCompact = this.element.classList.contains("w-20")

    if (this.hasBrandTarget) {
      this.brandTarget.classList.toggle("hidden", isCompact)
    }

    if (this.hasFooterTarget) {
      this.footerTarget.classList.toggle("hidden", isCompact)
    }

    this.linkTargets.forEach((link) => {
      link.classList.toggle("justify-center", isCompact)
      link.classList.toggle("px-2", isCompact)
      link.classList.toggle("px-3", !isCompact)
    })

    this.linkLabelTargets.forEach((label) => {
      label.classList.toggle("max-w-0", isCompact)
      label.classList.toggle("opacity-0", isCompact)
      label.classList.toggle("max-w-40", !isCompact)
      label.classList.toggle("opacity-100", !isCompact)
    })

    this.linkInitialTargets.forEach((initial) => {
      initial.classList.toggle("w-4", isCompact)
      initial.classList.toggle("opacity-100", isCompact)
      initial.classList.toggle("w-0", !isCompact)
      initial.classList.toggle("opacity-0", !isCompact)
    })

    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.setAttribute("aria-expanded", String(!isCompact))
    }
  }
}
