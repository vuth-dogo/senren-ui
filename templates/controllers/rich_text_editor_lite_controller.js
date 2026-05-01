import { Controller } from "@hotwired/stimulus"

// senren--rich-text-editor-lite
// Local UI: tiny contenteditable toolbar synced to a hidden textarea.
export default class extends Controller {
  static targets = ["editor", "input", "button"]
  static values = { debug: Boolean }

  connect() {
    this.savedRange = null
    if (document.queryCommandSupported?.("defaultParagraphSeparator")) {
      document.execCommand("defaultParagraphSeparator", false, "p")
    }
    this.enableToolbar()
    this.sync()
    this.rememberSelection()
    this.updateToolbar()
    this.debug("connect", this.snapshot())
  }

  keepSelection(event) {
    event.preventDefault()
    this.rememberSelection()
  }

  openLink(event) {
    const link = event.target.closest("a[href]")
    if (!link || !this.editorTarget.contains(link)) return

    this.debug("openLink", { href: link.href, metaKey: event.metaKey, ctrlKey: event.ctrlKey })
    if (!event.metaKey && !event.ctrlKey) return

    event.preventDefault()
    window.open(link.href, "_blank", "noopener,noreferrer")
  }

  format(event) {
    event.preventDefault()
    const command = event.currentTarget.dataset.command
    if (!command) return

    this.debug("format:start", { command, before: this.snapshot() })
    this.restoreSelection()
    if (command === "createLink") {
      const url = window.prompt("Paste a URL")
      this.debug("createLink:prompt", { url, afterPrompt: this.snapshot() })
      if (!url) return
      this.restoreSelection()
      this.insertLink(url)
    } else if (command === "insertUnorderedList") {
      this.toggleList("ul")
    } else if (command === "insertOrderedList") {
      this.toggleList("ol")
    } else if (command.startsWith("formatBlock:")) {
      this.formatBlocks(command.split(":")[1])
    } else if (command.startsWith("align:")) {
      this.alignBlocks(command.split(":")[1])
    } else {
      this.restoreSelection()
      document.execCommand(command, false, null)
    }
    this.editorTarget.focus()
    this.sync()
    this.updateToolbar()
    this.rememberSelection()
    this.debug("format:done", { command, after: this.snapshot() })
  }

  sync() {
    this.inputTarget.value = this.editorTarget.innerHTML
    this.debug("sync", { inputValue: this.inputTarget.value })
  }

  syncSoon() {
    requestAnimationFrame(() => this.sync())
  }

  updateToolbar() {
    this.buttonTargets.forEach((button) => {
      const command = button.dataset.command
      if (!command || command === "createLink") return

      if (command.startsWith("formatBlock:")) {
        button.setAttribute("aria-pressed", this.selectionInsideBlock(command.split(":")[1]) ? "true" : "false")
        return
      }

      if (command.startsWith("align:")) {
        button.setAttribute("aria-pressed", this.currentAlignment() === command.split(":")[1] ? "true" : "false")
        return
      }

      if (command === "insertUnorderedList") {
        button.setAttribute("aria-pressed", this.selectionInsideList("ul") ? "true" : "false")
        return
      }

      if (command === "insertOrderedList") {
        button.setAttribute("aria-pressed", this.selectionInsideList("ol") ? "true" : "false")
        return
      }

      button.setAttribute("aria-pressed", document.queryCommandState(command) ? "true" : "false")
    })
  }

  enableToolbar() {
    this.buttonTargets.forEach((button) => {
      button.disabled = false
    })
  }

  rememberSelection() {
    const selection = window.getSelection()
    if (!selection || selection.rangeCount === 0) {
      this.debug("rememberSelection:empty")
      return
    }

    const range = selection.getRangeAt(0)
    if (this.rangeInsideEditor(range)) {
      this.savedRange = range.cloneRange()
      this.debug("rememberSelection:saved", this.describeRange(this.savedRange))
    } else {
      this.debug("rememberSelection:outside", this.describeRange(range))
    }
  }

  restoreSelection() {
    this.editorTarget.focus()
    if (this.savedRange && this.rangeInsideEditor(this.savedRange)) {
      const selection = window.getSelection()
      selection.removeAllRanges()
      selection.addRange(this.savedRange)
      this.debug("restoreSelection:saved", this.describeRange(this.savedRange))
      return
    }

    this.debug("restoreSelection:endFallback", this.snapshot())
    this.placeCaretAtEnd()
  }

