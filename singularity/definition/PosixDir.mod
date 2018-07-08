(* Copyright 2017-2018 ComdivByZero
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

 TYPE
   Dir* = POINTER TO RECORD
   END;

   Ent* = POINTER TO RECORD
   END;

 VAR
   supported*: BOOLEAN;

 PROCEDURE Open*(VAR d: Dir; name: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
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

BEGIN
  supported := FALSE
END PosixDir.
