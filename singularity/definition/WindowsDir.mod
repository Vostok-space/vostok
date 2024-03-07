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
MODULE WindowsDir;

 TYPE
   FindData* = POINTER TO RECORD
   END;

   FindId* = POINTER TO RECORD
   END;

 VAR
   supported*: BOOLEAN;

 PROCEDURE FindFirst*(VAR id: FindId; VAR d: FindData;
                      filespec: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
 BEGIN
   ASSERT((0 <= ofs) & (ofs < LEN(filespec)))
 RETURN
   FALSE
 END FindFirst;

 PROCEDURE FindNext*(VAR d: FindData; id: FindId): BOOLEAN;
 BEGIN
   ASSERT(FALSE)
   RETURN FALSE
 END FindNext;

 PROCEDURE Close*(VAR id: FindId): BOOLEAN;
   RETURN FALSE
 END Close;

 PROCEDURE CopyName*(VAR buf: ARRAY OF CHAR; VAR ofs: INTEGER; f: FindData): BOOLEAN;
 BEGIN
   ASSERT(FALSE)
   RETURN FALSE
 END CopyName;

 PROCEDURE Mkdir*(name: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
 BEGIN
   ASSERT((0 <= ofs) & (ofs < LEN(name)))
   RETURN FALSE
 END Mkdir;

BEGIN
  supported := FALSE
END WindowsDir.
