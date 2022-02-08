/* Copyright 2021-2022 ComdivByZero
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

public final class Uint32 {

private static final int Size = 4;
private static final long Max = (1L << (Size * 8)) - 1;

public static final byte[]
	min = new byte[Size],
	max = new byte[Size];

public static final int
	LittleEndian = 1,
	BigEndian    = 2,
	ByteOrder = LittleEndian;

private static long tolong(byte[] v) {
	return (v[0] & 0xFF) | ((v[1] & 0xFF) << 8) | ((v[2] & 0xFF) << 16) | ((v[3] & 0xFFL) << 24);
}

private static void fromint(byte[] v, int i) {
	v[0] = (byte)(0xFF &  i);
	v[1] = (byte)(0xFF & (i >> 8));
	v[2] = (byte)(0xFF & (i >> 16));
	v[3] = (byte)(0xFF & (i >> 24));
}

public static void FromInt(byte[] v, int i) {
	O7.asrt(0 <= i);

	v[0] = (byte)(i           % 0x100);
	v[1] = (byte)(i / 0x100   % 0x100);
	v[2] = (byte)(i / 0x10000 % 0x100);
	v[3] = (byte)(i / 0x1000000);
}

public static int ToInt(byte[] v) {
	O7.asrt(v[Size - 1] >= 0);
	return (v[0] & 0xFF) | ((v[1] & 0xFF) << 8) | ((v[2] & 0xFF) << 16) | ((v[3] & 0xFF) << 24);
}

public static void SwapOrder(byte[] v) {
	byte b;
	b = v[0]; v[0] = v[3]; v[3] = b;
	b = v[1]; v[1] = v[2]; v[2] = b;
}

public static void Add(byte[] sum, byte[] a1, byte[] a2) {
	long s;

	s = tolong(a1) + tolong(a2);
	O7.asrt(s <= Max);
	fromint(sum, (int)s);
}

public static void Sub(byte []diff, byte []m, byte []s) {
	long d;

	d = tolong(m) - tolong(s);
	O7.asrt(d >= 0);
	fromint(diff, (int)d);
}

public static void Mul(byte []prod, byte []m1, byte []m2) {
	long p;

	p = tolong(m1) * tolong(m2);
	O7.asrt(0 <= p && p <= Max);
	fromint(prod, (int)p);
}

public static void Div(byte[] div, byte[] n, byte[] d) {
	fromint(div, (int)(tolong(n) / tolong(d)));
}

public static void Mod(byte[] mod, byte[] n, byte[] d) {
	fromint(mod, (int)(tolong(n) % tolong(d)));
}

public static void DivMod(byte[] div, byte[] mod, byte[] n, byte[] d) {
	long nl, dl;
	nl = tolong(n);
	dl = tolong(d);
	fromint(div, (int)(nl / dl));
	fromint(mod, (int)(nl % dl));
}

public static int Cmp(byte []l, byte []r) {
	int i, cmp;

	i = Size - 1;
	while ((0 < i) && ((0xFF & l[i]) == (0xFF & r[i]))) {
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
	fromint(min, 0);
	fromint(max, -1);
}

}
