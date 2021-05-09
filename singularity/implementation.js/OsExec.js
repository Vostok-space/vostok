/* Copyright 2019,2021 ComdivByZero
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

var child_process;

var module = {};
o7.export.OsExec = module;

var Ok = 0;
module.Ok = Ok;

function Do(cmd) {
	var ret, out;
	o7.assert((0xFF & cmd[0]) != 0x00);

	if (child_process != null) {
		try {
			/*TODO*/
			out = child_process.execSync(o7.utf8ToStr(cmd));
			ret = Ok;
		} catch (err) {
			ret = err.status;
		}
		if (ret == Ok && out.length > 0) {
			console.log(out.toString());
		}
	} else {
		ret = -1;
	}
	return ret;
}
module.Do = Do;

if (typeof require !== 'undefined') {
	child_process = require("child_process");
} else {
	child_process = null;
}

return module;
})();

