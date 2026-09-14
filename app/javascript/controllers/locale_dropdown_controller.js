import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
  }

  toggle() {
    const open = this.menuTarget.classList.toggle("hidden") === false
    this.buttonTarget.setAttribute("aria-expanded", open)

    if (open) this.menuTarget.focus()
  }

  clickOutside(event) {
    if (!this.menuTarget.classList.contains("hidden") && !this.element.contains(event.target)) {
      this.close()
    }
  }

  close(event) {
    if (this.menuTarget.classList.contains("hidden")) return

    this.menuTarget.classList.add("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "false")

    // Only Escape should return keyboard focus to the language switcher.
    // Clicking another control must leave focus on that control.
    if (event?.type === "keydown" && event.key === "Escape") this.buttonTarget.focus()
  }
}
