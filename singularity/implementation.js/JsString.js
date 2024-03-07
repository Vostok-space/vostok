/* Wrapper for JavaScript String
 *
 * Copyright 2023 ComdivByZero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

(function() { 'use strict';

var module = {};
o7.export.JsString = module;

function T(str) {
  if (str !== undefined) {
    this._s = str;
  } else {
    this._s = NaN;
  }
}
T.prototype.assign = function(r) {
  this._s = r._s;
}
module.T = T;

function CharzByOfs(src, ofs) {
  var str, s;
  o7.assert((0 <= ofs) && (ofs < src.length));
  s = o7.utf8ByOfsToStr(src, ofs);
  if (s != null) {
    str = new T(s);
  } else {
    str = null;
  }
  return str;
}
module.CharzByOfs = CharzByOfs;

function Charz(src) {
  return CharzByOfs(src, 0);
}
module.Charz = Charz;

function ToCharz(src, dest, ofs, ofs_i) {
  var o, n;
  o = ofs[ofs_i];
  o7.assert((0 <= o) && (o < dest.length));

  src = o7.toUtf8(src._s);
  n = dest.length - o;
  if (n > src.length) {
    n = src.length;
  }
  o7.memcpy(dest, o, src, 0, n - 1);
  dest[n - 1] = 0;
  ofs[ofs_i] = o + n - 1;
  return n == src.length;
}
module.ToCharz = ToCharz;

return module;
})();

