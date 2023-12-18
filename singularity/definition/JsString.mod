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

MODULE JsString;

 TYPE T* = POINTER TO RECORD END;

 PROCEDURE CharzByOfs*(src: ARRAY OF CHAR; ofs: INTEGER): T;
 BEGIN
  ASSERT((0 <= ofs) & (ofs < LEN(src)));
  ASSERT(FALSE)
 RETURN
  NIL
 END CharzByOfs;

 PROCEDURE Charz*(src: ARRAY OF CHAR): T;
 RETURN
  CharzByOfs(src, 0)
 END Charz;

 PROCEDURE ToCharz*(src: T; VAR dest: ARRAY OF CHAR; VAR ofs: INTEGER): BOOLEAN;
 BEGIN
  ASSERT(src # NIL);
  ASSERT((0 <= ofs) & (ofs < LEN(dest)))
 RETURN
  FALSE
 END ToCharz; 

END JsString.