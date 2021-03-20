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
package o7;

import o7.O7;

public final class Int64 {

private static final int Size = 8, IntMin = 1 << 31, IntMax = -1 - IntMin;
private static final long IntMul = 1L << 31, Min = 1L << (Size * 8 - 1), Max = -1 - Min;

public static byte[] min = new byte[Size];
public static byte[] max = new byte[Size];

private static void fromlong(byte[] v, long l) {
	int i;

	i = (int)l;
	v[0] = (byte)(0xFF & i);
	v[1] = (byte)(0xFF & (i >> 8));
	v[2] = (byte)(0xFF & (i >> 16));
	v[3] = (byte)(0xFF & (i >> 24));

	i = (int)(l >>> 32);
	v[4] = (byte)(0xFF & i);
	v[5] = (byte)(0xFF & (i >> 8));
	v[6] = (byte)(0xFF & (i >> 16));
	v[7] = (byte)(0xFF & (i >> 24));
}

private static long tolong(byte[] v) {
	return (0xFF & v[0]) | ((0xFF & v[1]) << 8) | ((0xFF & v[2]) << 16) | ((0xFFL& v[3]) << 24)
	   | (((0xFF & v[4]) | ((0xFF & v[5]) << 8) | ((0xFF & v[6]) << 16) | ((0xFFL& v[7]) << 24)) << 32);
}

public static void FromInt(byte[] v, int high, int low) {
	fromlong(v, high * IntMul + low);
}

public static int ToInt(byte[] v) {
	long l;
	l = tolong(v);
	O7.asrt((IntMin < l) && (l <= IntMax));
	return (int)l;
}

public static void Add(byte[] sum, byte[] a1, byte[] a2) {
	/* TODO */
	fromlong(sum, tolong(a1) + tolong(a2));
}

public static void Sub(byte[] diff, byte[] m, byte[] s) {
	/* TODO */
	fromlong(diff, tolong(m) - tolong(s));
}

public static void Mul(byte[] prod, byte[] m1, byte[] m2) {
	/* TODO */
	fromlong(prod, tolong(m1) * tolong(m2));
}

public static void Div(byte[] div, byte[] n, byte[] d) {
	long nl, dl;
	nl = tolong(n);
	dl = tolong(d);
	O7.asrt(nl > Min || dl != -1);
	fromlong(div, nl / dl);
}

public static void Mod(byte[] mod, byte[] n, byte[] d) {
	long nl, dl;
	nl = tolong(n);
	dl = tolong(d);
	O7.asrt(nl > Min || dl != -1);
	fromlong(mod, nl % dl);
}

public static void DivMod(byte[] div, byte[] mod, byte[] n, byte[] d) {
	long nl, dl;
	nl = tolong(n);
	dl = tolong(d);
	O7.asrt(nl > Min || dl != -1);
	fromlong(div, nl / dl);
	fromlong(mod, nl % dl);
}

public static int Cmp(byte[] l, byte[] r) {
	int cmp, i, li, ri;
	i = Size - 1;
	while ((0 < i) && (l[i] == r[i])) {
		i -= 1;
	}
	li = (0xFF & l[i]) - (0x80 & l[Size - 1]) * 2;
	ri = (0xFF & r[i]) - (0x80 & r[Size - 1]) * 2;
	if (li < ri) {
		cmp = -1;
	} else if (li != ri) {
		cmp = 1;
	} else {
		cmp = 0;
	}
	return cmp;
}

static {
	fromlong(min, Min);
	fromlong(max, Max);
}

}
