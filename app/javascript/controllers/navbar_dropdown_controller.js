import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "toggle"]

  connect() {
    this._outsideClickHandler = this._handleOutsideClick.bind(this)
    document.addEventListener("click", this._outsideClickHandler)
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClickHandler)
  }

  toggle(event) {
    event.preventDefault()
    const isOpen = this.menuTarget.classList.contains("show")
    this.menuTarget.classList.toggle("show", !isOpen)
    this.toggleTarget.setAttribute("aria-expanded", String(!isOpen))
  }

  _handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.remove("show")
      this.toggleTarget.setAttribute("aria-expanded", "false")
    }
  }
}
