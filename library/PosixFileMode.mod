POSIX files mode constants in hex and normalizer to octal

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

MODULE PosixFileMode;

 CONST
  (* Права файла в 16-ричном виде для удобства задания *)
  X* = 1; W* = X*2; R* = W*2; Rw* = R+W; Rx* = R+X; Rwx* = Rw+X;

  O* = 1; G* = O*10H; U* = G*10H; All* = U+G+O;

  Execute* = X;
  Write*   = W;
  Read*    = R;

  Other*   = O;
  Group*   = G;
  User*    = U;

 (* Приведение прав файла в 16-ном виде к исходному 8-чному. *)
 PROCEDURE Hex*(hex: INTEGER): INTEGER;
  PROCEDURE C(oct: INTEGER): INTEGER;
  BEGIN
    ASSERT(oct <= Rwx)
  RETURN
    oct
  END C;
 BEGIN
  ASSERT(hex >= 0)
 RETURN
    C(hex MOD 10H)
  + C(hex DIV 10H MOD 10H) * 8
  + C(hex DIV 100H       ) * 40H
 END Hex;

END PosixFileMode.
