import * as mdb from "mdb-ui-kit/js/mdb.min.js"

// Function to refresh input element style when necessary
var mdbInputUpdate = function () {
  document.querySelectorAll('.form-outline').forEach((formOutline) => {
    new mdb.Input(formOutline).init();
  });
  document.querySelectorAll('.form-outline').forEach((formOutline) => {
    new mdb.Input(formOutline).update();
  });
}

document.addEventListener('turbolinks:load', () => {
  mdbInputUpdate();
});

document.addEventListener('turbolinks:render', () => {
  mdbInputUpdate();
});