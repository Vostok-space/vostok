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
var o7;
(function(o7) { 'use strict';

var module = {};
o7.export.CLI = module;

var MaxLen = 4096;
module.MaxLen = MaxLen;

var startCliArg;

function copy(str, ofs, ofs_ai, argi) {
	var arg, i, len, j, ok;

	str = o7.getjsa(str);
	ofs = o7.getjsa(ofs);

	j = ofs[ofs_ai];
	o7.assert((0 <= j) && (j < str.length));

	arg = o7.toUtf8(process.argv[argi]);
	arg = o7.getjsa(arg);
	len = arg.length - 1;
	ok = j < str.length - len;
	if (ok) {
		i = 0;
		while (i < len) {
			str[j] = arg[i];
			/* предотвращение попадания завершения посреди строки */
			if (str[j] == 0) {
				str[j] = 1;
			}
			i += 1;
			j += 1;
		}
		ofs[ofs_ai] = j;
	}
	str[j] = 0;
	return ok;
}

function GetName(str, ofs, ofs_ai) {
	return copy(str, ofs, ofs_ai, 1);
}
module.GetName = GetName;

function Get(str, ofs, ofs_ai, argi) {
	o7.assert((0 <= argi) && (argi < module.count));
	return copy(str, ofs, ofs_ai, argi + 2 + startCliArg);
}
module.Get = Get;

function SetExitCode(code) {
	o7.exit_code = code;
}
module.SetExitCode = SetExitCode;

if (typeof start_cli_arg !== 'undefined') {
	module.count = process.argv.length - 2 - start_cli_arg;
	startCliArg  = start_cli_arg;
} else {
	module.count = process.argv.length - 2;
	startCliArg  = 0;
}

return module;
})(o7 || (o7 = {}));

