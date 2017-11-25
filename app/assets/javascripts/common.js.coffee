ready = ->
  $('body').bootstrapMaterialDesign();

$(document).ready ready
$(document).on 'turbolinks:load', ready