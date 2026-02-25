import $ from "jquery"
window.$ = $
window.jQuery = $

$.ajaxSetup({
  beforeSend(xhr) {
    const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    if (token) { xhr.setRequestHeader('X-CSRF-Token', token) }
  }
})

import * as mdb from 'mdb-ui-kit/js/mdb.es.min.js'
import './mdb'
import "@hotwired/turbo-rails"
import * as ActiveStorage from "@rails/activestorage"
import "./channels/consumer"
import '@fortawesome/fontawesome-free/js/all'
import 'marked'
import './items'
import './events'
import './users'

ActiveStorage.start()

// Bootstrap 4 compatibility: handle data-dismiss="alert" for devise-bootstrap-views gem
$(document).on('turbo:load', function() {
  $(document).on('click', '[data-dismiss="alert"]', function() {
    $(this).closest('.alert').remove()
  })
})
