/* Copyright 2018,2021,2024 ComdivByZero
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

private static String[] split(byte[] cmd) {
    int i, k, len, skip;
    java.util.ArrayList<String> als;

    als = new java.util.ArrayList<String>();
    cmd = cmd.clone();
    i = 0;

    while (cmd[i] != 0) {
        while (cmd[i] == ' ') { i += 1; }
        k = i;
        if (cmd[i] == '\'') {
            i += 1;
            skip = 0;
            while (cmd[i] != '\'') {
                if (cmd[i] == '\\') {
                    i += 2;
                    skip += 1;
                } else {
                    i += 1;
                }
                cmd[i - 1 - skip] = cmd[i - 1];
            }
            als.add(O7.string(cmd, k + 1, i - k - 1 - skip));
            i += 1;
        } else {
            while (cmd[i] != ' ' && cmd[i] != 0) { i += 1; }
            als.add(O7.string(cmd, k, i - k));
        }
    }
    return als.toArray(new String[0]);
}

public static int Do(byte[] cmd) {
    int ret;
    String[] acmd;
    java.lang.Process p;
    byte[] buf = new byte[256];

    acmd = split(cmd);
    cmd = null;
    try {
        p = java.lang.Runtime.getRuntime().exec(acmd);
        ret = p.waitFor();
        print(p.getInputStream(), buf, java.lang.System.out);
        print(p.getErrorStream(), buf, java.lang.System.err);
    } catch (java.lang.InterruptedException e) {
        ret = -1;
    } catch (java.io.IOException e) {
        ret = -1;
    }
    return ret;
}

}
