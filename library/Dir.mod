(* Copyright 2018,2023-2024 ComdivByZero
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
 *)
MODULE Dir;

 IMPORT Posix := PosixDir, Windows := WindowsDir, Js := JsDir, Java := JavaDir, JavaPath;

 CONST
   NameLenMax* = 260;

   None = 0;
   IdPosix = 1;
   IdWindows = 2;
   IdJs = 3;
   IdJava = 4;

 TYPE
   Dir* = RECORD
     p: Posix.Dir;
     w: Windows.FindId;
     f: Windows.FindData;
     js: Js.T;
     jv: Java.T
   END;

   File* = RECORD
     p: Posix.Ent;
     w: Windows.FindData;
     js: Js.Ent;
     jv: JavaPath.T
   END;

 VAR id: INTEGER;

 PROCEDURE Open*(VAR d: Dir; name: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
 VAR ok: BOOLEAN;
     spec: ARRAY 262 OF CHAR;
     i: INTEGER;
 BEGIN
   CASE id OF
     IdPosix:
     ok := Posix.Open(d.p, name, ofs)
   | IdWindows:
     i := 0;
     WHILE (ofs < LEN(name)) & (name[ofs] # 0X) DO
       spec[i] := name[ofs];
       INC(i); INC(ofs)
     END;
     spec[i    ] := "\";
     spec[i + 1] := "*";
     spec[i + 2] := 0X;
     ok := Windows.FindFirst(d.w, d.f, spec, 0)
   | IdJs:
     d.js := Js.OpenByCharz(name, ofs);
     ok := d.js # NIL
   | IdJava:
     d.jv := Java.OpenByCharz(name, ofs);
     ok := d.jv # NIL
   | None:
     ok := FALSE
   END
   RETURN ok
 END Open;

 PROCEDURE Close*(VAR d: Dir): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
   CASE id OF
     IdPosix:
     ok := Posix.Close(d.p)
   | IdWindows:
     ok := Windows.Close(d.w)
   | IdJs:
     ok := Js.Close(d.js)
   | IdJava:
     ok := Java.Close(d.jv);
     d.jv := NIL
   | None:
     ok := FALSE
   END
   RETURN ok
 END Close;

 PROCEDURE Read*(VAR e: File; VAR d: Dir): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
   CASE id OF
     IdPosix:
     ok := Posix.Read(e.p, d.p)
   | IdWindows:
     IF d.f # NIL THEN
       e.w := d.f;
       d.f := NIL;
       ok := TRUE
     ELSE
       ok := Windows.FindNext(e.w, d.w)
     END
   | IdJs:
     e.js := Js.Read(d.js);
     ok := e.js # NIL
   | IdJava:
     e.jv := Java.Next(d.jv);
     ok := e.jv # NIL
   END
   RETURN ok
 END Read;

 PROCEDURE CopyName*(VAR buf: ARRAY OF CHAR; VAR ofs: INTEGER; f: File): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
   CASE id OF
     IdPosix:
     ok := Posix.CopyName(buf, ofs, f.p)
   | IdWindows:
     ok := Windows.CopyName(buf, ofs, f.w)
   | IdJs:
     ok := Js.CopyName(buf, ofs, f.js)
   | IdJava:
     ok := JavaPath.ToCharz(buf, ofs, f.jv)
   END
   RETURN ok
 END CopyName;

BEGIN
  IF Posix.supported THEN
    id := IdPosix
  ELSIF Windows.supported THEN
    id := IdWindows
  ELSIF Js.supported THEN
    id := IdJs
  ELSIF Java.supported THEN
    id := IdJava
  ELSE
    id := None
  END
END Dir.
