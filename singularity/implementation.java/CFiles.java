/* Copyright 2018-2019,2021 ComdivByZero
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

public final class CFiles {

public static final int KiB = 1024,
                        MiB = 1024 * KiB,
                        GiB = 1024 * MiB;

public static class File {
    java.io.RandomAccessFile fc;
    java.io.InputStream      is;
    java.io.OutputStream     os;
}

public static File in_ = null,
                   out = null,
                   err = null;

public static final File Open(byte[] name, int ofs, byte[] mode) {
    File f;
    java.io.RandomAccessFile fc;
    java.lang.String smode;

    smode = "r";
    try {
        for (int i = 0; i < mode.length; i += 1) {
            if (mode[i] == 'w') {
                smode = "rw";
            }
        }
        fc = new java.io.RandomAccessFile(O7.string(name), smode);
        f = new File();
        f.fc = fc;
    } catch (java.lang.Exception e) {
        f = null;
    }
    return f;
}

public static final void Close(File[] file, int file_i) {
    File f;
    f = file[file_i];
    try {
        if (f.fc != null) {
            f.fc.close();
            f.fc = null;
        } else if (f.os != null) {
            f.os.close();
            f.os = null;
        } else {
            f.is.close();
            f.is = null;
        }
    } catch (java.io.IOException e) {}
    file[file_i] = null;
}

public static final void Close(File[] file) {
    Close(file, 0);
}

public static final int Read(File file, byte[] buf, int ofs, int count) {
    int read;
    try {
        if (file.fc != null) {
            read = file.fc.read(buf, ofs, count);
            if (read == -1) {
                read = 0;
            }
        } else if (file.is != null) {
            file.is.read(buf, ofs, count);
            read = count;
        } else {
            read = 0;
        }
    } catch (java.io.IOException e) {
        read = 0;
    }
    return read;
}

public static final int
Write(File file, byte[] buf, int ofs, int count) {
    int write;
    try {
        if (file.fc != null) {
            file.fc.write(buf, ofs, count);
            write = count;
        } else if (file.os != null) {
            file.os.write(buf, ofs, count);
            write = count;
        } else {
            write = 0;
        }
    } catch (java.io.IOException e) {
        write = 0;
    }
    return write;
}

public static final int ReadChars(File file, byte[] buf, int ofs, int count) {
    return Read(file, buf, ofs, count);
}

public static final int WriteChars(File file, byte[] buf, int ofs, int count) {
    return Write(file, buf, ofs, count);
}

public static final boolean Flush(File file) {
    return false;
}

/* полная позиция = gibs * GiB + bytes; 0 <= bytes < GiB */
public static final boolean Seek(File file, int gibs, int bytes) {
    boolean ok;
    O7.asrt((gibs >= 0) && (bytes >= 0) && (bytes < GiB));
    try {
        file.fc.seek((long)gibs * GiB + bytes);
        ok = true;
    } catch (java.io.IOException e) {
        ok = false;
    }
    return ok;
}

public static final boolean Tell(File file, int[] gibs, int gibs_i, int[] bytes, int bytes_i) {
    boolean ok; long fp;
    try {
        fp = file.fc.getFilePointer();
        gibs[gibs_i] = (int)(fp / GiB);
        bytes[bytes_i] = (int)(fp % GiB);
        ok = true;
    } catch (java.io.IOException e) {
        ok = false;
    }
    return ok;
}

public static final boolean Remove(byte[] name, int ofs) {
    boolean ok;
    try {
        ok = new java.io.File(O7.string(name, ofs)).delete();
    } catch (java.lang.SecurityException e) {
        ok = false;
    }
    return ok;
}

public static final boolean Exist(byte[] name, int ofs) {
    boolean exist;
    exist = true;
    try {
        new java.io.RandomAccessFile(O7.string(name, ofs), "r").close();
    } catch (java.io.FileNotFoundException e) {
        exist = false;
    } catch (java.io.IOException e) {}
    return exist;
}

static {
    in_ = new File();
    in_.is = java.lang.System.in;

    out = new File();
    out.os = java.lang.System.out;

    err = new File();
    err.os = java.lang.System.err;
}

}
