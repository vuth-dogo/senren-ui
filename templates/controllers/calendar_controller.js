import { Controller } from "@hotwired/stimulus"

// senren--calendar
// Local UI: select a visible day and update the optional hidden field.
export default class extends Controller {
  static targets = ["day", "value"]

  select(event) {
    const day = event.currentTarget
    this.dayTargets.forEach((target) => {
      target.classList.remove("bg-[hsl(var(--senren-primary))]", "text-[hsl(var(--senren-primary-foreground))]")
    })
    day.classList.add("bg-[hsl(var(--senren-primary))]", "text-[hsl(var(--senren-primary-foreground))]")
    if (this.hasValueTarget) this.valueTarget.value = day.dataset.date
  }
}
