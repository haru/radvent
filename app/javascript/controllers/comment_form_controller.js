import { Controller } from '@hotwired/stimulus'
import { Input } from 'mdb-ui-kit/js/mdb.es.min.js'

export default class CommentFormController extends Controller {
  // Clears only the comment body after a successful post; the form itself is kept as is.
  reset(event) {
    if (!event.detail.success) return

    const body = this.element.querySelector('textarea')
    body.value = ''
    Input.getOrCreateInstance(body.closest('.form-outline')).update()
  }
}
