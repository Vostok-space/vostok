/* Copyright 2021 ComdivByZero
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
o7.export.Uint32 = module;

var getjsa, assert;

var Size, Max, IntMax, min, max;

getjsa = o7.getjsa;
assert = o7.assert;

Size = 4;
Max = 0xFFFFFFFF;
IntMax = 0x7FFFFFFF;

min = o7.sarray(Size);
module.min = min;
max = o7.sarray(Size);
module.max = max;

function fromint(v, i) {
	v = getjsa(v);
	v[0] = i & 0xFF;
	v[1] = (i >> 8) & 0xFF;
	v[2] = (i >> 16) & 0xFF;
	v[3] = i >> 24;
}

function fromnum(v, i) {
	v = getjsa(v);
	v[0] = i % 0x100;
	i = i / 0x100 | 0;
	v[1] = i & 0xFF;
	v[2] = (i >> 8) & 0xFF;
	v[3] = i >> 16;
}

function toint(v) {
	v = getjsa(v);
	return v[0] | (v[1] << 8) | (v[2] << 16) | (v[3] << 24);
}

function tonum(v) {
	var n;

	n = toint(v);
	if (v < 0) {
		n += Max + 1;
	}
	return n;
}

function FromInt(v, i) {
	assert(0 <= i);
	fromint(v, i);
}
module.FromInt = FromInt;

function ToInt(v) {
	var i;
	i = toint(v);
	assert(i >= 0);
	return i;
}
module.ToInt = ToInt;

function Add(sum, a1, a2) {
	var s;

	s = tonum(a1) + tonum(a2);
	assert(s <= Max);
	fromnum(sum, s);
}
module.Add = Add;

function Sub(diff, m, s) {
	var d;

	d = tonum(m) - tonum(s);
	assert(d >= 0);
	fromnum(diff, d);
}
module.Sub = Sub;

function Mul(prod, m1, m2) {
	var p;
	p = tonum(m1) * tonum(m2);
	assert(p <= Max);
	fromnum(prod, p);
}
module.Mul = Mul;

function Div(div, n, d) {
	d = tonum(d);
	assert(d > 0);
	fromnum(div, tonum(n) / d |0);
}
module.Div = Div;

function Mod(mod, n, d) {
	d = tonum(d);
	assert(d > 0);
	fromnum(mod, tonum(n) % d);
}
module.Mod = Mod;

function DivMod(div, mod, n, d) {
	d = tonum(d);
	assert(d > 0);
	fromnum(div, tonum(n) / d |0);
	fromnum(mod, tonum(n) % d);
}
module.DivMod = DivMod;

function Cmp(l, r) {
	var i, cmp;

	l = getjsa(l);
	r = getjsa(r);
	i = Size - 1;
	while ((0 < i) && (l[i] == r[i])) {
		i -= 1;
	}
	if (l[i] < r[i]) {
		cmp =  - 1;
	} else if (l[i] > r[i]) {
		cmp = 1;
	} else {
		cmp = 0;
	}
	return cmp;
}
module.Cmp = Cmp;

function init() {
	tonum(min, 0);
	tonum(max, Max);
}

init();

return module;
})();

