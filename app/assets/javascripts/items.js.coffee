# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

window.relative_url_root_path = '/'

@setRootPath = (path) ->
  window.relative_url_root_path = path

@parseText = (text) ->
  # parsing markdown to html
  $('#item-preview-content').html(marked(text))
  # highlighting
  $('#item-preview-content').find('pre code').each (i, block) ->
    hljs.highlightBlock(block)

@checkTextChange = () ->
  old = v = $('#item-text').val()
  return ->
    v = $('#item-text').val()
    if old isnt v
      old = v
      parseText(v)

@attachmentImageInputChange = (e) ->
  e.preventDefault
  return if !this.files.length
  form_data = new FormData
  form_data.append $(this).attr('name'), $(this).prop('files')[0]
  form_data.append $('#attachment-advent-calendar-id').attr('name'),
    $('#attachment-advent-calendar-id').val()
  uploadFile(form_data)

@uploadFile = (form_data) ->
  $.ajax window.relative_url_root_path + 'attachments',
    type: 'POST',
    dataType: 'json',
    data: form_data,
    processData: false,
    contentType: false,
    success: (data) ->
      $(this).val('')
      $('#item-text').focus()
      sentence = $('#item-text').val()
      len      = sentence.length
      pos      = $('#item-text').get(0).selectionStart
      if pos == undefined
          pos = 0
    
      before   = sentence.substr(0, pos)
      after    = sentence.substr(pos, len)
      $('#item-text').val before +
        "\r\n![#{data.image_name}](#{data.image_url})" + after
      parseText $('#item-text').val()

$(document).on 'paste', '#item-text', (event) ->
  items = event.originalEvent.clipboardData.items
  i = 0
  while i < items.length
    item = items[i]
    if item.type.indexOf('image') != -1
      # 画像のみサーバへ送信する
      file = item.getAsFile()
      form_data = new FormData
      form_data.append $('#attachment-image-select').attr('name'), file
      form_data.append $('#attachment-advent-calendar-id').attr('name'),
        $('#attachment-advent-calendar-id').val()
      uploadFile(form_data)
    i++
  return

ready = ->
  parseBody = ->
    $('#item-show').html(marked(text))
    $('#item-show').find('pre code').each (i, block) ->
      hljs.highlightBlock(block)
    $('.comment-content').each (i, block) ->
      comment = $(block).text()
      $(block).html(marked(comment))
  parseBody() if $('#item-show')[0]
  parseText $('#item-text').val() if $('#item-text').val()

$(document).ready ready
$(document).on 'turbolinks:render', ready
$(document).on 'keyup', '#item-text', checkTextChange()
$(document).on 'change', '#attachment-image-select', attachmentImageInputChange
