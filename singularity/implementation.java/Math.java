/* Copyright 2018 ComdivByZero
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
package o7;

import o7.O7;

public final class Math {

public static final double pi = 3.14159265358979323846;
public static final double e  = 2.71828182845904523536;

public static double sqrt(double x) {
	return java.lang.Math.sqrt(x);
}

public static double power(double x, double base) {
	return java.lang.Math.pow(x, base);
}

public static double exp(double x) {
	return java.lang.Math.exp(x);
}

public static double ln(double x) {
	return java.lang.Math.log(x);
}

public static double log(double x, double base) {
	final double l;
	if (base == 10.0) {
		l = java.lang.Math.log10(x);
	} else if (x == e) {
		l = java.lang.Math.log(x);
	} else {
		l = java.lang.Math.log(x) / java.lang.Math.log(base);
	}
	return l;
}

public static double round(double x) {
	return java.lang.Math.rint(x);
}

public static double sin(double x) {
	return java.lang.Math.sin(x);
}

public static double cos(double x) {
	return java.lang.Math.cos(x);
}

public static double tan(double x) {
	return java.lang.Math.tan(x);
}

public static double arcsin(double x) {
	return java.lang.Math.asin(x);
}

public static double arccos(double x) {
	return java.lang.Math.acos(x);
}

public static double arctan(double x) {
	return java.lang.Math.atan(x);
}

public static double arctan2(double x, double y) {
	return java.lang.Math.atan2(x, y);
}

public static double sinh(double x) {
	return java.lang.Math.sinh(x);
}

public static double cosh(double x) {
	return java.lang.Math.cosh(x);
}

public static double tanh(double x) {
	return java.lang.Math.tanh(x);
}

public static double arcsinh(double x) {
	O7.asrt(false);
	return 0.0;
}

public static double arccosh(double x) {
	O7.asrt(false);
	return 0.0;
}

public static double arctanh(double x) {
	O7.asrt(false);
	return 0.0;
}

}
