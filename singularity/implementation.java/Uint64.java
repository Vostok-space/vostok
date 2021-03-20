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

public final class Uint64 {

private static final int Size = 8;
private static final long IntMul = 0x80000000L, HighBit = 1L << (Size * 8 - 1);

public final static byte[] min = new byte[Size];
public final static byte[] max = new byte[Size];

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

/* v = high * (INTEGER_MAX + 1) + low  */
public static void FromInt(byte[] v, int high, int low) {
	O7.asrt((0 <= low) && (0 <= high));
	fromlong(v, high * IntMul + low);
}

public static int ToInt(byte []v) {
	O7.asrt((v[7] == 0) && (v[6] == 0) && (v[5] == 0) && (v[4] == 0) && (v[3] >= 0));
	return (0xFF & v[0]) | ((0xFF & v[1]) << 8) | ((0xFF & v[2]) << 16) | (v[3] << 24);
}

public static void Add(byte[] sum, byte[] a1, byte[] a2) {
	int i, r;

	r = 0;
	for (i = 0; i < Size; ++i) {
		r = (0xFF & a1[i]) + (0xFF & a2[i]) + r / 0x100;
		sum[i] = (byte)r;
	}
	O7.asrt(r < 0x100);
}

public static void Sub(byte[] diff, byte[] m, byte[] s) {
	int i, r;

	r = 0;
	for (i = 0; i < Size; i += 1) {
		r = (0xFF & m[i]) - (0xFF & s[i]) + r / 0x100;
		diff[i] = (byte)r;
	}
	O7.asrt(r > -0x100);
}

public static void Mul(byte[] prod, byte[] m1, byte[] m2) {
	/* TODO */
	fromlong(prod, tolong(m1) * tolong(m2));
}

public static long div(long n, long d) {
	long r, rem;
	if (d < 0) {
		if ((n ^ HighBit) < (d ^ HighBit)) {
			r = 0;
		} else {
			r = 1;
		}
	} else if (n >= 0) {
		r = n / d;
	} else {
		r = ((n >>> 1) / d) * 2;
		rem = n - r * d;
		if ((rem ^ HighBit) >= d) {
			r += 1;
		}
	}
	return r;
}

public static void Div(byte[] dv, byte[] n, byte[] d) {
	fromlong(dv, div(tolong(n), tolong(d)));
}

public static void Mod(byte []mod, byte []n, byte []d) {
	long nl, dl;
	nl = tolong(n);
	dl = tolong(d);
	/* TODO */
	fromlong(mod, nl - div(nl, dl) * dl);
}

public static void DivMod(byte[] dv, byte[] mod, byte[] n, byte[] d) {
	long nl, dl, dvl;
	nl = tolong(n);
	dl = tolong(d);
	dvl = div(nl, dl);
	/* TODO */
	fromlong(dv, dvl);
	fromlong(mod, nl - dvl * dl);
}

public static int cmp(long l, long r) {
	int cmp;
	if ((l ^ HighBit) < (r ^ HighBit)) {
		cmp = -1;
	} else if (l != r) {
		cmp = 1;
	} else {
		cmp = 0;
	}
	return cmp;
}

public static int Cmp(byte[] l, byte[] r) {
	int i, cmp;

	i = Size - 1;
	while ((0 < i) && (l[i] == r[i])) {
		i -= 1;
	}
	if ((0xFF & l[i]) < (0xFF & r[i])) {
		cmp = -1;
	} else if (l[i] != r[i]) {
		cmp = 1;
	} else {
		cmp = 0;
	}
	return cmp;
}

static {
	for (int i = 0; i < Size; i += 1) {
		min[i] = 0;
		max[i] = -1;
	}
}

}
