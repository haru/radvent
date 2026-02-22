import * as mdb from "mdb-ui-kit/js/mdb.es.min.js"

// Function to refresh input element style when necessary
var mdbInputUpdate = function () {
  document.querySelectorAll('.form-outline').forEach((formOutline) => {
    new mdb.Input(formOutline).init();
  });
  document.querySelectorAll('.form-outline').forEach((formOutline) => {
    new mdb.Input(formOutline).update();
  });
}

document.addEventListener('turbo:load', () => {
  mdbInputUpdate();
});

document.addEventListener('turbo:render', () => {
  mdbInputUpdate();
});
