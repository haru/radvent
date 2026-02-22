import $ from 'jquery'
import DataTable from 'datatables.net-bs5';

var ready = function() {
    new DataTable('#users', {
        paging: true
    });
}
$(document).on('turbo:load', ready);
