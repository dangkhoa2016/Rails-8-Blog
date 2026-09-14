import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values  = { active: { type: String, default: "en" } }

  connect() {
    this.activate(this.activeValue)
    this.element.dataset.languageTabsReady = "true"
  }

  disconnect() {
    delete this.element.dataset.languageTabsReady
  }

  switch(event) {
    const locale = event.currentTarget.dataset.locale
    this.activeValue = locale
    this.activate(locale)
  }

  navigate(event) {
    const currentIndex = this.tabTargets.indexOf(event.currentTarget)
    const targetIndex = {
      ArrowRight: (currentIndex + 1) % this.tabTargets.length,
      ArrowLeft: (currentIndex - 1 + this.tabTargets.length) % this.tabTargets.length,
      Home: 0,
      End: this.tabTargets.length - 1
    }[event.key]

    if (targetIndex === undefined) return

    event.preventDefault()
    const tab = this.tabTargets[targetIndex]
    this.activeValue = tab.dataset.locale
    this.activate(this.activeValue)
    tab.focus()
  }

  activate(locale) {
    // Update tabs
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.locale === locale
      if (isActive) {
        tab.classList.add("border-indigo-500", "text-indigo-600")
        tab.classList.remove("border-transparent", "text-gray-500")
      } else {
        tab.classList.remove("border-indigo-500", "text-indigo-600")
        tab.classList.add("border-transparent", "text-gray-500")
      }

      tab.setAttribute("aria-selected", isActive)
      tab.setAttribute("tabindex", isActive ? "0" : "-1")
    })
    
    // Update panels
    this.panelTargets.forEach(panel => {
      if (panel.dataset.locale === locale) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}
