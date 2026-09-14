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

  close() {
    this.menuTarget.classList.add("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.buttonTarget.focus()
  }

  clickOutside(event) {
    if (!this.menuTarget.classList.contains("hidden") && !this.element.contains(event.target)) this.close()
  }
}
