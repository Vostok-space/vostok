Filling arrays of chars and bytes

Copyright 2021 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE ArrayFill;

  PROCEDURE Char*(VAR a: ARRAY OF CHAR; ofs: INTEGER; ch: CHAR; n: INTEGER);
  VAR i: INTEGER;
  BEGIN
    ASSERT(0 <= n);
    ASSERT((0 <= ofs) & (ofs <= LEN(a) - n));

    INC(n, ofs - 1);
    FOR i := ofs TO n DO
      a[i] := ch
    END
  END Char;

  PROCEDURE Char0*(VAR a: ARRAY OF CHAR; ofs: INTEGER; n: INTEGER);
  BEGIN
    Char(a, ofs, 0X, n)
  END Char0;

  PROCEDURE Byte*(VAR a: ARRAY OF BYTE; ofs: INTEGER; b: BYTE; n: INTEGER);
  VAR i: INTEGER;
  BEGIN
    ASSERT(0 <= n);
    ASSERT((0 <= ofs) & (ofs <= LEN(a) - n));

    INC(n, ofs - 1);
    FOR i := ofs TO n DO
      a[i] := b
    END
  END Byte;

  PROCEDURE Byte0*(VAR a: ARRAY OF BYTE; ofs: INTEGER; n: INTEGER);
  BEGIN
    Byte(a, ofs, 0, n)
  END Byte0;

END ArrayFill.
