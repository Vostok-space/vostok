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

var module = {};
o7.export.JsEval = module;

function Code() {
	this.code = [];
	this.end = false;
}
Code.prototype.assign = function(r) {}
module.Code = Code;

module.supported = typeof Function !== 'undefined';

var lastResult, lastException, args;

function New(c, c_ai) {
	try {
		c[c_ai] = new Code();
	} catch (exc) {
		c[c_ai] = null;
	}
	return c[c_ai] != null;
}
module.New = New;

function Add(c, partCode) {
	var i, len;
	o7.assert(c != null);
	i = 0;
	len = partCode.length;
	while (i < len && partCode[i] != 0x00) {
		c.code.push(partCode[i]);
		i += 1;
	}
	/* TODO */
	return true;
}
module.Add = Add;
module.AddBytes = Add;

if (typeof process !== 'undefined') {
	args = process.argv;
} else if (typeof scriptArgs !== 'undefined') {
	args = scriptArgs;
} else {
	args = [" "];
}

function End(c, startCliArg) {
	var code;
	o7.assert(c != null);
	if (typeof start_cli_arg !== 'undefined') {
		startCliArg += start_cli_arg;
	}
	o7.assert(0 <= startCliArg && startCliArg <= args.length - 1);
	o7.assert(!c.end);
	c.end = true;
	code = o7.utf8ToStr(c.code);
	if (code != null) {
		c.text = "(function(start_cli_arg){" + code + "})(" + startCliArg + ");";
	}
	/* TODO */
	return code != null;
}
module.End = End;

function Run(code) {
	var ret;
	try {
		lastResult = eval(code);
		ret = true;
	} catch (exc) {
		console.log("exception "  + exc);
		lastException = exc;
		ret = false;
	}
	return ret;
}

function Do(c) {
	var ret;
	o7.assert(c != null);
	o7.assert(c.end);
	return Run(c.text);
}
module.Do = Do;

function DoStr(str) {
	o7.assert((0xFF & str[0]) != 0x00);
	return Run(o7.utf8ToStr(str));
}
module.DoStr = DoStr;

return module;
})();

