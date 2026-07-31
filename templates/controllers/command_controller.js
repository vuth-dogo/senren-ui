import { Controller } from "@hotwired/stimulus"

// senren--command
// Local UI: filter command options and support keyboard navigation.
export default class extends Controller {
  static targets = ["input", "list", "option", "empty"]

  connect() {
    this.activeIndex = 0
    this.filter()
  }

  filter() {
    const query = this.normalize(this.inputTarget.value)
    this.optionTargets.forEach((option) => {
      const label = this.normalize(option.dataset.label || option.textContent)
      option.hidden = query.length > 0 && !query.split(/\s+/).every((part) => label.includes(part))
    })
    this.activeIndex = 0
    this.updateActive()
  }

  onKey(event) {
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.move(1)
      return
    }

    if (event.key === "ArrowUp") {
      event.preventDefault()
      this.move(-1)
      return
    }

    if (event.key === "Enter") {
      const option = this.visibleOptions[this.activeIndex]
      if (option) {
        event.preventDefault()
        option.click()
      }
    }
  }

  choose(event) {
    this.dispatch("select", {
      detail: { label: event.currentTarget.textContent.trim(), href: event.currentTarget.getAttribute("href") }
    })
  }

  move(delta) {
    const options = this.visibleOptions
    if (options.length === 0) return
    this.activeIndex = (this.activeIndex + delta + options.length) % options.length
    this.updateActive()
  }

  updateActive() {
    const options = this.visibleOptions
    this.emptyTarget.hidden = options.length > 0
    this.optionTargets.forEach((option) => { option.setAttribute("aria-selected", "false") })
    const active = options[this.activeIndex]
    if (!active) {
      this.inputTarget.removeAttribute("aria-activedescendant")
      return
    }
    active.setAttribute("aria-selected", "true")
    this.inputTarget.setAttribute("aria-activedescendant", active.id)
    active.scrollIntoView({ block: "nearest" })
  }

  normalize(value) {
    return String(value || "").toLowerCase().replace(/[_-]+/g, " ").trim()
  }

  get visibleOptions() {
    return this.optionTargets.filter((option) => !option.hidden)
  }
}
