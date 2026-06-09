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
    for (const [name, type] of Object.entries(this.constructor.values || {})) {
      const property = `${name}Value`
      const attr = `data-${this.identifier}-${name.replace(/[A-Z]/g, (match) => `-${match.toLowerCase()}`)}-value`

      Object.defineProperty(this, property, {
        get: () => this._castValue(this.element.getAttribute(attr), type),
        set: (value) => this.element.setAttribute(attr, String(value))
      })
    }
  }

  _castValue(value, type) {
    if (type === Boolean) return value === "true"
    if (type === Number) return Number(value)
    return value
  }
}

export class Application {
  static start() {
    return new Application()
  }

  constructor() {
    this.controllers = new Map()
    this.instances = []
  }

  register(identifier, ControllerClass) {
    this.controllers.set(identifier, ControllerClass)
    this._connect(identifier, ControllerClass)
  }

  _connect(identifier, ControllerClass) {
    document.querySelectorAll(`[data-controller~="${identifier}"]`).forEach((element) => {
      if (element.__senrenControllers?.[identifier]) return

      const instance = new ControllerClass({ application: this, element, identifier })
      element.__senrenControllers ||= {}
      element.__senrenControllers[identifier] = instance
      this.instances.push(instance)
      this._installActions(identifier, element, instance)
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
