import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values  = { active: { type: String, default: "en" } }

  connect() {
    this.activate(this.activeValue)
  }

  switch(event) {
    const locale = event.currentTarget.dataset.locale
    this.activeValue = locale
    this.activate(locale)
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
