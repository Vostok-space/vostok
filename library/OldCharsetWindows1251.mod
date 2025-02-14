Conversion code of old charset Windows-1251 to toUnicode code point and UTF-8.

Copyright 2025 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE OldCharsetWindows1251;

 IMPORT toUnicode := OldCharsetWindows1251ToUnicode, toUtf8 := OldCharsetWindows1251ToUtf8, Utf8;

 CONST Supported* = toUnicode.Supported OR toUtf8.Supported;

 PROCEDURE ToUnicode*(wc: INTEGER): INTEGER;
 VAR code: INTEGER; b: ARRAY 4 OF CHAR; l: INTEGER; r: Utf8.R;
 BEGIN
  IF toUnicode.Supported THEN
    code := toUnicode.Do(wc)
  ELSE
    l := 0;
    ASSERT(toUtf8.Do(b, l, wc));
    ASSERT(~(Utf8.Begin(r, b[0])
            & Utf8.Next(r, b[1])
            & Utf8.Next(r, b[2])
            & Utf8.Next(r, b[3])));
    code := r.val
  END
 RETURN
  code
 END ToUnicode;

 PROCEDURE ToUtf8*(VAR out: ARRAY OF CHAR; VAR ofs: INTEGER; wc: INTEGER): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
  IF toUtf8.Supported THEN
    ok := toUtf8.Do(out, ofs, wc)
  ELSE
    ok := Utf8.FromCode(out, ofs, toUnicode.Do(wc))
  END
 RETURN
  ok
 END ToUtf8;

END OldCharsetWindows1251.
