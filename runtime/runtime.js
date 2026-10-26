;(function (root) {
  "use strict"

  const VERSION = "1.0.2-oc214"
  const RTL_LETTERS = /\p{Script=Arabic}/gu
  const LTR_LETTERS = /\p{Script=Latin}/gu
  const TECHNICAL_TOKEN = /(?:https?:\/\/|www\.)\S+|(?:[A-Za-z]:[\\/]|\.{0,2}[\\/])\S+|\b\S+@\S+\.\S+\b|\b[0-9a-f]{7,}\b/giu
  const EXCLUDED_TEXT_SELECTOR = [
    "code",
    "pre",
    "kbd",
    "samp",
    ".katex",
    '[data-component="markdown-code"]',
    '[data-slot="message-part-directory"]',
  ].join(", ")
  const BLOCK_SELECTOR = [
    '[data-component="markdown"] :where(p, h1, h2, h3, h4, h5, h6, blockquote, ul, ol, table)',
    '[data-slot="user-message-text"]',
    '[data-slot="text-part-body"]',
    '[data-component="composer-editor"]',
    '[data-component="home-session-row"] > span',
    '[data-component="home-session-search-row"] span',
    '[data-component="home-project-row"] span',
    '[data-component="home-recently-closed-row"] span',
    '[data-session-id] a > span',
    '[data-slot="titlebar-tab-item"] [data-slot="tab-title"]',
    '[data-slot="titlebar-tabs"] [data-slot="title"]',
  ].join(", ")
  const COMPOSER_SELECTOR = '[data-component="composer-editor"]'

  function cleanTechnicalText(text) {
    return text.replace(TECHNICAL_TOKEN, " ")
  }

  function dominantDirection(text) {
    const readable = cleanTechnicalText(text)
    const rtl = readable.match(RTL_LETTERS)?.length ?? 0
    const ltr = readable.match(LTR_LETTERS)?.length ?? 0
    if (!rtl && !ltr) return null
    return rtl > ltr ? "rtl" : "ltr"
  }

  const api = { cleanTechnicalText, dominantDirection }
  if (typeof module === "object" && module.exports) {
    module.exports = api
    return
  }
  if (!root.document?.body) return

  const document = root.document
  const html = document.documentElement
  if (html.dataset.opencodePersianRuntime === VERSION) return

  const originals = new WeakMap()

  function readableText(element) {
    const clone = element.cloneNode(true)
    for (const excluded of clone.querySelectorAll(EXCLUDED_TEXT_SELECTOR)) excluded.remove()
    return clone.textContent ?? ""
  }

  function remember(element) {
    if (originals.has(element)) return
    originals.set(element, {
      hadDir: element.hasAttribute("dir"),
      dir: element.getAttribute("dir"),
    })
  }

  function restore(element) {
    const original = originals.get(element)
    if (!original) return
    if (original.hadDir) element.setAttribute("dir", original.dir ?? "")
    else element.removeAttribute("dir")
    element.removeAttribute("data-oppt-direction")
    originals.delete(element)
  }

  function applyDirection(element) {
    if (!(element instanceof Element) || element.closest(EXCLUDED_TEXT_SELECTOR)) return

    const managed = originals.has(element)
    if (!managed && element.hasAttribute("dir")) return

    const direction = dominantDirection(readableText(element))
    if (!direction) {
      if (element.matches(COMPOSER_SELECTOR)) {
        remember(element)
        element.setAttribute("dir", "auto")
        element.dataset.opptDirection = "auto"
      } else {
        restore(element)
      }
      return
    }

    remember(element)
    element.setAttribute("dir", direction)
    element.dataset.opptDirection = direction
  }

  function scan() {
    frame = 0
    for (const element of document.querySelectorAll(BLOCK_SELECTOR)) {
      if (
        element.matches('[data-slot="text-part-body"]') &&
        element.querySelector('[data-component="markdown"]')
      ) {
        continue
      }
      applyDirection(element)
    }
  }

  let frame = 0
  function schedule() {
    if (!frame) frame = requestAnimationFrame(scan)
  }

  html.dataset.opencodePersianRuntime = VERSION
  root.__OPPT_STATUS__ = { active: true, version: VERSION }
  scan()

  const observer = new MutationObserver(schedule)
  observer.observe(document.body, {
    characterData: true,
    childList: true,
    subtree: true,
  })

  root.addEventListener(
    "pagehide",
    () => {
      observer.disconnect()
      if (frame) cancelAnimationFrame(frame)
    },
    { once: true },
  )
})(globalThis)
