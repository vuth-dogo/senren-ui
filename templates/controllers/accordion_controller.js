import { Controller } from "@hotwired/stimulus"

// senren--accordion
// Local UI: expand/collapse one or multiple panels.
export default class extends Controller {
  static targets = ["trigger", "panel"]
  static values = { multiple: Boolean }

  // Every pending close timer, so disconnect() can clear them. A panel mid-close
  // when Turbo swaps the page would otherwise leave a timer holding a reference
  // to a detached element -- caught by bin/performance, which fails the build
  // for a timer no disconnect() clears.
  connect() {
    this._timers = new Set()
  }

  disconnect() {
    this._timers?.forEach(clearTimeout)
    this._timers?.clear()
  }

  toggle(event) {
    const trigger = event.currentTarget
    const panel = this._panelFor(trigger.dataset.panelId)
    const nextOpen = trigger.getAttribute("aria-expanded") !== "true"

    if (!this.multipleValue) this._closeAll()
    trigger.setAttribute("aria-expanded", nextOpen ? "true" : "false")
    this._setOpen(panel, nextOpen)
  }

  // The panel animates from grid-template-rows 0fr to 1fr, and it also carries
  // the `hidden` attribute so collapsed content is not focusable or read aloud.
  // Those two want opposite things: `hidden` has to be off for the browser to
  // animate anything, and on once the panel is closed.
  //
  // Opening: drop `hidden`, then flip the row on the next frame -- setting both
  // in one go gives the browser no first value to animate from, and the panel
  // snaps open.
  //
  // Closing: flip the row now, restore `hidden` when the transition ends.
  _setOpen(panel, open) {
    if (!panel) return

    if (open) {
      panel.hidden = false
      requestAnimationFrame(() => {
        panel.classList.remove("grid-rows-[0fr]")
        panel.classList.add("grid-rows-[1fr]")
      })
      return
    }

    panel.classList.remove("grid-rows-[1fr]")
    panel.classList.add("grid-rows-[0fr]")
    this._hideAfterTransition(panel)
  }

  // `transitionend` alone is not enough: it never fires when the panel is
  // already collapsed, when a reduced-motion setting removes the transition, or
  // when the element is off-screen. Without the timeout those panels would stay
  // focusable forever, so whichever arrives first wins and the other is dropped.
  _hideAfterTransition(panel) {
    const finish = () => {
      clearTimeout(timer)
      this._timers?.delete(timer)
      panel.removeEventListener("transitionend", onEnd)
      if (panel.classList.contains("grid-rows-[0fr]")) panel.hidden = true
    }

    const onEnd = (event) => {
      if (event.target === panel && event.propertyName === "grid-template-rows") finish()
    }

    const timer = setTimeout(finish, 300)
    this._timers?.add(timer)
    panel.addEventListener("transitionend", onEnd)
  }

  _closeAll() {
    this.triggerTargets.forEach((trigger) => {
      trigger.setAttribute("aria-expanded", "false")
    })
    this.panelTargets.forEach((panel) => {
      this._setOpen(panel, false)
    })
  }

  _panelFor(id) {
    return this.panelTargets.find((panel) => panel.dataset.panelId === id)
  }
}
