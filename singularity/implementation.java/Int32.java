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

public final class Int32 {

private static final int Size = 4, Min = (1 << (Size * 8 - 1)), Max = -1 + Min;

public static final byte[]
	min = new byte[Size],
	max = new byte[Size];

public static final int
	LittleEndian = 1,
	BigEndian    = 2,
	ByteOrder = LittleEndian;

public static void FromInt(byte[] v, int i) {
	v[0] = (byte)i;
	v[1] = (byte)(i >> 8);
	v[2] = (byte)(i >> 16);
	v[3] = (byte)(i >> 24);
}

public static void fromint(byte[] v, long i) {
	O7.asrt(Min <= i && i <= Max);
	FromInt(v, (int)i);
}

public static int toint(byte[] v) {
	return (0xFF & v[0]) | ((0xFF & v[1]) << 8) | ((0xFF & v[2]) << 16) | (v[3] << 24);
}

public static int ToInt(byte[] v) {
	int i;
	i = toint(v);
	O7.asrt(i > Min);
	return i;
}

public static void SwapOrder(byte[] v) {
	byte b;
	b = v[0]; v[0] = v[3]; v[3] = b;
	b = v[1]; v[1] = v[2]; v[2] = b;
}

public static void Add(byte[] sum, byte[] a1, byte[] a2) {
	fromint(sum, (long)toint(a1) + toint(a2));
}

public static void Sub(byte[] diff, byte[] m, byte[] s) {
	fromint(diff, (long)toint(m) - toint(s));
}

public static void Mul(byte[] prod, byte[] m1, byte[] m2) {
	fromint(prod, (long)toint(m1) * toint(m2));
}

public static void Div(byte[] div, byte[] n, byte[] d) {
	int ni, di;
	ni = toint(n);
	di = toint(d);
	O7.asrt(ni > Min || di != -1);
	FromInt(div, ni / di);
}

public static void Mod(byte[] mod, byte[] n, byte[] d) {
	int ni, di;
	ni = toint(n);
	di = toint(d);
	O7.asrt(ni > Min || di != -1);
	FromInt(mod, ni % di);
}

public static void DivMod(byte[] div, byte[] mod, byte[] n, byte[] d) {
	int ni, di;
	ni = toint(n);
	di = toint(d);
	O7.asrt(ni > Min || di != -1);
	FromInt(div, ni / di);
	FromInt(mod, ni % di);
}

public static int Cmp(byte[] l, byte[] r) {
	int li, ri, cmp;
	li = toint(l);
	ri = toint(r);
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
	fromint(min, Min);
	fromint(max, Max);
}

}
