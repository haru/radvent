import { Controller } from '@hotwired/stimulus'
import { marked } from 'marked'
import DOMPurify from 'dompurify'

export default class CommentController extends Controller {
  connect() {
    const text = this.element.textContent
    this.element.innerHTML = DOMPurify.sanitize(marked(text))
  }
}
