// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import * as mdb from 'mdb-ui-kit';
//import { Input } from 'mdb-ui-kit';
import './mdb'
import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"
import '@fortawesome/fontawesome-free/js/all';
import 'marked'
import './items';
import './events';
import './users';
import '../stylesheets/application'


Rails.start()
Turbolinks.start()
ActiveStorage.start()

