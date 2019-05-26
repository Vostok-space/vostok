/* Copyright 2018-2019 ComdivByZero
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

public final class O7 {

public static abstract class ArgsReceiver {
    abstract protected void set(byte[][] args);
}

public static ArgsReceiver argsReceiver = null;

public static final byte BOOL_UNDEF   = (byte)0xFF;
public static final int  INT_UNDEF    = Integer.MIN_VALUE;
public static final long LONG_UNDEF   = Long.MIN_VALUE;
public static final long DOUBLE_UNDEF = 0x7FFF_FFFF_0000_0000L;

public static final java.nio.charset.Charset UTF_8
                  = java.nio.charset.Charset.forName("UTF-8");

static int      exitCode  = 0;
static byte[][] args      = new byte[][]{};

private static final java.util.HashMap<java.lang.String, byte[]> stringsCache
                   = new java.util.HashMap<>();

public static void exit() {
    if (0 != exitCode) {
        java.lang.System.exit(exitCode);
    }
}

public static void asrt(final boolean c) {
    if (!c) {
        throw new java.lang.AssertionError();
    }
}

public static void asrt(final boolean c, final String msg) {
    if (!c) {
        throw new java.lang.AssertionError(msg);
    }
}

public static void caseFail(final int c) {
    throw new java.lang.AssertionError("case fail: " + c);
}

public static boolean inited(final byte b) {
    if (b == BOOL_UNDEF) {
        throw new java.lang.AssertionError("boolean variable is not initialized");
    }
    return b != 0;
}

public static int inited(final int i) {
    if (i == INT_UNDEF) {
        throw new java.lang.AssertionError("int variable is not initialized");
    }
    return i;
}

public static long inited(final long i) {
    if (i == LONG_UNDEF) {
        throw new java.lang.AssertionError("long variable is not initialized");
    }
    return i;
}

public static double inited(final double d) {
    if (Double.doubleToRawLongBits(d) == DOUBLE_UNDEF) {
        throw new java.lang.AssertionError("double variable is not initialized");
    }
    return d;
}

public static int ord(final boolean b) {
    final int i;
    if (b) {
        i = 1;
    } else {
        i = 0;
    }
    return i;
}

/* BOOLEAN to integer */
public static int ord(final byte b) {
    inited(b);
    return b;
}

/* SET to integer */
public static int ord(final int i) {
    if (i < 0) {
        throw new java.lang.ArithmeticException("31 is not accepted in SET, when it converted to int");
    }
    return i;
}

public static byte toByte(final int i) {
    if (i < 0 || 0x100 <= i) {
        throw new java.lang.ArithmeticException("int value " + i + " out of byte range");
    }
    return (byte)i;
}

public static byte toByte(final long i) {
    if (i < 0 || 0x100 <= i) {
        throw new java.lang.ArithmeticException("long value " + i + " out of byte range");
    }
    return (byte)i;
}

public static int toInt(final byte b) {
    return b & 0xFF;
}

public static int toInt(final char c) {
    asrt(c <= 255);
    return c;
}

public static int add(final int a, final int b) {
    final int sum;
    //sum = java.lang.Math.addExact(inited(a), inited(b));
    sum = inited(a) + inited(b);
    if (sum == INT_UNDEF) {
        throw new java.lang.ArithmeticException("addition overflow");
    }
    return sum;
}

public static long add(final long a, final long b) {
    final long sum;
    //sum = java.lang.Math.addExact(inited(a), inited(b));
    sum = inited(a) + inited(b);
    if (sum == LONG_UNDEF) {
        throw new java.lang.ArithmeticException("addition overflow");
    }
    return sum;
}

public static int sub(final int a, final int b) {
    final int diff;
    //diff = java.lang.Math.subtractExact(inited(a), inited(b));
    diff = inited(a) - inited(b);
    if (diff == INT_UNDEF) {
        throw new java.lang.ArithmeticException("subtraction overflow");
    }
    return diff;
}

public static long sub(final long a, final int b) {
    final long diff;
    //diff = java.lang.Math.subtractExact(inited(a), inited(b));
    diff = inited(a) - inited(b);
    if (diff == LONG_UNDEF) {
        throw new java.lang.ArithmeticException("subtraction overflow");
    }
    return diff;
}

public static int mul(final int a, final int b) {
    final int prod;
    //prod = java.lang.Math.multiplyExact(inited(a), inited(b));
    prod = inited(a) * inited(b);
    if (prod == INT_UNDEF) {
        throw new java.lang.ArithmeticException("multiply overflow");
    }
    return prod;
}

public static long mul(final long a, final long b) {
    final long prod;
    //prod = java.lang.Math.multiplyExact(inited(a), inited(b));
    prod = inited(a) * inited(b);
    if (prod == LONG_UNDEF) {
        throw new java.lang.ArithmeticException("multiply overflow");
    }
    return prod;
}

public static int div(final int a, final int b) {
    asrt(b >= 0);
    final int mask;

    mask = a >> 31;
    return mask ^ ((mask ^ inited(a)) / b);
}

