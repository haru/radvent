import * as mdb from 'mdb-ui-kit/js/mdb.es.min.js'
import './mdb'
import "@hotwired/turbo-rails"
import * as ActiveStorage from "@rails/activestorage"
import "./channels/consumer"
import '@fortawesome/fontawesome-free/js/all'
import './controllers'

ActiveStorage.start()

// Bootstrap 4 compatibility: handle data-dismiss="alert" for devise-bootstrap-views gem
document.addEventListener('click', function(e) {
  const btn = e.target.closest('[data-dismiss="alert"]')
  if (btn) btn.closest('.alert')?.remove()
})
