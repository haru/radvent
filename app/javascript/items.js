import $ from 'jquery'
import { marked } from 'marked'
import * as mdb from 'mdb-ui-kit/js/mdb.es.min.js';
import EasyMDE from 'easymde';
import DOMPurify from 'dompurify';
window.relative_url_root_path = '/';

export const setRootPath = path => window.relative_url_root_path = path;

let easyMDEInstance = null;

const uploadImageToServer = function(file, onSuccess, onError) {
  const formData = new FormData();
  formData.append('attachment[image]', file);
  const aciField = document.querySelector('[name="item[advent_calendar_item_id]"]');
  if (aciField) {
    formData.append('attachment[advent_calendar_item_id]', aciField.value);
  }
  const csrfMeta = document.querySelector('meta[name="csrf-token"]');
  fetch(window.relative_url_root_path + 'attachments', {
    method: 'POST',
    headers: { 'X-CSRF-Token': csrfMeta ? csrfMeta.content : '' },
    body: formData
  })
    .then(function(r) { return r.json(); })
    .then(function(data) {
      if (data.image_url) {
        onSuccess(data.image_url);
      } else {
        onError(data.image_name || 'アップロードに失敗しました');
      }
    })
    .catch(function() { onError('ネットワークエラーが発生しました'); });
};

const initEditor = function() {
  const el = document.getElementById('item-text');
  if (!el) { return; }
  if (easyMDEInstance) {
    easyMDEInstance.toTextArea();
    easyMDEInstance = null;
  }
  easyMDEInstance = new EasyMDE({
    element: el,
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
        return DOMPurify.sanitize(renderedHTML);
      }
    },
    uploadImage: true,
    imageUploadFunction: uploadImageToServer
  });
};

const ready = function() {
  const parseBody = function() {
    $('#item-show').html(marked(text));
    $('#item-show').find('pre code').each((i, block) => hljs.highlightBlock(block));
    return $('.comment-content').each(function(i, block) {
      const comment = $(block).text();
      return $(block).html(marked(comment));
    });
  };
  if ($('#item-show')[0]) { parseBody(); }
  initEditor();
};

// Submit preview in a new tab using a dedicated form with a valid CSRF token.
// The main form's token is bound to its original action (create/update) via
// Rails per-form CSRF tokens, so using formaction causes a token mismatch.
const submitPreview = function(button) {
  const url = button.getAttribute('data-preview-url');
  const form = button.closest('form');
  const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

  const previewForm = document.createElement('form');
  previewForm.method = 'post';
  previewForm.action = url;
  previewForm.target = '_blank';
  previewForm.style.display = 'none';

  const tokenInput = document.createElement('input');
  tokenInput.type = 'hidden';
  tokenInput.name = 'authenticity_token';
  tokenInput.value = token;
  previewForm.appendChild(tokenInput);

  // Copy item fields
  const title = form.querySelector('[name="item[title]"]');
  const body = form.querySelector('[name="item[body]"]');
  const aciId = form.querySelector('[name="item[advent_calendar_item_id]"]');
  [title, body, aciId].forEach(function(field) {
    if (field) {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = field.name;
      input.value = field.value;
      previewForm.appendChild(input);
    }
  });

  document.body.appendChild(previewForm);
  previewForm.submit();
  document.body.removeChild(previewForm);
};

$(document).ready(ready);
$(document).on('turbo:render', ready);
$(document).on('click', '#preview-button', function() { submitPreview(this); });


var setPopOver = function() {
  var popoverTriggerList = $('[data-mdb-toggle="popover"]');
  popoverTriggerList.each(function (i, popoverTriggerEl) {
    if (!mdb.Popover.getInstance(popoverTriggerEl)) {
      new mdb.Popover(popoverTriggerEl);
    }
  });
};
$(document).on('turbo:load', setPopOver);
document.addEventListener('turbo:before-stream-render', function(event) {
  var originalRender = event.detail.render;
  event.detail.render = function(streamElement) {
    originalRender(streamElement);
    setPopOver();
  };
});