public static int mod(final int a, final int b) {
    asrt(b >= 0);
    final int mask;

    mask = a >> 31;
    return (b & mask) + (mask ^ ((mask ^ inited(a)) % b));
}

public static int floor(final double d) {
    final double v;
    v = java.lang.Math.floor(inited(d));
    if ((v <= Integer.MIN_VALUE) || (Integer.MAX_VALUE < v)) {
        throw new java.lang.ArithmeticException("floor overflow");
    }
    return (int)v;
}

public static double scalb(final double d, final int n) {
    asrt(!java.lang.Double.isNaN(d));
    return java.lang.Math.scalb(d, n);
}

public static double frexp(final double d, final int[] n, final int n_i) {
    final long bits, mantissa;
    long       divider;
    int        exponent;

    asrt(!java.lang.Double.isNaN(d));

    bits = Double.doubleToLongBits(d);

    exponent = (int)((bits >> 52) & 0x07FFL);

    if (exponent == 0) {
        exponent =  1;
        mantissa =  bits & 0x000F_FFFF_FFFF_FFFFL;
    } else {
        mantissa = (bits & 0x000F_FFFF_FFFF_FFFFL) | (1L << 52);
    }

    exponent -= 1075;

    divider = 1;
    while (divider < mantissa) {
        divider  *= 2;
        exponent += 1;
    }

    if (bits < 0) {
       divider = -divider;
    }

    n[n_i] = exponent;
    return ((double)mantissa) / divider;
}

public static double flt(final int i) {
    return (double)inited(i);
}

public static byte[] bytes(final java.lang.String s) {
    final java.nio.ByteBuffer bb;
    final int len;
    byte ba[];

    ba = stringsCache.get(s);
    if (ba == null) {
        bb = UTF_8.encode(s);
        len = bb.limit();
        ba = new byte[len];
        bb.get(ba);

        stringsCache.put(s, ba);
    }
    return ba;
}

public static java.lang.String string(final byte[] bytes, final int ofs) {
    int i;
    final int len;
    final java.nio.ByteBuffer buf;

    i = ofs;
    len = bytes.length;
    while (i < len && bytes[i] != 0) {
         i += 1;
    }
    buf = java.nio.ByteBuffer.wrap(bytes, ofs, i - ofs);
    return UTF_8.decode(buf).toString();
}

public static java.lang.String string(final byte[] bytes) {
    return string(bytes, 0);
}

public static int strcmp(final byte[] s1, final byte[] s2) {
    final int c1, c2, len;
    int i;
    if (s1.length <= s2.length) {
        len = s1.length;
    } else {
        len = s2.length;
    }
    i = 0;
    while ((i < len) && (s1[i] == s2[i]) && (s1[i] != 0)) {
        i += 1;
    }
    if (i < s1.length) {
        c1 = 0xFF & s1[i];
    } else {
        c1 = 0;
    }
    if (i < s2.length) {
        c2 = 0xFF & s2[i];
    } else {
        c2 = 0;
    }
    return c1 - c2;
}

public static int strcmp(final byte[] s1, final byte s2) {
    final int c1, c2;
    int ret;
    if (s1.length == 0) {
        /* TODO не должно быть таких строк */
        c1 = 0;
    } else {
        c1 = 0xFF & s1[0];
    }
    c2 = 0xFF & s2;
    ret = c1 - c2;
    if (ret == 0 && c1 != 0 && s1.length > 1 && s1[1] != 0) {
        ret = 0xFF & s1[1];
    }
    return ret;
}

public static int strcmp(final byte s1, final byte[] s2) {
    return -strcmp(s2, s1);
}

/* Copy chars */
public static void strcpy(final byte[] d, final byte[] s) {
    final int len;
    int i;

    len = s.length;
    i = 0;
    while (i < len && s[i] != 0) {
        d[i] = s[i];
        i += 1;
    }
    d[i] = 0;
}

public static void strcpy(final byte[] d, final java.lang.String s) {
    final int len;
    final byte[] b;

    b = bytes(s);
    len = b.length;
    for (int i = 0; i < len; i += 1) {
        d[i] = b[i];
    }
    d[len] = 0;
}

public static void copy(final Object d, final Object s) {
    java.lang.System.arraycopy(s, 0, d, 0, java.lang.reflect.Array.getLength(s));
}

public static int set(final int low, final int high) {
    asrt(high <= 31);
    asrt(0 <= low && low <= high);
    return (~0 << low) & (~0 >>> (31 - high));
}

public static long lset(final int low, final int high) {
    asrt(high <= 63);
    asrt(0 <= low && low <= high);
    return (~0l << low) & (~0l >>> (63 - high));
}

public static boolean in(final int n, final int set) {
    return (0 <= n) && (n <= 31) && (0 != (set & (1 << n)));
}

public static boolean in(final int n, final long set) {
    return (0 <= n) && (n <= 63) && (0 != (set & (1l << n)));
}

public static void init(final java.lang.String[] sargs) {
    args = new byte[sargs.length][];
    for (int i = 0; i < sargs.length; i += 1) {
        args[i] = bytes(sargs[i]);
    }
    if (argsReceiver != null) {
        argsReceiver.set(args);
    }
}

}
