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

MODULE JavaDir;

 IMPORT Path := JavaPath;

 TYPE
  T* = POINTER TO RECORD END;

 VAR supported*: BOOLEAN;

 PROCEDURE Open*(p: Path.T): T;
 BEGIN
  ASSERT(p # NIL)
 RETURN
  NIL
 END Open;

 PROCEDURE OpenByCharz*(path: ARRAY OF CHAR; ofs: INTEGER): T;
 BEGIN
  ASSERT(path[0] # 0X)
 RETURN
  NIL
 END OpenByCharz;

 PROCEDURE CopyName*(VAR str: ARRAY OF CHAR; VAR ofs: INTEGER; path: T): BOOLEAN;
 BEGIN
  ASSERT((0 <= ofs) & (ofs < LEN(str)))
 RETURN
  FALSE
 END CopyName;

 PROCEDURE Next*(dir: T): Path.T;
 BEGIN
  ASSERT(dir # NIL)
 RETURN
  NIL
 END Next;

 PROCEDURE Close*(dir: T): BOOLEAN;
 BEGIN
  ASSERT(dir # NIL)
 RETURN
  FALSE
 END Close;

 PROCEDURE MkdirByCharz*(path: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
 BEGIN
  ASSERT((0 <= ofs) & (ofs < LEN(path)));
  ASSERT(path[ofs] # 0X)
 RETURN
  FALSE
 END MkdirByCharz;

BEGIN
  supported := FALSE
END JavaDir.
