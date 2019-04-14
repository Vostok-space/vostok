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

public final class OsExec {

public static final int Ok = 0;

private static void
print(final java.io.InputStream is, byte[] buf, java.io.PrintStream ps)
throws java.io.IOException
{
    int len;
    len = is.read(buf, 0, buf.length);
    while (len > 0) {
        ps.write(buf, 0, len);
        len = is.read(buf, 0, buf.length);
    }
}

public static int Do(final byte[] cmd) {
    int ret;
    java.lang.Process p;
    byte[] buf = new byte[256];
    try {
        p = java.lang.Runtime.getRuntime().exec(O7.string(cmd));
        ret = p.waitFor();
        print(p.getInputStream(), buf, java.lang.System.out);
        print(p.getErrorStream(), buf, java.lang.System.err);
    } catch (java.lang.InterruptedException | java.io.IOException e) {
        ret = -1;
    }
    return ret;
}

}
