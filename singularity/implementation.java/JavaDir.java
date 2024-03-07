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
import o7.JavaPath;

public final class JavaDir {

public static final boolean supported = true;

public static class T {
    private java.nio.file.DirectoryStream d;
    private java.util.Iterator<java.nio.file.Path> it;
}

public static T Open(JavaPath.T p) {
    java.nio.file.DirectoryStream<java.nio.file.Path> d;
    T t;

    O7.asrt(p != null);
    try {
        d = java.nio.file.Files.newDirectoryStream(p.p);
    } catch (java.lang.Exception e) {
        d = null;
    }
    if (d != null) {
        t = new T();
        t.d = d;
        t.it = d.iterator();
    } else {
        t = null;
    }
    return t;
}

public static T OpenByCharz(byte[] path, int ofs) {
    O7.asrt(path[ofs] != 0);
    return Open(JavaPath.FromCharz(path, ofs));
}

public static boolean CopyName(byte[] str, int[] ofs, int ofsi, JavaPath.T path) {
    return JavaPath.ToCharz(str, ofs, ofsi, path);
}

public static JavaPath.T Next(T dir) {
    JavaPath.T p;
    if (dir.it.hasNext()) {
        p = JavaPath.wrap(dir.it.next().getFileName());
    } else {
        p = null;
    }
    return p;
}

public static boolean Close(T dir) {
    boolean ret;
    try {
        dir.d.close();
        dir.d = null;
        ret = true;
    } catch (java.io.IOException e) {
        ret = false;
    }
    return ret;
}

public static boolean MkdirByCharz(byte[] path, int ofs) {
    java.lang.String s;
    java.nio.file.Path p;
    
    O7.asrt(path[ofs] != 0);
    
    s = O7.string(path, ofs);
    if (s != null) {
        p = java.nio.file.FileSystems.getDefault().getPath(s);
        try {
            p = java.nio.file.Files.createDirectory(p);
        } catch (java.io.IOException e) {
            p = null;
        }
    } else {
        p = null;
    }
    return p != null;
}

}
