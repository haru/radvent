import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['radio']
  static values = { updateFailedMessage: String }

  change(event) {
    const previousTheme = document.documentElement.dataset.theme
    const newTheme = event.target.value
    document.documentElement.dataset.theme = newTheme

    fetch('/theme', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ theme: newTheme })
    }).then((response) => {
      if (!response.ok) {
        this._rollback(previousTheme)
      }
    }).catch(() => {
      this._rollback(previousTheme)
    })
  }

  _rollback(previousTheme) {
    document.documentElement.dataset.theme = previousTheme
    this.radioTargets.forEach((radio) => {
      radio.checked = radio.value === previousTheme
    })
    window.alert(this.updateFailedMessageValue)
  }
}
