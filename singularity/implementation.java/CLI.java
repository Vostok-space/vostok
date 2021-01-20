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

import o7.O7;

public final class CLI {

public  static final int MaxLen = 4096;

public  static int      count;
private static byte[][] args;

public static final boolean GetName(byte[] str, int[] v_ofs, int v_ofs_i) {
    int ofs = v_ofs[v_ofs_i];
    assert 0 <= ofs && ofs < str.length;
    return false;
}

public static final boolean Get(byte[] str, int[] v_ofs, int v_ofs_i, int arg) {
    int ofs = v_ofs[v_ofs_i];
    int len = args[arg].length;
    int last, i;

    assert 0 <= arg && arg < count;
    assert 0 <= ofs && ofs < str.length;

    boolean ret;

    last = ofs + len - 1;
    ret = last < str.length;
    if (ret) {
        i = 0;
        while (ofs < last) {
            str[ofs] = args[arg][i];
            /* предотвращение попадания завершения посреди строки */
            if (str[ofs] == 0) {
                str[ofs] = 1;
            }
            ofs += 1;
            i   += 1;
        }
        assert args[arg][i] == 0;
        str[ofs] = 0;
        v_ofs[v_ofs_i] = ofs;
    }
    return ret;
}

public static final void SetExitCode(int code) {
    O7.exitCode = code;
}

static {
    args  = O7.args;
    count = O7.args.length;
    O7.argsReceiver = new O7.ArgsReceiver() {
        @Override protected void set(byte[][] vargs) {
            args  = vargs;
            count = args.length;
        }
    };
}

}
