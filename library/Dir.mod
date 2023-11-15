(* Copyright 2018,2023 ComdivByZero
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

 IMPORT Posix := PosixDir, Windows := WindowsDir, Js := JsDir;

 CONST
   NameLenMax* = 260;

 TYPE
   Dir* = RECORD
     p: Posix.Dir;
     w: Windows.FindId;
     f: Windows.FindData;
     js: Js.T
   END;

   File* = RECORD
     p: Posix.Ent;
     w: Windows.FindData;
     js: Js.Ent
   END;

 PROCEDURE Open*(VAR d: Dir; name: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
 VAR ok: BOOLEAN;
     spec: ARRAY 262 OF CHAR;
     i: INTEGER;
 BEGIN
   IF Posix.supported THEN
     ok := Posix.Open(d.p, name, ofs)
   ELSIF Windows.supported THEN
     i := 0;
     WHILE (ofs < LEN(name)) & (name[ofs] # 0X) DO
       spec[i] := name[ofs];
       INC(i); INC(ofs)
     END;
     spec[i    ] := "\";
     spec[i + 1] := "*";
     spec[i + 2] := 0X;
     ok := Windows.FindFirst(d.w, d.f, spec, 0)
   ELSIF Js.supported THEN
     d.js := Js.OpenByCharz(name, ofs);
     ok := d.js # NIL
   ELSE
     ok := FALSE
   END
   RETURN ok
 END Open;

 PROCEDURE Close*(VAR d: Dir): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
   IF Posix.supported THEN
     ok := Posix.Close(d.p)
   ELSIF Windows.supported THEN
     ok := Windows.Close(d.w)
   ELSIF Js.supported THEN
     ok := Js.Close(d.js)
   ELSE
     ok := FALSE
   END
   RETURN ok
 END Close;

 PROCEDURE Read*(VAR e: File; VAR d: Dir): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
   IF Posix.supported THEN
     ok := Posix.Read(e.p, d.p)
   ELSIF Windows.supported THEN
     IF d.f # NIL THEN
       e.w := d.f;
       d.f := NIL;
       ok := TRUE
     ELSE
       ok := Windows.FindNext(e.w, d.w)
     END
   ELSIF Js.supported THEN
     e.js := Js.Read(d.js);
     ok := e.js # NIL
   ELSE
     ok := FALSE
   END
   RETURN ok
 END Read;

 PROCEDURE CopyName*(VAR buf: ARRAY OF CHAR; VAR ofs: INTEGER; f: File): BOOLEAN;
 VAR ok: BOOLEAN;
 BEGIN
   IF Posix.supported THEN
     ok := Posix.CopyName(buf, ofs, f.p)
   ELSIF Windows.supported THEN
     ok := Windows.CopyName(buf, ofs, f.w)
   ELSIF Js.supported THEN
     ok := Js.CopyName(buf, ofs, f.js)
   ELSE
     ok := FALSE
   END
   RETURN ok
 END CopyName;

END Dir.
