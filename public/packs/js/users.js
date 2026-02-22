"use strict";
(self["webpackChunkradvent"] = self["webpackChunkradvent"] || []).push([["users"],{

/***/ "./app/javascript/packs/users.js":
/*!***************************************!*\
  !*** ./app/javascript/packs/users.js ***!
  \***************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
/* harmony import */ var datatables_net_bs5__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! datatables.net-bs5 */ "./node_modules/datatables.net-bs5/js/dataTables.bootstrap5.mjs");
/* provided dependency */ var $ = __webpack_require__(/*! jquery/src/jquery */ "./node_modules/jquery/src/jquery.js");
// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/


var ready = function ready() {
  new datatables_net_bs5__WEBPACK_IMPORTED_MODULE_0__["default"]('#users', {
    paging: true
  });
};
$(document).on('turbolinks:load', ready);

/***/ })

},
/******/ function(__webpack_require__) { // webpackRuntimeModules
/******/ var __webpack_exec__ = function(moduleId) { return __webpack_require__(__webpack_require__.s = moduleId); }
/******/ __webpack_require__.O(0, ["vendors-node_modules_jquery_src_jquery_js","vendors-node_modules_datatables_net-bs5_js_dataTables_bootstrap5_mjs"], function() { return __webpack_exec__("./app/javascript/packs/users.js"); });
/******/ var __webpack_exports__ = __webpack_require__.O();
/******/ }
]);
//# sourceMappingURL=users.js.map