export class Controller {
  constructor(context) {
    this.context = context
    this.application = context.application
    this.element = context.element
    this.identifier = context.identifier
    this._defineTargets()
    this._defineValues()
  }

  _defineTargets() {
    for (const name of this.constructor.targets || []) {
      const property = `${name}Target`
      const listProperty = `${name}Targets`
      const presenceProperty = `has${name[0].toUpperCase()}${name.slice(1)}Target`

      Object.defineProperty(this, listProperty, {
        get: () => Array.from(this.element.querySelectorAll(`[data-${this.identifier}-target~="${name}"]`))
      })
      Object.defineProperty(this, property, {
        get: () => this[listProperty][0]
      })
      Object.defineProperty(this, presenceProperty, {
        get: () => this[listProperty].length > 0
      })
    }
  }

  _defineValues() {
    this._valueAttributes = {}

    for (const [name, type] of Object.entries(this.constructor.values || {})) {
      const property = `${name}Value`
      const attr = `data-${this.identifier}-${name.replace(/[A-Z]/g, (match) => `-${match.toLowerCase()}`)}-value`
      this._valueAttributes[attr] = { name, type }

      Object.defineProperty(this, property, {
        get: () => this._castValue(this.element.getAttribute(attr), type),
        set: (value) => this.element.setAttribute(attr, String(value))
      })
    }
  }

  // Real Stimulus invokes `<name>ValueChanged` when a value changes, including
  // once during initialization so a server-rendered attribute paints the first
  // frame, and again when the attribute is changed from outside — by a Turbo
  // Stream, a morph, or a test. Senren's stateful controllers put all their DOM
  // work in these callbacks, so the preview app has to implement them or the
  // components render inert.
  _startValueObserver() {
    for (const [attr, { name, type }] of Object.entries(this._valueAttributes || {})) {
      const current = this._castValue(this.element.getAttribute(attr), type)
      this[`${name}ValueChanged`]?.(current, undefined)
      this._lastValues ||= {}
      this._lastValues[name] = current
    }

    const attributeFilter = Object.keys(this._valueAttributes || {})
    if (attributeFilter.length === 0) return

    this._valueObserver = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        const entry = this._valueAttributes[mutation.attributeName]
        if (!entry) continue

        const next = this._castValue(this.element.getAttribute(mutation.attributeName), entry.type)
        const previous = this._lastValues[entry.name]
        if (next === previous) continue

        this._lastValues[entry.name] = next
        this[`${entry.name}ValueChanged`]?.(next, previous)
      }
    })

    this._valueObserver.observe(this.element, { attributes: true, attributeFilter })
  }

  _stopValueObserver() {
    this._valueObserver?.disconnect()
  }

  _castValue(value, type) {
    if (type === Boolean) return value === "true"
    if (type === Number) return Number(value)
    return value
  }

  // Real Stimulus namespaces the event with the controller identifier, so
  // dispatch("changed") from senren--cart emits "senren--cart:changed". Seven
  // controllers announce state this way and a host app is expected to listen,
  // so the preview app has to emit the same names or the contract is untested.
  dispatch(eventName, { target = this.element, detail = {}, prefix = this.identifier, bubbles = true, cancelable = true } = {}) {
    const type = prefix ? `${prefix}:${eventName}` : eventName
    const event = new CustomEvent(type, { detail, bubbles, cancelable })
    target.dispatchEvent(event)
    return event
  }
}

export class Application {
  static start() {
    return new Application()
  }

  constructor() {
    this.controllers = new Map()
    this.instances = []
    this._observe()
  }

  register(identifier, ControllerClass) {
    this.controllers.set(identifier, ControllerClass)
    this._connect(identifier, ControllerClass)
  }

  // Real Stimulus runs connect()/disconnect() as elements enter and leave the
  // DOM. Without this the preview app could not exercise listener lifecycle,
  // which is exactly where controllers leak.
  _observe() {
    this.observer = new MutationObserver((mutations) => {
      let added = false

      mutations.forEach((mutation) => {
        mutation.removedNodes.forEach((node) => this._disconnectTree(node))
        if (mutation.addedNodes.length > 0) added = true
      })

      if (added) this.controllers.forEach((klass, id) => this._connect(id, klass))
    })

    this.observer.observe(document.documentElement, { childList: true, subtree: true })
  }

  _disconnectTree(node) {
    if (node.nodeType !== Node.ELEMENT_NODE) return

    const elements = [node, ...node.querySelectorAll("[data-controller]")]
    elements.forEach((element) => {
      const registry = element.__senrenControllers
      if (!registry) return

      Object.values(registry).forEach((instance) => {
        instance._stopValueObserver?.()
        instance.disconnect?.()
      })
      delete element.__senrenControllers
    })
  }

  _connect(identifier, ControllerClass) {
    document.querySelectorAll(`[data-controller~="${identifier}"]`).forEach((element) => {
      if (element.__senrenControllers?.[identifier]) return

      const instance = new ControllerClass({ application: this, element, identifier })
      element.__senrenControllers ||= {}
      element.__senrenControllers[identifier] = instance
      this.instances.push(instance)
      this._installActions(identifier, element, instance)
      instance._startValueObserver()
      instance.connect?.()
    })
  }

  _installActions(identifier, root, instance) {
    root.querySelectorAll("[data-action]").forEach((element) => {
      element.getAttribute("data-action").split(/\s+/).forEach((descriptor) => {
        const match = descriptor.match(/^([^->]+)->([^#]+)#(.+)$/)
        if (!match || match[2] !== identifier) return

        element.addEventListener(match[1], (event) => instance[match[3]]?.(event))
      })
    })
  }
}
