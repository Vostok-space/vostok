Simple output subroutines with short names

Copyright 2021-2022 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE log;

  IMPORT Out, Hex;

  PROCEDURE s*(str: ARRAY OF CHAR);
  BEGIN
    Out.String(str)
  END s;

  PROCEDURE sn*(str: ARRAY OF CHAR);
  BEGIN
    Out.String(str); Out.Ln
  END sn;

  PROCEDURE c*(ch: CHAR);
  VAR str: ARRAY 2 OF CHAR;
  BEGIN
    str[0] := ch;
    str[1] := 0X;
    Out.String(str)
  END c;

  PROCEDURE i*(int: INTEGER);
  BEGIN
    Out.Int(int, 0)
  END i;

  PROCEDURE in*(int: INTEGER);
  BEGIN
    Out.Int(int, 0); Out.Ln
  END in;

  PROCEDURE h*(int: INTEGER);
  VAR buf: ARRAY 9 OF CHAR; j, k: INTEGER;
  BEGIN
    j := LEN(buf) - 2;
    buf[j] := Hex.To(int MOD 10H);
    int := int DIV 10H + ORD(int < 0) * 8000000H;
    WHILE int # 0 DO
      DEC(j);
      buf[j] := Hex.To(int MOD 10H);
      int := int DIV 10H
    END;

    IF j > 0 THEN
      k := 0;
      WHILE j < LEN(buf) - 1 DO
        buf[k] := buf[j];
        INC(k);
        INC(j)
      END;
      buf[k] := 0X
    ELSE
      buf[LEN(buf) - 1] := 0X
    END;

    Out.String(buf)
  END h;

  PROCEDURE hn*(int: INTEGER);
  BEGIN
    h(int); Out.Ln
  END hn;

  PROCEDURE r*(frac: REAL);
  BEGIN
    Out.Real(frac, 0)
  END r;

  PROCEDURE rn*(frac: REAL);
  BEGIN
    Out.Real(frac, 0); Out.Ln
  END rn;

  PROCEDURE b*(logic: BOOLEAN);
  BEGIN
    IF logic THEN
      Out.String("TRUE")
    ELSE
      Out.String("FALSE")
    END
  END b;

  PROCEDURE bn*(logic: BOOLEAN);
  BEGIN
    b(logic); Out.Ln
  END bn;

  PROCEDURE set*(val: SET);
  VAR f: INTEGER;

    PROCEDURE Item(VAR val: SET; VAR f: INTEGER);
    VAR l: INTEGER;
    BEGIN
      ASSERT(val # {});
      WHILE ~(f IN val) DO
        INC(f)
      END;
      l := f;
      REPEAT
        EXCL(val, l);
        INC(l)
      UNTIL ~(l IN val);
      Out.Int(f, 0);
      IF f < l - 1 THEN
        Out.String(".."); Out.Int(l - 1, 0)
      END;
      f := l
    END Item;
  BEGIN
    IF val = {} THEN
      Out.String("{}")
    ELSE
      Out.Char("{");
      f := 0;
      Item(val, f);
      WHILE val # {} DO
        Out.String(", ");
        Item(val, f)
      END;
      Out.Char("}")
    END
  END set;

  PROCEDURE setn*(val: SET);
  BEGIN
    set(val); Out.Ln
  END setn;

  (* Double quote - " *)
  PROCEDURE dq*;
  BEGIN
    Out.Char(22X)
  END dq;

  PROCEDURE dqn*;
  BEGIN
    Out.Char(22X); Out.Ln
  END dqn;

  PROCEDURE n*;
  BEGIN
    Out.Ln
  END n;

BEGIN
  Out.Open
END log.
