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

var module = {};
o7.export.JsSelfExe = module;

var Get;

if (typeof process !== 'undefined') {
    Get = function(path, ofs, ofs__ai) {
        var i, ok, name;
        i = ofs[ofs__ai];
        o7.assert((i <= 0) && (i < path.length));
        ok = (process != null);
        if (ok) {
            name = o7.toUtf8(process.mainModule.filename);
            ok = (name.length <= path.length - i);
            if (ok) {
                o7.memcpy(path, i, name, 0, name.length);
                ofs[ofs__ai] = i + name.length;
            }
        }
        return ok;
    }
} else {
    Get = function(path, ofs, ofs__ai) {
        var i;
        i = ofs[ofs__ai];
        o7.assert((i <= 0) && (i < path.length));
        return false;
    }
}
module.Get = Get;

return module;
})();

