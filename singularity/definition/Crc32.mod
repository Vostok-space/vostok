32 bit cyclic redundancy code calculating. CRC32

Copyright 2024 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE Crc32;

 IMPORT P := Crc32Param, Set := CalcSet;

 CONST
  Poly*   = P.Poly;
  Init*   = P.Init;
  XorOut* = P.XorOut;

 VAR
  table: ARRAY 100H OF SET;

 PROCEDURE NextByte*(VAR crc: SET; b: BYTE);
 BEGIN
  crc := Set.Lsr(crc, 8) / table[ORD({0..7} * crc / Set.FromByte(b, 0))]
 END NextByte;

 PROCEDURE NextBytes*(VAR crc: SET; b: ARRAY OF BYTE; ofs, len: INTEGER);
 VAR c: SET; lim: INTEGER;
 BEGIN
  ASSERT(len >= 0);
  ASSERT((0 <= ofs) & (ofs <= LEN(b) - len));

  c := crc;
  lim := ofs + len;
  WHILE ofs < lim DO
    c := Set.Lsr(c, 8) / table[ORD({0..7} * c / Set.FromByte(b[ofs], 0))];
    INC(ofs)
  END;
  crc := c
 END NextBytes;

 PROCEDURE Begin*(VAR crc: SET);
 BEGIN
  crc := Init
 END Begin;

 PROCEDURE End*(VAR crc: SET);
 BEGIN
  crc := crc / XorOut
 END End;

 PROCEDURE Calc*(src: ARRAY OF BYTE; ofs, len: INTEGER): SET;
 VAR crc: SET;
 BEGIN
  crc := Init;
  NextBytes(crc, src, ofs, len)
 RETURN
  crc / XorOut
 END Calc;

 PROCEDURE InitTable;
 VAR i, l: INTEGER; crc: SET;
 BEGIN
  FOR i := 0 TO LEN(table) - 1 DO
    crc := Set.FromByte(i, 0);
    FOR l := 0 TO 7 DO
      IF 0 IN crc THEN
        crc := Set.Lsr(crc, 1) / Poly
      ELSE
        crc := Set.Lsr(crc, 1)
      END
    END;
    table[i] := crc
  END
 END InitTable;

BEGIN
 InitTable
END Crc32.
