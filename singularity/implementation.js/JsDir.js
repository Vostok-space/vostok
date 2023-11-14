/* Copyright 2023 ComdivByZero
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
var String = o7.import.JsString,
    Mode   = o7.import.PosixFileMode;

var module = {supported: true};
o7.export.JsDir = module;

var X = Mode.X;
module.X = X;
var R = Mode.R;
module.R = R;
var W = Mode.W;
module.W = W;

var O = Mode.O;
module.O = O;
var G = Mode.G;
module.G = G;
var U = Mode.U;
module.U = U;

function T(d) {
  if (d !== undefined) {
    this._d = d;
  } else {
    this._d = NaN;
  }
}
T.prototype.assign = function(r) {
  this._d = r._d;
}
module.T = T;
function Ent(e) {
  if (e !== undefined) {
    this._e = e;
  } else {
    this._e = NaN;
  }
}
Ent.prototype.assign = function(r) {
  this._e = r._e;
}
module.Ent = Ent;

var fs;
fs = {opendirSync: function() {return null; },
      mkdirSync  : function() {return false;}};
if (typeof require !== 'undefined') {
  try { fs = require('fs'); } catch {}
}

function Open(path) {
  var dir;
  try {
    dir = new T(fs.opendirSync(path));
  } catch {
    dir = null;
  }
  return dir;
}
module.Open = Open;

function OpenByCharz(path, ofs) {
  var p, d;

  o7.assert(path[0] != 0x00);
  p = o7.utf8ByOfsToStr(path, ofs);
  if (p != null) {
    d = Open(p);
  } else {
    d = null;
  }
  return d;
}
module.OpenByCharz = OpenByCharz;

function Close(dir, dir_i) {
  var d;
  d = dir.at(dir_i);
  dir[dir_i] = null;
  d._d.close();
  d._d = null;
  return true;
}
module.Close = Close;

function Read(dir) {
  var e, ent;
  e = dir._d.readSync();
  if (e == null) {
    ent = null;
  } else {
    ent = new Ent(e);
  }
  return ent;
}
module.Read = Read;

function GetName(ent) {
  return new String.T(ent._e.name);
}
module.GetName = GetName;

function CopyName(str, ofs, ofs_i, ent) {
  return String.ToCharz(GetName(ent), str, ofs, ofs_i);
}
module.CopyName = CopyName;

function Mkdir(path, mode) {
  var ok;
  o7.assert(path != null);
  try {
    fs.mkdirSync(path._s, { mode: Mode.Hex(mode) });
    ok = true;
  } catch {
    ok = false;
  }
  return ok;
}
module.MkDir = Mkdir;

function MkdirByCharz(path, ofs, mode) {
  path = String.Charz(path, ofs);
  return (path != null) && Mkdir(path, mode);
}
module.MkdirByCharz = MkdirByCharz;

return module;
})();

