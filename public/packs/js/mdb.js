"use strict";
(self["webpackChunkradvent"] = self["webpackChunkradvent"] || []).push([["mdb"],{

/***/ "./app/javascript/packs/mdb.js":
/*!*************************************!*\
  !*** ./app/javascript/packs/mdb.js ***!
  \*************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
/* harmony import */ var mdb_ui_kit_js_mdb_min_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! mdb-ui-kit/js/mdb.min.js */ "./node_modules/mdb-ui-kit/js/mdb.min.js");
/* harmony import */ var mdb_ui_kit_js_mdb_min_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(mdb_ui_kit_js_mdb_min_js__WEBPACK_IMPORTED_MODULE_0__);


// Function to refresh input element style when necessary
var mdbInputUpdate = function mdbInputUpdate() {
  document.querySelectorAll('.form-outline').forEach(function (formOutline) {
    new mdb_ui_kit_js_mdb_min_js__WEBPACK_IMPORTED_MODULE_0__.Input(formOutline).init();
  });
  document.querySelectorAll('.form-outline').forEach(function (formOutline) {
    new mdb_ui_kit_js_mdb_min_js__WEBPACK_IMPORTED_MODULE_0__.Input(formOutline).update();
  });
};
document.addEventListener('turbolinks:load', function () {
  mdbInputUpdate();
});
document.addEventListener('turbolinks:render', function () {
  mdbInputUpdate();
});

/***/ })

},
/******/ function(__webpack_require__) { // webpackRuntimeModules
/******/ var __webpack_exec__ = function(moduleId) { return __webpack_require__(__webpack_require__.s = moduleId); }
/******/ __webpack_require__.O(0, ["vendors-node_modules_mdb-ui-kit_js_mdb_min_js"], function() { return __webpack_exec__("./app/javascript/packs/mdb.js"); });
/******/ var __webpack_exports__ = __webpack_require__.O();
/******/ }
]);
//# sourceMappingURL=mdb.js.map