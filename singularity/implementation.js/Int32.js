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
o7.export.Int32 = module;

var getjsa, assert;

var Size, Min, Max, min, max;

getjsa = o7.getjsa;
assert = o7.assert;

Size = 4;

Min = (1 << (Size * 8 - 2)) * -2;
Max = -1 - Min;

/* TODO */
min = o7.sarray(Size);
module.min = min;
max = o7.sarray(Size);
module.max = max;

function FromInt(v, i) {
	v = getjsa(v);
	v[0] = i & 0xFF;
	v[1] = (i >> 8) & 0xFF;
	v[2] = (i >> 16) & 0xFF;
	v[3] = (i >> 24) & 0xFF;
}
module.FromInt = FromInt;

function fromint(v, i) {
	assert(Min <= i && i <= Max);
	FromInt(v, i);
}

function toint(v) {
	v = getjsa(v);
	return v[0] | (v[1] << 8) | (v[2] << 16) | (v[3] << 24);
}

function ToInt(v) {
	var i;
	i = toint(v);
	assert(i != Min);
	return i;
}
module.ToInt = ToInt;

function Add(sum, a1, a2) {
	fromint(sum, toint(a1) + toint(a2));
}
module.Add = Add;

function Sub(diff, m, s) {
	fromint(diff, toint(m) - toint(s));
}
module.Sub = Sub;

function Mul(prod, m1, m2) {
	fromint(prod, toint(m1) * toint(m2));
}
module.Mul = Mul;

function Div(div, n, d) {
	fromint(div, toint(n) / toint(d) |0);
}
module.Div = Div;

function Mod(mod, n, d) {
	fromint(mod, toint(n) % toint(d));
}
module.Mod = Mod;

function DivMod(div, mod, n, d) {
	n = toint(n);
	d = toint(d);
	FromInt(div, n / d |0);
	FromInt(mod, n % d);
}
module.DivMod = DivMod;

function Cmp(l, r) {
	var c;
	l = toint(l);
	r = toint(r);
	if (l < r) {
		c = -1;
	} else if (l > r) {
		c = 1;
	} else {
		c = 0;
	}
	return c;
}
module.Cmp = Cmp;

function init() {
	fromint(min, Min);
	fromint(max, Max);
}

init();

return module;
})();

