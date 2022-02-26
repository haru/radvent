// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/

import DataTable from 'datatables.net-bs5';


var ready = function() {
    new DataTable('#users', {
        paging: true
    });
}
$(document).on('turbolinks:load', ready);