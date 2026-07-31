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

    // Read each cell once (O(n)) rather than once per comparison (O(n log n)),
    // then move the rows in a single batched write.
    const decorated = this.rowTargets.map((row) => ({ row, value: this.valueFor(row, key) }))
    decorated.sort((a, b) => this.compare(a.value, b.value, direction))

    const fragment = document.createDocumentFragment()
    decorated.forEach((entry) => { fragment.appendChild(entry.row) })
    this.bodyTarget.appendChild(fragment)
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
