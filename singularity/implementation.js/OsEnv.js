/* Copyright 2022 ComdivByZero
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
o7.export.OsEnv = module;

var getenv;

module.MaxLen = 4096;

function Exist(name) {
    return env[name] != undefined;
}
module.Exist = Exist;

function Get(val, ofs, ofs_i, name) {
    var ok, e, i, j;

    i = ofs.at(ofs_i);
    o7.assert((0 <= i) && (i < val.length - 1));

    e = getenv(o7.utf8ToStr(name));
    ok = e != undefined;
    if (ok) {
        e = o7.toUtf8(e);
        ok = e.length <= val.length - i;
        if (ok) {
            for (j = 0; j < e.length; j += 1) {
                val[i] = e[j];
                i += 1;
            }
        }
    }
    return ok;
}
module.Get = Get;


     if (typeof process !== 'undefined') { getenv = function(str) { return process.env[str]; } }
else if (typeof std     !== 'undefined') { getenv = std.getenv; }
else                                     { getenv = function(str) { return undefined; } }

return module;
})();

