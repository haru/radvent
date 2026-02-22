(self["webpackChunkradvent"] = self["webpackChunkradvent"] || []).push([["common"],{

/***/ "./app/javascript/packs/common.js":
/*!****************************************!*\
  !*** ./app/javascript/packs/common.js ***!
  \****************************************/
/***/ (function(__unused_webpack_module, __unused_webpack_exports, __webpack_require__) {

/* provided dependency */ var $ = __webpack_require__(/*! jquery/src/jquery */ "./node_modules/jquery/src/jquery.js");
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
var ready = function ready() {
  return $('body').bootstrapMaterialDesign();
};
$(document).ready(ready);
$(document).on('turbolinks:load', ready);

/***/ })

},
/******/ function(__webpack_require__) { // webpackRuntimeModules
/******/ var __webpack_exec__ = function(moduleId) { return __webpack_require__(__webpack_require__.s = moduleId); }
/******/ __webpack_require__.O(0, ["vendors-node_modules_jquery_src_jquery_js"], function() { return __webpack_exec__("./app/javascript/packs/common.js"); });
/******/ var __webpack_exports__ = __webpack_require__.O();
/******/ }
]);
//# sourceMappingURL=common.js.map