import { Application } from "@hotwired/stimulus"

const application = Application.start()

window.Stimulus = application
window.SenrenLoadedControllers = []

function controllerPath(identifier) {
  const [namespace, name] = identifier.split("--")
  return `controllers/${namespace}/${name.replaceAll("-", "_")}_controller.js`
}

async function lazyLoadControllersFrom() {
  const identifiers = Array.from(document.querySelectorAll("[data-controller]"))
    .flatMap((element) => element.getAttribute("data-controller").split(/\s+/))
    .filter((identifier) => identifier.startsWith("senren--"))

  for (const identifier of Array.from(new Set(identifiers)).sort()) {
    const module = await import(controllerPath(identifier))
    application.register(identifier, module.default)
    window.SenrenLoadedControllers.push(identifier)
  }
}

lazyLoadControllersFrom()
