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

public final class OsEnv {

public static final int MaxLen = 4096;

private static java.lang.String get(byte []name) {
	java.lang.String v;
	try {
		v = java.lang.System.getenv(O7.string(name));
	} catch (java.lang.SecurityException e) {
		v = null;
	}
	return v;
}

public static boolean Exist(byte []name) {
	return null != get(name);
}

public static boolean Get(byte []val, int []ofs, int ofs_ai, byte []name) {
	O7.asrt((0 <= ofs[ofs_ai]) && (ofs[ofs_ai] < val.length - 1));

	final java.lang.String v;
	byte[] b;
	int i;

	v = get(name);
	i = ofs[ofs_ai];
	val[i] = 0;
	if (v != null) {
		b = O7.bytes(v);
		if (i + b.length <= val.length) {
			java.lang.System.arraycopy(b, 0, val, i, b.length);
			/* TODO */
			i += b.length;
			if (i < val.length) {
				val[i] = 0;
			}
			ofs[ofs_ai] = i;
		} else {
			b = null;
		}
	} else {
		b = null;
	}
	return b != null;
}

}
