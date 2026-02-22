import $ from 'jquery'
import DataTable from 'datatables.net-bs5';

var ready = function() {
    new DataTable('#events', {
        paging: true
    });
}
$(document).on('turbo:load', ready);
