import { Controller } from '@hotwired/stimulus'

export default class BoardDeleteConfirmationController extends Controller {
  static targets = ['input', 'submit']
  static values = { expectedId: String }

  connect() {
    if (this.element.dataset.rendered === 'true') {
      return
    }
    this.element.dataset.rendered = 'true'
    this.submitTarget.disabled = true
  }

  check() {
    this.submitTarget.disabled = this.inputTarget.value.trim().toLowerCase() !== this.expectedIdValue
  }
}
