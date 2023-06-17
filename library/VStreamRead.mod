Subroutines for reading different types from VDataStream.In

Copyright 2022-2023 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE VStreamRead;

IMPORT Stream := VDataStream, Uint32, Int32, ArrayCmp, log;

PROCEDURE Byte*(VAR in: Stream.In; VAR b: BYTE): BOOLEAN;
VAR buf: ARRAY 1 OF BYTE; ok: BOOLEAN;
BEGIN
  ok := 1 = Stream.ReadWhole(in, buf);
  IF ok THEN
    b := buf[0]
  END
RETURN
  ok
END Byte;

PROCEDURE LeUint32*(VAR in: Stream.In; VAR u: Uint32.Type): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
  ok := LEN(u) = Stream.ReadWhole(in, u);
  IF (Uint32.ByteOrder = Uint32.BigEndian) & ok THEN
    Uint32.SwapOrder(u)
  END
RETURN
  ok
END LeUint32;

PROCEDURE LeUinteger*(VAR in: Stream.In; VAR i: INTEGER): BOOLEAN;
VAR u: Uint32.Type; ok: BOOLEAN;
BEGIN
  ok := (LEN(u) = Stream.ReadWhole(in, u))
      & (u[3] < 80H);
  IF ok THEN
    IF Uint32.ByteOrder = Uint32.BigEndian THEN
      Uint32.SwapOrder(u)
    END;
    i := Uint32.ToInt(u)
  END
RETURN
  ok
END LeUinteger;

PROCEDURE LeInt32*(VAR in: Stream.In; VAR i32: Int32.Type): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
  ok := LEN(i32) = Stream.ReadWhole(in, i32);
  IF (Int32.ByteOrder = Int32.BigEndian) & ok THEN
    Int32.SwapOrder(i32)
  END
RETURN
  ok
END LeInt32;

PROCEDURE LeInteger*(VAR in: Stream.In; VAR i: INTEGER): BOOLEAN;
VAR i32: Int32.Type; ok: BOOLEAN;
BEGIN
  ok := LeInt32(in, i32)
      & (0 # Int32.Cmp(Int32.min, i32));
  IF ok THEN
    i := Int32.ToInt(i32)
  END
RETURN
  ok
END LeInteger;

PROCEDURE SameChars*(VAR in: Stream.In; sample: ARRAY OF CHAR; ofs, count: INTEGER): BOOLEAN;
VAR buf: ARRAY 64 OF CHAR;
BEGIN
  ASSERT(sample[LEN(sample) - 1] = 0X);
  ASSERT(ofs >= 0);
  ASSERT(count >= 0);
  ASSERT(ofs <= LEN(sample) - count);

  WHILE (count > LEN(buf)) & (Stream.ReadCharsWhole(in, buf) = LEN(buf))
      & (ArrayCmp.Chars(buf, 0, sample, ofs, LEN(buf)) = 0)
  DO
    DEC(count, LEN(buf));
    INC(ofs)
  END
RETURN
  (count <= LEN(buf))
& (count = Stream.ReadChars(in, buf, 0, count))
& (ArrayCmp.Chars(buf, 0, sample, ofs, count) = 0)
END SameChars;

PROCEDURE Skip*(VAR in: Stream.In; count: INTEGER): BOOLEAN;
RETURN
  count = Stream.Skip(in, count)
END Skip;

(* Читает до байта=end, но не больше count. Возвращает последний прочитанный байт *)
PROCEDURE SkipUntil*(VAR in: Stream.In; end: BYTE; VAR count: INTEGER): INTEGER;
VAR b: ARRAY 1 OF BYTE; rest, last: INTEGER;
BEGIN
  ASSERT(count >= 0);

  rest := count;
  IF (rest = 0) OR (Stream.ReadWhole(in, b) < 1) THEN
    last := 100H
  ELSE
    DEC(rest);
    WHILE (b[0] # end) & (rest > 0) & (Stream.ReadWhole(in, b) = 1) DO
      DEC(rest)
    END;
    last := b[0]
  END;
  DEC(count, rest)
RETURN
  last
END SkipUntil;

PROCEDURE UntilChar*(VAR in: Stream.In; end: CHAR; count: INTEGER;
                     VAR out: ARRAY OF CHAR; VAR ofs: INTEGER): CHAR;
VAR i: INTEGER; last: CHAR;
BEGIN
  ASSERT(count >= 0);
  ASSERT((0 <= ofs) & (ofs <= LEN(out) - count));

  i := ofs;
  IF (count = 0) OR (Stream.ReadChars(in, out, i, 1) < 1) THEN
    last := CHR(0FFH - ORD(end = 0FFX));
  ELSE
    DEC(count);
    WHILE (out[i] # end) & (count > 0) & (Stream.ReadChars(in, out, i + 1, 1) = 1) DO
      INC(i); DEC(count)
    END;
    last := out[i];
    ofs := i + 1
  END
RETURN
  last
END UntilChar;

(* TODO more *)

END VStreamRead.
