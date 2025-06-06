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
o7.export.Int64 = module;

var assert;

var Size, Sizen, Min, Max, IntMul, IntMax, IntMin, min, max;

assert = o7.assert;

Size = 8;
Sizen = 8n;

Min = -(1n << (Sizen * 8n - 1n));
Max = -1n - Min;
IntMul = 1n << (Sizen / 2n * 8n - 1n);
IntMax = IntMul - 1n;
IntMin = -IntMul;
Mod = 1n << (Sizen * 8n);

min = o7.array(Size);
module.min = min;
max = o7.array(Size);
module.max = max;


function frombig(v, i) {
	var l, h;

	assert(Min <= i && i <= Max);

	if (i < 0) {
		i += Mod;
	}

	h = Number(i >> 32n);
	l = Number(i % (1n << 32n));
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
	var b;
	b =  BigInt(v[0] + (v[1] | (v[2] << 8) | (v[3] << 16)) * 0x100)
	  | (BigInt(v[4] + (v[5] | (v[6] << 8) | (v[7] << 16)) * 0x100) << 32n);
	if (b > Max) {
		b -= Mod;
	}
	return b;
}

function FromInt(v, high, low) {
	frombig(v, BigInt(high) * IntMul + BigInt(low));
}
module.FromInt = FromInt;

function ToInt(v) {
	var b;
	b = tobig(v);
	assert(IntMin <= b && b <= IntMax);
	return Number(b);
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
	frombig(mod, tobig(n) % tobig(d));
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
	var i, cmp, li, ri;

	i = Size - 1;
	while ((0 < i) && (l[i] == r[i])) {
		i -= 1;
	}
	li = l[i] - (l[Size - 1] >> 7 << 8);
	ri = r[i] - (r[Size - 1] >> 7 << 8);
	if (li < ri) {
		cmp = -1;
	} else if (li > ri) {
		cmp = +1;
	} else {
		cmp = 0;
	}
	return cmp;
}
module.Cmp = Cmp;


return module;
})();

