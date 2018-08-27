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

public final class O7 {

public static abstract class ArgsReceiver {
    abstract protected void set(byte[][] args);
}

public static ArgsReceiver argsReceiver = null;

public static final byte BOOL_UNDEF   = (byte)0xFF;
public static final int  INT_UNDEF    = Integer.MIN_VALUE;
public static final long LONG_UNDEF   = Long.MIN_VALUE;
public static final long DOUBLE_UNDEF = 0x7FFF_FFFF_0000_0000L;

static int      exitCode  = 0;
static byte[][] args      = null;

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
    sum = java.lang.Math.addExact(inited(a), inited(b));
    if (sum == INT_UNDEF) {
        throw new java.lang.ArithmeticException("addition overflow");
    }
    return sum;
}

public static long add(final long a, final long b) {
    final long sum;
    sum = java.lang.Math.addExact(inited(a), inited(b));
    if (sum == LONG_UNDEF) {
        throw new java.lang.ArithmeticException("addition overflow");
    }
    return sum;
}

public static int sub(final int a, final int b) {
    final int diff;
    diff = java.lang.Math.subtractExact(a, b);
    if (diff == INT_UNDEF) {
        throw new java.lang.ArithmeticException("subtraction overflow");
    }
    return diff;
}

public static long sub(final long a, final int b) {
    final long diff;
    diff = java.lang.Math.subtractExact(a, b);
    if (diff == LONG_UNDEF) {
        throw new java.lang.ArithmeticException("subtraction overflow");
    }
    return diff;
}

public static int mul(final int a, final int b) {
    final int prod;
    prod = java.lang.Math.multiplyExact(a, b);
    if (prod == INT_UNDEF) {
        throw new java.lang.ArithmeticException("multiply overflow");
    }
    return prod;
}

public static long mul(final long a, final long b) {
    final long prod;
    prod = java.lang.Math.multiplyExact(a, b);
    if (prod == LONG_UNDEF) {
        throw new java.lang.ArithmeticException("multiply overflow");
    }
    return prod;
}

public static int div(final int a, final int b) {
    final int r;
    asrt(b > 0);

    if (a >= 0) {
        r = a / b;
    } else {
        r = -1 - (-1 - inited(a)) / b;
    }
    return r;
}

public static int mod(final int a, final int b) {
    final int r;
    asrt(b > 0);

    if (a >= 0) {
        r = a % b;
    } else {
        r = b + (-1 - (-1 - inited(a)) % b);
    }
    return r;
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
    asrt(java.lang.Double.isFinite(d));
    return java.lang.Math.scalb(d, n);
}

public static double frexp(final double d, final int[] n, final int n_i) {
    final long bits, mantissa;
    long       divider;
    int        exponent;

    asrt(java.lang.Double.isFinite(d));

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
    final byte ba[];
    /* TODO map */
    bb = java.nio.charset.StandardCharsets.UTF_8.encode(s);
    ba = new byte[bb.limit()];
    bb.get(ba);
/*
    System.out.println("bytes(\"" + s + "\") = " + java.util.Arrays.toString(ba));
*/
    return ba;
}

public static java.lang.String string(final byte[] bytes) {
    int i;
    final java.nio.ByteBuffer buf;

    i = 0;
    while (i < bytes.length && bytes[i] != 0) {
         i += 1;
    }
    buf = java.nio.ByteBuffer.wrap(bytes, 0, i);
    return java.nio.charset.StandardCharsets.UTF_8.decode(buf).toString();
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
/*
    System.out.println("compare " + java.util.Arrays.toString(s1) + " : "
                     + java.util.Arrays.toString(s2) + " = " + (c1 - c2));
*/
    return c1 - c2;
}

/* Copy chars */
public static void strcpy(final byte[] d, final byte[] s) {
    java.lang.System.arraycopy(s, 0, d, 0, s.length);
    d[s.length] = 0;
}

public static void strcpy(final byte[] d, final java.lang.String s) {
    final int len;

    len = s.length();
    for (int i = 0; i < len; i += 1) {
        d[i] = (byte)s.charAt(i);
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