  insertLink(rawUrl) {
    const url = this.normalizeUrl(rawUrl)
    this.debug("insertLink:start", { rawUrl, url, before: this.snapshot() })
    if (!url) return

    const range = this.activeRange()
    if (!range) {
      this.debug("insertLink:noRange")
      return
    }

    const anchor = document.createElement("a")
    anchor.href = url
    anchor.rel = "noopener noreferrer"
    anchor.target = "_blank"
    this.debug("insertLink:range", this.describeRange(range))

    if (range.collapsed) {
      anchor.textContent = url
      range.insertNode(anchor)
    } else {
      anchor.appendChild(range.extractContents())
      range.insertNode(anchor)
    }

    range.setStartAfter(anchor)
    range.collapse(true)
    const selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)
    this.debug("insertLink:done", { anchor: anchor.outerHTML, after: this.snapshot() })
  }

  toggleList(tagName) {
    const range = this.activeRange()
    this.debug("toggleList:start", { tagName, range: this.describeRange(range), before: this.snapshot() })
    if (!range) return

    const activeList = this.closestElement(range.startContainer, "ul, ol")
    if (activeList && this.editorTarget.contains(activeList)) {
      if (activeList.tagName.toLowerCase() === tagName) {
        this.unwrapList(activeList)
      } else {
        this.convertList(activeList, tagName)
      }
      this.debug("toggleList:existingList", { tagName, after: this.snapshot() })
      return
    }

    const blocks = this.selectedBlocks(range)
    this.debug("toggleList:blocks", { tagName, blocks: blocks.map((block) => block.outerHTML) })
    if (blocks.length === 0) return

    const list = document.createElement(tagName)
    blocks.forEach((block) => {
      const item = document.createElement("li")
      while (block.firstChild) item.appendChild(block.firstChild)
      if (item.childNodes.length === 0) item.appendChild(document.createElement("br"))
      list.appendChild(item)
    })

    blocks[0].before(list)
    blocks.forEach((block) => block.remove())
    this.selectNodeContents(list)
    this.debug("toggleList:done", { list: list.outerHTML, after: this.snapshot() })
  }

  formatBlocks(tagName) {
    const normalizedTagName = this.normalizedBlockTag(tagName)
    const range = this.activeRange()
    this.debug("formatBlocks:start", { tagName: normalizedTagName, range: this.describeRange(range) })
    if (!range) return

    const blocks = this.selectedBlocks(range)
    if (blocks.length === 0) return

    const replacements = blocks.map((block) => this.replaceBlock(block, normalizedTagName))
    this.selectNodeContents(replacements[replacements.length - 1])
    this.debug("formatBlocks:done", { tagName: normalizedTagName, blocks: replacements.map((block) => block.outerHTML) })
  }

  alignBlocks(alignment) {
    const normalizedAlignment = this.normalizedAlignment(alignment)
    const range = this.activeRange()
    this.debug("alignBlocks:start", { alignment: normalizedAlignment, range: this.describeRange(range) })
    if (!range) return

    const blocks = this.selectedBlocks(range)
    blocks.forEach((block) => {
      if (this.blockAlignment(block) === normalizedAlignment || normalizedAlignment === "left") {
        block.removeAttribute("data-align")
      } else {
        block.dataset.align = normalizedAlignment
      }
    })

    if (blocks.length > 0) this.selectNodeContents(blocks[blocks.length - 1])
    this.debug("alignBlocks:done", { alignment: normalizedAlignment, blocks: blocks.map((block) => block.outerHTML) })
  }

  unwrapList(list) {
    const paragraphs = Array.from(list.children).map((item) => {
      const paragraph = document.createElement("p")
      while (item.firstChild) paragraph.appendChild(item.firstChild)
      if (paragraph.childNodes.length === 0) paragraph.appendChild(document.createElement("br"))
      return paragraph
    })

    list.replaceWith(...paragraphs)
    this.selectNodeContents(paragraphs[paragraphs.length - 1])
  }

  convertList(list, tagName) {
    const replacement = document.createElement(tagName)
    while (list.firstChild) replacement.appendChild(list.firstChild)
    list.replaceWith(replacement)
    this.selectNodeContents(replacement)
  }

  placeCaretAtEnd() {
    const range = document.createRange()
    range.selectNodeContents(this.editorTarget)
    range.collapse(false)
    const selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)
    this.savedRange = range.cloneRange()
  }

  rangeInsideEditor(range) {
    try {
      return this.editorTarget.contains(range.commonAncestorContainer)
    } catch (_) {
      return false
    }
  }

  normalizeUrl(rawUrl) {
    const url = String(rawUrl || "").trim()
    if (url.length === 0) return null
    if (/^(?:[a-z][a-z0-9+.-]*:|\/|#)/i.test(url)) return url
    return `https://${url}`
  }

  activeRange() {
    const selection = window.getSelection()
    if (selection && selection.rangeCount > 0) {
      const range = selection.getRangeAt(0)
      if (this.rangeInsideEditor(range)) {
        this.debug("activeRange:selection", this.describeRange(range))
        return range
      }
    }

    if (this.savedRange && this.rangeInsideEditor(this.savedRange)) {
      this.debug("activeRange:saved", this.describeRange(this.savedRange))
      return this.savedRange
    }

    this.placeCaretAtEnd()
    const range = window.getSelection().getRangeAt(0)
    this.debug("activeRange:endFallback", this.describeRange(range))
    return range
  }

  selectedBlocks(range) {
    const selected = Array.from(this.editorTarget.querySelectorAll("p, div, li, blockquote, h1, h2, h3, h4, h5, h6"))
      .filter((block) => {
        try {
          return range.intersectsNode(block)
        } catch (_) {
          return false
        }
      })

    if (selected.length > 0) return selected

    const block = this.closestBlock(range.commonAncestorContainer)
    if (block) return [block]

    const paragraph = document.createElement("p")
    paragraph.appendChild(range.extractContents())
    if (paragraph.childNodes.length === 0) paragraph.appendChild(document.createElement("br"))
    range.insertNode(paragraph)
    return [paragraph]
  }

  closestBlock(node) {
    return this.closestElement(node, "p, div, li, blockquote, h1, h2, h3, h4, h5, h6")
  }

  closestElement(node, selector) {
    const element = node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement
    return element?.closest(selector)
  }

  selectionInsideList(tagName) {
    const range = this.selectionRange()
    return !!(range && this.closestElement(range.startContainer, tagName))
  }

  selectionInsideBlock(tagName) {
    const range = this.selectionRange()
    const block = range && this.closestBlock(range.startContainer)
    return block?.tagName.toLowerCase() === this.normalizedBlockTag(tagName)
  }

  currentAlignment() {
    const range = this.selectionRange()
    const block = range && this.closestBlock(range.startContainer)
    return this.blockAlignment(block)
  }

  blockAlignment(block) {
    return block?.dataset.align || "left"
  }

  replaceBlock(block, tagName) {
    if (block.tagName.toLowerCase() === tagName) return block

    const replacement = document.createElement(tagName)
    if (block.dataset.align) replacement.dataset.align = block.dataset.align
    while (block.firstChild) replacement.appendChild(block.firstChild)
    if (replacement.childNodes.length === 0) replacement.appendChild(document.createElement("br"))
    block.replaceWith(replacement)
    return replacement
  }

  normalizedBlockTag(tagName) {
    return ["p", "h1", "h2", "h3"].includes(tagName) ? tagName : "p"
  }

  normalizedAlignment(alignment) {
    return ["left", "center", "right", "justify"].includes(alignment) ? alignment : "left"
  }

  selectNodeContents(node) {
    if (!node) return

    const range = document.createRange()
    range.selectNodeContents(node)
    const selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)
    this.savedRange = range.cloneRange()
  }

  selectionRange() {
    const selection = window.getSelection()
    if (selection && selection.rangeCount > 0) {
      const range = selection.getRangeAt(0)
      if (this.rangeInsideEditor(range)) return range
    }

    if (this.savedRange && this.rangeInsideEditor(this.savedRange)) {
      return this.savedRange
    }

    return null
  }

  snapshot() {
    const range = this.selectionRange()
    return {
      html: this.editorTarget.innerHTML,
      text: this.editorTarget.textContent,
      selection: this.describeRange(range),
      savedSelection: this.describeRange(this.savedRange)
    }
  }

  describeRange(range) {
    if (!range) return null

    return {
      collapsed: range.collapsed,
      text: range.toString(),
      start: this.describeNode(range.startContainer),
      startOffset: range.startOffset,
      end: this.describeNode(range.endContainer),
      endOffset: range.endOffset,
      insideEditor: this.rangeInsideEditor(range)
    }
  }

  describeNode(node) {
    if (!node) return null
    if (node.nodeType === Node.TEXT_NODE) return `#text:${node.textContent}`
    if (node.nodeType !== Node.ELEMENT_NODE) return node.nodeName

    const id = node.id ? `#${node.id}` : ""
    const classes = node.className ? `.${String(node.className).trim().replace(/\s+/g, ".")}` : ""
    return `${node.tagName.toLowerCase()}${id}${classes}`
  }

  debug(message, detail = {}) {
    if (!this.debugValue) return

    console.debug("[senren rich text]", message, detail)
  }
}
