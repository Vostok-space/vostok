Simple output subroutines with short names

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

MODULE log;

  IMPORT Out;

  PROCEDURE s*(str: ARRAY OF CHAR);
  BEGIN
    Out.String(str)
  END s;

  PROCEDURE sn*(str: ARRAY OF CHAR);
  BEGIN
    Out.String(str); Out.Ln
  END sn;

  PROCEDURE i*(int: INTEGER);
  BEGIN
    Out.Int(int, 0)
  END i;

  PROCEDURE in*(int: INTEGER);
  BEGIN
    Out.Int(int, 0); Out.Ln
  END in;

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

  PROCEDURE n*;
  BEGIN
    Out.Ln
  END n;

BEGIN
  Out.Open
END log.
