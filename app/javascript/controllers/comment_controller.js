import { Controller } from '@hotwired/stimulus'
import { marked } from 'marked'
import DOMPurify from 'dompurify'

export default class CommentController extends Controller {
  connect() {
    if (this.element.dataset.rendered === 'true') return

    const markdown = this.element.dataset.markdown || this.element.textContent
    this.element.innerHTML = DOMPurify.sanitize(marked(markdown))
    this.element.dataset.rendered = 'true'
  }
}
