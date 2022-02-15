Comparison of arrays of chars and bytes

Copyright 2022 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE ArrayCmp;

PROCEDURE Bytes*(s1: ARRAY OF BYTE; ofs1: INTEGER;
                 s2: ARRAY OF BYTE; ofs2: INTEGER; count: INTEGER): INTEGER;
VAR last: INTEGER;
BEGIN
  ASSERT(count >= 0);
  ASSERT((0 <= ofs1) & (ofs1 <= LEN(s1) - count));
  ASSERT((0 <= ofs2) & (ofs2 <= LEN(s2) - count));

  last := ofs1 + count - 1;
  WHILE (ofs1 < last) & (s1[ofs1] = s2[ofs2]) DO
    INC(ofs1); INC(ofs2)
  END
RETURN
  s1[ofs1] - s2[ofs2]
END Bytes;

PROCEDURE Chars*(s1: ARRAY OF CHAR; ofs1: INTEGER;
                 s2: ARRAY OF CHAR; ofs2: INTEGER; count: INTEGER): INTEGER;
VAR last: INTEGER;
BEGIN
  ASSERT(count >= 0);
  ASSERT((0 <= ofs1) & (ofs1 <= LEN(s1) - count));
  ASSERT((0 <= ofs2) & (ofs2 <= LEN(s2) - count));

  last := ofs1 + count - 1;
  WHILE (ofs1 < last) & (s1[ofs1] = s2[ofs2]) DO
    INC(ofs1); INC(ofs2)
  END
RETURN
  ORD(s1[ofs1]) - ORD(s2[ofs2])
END Chars;

PROCEDURE BytesChars*(s1: ARRAY OF BYTE; ofs1: INTEGER;
                      s2: ARRAY OF CHAR; ofs2: INTEGER; count: INTEGER): INTEGER;
VAR last: INTEGER;
BEGIN
  ASSERT(count >= 0);
  ASSERT((0 <= ofs1) & (ofs1 <= LEN(s1) - count));
  ASSERT((0 <= ofs2) & (ofs2 <= LEN(s2) - count));

  last := ofs1 + count - 1;
  WHILE (ofs1 < last) & (s1[ofs1] = ORD(s2[ofs2])) DO
    INC(ofs1); INC(ofs2)
  END
RETURN
  s1[ofs1] - ORD(s2[ofs2])
END BytesChars;

END ArrayCmp.
