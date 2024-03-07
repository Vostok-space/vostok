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
import o7.JavaString;

public final class JavaPath {

public static class T { java.nio.file.Path p; }

public static T wrap(java.nio.file.Path p) {
    T t;
    if (p != null) {
        t = new T();
        t.p = p;
    } else {
        t = null;
    }
    return t;
}

public static T From(JavaString.T str) {
    java.nio.file.Path p;

    O7.asrt(str != null);

    try {
        p = java.nio.file.Paths.get(str.s);
    } catch (java.nio.file.InvalidPathException e) {
        p = null;
    }
    return wrap(p);
}

public static T FromCharz(byte[] str, int ofs) {
    O7.asrt((0 <= ofs) && (ofs < str.length));
    O7.asrt(str[ofs] != 0);
    return From(JavaString.From(str, ofs));
}

public static JavaString.T ToString(T path) {
    return JavaString.wrap(path.p.toString());
}

public static boolean ToCharz(byte[] charz, int[] ofsv, int ofsi, T path) {
    O7.asrt((0 <= ofsv[ofsi]) && (ofsv[ofsi] < charz.length));
    return JavaString.To(charz, ofsv, ofsi, ToString(path));
}

}
