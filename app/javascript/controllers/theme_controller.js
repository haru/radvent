import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['radio']
  static values = { updateFailedMessage: String, path: String }

  change(event) {
    const themeMeta = document.querySelector('meta[name="theme"]')
    const previousTheme = document.documentElement.dataset.theme
    const newTheme = event.target.value
    document.documentElement.dataset.theme = newTheme
    if (themeMeta) themeMeta.content = newTheme

    this.requestToken = {}
    const requestToken = this.requestToken

    fetch(this.pathValue, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ theme: newTheme })
    }).then((response) => {
      if (requestToken !== this.requestToken) return
      if (!response.ok || response.redirected) {
        this._rollback(previousTheme, themeMeta)
      }
    }).catch(() => {
      if (requestToken !== this.requestToken) return
      this._rollback(previousTheme, themeMeta)
    })
  }

  _rollback(previousTheme, themeMeta) {
    document.documentElement.dataset.theme = previousTheme
    if (themeMeta) themeMeta.content = previousTheme
    this.radioTargets.forEach((radio) => {
      radio.checked = radio.value === previousTheme
    })
    window.alert(this.updateFailedMessageValue)
  }
}
