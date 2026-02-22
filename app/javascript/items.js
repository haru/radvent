import $ from 'jquery'
import { marked } from 'marked'
import * as mdb from 'mdb-ui-kit/js/mdb.es.min.js';
window.relative_url_root_path = '/';

export const setRootPath = path => window.relative_url_root_path = path;

const parseText = function(text) {
  // parsing markdown to html
  $('#item-preview-content').html(marked(text));
  // highlighting
  return $('#item-preview-content').find('pre code').each((i, block) => hljs.highlightBlock(block));
};

const checkTextChange = function() {
  let v;
  let old = (v = $('#item-text').val());
  return function() {
    v = $('#item-text').val();
    if (old !== v) {
      old = v;
      return parseText(v);
    }
  };
};

const attachmentImageInputChange = function(e) {
  e.preventDefault;
  if (!this.files.length) { return; }
  const form_data = new FormData;
  form_data.append($(this).attr('name'), $(this).prop('files')[0]);
  form_data.append($('#attachment-advent-calendar-id').attr('name'),
    $('#attachment-advent-calendar-id').val());
  return uploadFile(form_data);
};

const uploadFile = function(form_data) {
  return $.ajax(window.relative_url_root_path + 'attachments', {
    type: 'POST',
    dataType: 'json',
    data: form_data,
    processData: false,
    contentType: false,
    success(data) {
      $(this).val('');
      $('#item-text').focus();
      const sentence = $('#item-text').val();
      const len      = sentence.length;
      let pos      = $('#item-text').get(0).selectionStart;
      if (pos === undefined) {
          pos = 0;
        }

      const before   = sentence.substr(0, pos);
      const after    = sentence.substr(pos, len);
      $('#item-text').val(before +
        `\r\n![${data.image_name}](${data.image_url})` + after
      );
      return parseText($('#item-text').val());
    }
  }
  );
};

$(document).on('paste', '#item-text', function(event) {
  const {
    items
  } = event.originalEvent.clipboardData;
  let i = 0;
  while (i < items.length) {
    const item = items[i];
    if (item.type.indexOf('image') !== -1) {
      const file = item.getAsFile();
      const form_data = new FormData;
      form_data.append($('#attachment-image-select').attr('name'), file);
      form_data.append($('#attachment-advent-calendar-id').attr('name'),
        $('#attachment-advent-calendar-id').val());
      uploadFile(form_data);
    }
    i++;
  }
});

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
  if ($('#item-text').val()) { return parseText($('#item-text').val()); }
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
$(document).on('keyup', '#item-text', checkTextChange());
$(document).on('change', '#attachment-image-select', attachmentImageInputChange);
$(document).on('click', '#preview-button', function() { submitPreview(this); });


var setPopOver = function() {
  var popoverTriggerList = $('[data-mdb-toggle="popover"]');
  var popoverList = popoverTriggerList.each(function (i, popoverTriggerEl) {
    return new mdb.Popover(popoverTriggerEl);
  });
};
$(document).on('turbo:load', setPopOver);
