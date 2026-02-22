import $ from "jquery"
window.$ = $
window.jQuery = $

import * as mdb from 'mdb-ui-kit'
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
