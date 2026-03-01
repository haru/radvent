import { Controller } from '@hotwired/stimulus'
import { marked } from 'marked'
import EasyMDE from 'easymde'
import DOMPurify from 'dompurify'

export default class EditorController extends Controller {
  static targets = ['textarea', 'previewButton']
  static values = {
    uploadPath: String,
    uploadError: String,
    networkError: String
  }

  connect() {
    if (!this.hasTextareaTarget) return
    if (this.easyMDE) return

    const uploadPath = this.uploadPathValue || '/'
    const uploadErrorMsg = this.uploadErrorValue || 'アップロードに失敗しました'
    const networkErrorMsg = this.networkErrorValue || 'ネットワークエラーが発生しました'

    this.easyMDE = new EasyMDE({
      element: this.textareaTarget,
      forceSync: true,
      spellChecker: false,
      minHeight: '200px',
      maxHeight: '400px',
      toolbar: [
        'bold', 'italic', 'heading', '|',
        'quote', 'unordered-list', 'ordered-list', '|',
        'link', 'code', '|',
        'preview', 'side-by-side', 'fullscreen', 'guide'
      ],
      renderingConfig: {
        codeSyntaxHighlighting: true,
        sanitizerFunction: function(renderedHTML) {
          return DOMPurify.sanitize(renderedHTML)
        }
      },
      previewRender: function(plainText) {
        return DOMPurify.sanitize(marked(plainText))
      },
      uploadImage: true,
      imageUploadFunction: (file, onSuccess, onError) => {
        this._uploadImage(file, onSuccess, onError, uploadPath, uploadErrorMsg, networkErrorMsg)
      }
    })
  }

  disconnect() {
    if (this.easyMDE) {
      this.easyMDE.toTextArea()
      this.easyMDE = null
    }
  }

  submitPreview(event) {
    const button = event.currentTarget
    const url = button.dataset.previewUrl
    const form = this.element.querySelector('form') || button.closest('form')
    const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

    const previewForm = document.createElement('form')
    previewForm.method = 'post'
    previewForm.action = url
    previewForm.target = '_blank'
    previewForm.style.display = 'none'

    const tokenInput = document.createElement('input')
    tokenInput.type = 'hidden'
    tokenInput.name = 'authenticity_token'
    tokenInput.value = token
    previewForm.appendChild(tokenInput)

    const title = form.querySelector('[name="item[title]"]')
    const body = form.querySelector('[name="item[body]"]')
    const aciId = form.querySelector('[name="item[advent_calendar_item_id]"]')
    ;[title, body, aciId].forEach(function(field) {
      if (field) {
        const input = document.createElement('input')
        input.type = 'hidden'
        input.name = field.name
        input.value = field.value
        previewForm.appendChild(input)
      }
    })

    document.body.appendChild(previewForm)
    previewForm.submit()
    document.body.removeChild(previewForm)
  }

  _uploadImage(file, onSuccess, onError, uploadPath, uploadErrorMsg, networkErrorMsg) {
    const formData = new FormData()
    formData.append('attachment[image]', file)
    const aciField = this.element.querySelector('[name="item[advent_calendar_item_id]"]')
    if (aciField) {
      formData.append('attachment[advent_calendar_item_id]', aciField.value)
    }
    const csrfMeta = document.querySelector('meta[name="csrf-token"]')
    fetch(uploadPath, {
      method: 'POST',
      headers: { 'X-CSRF-Token': csrfMeta ? csrfMeta.content : '' },
      body: formData
    })
      .then(function(r) { if (!r.ok) { throw new Error('HTTP ' + r.status) } return r.json() })
      .then(function(data) {
        if (data.image_url) {
          onSuccess(data.image_url)
        } else {
          onError(data.image_name || uploadErrorMsg)
        }
      })
      .catch(function() { onError(networkErrorMsg) })
  }
}
