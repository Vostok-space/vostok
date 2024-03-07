Copyright 2023-2024 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE JavaPath;

 IMPORT String := JavaString;

 TYPE
  T* = POINTER TO RECORD END;

 PROCEDURE From*(str: String.T): T;
 BEGIN
  ASSERT(str # NIL)
 RETURN
  NIL
 END From;

 PROCEDURE FromCharz*(str: ARRAY OF CHAR; ofs: INTEGER): T;
 BEGIN
  ASSERT((0 <= ofs) & (ofs < LEN(str)));
  ASSERT(str[ofs] # 0X)
 RETURN
  From(String.From(str, ofs))
 END FromCharz;

 PROCEDURE ToString*(path: T): String.T;
 BEGIN
  ASSERT(path # NIL)
 RETURN
  NIL
 END ToString;

 PROCEDURE ToCharz*(VAR charz: ARRAY OF CHAR; VAR ofs: INTEGER; path: T): BOOLEAN;
 BEGIN
  ASSERT((0 <= ofs) & (ofs < LEN(charz)))
 RETURN
  String.To(charz, ofs, ToString(path))
 END ToCharz;

END JavaPath.
