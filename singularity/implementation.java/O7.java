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
public static final long DOUBLE_UNDEF = 0x7FFFFFFF00000000L;

public static final java.nio.charset.Charset UTF_8
                  = java.nio.charset.Charset.forName("UTF-8");

static int      exitCode  = 0;
static byte[][] args      = new byte[][]{};

private static
    java.lang.ref.SoftReference<java.util.HashMap<java.lang.String, byte[]>>
    stringsCache = new java.lang.ref.SoftReference<java.util.HashMap<java.lang.String, byte[]>>(null);

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
    if (java.lang.Double.doubleToRawLongBits(d) == DOUBLE_UNDEF) {
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
    if ((v <= java.lang.Integer.MIN_VALUE) || (java.lang.Integer.MAX_VALUE < v)) {
        throw new java.lang.ArithmeticException("floor overflow");
    }
    return (int)v;
}

public static double scalb(final double d, final int n) {
    asrt(!java.lang.Double.isNaN(d));
    return java.lang.Math.scalb(d, inited(n));
}

public static void scalb(final double d[], final int d_i, final int n) {
    d[d_i] = scalb(d[d_i], n);
}

public static double frexp(final double d, final int[] n, final int n_i) {
    final long bits, mantissa;
    long       divider;
    int        exponent;

    asrt(!java.lang.Double.isNaN(d));

    bits = java.lang.Double.doubleToLongBits(d);

    exponent = (int)((bits >> 52) & 0x07FFL);

    if (exponent == 0) {
        exponent =  1;
        mantissa =  bits & 0x000FFFFFFFFFFFFFL;
    } else {
        mantissa = (bits & 0x000FFFFFFFFFFFFFL) | (1L << 52);
    }

    exponent -= 1075;

    divider = 1;
    while (divider < mantissa) {
        divider  *= 2;
        exponent += 1;
    }
    if (divider != mantissa) {
        divider  /= 2;
        exponent -= 1;
    }

    if (bits < 0) {
       divider = -divider;
    }

    n[n_i] = exponent;
    return ((double)mantissa) / divider;
}

public static double frexp(final double d, final int[] n) {
    return frexp(d, n, 0);
}

public static void frexp(final double d[], final int d_i, final int[] n, final int n_i) {
    d[d_i] = frexp(d[d_i], n, n_i);
}

public static double flt(final int i) {
    return (double)inited(i);
}

public static byte[] bytes(final java.lang.String s) {
    final java.nio.ByteBuffer bb;
    final int len;
    java.util.HashMap<java.lang.String, byte[]> cache;
    byte ba[];

    cache = stringsCache.get();
    if (cache == null) {
        cache = new java.util.HashMap<java.lang.String, byte[]>();
        stringsCache =
            new java.lang.ref.SoftReference<java.util.HashMap<java.lang.String, byte[]>>(cache);
        ba = null;
    } else {
        ba = cache.get(s);
    }
    if (ba == null) {
        bb = UTF_8.encode(s);
        len = bb.limit();
        ba = new byte[len + 1];
        bb.get(ba, 0, len);

        cache.put(s, ba);
    }
    return ba;
}

public static java.lang.String string(final byte[] bytes, final int ofs) {
    int i;
    final java.nio.ByteBuffer buf;

    i = ofs;
    while (bytes[i] != 0) {
         i += 1;
    }
    buf = java.nio.ByteBuffer.wrap(bytes, ofs, i - ofs);
    return UTF_8.decode(buf).toString();
}

public static java.lang.String string(final byte[] bytes) {
    return string(bytes, 0);
}

public static int strcmp(final byte[] s1, final byte[] s2) {
    int i;
    i = 0;
    while ((s1[i] == s2[i]) && (s1[i] != 0)) {
        i += 1;
    }
    return (s1[i] & 0xFF) - (s2[i] & 0xFF);
}

public static int strcmp(final byte[] s1, final byte s2) {
    final int c1, c2;
    int ret;
    c1 = 0xFF & s1[0];
    c2 = 0xFF & s2;
    ret = c1 - c2;
    if (ret == 0 && c1 != 0 && s1[1] != 0) {
        ret = 0xFF & s1[1];
    }
    return ret;
}

public static int strcmp(final byte s1, final byte[] s2) {
    return -strcmp(s2, s1);
}

/* Copy chars */
public static void strcpy(final byte[] d, final byte[] s) {
    int i;

    i = 0;
    while (s[i] != 0) {
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

public static void copy(java.lang.Object d, java.lang.Object s, int len) {
    java.lang.System.arraycopy(s, 0, d, 0, len);
}

public static void copy(boolean[] d, boolean[] s) {copy(d, s, s.length);}
public static void copy(byte   [] d, byte   [] s) {copy(d, s, s.length);}
public static void copy(int    [] d, int    [] s) {copy(d, s, s.length);}
public static void copy(double [] d, double [] s) {copy(d, s, s.length);}


public static void copy(java.lang.Object d, java.lang.Object s, int ti, java.lang.String type) {
    int len, ilen;
    char ct;
    java.lang.Object item;

    len = java.lang.reflect.Array.getLength(s);
    ct = type.charAt(ti + 1);
    if (ct == '[') {
        for (int i = 0; i < len; i += 1) {
            /* TODO */
            copy(java.lang.reflect.Array.get(d, i),
                 java.lang.reflect.Array.get(s, i), ti + 1, type);
        }
    } else {
        /*TODO*/
        asrt(ct != 'L');

        item = java.lang.reflect.Array.get(s, 0);
        ilen = java.lang.reflect.Array.getLength(item);
        copy(java.lang.reflect.Array.get(d, 0), item, ilen);
        for (int i = 1; i < len; i += 1) {
            copy(java.lang.reflect.Array.get(d, i),
                 java.lang.reflect.Array.get(s, i), ilen);
        }
    }
}

public static void copy(java.lang.Object d, java.lang.Object s) {
    copy(d, s, 1, s.getClass().getName());
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

public static int ror(final int n, final int shift) {
    asrt(shift >= 0);
    asrt(n >= 0);
    final int r;
    r = java.lang.Integer.rotateRight(n, shift);
    asrt(r >= 0);
    return r;
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

public static boolean bit(int addr, int n) {
    asrt(false);
    return false;
}

}
