import { Controller } from "@hotwired/stimulus"

// senren--data-table
export default class extends Controller {
  static targets = ["body", "row"]

  connect() {
    this.directions = {}
  }

  sort(event) {
    const key = event.currentTarget.dataset.sortKey
    if (!key || !this.hasBodyTarget) return

    const direction = this.directions[key] === "asc" ? "desc" : "asc"
    this.directions[key] = direction

    const rows = [...this.rowTargets]
    rows.sort((a, b) => this.compare(this.valueFor(a, key), this.valueFor(b, key), direction))
    rows.forEach((row) => this.bodyTarget.appendChild(row))
  }

  valueFor(row, key) {
    const cell = row.querySelector(`[data-sort-key="${CSS.escape(key)}"]`)
    return (cell?.dataset.sortValue || cell?.textContent || "").trim().toLowerCase()
  }

  compare(a, b, direction) {
    const left = Number(a)
    const right = Number(b)
    const result = Number.isNaN(left) || Number.isNaN(right) ? a.localeCompare(b) : left - right
    return direction === "asc" ? result : -result
  }
}
