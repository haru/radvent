/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const ready = () => $('body').bootstrapMaterialDesign();

$(document).ready(ready);
$(document).on('turbolinks:load', ready);