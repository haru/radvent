"use strict";
(self["webpackChunkradvent"] = self["webpackChunkradvent"] || []).push([["items"],{

/***/ "./app/javascript/packs/items.js":
/*!***************************************!*\
  !*** ./app/javascript/packs/items.js ***!
  \***************************************/
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   setRootPath: function() { return /* binding */ setRootPath; }
/* harmony export */ });
/* harmony import */ var marked__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! marked */ "./node_modules/marked/lib/marked.js");
/* harmony import */ var marked__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(marked__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var mdb_ui_kit__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! mdb-ui-kit */ "./node_modules/mdb-ui-kit/js/mdb.min.js");
/* harmony import */ var mdb_ui_kit__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(mdb_ui_kit__WEBPACK_IMPORTED_MODULE_1__);
/* provided dependency */ var $ = __webpack_require__(/*! jquery/src/jquery */ "./node_modules/jquery/src/jquery.js");
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS208: Avoid top-level this
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://coffeescript.org/


window.relative_url_root_path = '/';
var setRootPath = function setRootPath(path) {
  return window.relative_url_root_path = path;
};
var parseText = function parseText(text) {
  // parsing markdown to html
  $('#item-preview-content').html(marked__WEBPACK_IMPORTED_MODULE_0___default()(text));
  // highlighting
  return $('#item-preview-content').find('pre code').each(function (i, block) {
    return hljs.highlightBlock(block);
  });
};
var checkTextChange = function checkTextChange() {
  var v;
  var old = v = $('#item-text').val();
  return function () {
    v = $('#item-text').val();
    if (old !== v) {
      old = v;
      return parseText(v);
    }
  };
};
var attachmentImageInputChange = function attachmentImageInputChange(e) {
  e.preventDefault;
  if (!this.files.length) {
    return;
  }
  var form_data = new FormData();
  form_data.append($(this).attr('name'), $(this).prop('files')[0]);
  form_data.append($('#attachment-advent-calendar-id').attr('name'), $('#attachment-advent-calendar-id').val());
  return uploadFile(form_data);
};
var uploadFile = function uploadFile(form_data) {
  return $.ajax(window.relative_url_root_path + 'attachments', {
    type: 'POST',
    dataType: 'json',
    data: form_data,
    processData: false,
    contentType: false,
    success: function success(data) {
      $(this).val('');
      $('#item-text').focus();
      var sentence = $('#item-text').val();
      var len = sentence.length;
      var pos = $('#item-text').get(0).selectionStart;
      if (pos === undefined) {
        pos = 0;
      }
      var before = sentence.substr(0, pos);
      var after = sentence.substr(pos, len);
      $('#item-text').val(before + "\r\n![".concat(data.image_name, "](").concat(data.image_url, ")") + after);
      return parseText($('#item-text').val());
    }
  });
};
$(document).on('paste', '#item-text', function (event) {
  var items = event.originalEvent.clipboardData.items;
  var i = 0;
  while (i < items.length) {
    var item = items[i];
    if (item.type.indexOf('image') !== -1) {
      // 画像のみサーバへ送信する
      var file = item.getAsFile();
      var form_data = new FormData();
      form_data.append($('#attachment-image-select').attr('name'), file);
      form_data.append($('#attachment-advent-calendar-id').attr('name'), $('#attachment-advent-calendar-id').val());
      uploadFile(form_data);
    }
    i++;
  }
});
var ready = function ready() {
  var parseBody = function parseBody() {
    $('#item-show').html(marked__WEBPACK_IMPORTED_MODULE_0___default()(text));
    $('#item-show').find('pre code').each(function (i, block) {
      return hljs.highlightBlock(block);
    });
    return $('.comment-content').each(function (i, block) {
      var comment = $(block).text();
      return $(block).html(marked__WEBPACK_IMPORTED_MODULE_0___default()(comment));
    });
  };
  if ($('#item-show')[0]) {
    parseBody();
  }
  if ($('#item-text').val()) {
    return parseText($('#item-text').val());
  }
};
$(document).ready(ready);
$(document).on('turbolinks:render', ready);
$(document).on('keyup', '#item-text', checkTextChange());
$(document).on('change', '#attachment-image-select', attachmentImageInputChange);
var setPopOver = function setPopOver() {
  var popoverTriggerList = $('[data-mdb-toggle="popover"]');
  var popoverList = popoverTriggerList.each(function (i, popoverTriggerEl) {
    return new mdb_ui_kit__WEBPACK_IMPORTED_MODULE_1__.Popover(popoverTriggerEl);
  });
};
$(document).on('turbolinks:load', setPopOver);

/***/ })

},
/******/ function(__webpack_require__) { // webpackRuntimeModules
/******/ var __webpack_exec__ = function(moduleId) { return __webpack_require__(__webpack_require__.s = moduleId); }
/******/ __webpack_require__.O(0, ["vendors-node_modules_jquery_src_jquery_js","vendors-node_modules_mdb-ui-kit_js_mdb_min_js","vendors-node_modules_marked_lib_marked_js"], function() { return __webpack_exec__("./app/javascript/packs/items.js"); });
/******/ var __webpack_exports__ = __webpack_require__.O();
/******/ }
]);
//# sourceMappingURL=items.js.map