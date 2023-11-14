(* Copyright 2017-2018,2023 ComdivByZero
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
MODULE PosixDir;

 IMPORT Mode := PosixFileMode;

 CONST
   (* Режим создания каталога в 16-ричном виде *)
   X* = Mode.X; W* = Mode.W; R* = Mode.R; Rw* = Mode.Rw; Rx* = Mode.Rx; Rwx* = Mode.Rwx;
   O* = Mode.O; G* = Mode.G; U* = Mode.U; All* = Mode.All;

 TYPE
   Dir* = POINTER TO RECORD
   END;

   Ent* = POINTER TO RECORD
   END;

 VAR
   supported*: BOOLEAN;

 PROCEDURE Open*(VAR d: Dir; name: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
 BEGIN
   ASSERT((0 <= ofs) & (ofs < LEN(name)))
 RETURN FALSE
 END Open;

 PROCEDURE Close*(VAR d: Dir): BOOLEAN;
 RETURN FALSE
 END Close;

 PROCEDURE Read*(VAR e: Ent; d: Dir): BOOLEAN;
 BEGIN
   ASSERT(FALSE)
 RETURN FALSE
 END Read;

 PROCEDURE CopyName*(VAR buf: ARRAY OF CHAR; VAR ofs: INTEGER; e: Ent): BOOLEAN;
 BEGIN
   ASSERT(FALSE)
 RETURN FALSE
 END CopyName;

 PROCEDURE HexToMode*(hex: INTEGER): INTEGER;
 RETURN
   Mode.Hex(hex)
 END HexToMode;

 (* mode в 16-ричной системе, то есть 777H вместо 8-ричной 0777 *)
 PROCEDURE Mkdir*(name: ARRAY OF CHAR; ofs: INTEGER; mode: INTEGER): BOOLEAN;
 BEGIN
   ASSERT((0 <= ofs) & (ofs < LEN(name)));
   ASSERT(name # "");
   ASSERT(Mode.Hex(mode) < 200H)
 RETURN FALSE
 END Mkdir;

BEGIN
  supported := FALSE
END PosixDir.
