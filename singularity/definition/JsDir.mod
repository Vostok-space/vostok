Copyright 2023 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE JsDir;

 IMPORT String := JsString, Mode := PosixFileMode; 

 CONST
  X* = Mode.X;
  R* = Mode.R;
  W* = Mode.W;

  O* = Mode.O;
  G* = Mode.G;
  U* = Mode.U;

 TYPE
  T* = POINTER TO RECORD END;
  Ent* = POINTER TO RECORD END;

 VAR supported*: BOOLEAN;

 PROCEDURE Open*(path: String.T): T;
 BEGIN
  ASSERT(path # NIL)
 RETURN
  NIL
 END Open;

 PROCEDURE OpenByCharz*(path: ARRAY OF CHAR; ofs: INTEGER): T;
 VAR p: String.T; d: T;
 BEGIN
  ASSERT(path[0] # 0X);
  p := String.CharzByOfs(path, ofs);
  IF p # NIL THEN
    d := Open(p)
  ELSE
    d := NIL
  END
 RETURN
  d
 END OpenByCharz;

 PROCEDURE Close*(VAR dir: T): BOOLEAN;
 BEGIN
  dir := NIL
 RETURN
  FALSE
 END Close;

 PROCEDURE Read*(dir: T): Ent;
 BEGIN
  ASSERT(dir # NIL);
  ASSERT(FALSE)
 RETURN
  NIL
 END Read;

 PROCEDURE GetName*(ent: Ent): String.T;
 BEGIN
  ASSERT(FALSE)
 RETURN
  NIL
 END GetName;

 PROCEDURE CopyName*(VAR str: ARRAY OF CHAR; VAR ofs: INTEGER; ent: Ent): BOOLEAN;
 VAR n: String.T;
 BEGIN
  n := GetName(ent)
 RETURN
  (n # NIL) & String.ToCharz(n, str, ofs)
 END CopyName;

 PROCEDURE Mkdir*(path: String.T; mode: INTEGER): BOOLEAN;
 BEGIN
  ASSERT(path # NIL);
  ASSERT(Mode.Hex(mode) < 200H)
 RETURN
  FALSE
 END Mkdir;

 PROCEDURE MkdirByCharz*(path: ARRAY OF CHAR; ofs: INTEGER; mode: INTEGER): BOOLEAN;
 VAR p: String.T;
 BEGIN
  ASSERT(path[0] # 0X);
  p := String.CharzByOfs(path, ofs)
 RETURN
  (p # NIL) & Mkdir(p, mode)
 END MkdirByCharz;

BEGIN
  supported := FALSE
END JsDir.
