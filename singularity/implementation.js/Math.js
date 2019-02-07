/* Copyright 2019 ComdivByZero
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
o7.export.Math = module;

module.pi = Math.PI;
module.e  = Math.E;

function sqrt(x) {
	/* TODO */
	return Math.sqrt(x);
}
module.sqrt = sqrt;

function power(x, base) {
	/* TODO */
	return Math.pow(x, base);
}
module.power = power;

function exp(x) {
	/* TODO */
	return Math.exp();
}
module.exp = exp;

function ln(x) {
	/* TODO */
	return Math.log(x);
}
module.ln = ln;

function log(x, base) {
	/* TODO */
	var d;
	if (base == 10) {
		d = Math.LN10;
	} else {
		d = Math.log(base);
	}
	return Math.log(x) / d;
}
module.log = log;

function round(x) {
	/* TODO */
	return Math.round(x);
}
module.round = round;

function sin(x) {
	/* TODO */
	return Math.sin(x);
}
module.sin = sin;

function cos(x) {
	/* TODO */
	return Math.cos(x);
}
module.cos = cos;

function tan(x) {
	/* TODO */
	return Math.tan(x);
}
module.tan = tan;

function arcsin(x) {
	/* TODO */
	return Math.asin(x);
}
module.arcsin = arcsin;

function arccos(x) {
	/* TODO */
	return Math.acos(x);
}
module.arccos = arccos;

function arctan(x) {
	/* TODO */
	return Math.atan(x);
}
module.arctan = arctan;

function arctan2(x, y) {
	/* TODO */
	return Math.atan2(x, y);
}
module.arctan2 = arctan2;

function sinh(x) {
	/* TODO */
	return Math.sinh(x);
}
module.sinh = sinh;

function cosh(x) {
	/* TODO */
	return Math.cosh(x);
}
module.cosh = cosh;

function tanh(x) {
	/* TODO */
	return Math.tanh(x);
}
module.tanh = tanh;

function arcsinh(x) {
	/* TODO */
	return Math.asinh(x);
}
module.arcsinh = arcsinh;

function arccosh(x) {
	/* TODO */
	return Math.acosh(x);
}
module.arccosh = arccosh;

function arctanh(x) {
	/* TODO */
	return Math.atanh(x);
}
module.arctanh = arctanh;

return module;
})(o7 || (o7 = {}));

