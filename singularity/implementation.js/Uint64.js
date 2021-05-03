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
o7.export.Uint64 = module;

var getjsa, assert;

var Size, Sizen, Max, IntMax, min, max;

getjsa = o7.getjsa;
assert = o7.assert;

Size = 8;
Sizen = BigInt(Size);
Max = (1n << (Sizen * 8n)) - 1n;
IntMax = 0x7FFFFFFF;

var min = o7.array(Size);
module.min = min;
var max = o7.array(Size);
module.max = max;

function bigToInt(bi) {
	if (bi >= 0x080000000n) {
		bi -= 0x100000000n;
	}
	return Number(bi);
}

function frombig(v, i) {
	var l, h;

	assert(0n <= i && i < 0x10000000000000000n);

	v = getjsa(v);

	h = Number(i / 0x100000000n);
	l = Number(i % 0x100000000n);
	v[0] = l % 0x100;
	l = l / 0x100 | 0;
	v[1] = l & 0xFF;
	v[2] = (l >> 8) & 0xFF;
	v[3] = (l >> 16) & 0xFF;

	v[4] = h % 0x100;
	h = h / 0x100 | 0;
	v[5] = h & 0xFF;
	v[6] = (h >> 8) & 0xFF;
	v[7] = (h >> 16) & 0xFF;
}

function tobig(v) {
	v = getjsa(v);
	return BigInt(v[0] + (v[1] | (v[2] << 8) | (v[3] << 16)) * 0x100)
	     + BigInt(v[4] + (v[5] | (v[6] << 8) | (v[7] << 16)) * 0x100) * 0x100000000n;
}

function FromInt(v, high, low) {
	assert((0 <= low) && (0 <= high));

	frombig(v, BigInt(IntMax + 1) * BigInt(high) + BigInt(low));
}
module.FromInt = FromInt;

function ToInt(v) {
	var i;

	v = getjsa(v);

	assert(v[3] < 0x80
	    && v[4] == 0
	    && v[5] == 0
	    && v[6] == 0
	    && v[7] == 0);
	i = v[0] | (v[1] << 8) | (v[2] << 16) | (v[3] << 24);
	assert(i >= 0);
	return i;
}
module.ToInt = ToInt;

function Add(sum, a1, a2) {
	frombig(sum, tobig(a1) + tobig(a2));
}
module.Add = Add;

function Sub(diff, m, s) {
	frombig(diff, tobig(m) - tobig(s));
}
module.Sub = Sub;

function Mul(prod, m1, m2) {
	frombig(prod, tobig(m1) * tobig(m2));
}
module.Mul = Mul;

function Div(div, n, d) {
	frombig(div, tobig(n) / tobig(d));
}
module.Div = Div;

function Mod(mod, n, d) {
	frombig(div, tobig(n) % tobig(d));
}
module.Mod = Mod;

function DivMod(div, mod, n, d) {
	n = tobig(n);
	d = tobig(d);
	frombig(div, n / d);
	frombig(mod, n % d);
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
		cmp = -1;
	} else if (l[i] > r[i]) {
		cmp = +1;
	} else {
		cmp = 0;
	}
	return cmp;
}
module.Cmp = Cmp;

function Init() {
	var i, mi, ma;

	mi = getjsa(min);
	ma = getjsa(max);
	for (i = Size - 1; i > 0; i -= 1) {
		mi[i] = 0;
		ma[i] = 0xFF;
	}
}

Init();

return module;
})();

