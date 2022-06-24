Simple module for text input based on Oakwood guidelines. Procedure Name is not included

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

MODULE In;

IMPORT Stream := VDataStream, IO := VDefaultIO, Arithm := CheckIntArithmetic, Hex, Utf8;

VAR
  Done*,
  defer : BOOLEAN;
  char  : CHAR;
  in    : Stream.PIn;

PROCEDURE Open*;
VAR i: Stream.PIn;
BEGIN
  i := IO.OpenIn();
  Done := i # NIL;
  IF Done THEN
    Stream.CloseIn(in);
    in := i
  END
END Open;

PROCEDURE Read(): BOOLEAN;
VAR d: ARRAY 1 OF CHAR; ok: BOOLEAN;
BEGIN
  d[0] := 0X;
  ok := 1 = Stream.ReadChars(in^, d, 0, 1);
  char := d[0]
RETURN
  ok
END Read;

PROCEDURE Char*(VAR ch: CHAR);
BEGIN
  IF defer THEN
    ch    := char;
    defer := FALSE;
    Done  := TRUE
  ELSE
    Done := Read();
    ch   := char
  END
END Char;

PROCEDURE NotBlank(): BOOLEAN;
BEGIN
  IF ~defer THEN
    char := 0X;
    defer := TRUE
  END;
  WHILE (char <= " ") & Read() DO ; END;
  defer := char > " "
RETURN
  defer
END NotBlank;

PROCEDURE IsDec(ch: CHAR): BOOLEAN;
RETURN
  ("0" <= ch) & (ch <= "9")
END IsDec;

PROCEDURE Int*(VAR res: INTEGER);
VAR v, t, i, k: INTEGER; b: ARRAY 10 OF INTEGER;
BEGIN
  Done := NotBlank() & IsDec(char);
  IF Done THEN
    b[0] := 0;
    WHILE char = "0" DO defer := Read() END;

    i := 0;
    WHILE (i < LEN(b)) & IsDec(char) DO
      b[i] := ORD(char) - ORD("0");
      INC(i);
      defer := Read()
    END;

    IF (char = "H")
    OR ("A" <= char) & (char <= "F")
    THEN
      WHILE (i < 8) & Hex.InRange(char) DO
        b[i] := Hex.From(char);
        defer := Read();
        INC(i)
      END;
      Done := (char = "H")
            & ((i < 8) OR (b[0] < 8));
      defer := ~Done;
      IF Done THEN
        v := b[0];
        FOR k := 1 TO i DO v := v * 10H + b[k] END
      END
    ELSE
      Done := ~IsDec(char);
      IF Done THEN
        Done := i < 9;
        v := b[0];
        IF Done THEN
          FOR k := 1 TO i - 1 DO v := v * 10 + b[k] END
        ELSE
          FOR k := 1 TO 8 DO v := v * 10 + b[k] END;
          Done := Arithm.Mul(t, v, 10)
                & Arithm.Add(v, t, b[9]);
        END
      END
    END;
    res := v
  END;
END Int;

PROCEDURE LongInt*(VAR l: INTEGER);
BEGIN
  Int(l)
END LongInt;

PROCEDURE Pow(x: REAL; n: INTEGER): REAL;
VAR p: REAL;
BEGIN
  p := 1.0;
  WHILE n > 0 DO
    IF ODD(n) THEN
      p := p * x
    END;
    n := n DIV 2;
    x := x * x
  END
RETURN
  p
END Pow;

PROCEDURE RealOpt(VAR r: REAL; altExpLetter: CHAR);
VAR v, f, d: REAL; expSign: CHAR; exp: INTEGER;
BEGIN
  Done := NotBlank() & IsDec(char);
  IF Done THEN
    WHILE char = "0" DO defer := Read() END;
    v := 0.0;
    WHILE IsDec(char) DO
      (* TODO *)
      v := v * 10.0 + FLT(ORD(char) - ORD("0"));
      defer := Read()
    END;
    IF "." = char THEN
      defer := Read();
      Done := IsDec(char);
      IF Done THEN
        f := 0.0; d := 1.0;
        REPEAT
          f := f * 10.0 + FLT(ORD(char) - ORD("0"));
          d := d * 10.0;
          defer := Read()
        UNTIL ~IsDec(char);
        v := v + f / d;
        IF (char = "E") OR (char = altExpLetter) THEN
          defer := Read();
          Done := (char = "+") OR (char = "-");
          IF Done THEN
            expSign := char;
            defer := Read();
            Done := IsDec(char);
            IF Done THEN
              exp := 0;
              REPEAT
                exp := exp * 10 + (ORD(char) - ORD("0"));
                defer := Read()
              UNTIL (exp >= 1000) OR ~IsDec(char);
              Done := ~IsDec(char);
              IF ~Done THEN
                ;
              ELSIF expSign = "+" THEN
                v := v * Pow(10.0, exp)
              ELSE
                v := v / Pow(10.0, exp)
              END
            END
          END
        END
      END
    END;
    r := v
  END
END RealOpt;

PROCEDURE Real*(VAR r: REAL);
BEGIN
  RealOpt(r, "E")
END Real;

PROCEDURE LongReal*(VAR r: REAL);
BEGIN
  RealOpt(r, "D")
END LongReal;

PROCEDURE String*(VAR str: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  Done := NotBlank() & (Utf8.DQuote = char);
  IF Done THEN
    i := 0;
    defer := Read();
    WHILE (i < LEN(str) - 1) & (char >= " ") & (char # Utf8.DQuote) DO
      str[i] := char;
      INC(i);
      defer := Read();
    END;
    str[i] := 0X;
    Done := char = Utf8.DQuote;
    IF Done THEN defer := FALSE END
  END
END String;

BEGIN
  in    := IO.OpenIn();
  Done  := in # NIL;
  defer := FALSE
END In.
