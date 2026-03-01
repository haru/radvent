import { Controller } from '@hotwired/stimulus'
import { marked } from 'marked'
import DOMPurify from 'dompurify'

export default class MarkdownController extends Controller {
  static values = { body: String }

  connect() {
    if (!this.bodyValue) return
    this.element.innerHTML = DOMPurify.sanitize(marked(this.bodyValue))
    this.element.querySelectorAll('pre code').forEach((block) => {
      if (window.hljs) {
        window.hljs.highlightBlock(block)
      }
    })
  }
}
