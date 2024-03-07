/* Copyright 2023-2024 ComdivByZero
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

public final class JavaString {

public static class T { java.lang.String s; }

public static T wrap(java.lang.String s) {
    T t;
    if (s != null) {
        t = new T();
        t.s = s;
    } else {
        t = null;
    }
    return t;
}

public static T From(byte[] charz, int ofs) {
    O7.asrt((0 <= ofs) && (ofs < charz.length));
    return wrap(O7.string(charz, ofs));
}

public static boolean To(byte[] charz, int[] ofsv, int ofsi, T str) {
    int ofs;
    byte[] bytes;
    boolean ok;

    ofs = ofsv[ofsi];
    O7.asrt((0 <= ofs) && (ofs < charz.length));
    O7.asrt(str != null);
    
    bytes = str.s.getBytes(java.nio.charset.StandardCharsets.UTF_8);

    ok = ofs < charz.length - bytes.length;
    if (ok) {
        java.lang.System.arraycopy(bytes, 0, charz, ofs, bytes.length);
        ofs += bytes.length;
        ofsv[ofsi] = ofs;
    }
    charz[ofs] = 0;
    return ok;
}

}
