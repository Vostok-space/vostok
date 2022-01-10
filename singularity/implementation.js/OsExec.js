/* Copyright 2019,2021-2022 ComdivByZero
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

var child_process, fs;

var module = {};
o7.export.OsExec = module;

var Ok = 0;
module.Ok = Ok;

if (typeof require !== 'undefined') {
	child_process = require("child_process");
	fs = require('fs');
} else {
	child_process = null;
	fs = null;
}

if (child_process != null) {
	module.Do = function(cmd) {
		var ret, out, errout;
		o7.assert((0xFF & cmd[0]) != 0x00);

		try {
			out = child_process.execSync(o7.utf8ToStr(cmd))
			errout = null;
			ret = Ok;
		} catch (err) {
			out = err.stdout;
			errout = err.stderr;
			ret = err.status;
		}
		if (fs != null) {
			if (out != null && out.length > 0) {
				fs.writeSync(process.stdout.fd, out);
			}
			if (errout != null && errout.length > 0) {
				fs.writeSync(process.stderr.fd, errout);
			}
		} else if (console != undefined) {
			if (out != null) {
				out = out.toString();
			} else {
				out = "";
			}
			if (errout != null) {
				out += errout.toString();
			}
			console.log(out);
		}
		return ret;
	}
} else if (typeof os !== 'undefined') {
	module.Do = function(cmd) {
		o7.assert((0xFF & cmd[0]) != 0x00);
		/* TODO */
		return os.exec(["bash", "-c", o7.utf8ToStr(cmd)]);
	}
} else {
	module.Do = function(cmd) { o7.assert((0xFF & cmd[0]) != 0x00); return -1; }
}

return module;
})();

