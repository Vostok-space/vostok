Pack and Unpk for power of 10 instead of power of 2

Copyright 2025 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE Real10;

 IMPORT MathPower10;

 (* x' = x / 10^e'; 1.0 ≤ x' < 10.0 *)
 PROCEDURE Unpk*(VAR x: REAL; VAR e: INTEGER);
 VAR e10, e2: INTEGER; tx, xx, tens: REAL;
 BEGIN
  tx := x; xx := tx;
  UNPK(tx, e2);
  e10 := ABS(e2) * 77 DIV 256;
  tens := MathPower10.Calc(e10);
  IF e2 < 0 THEN
    xx := xx * tens;
    IF xx < 1.0 THEN
      INC(e10);
      xx := xx * 10.0
    END;
    e10 := -e10
  ELSE
    IF 10.0 <= xx THEN
      xx := xx / tens;
      IF 10.0 <= xx THEN
        INC(e10);
        xx := xx / 10.0
      END
    ELSE
      e10 := 0
    END
  END;
  tx := ABS(xx);
  ASSERT((1.0 <= tx) & (tx < 10.0));

  e := e10; x := xx
 END Unpk;

 (* x' := x * 10^e *)
 PROCEDURE Pack*(VAR x: REAL; e: INTEGER);
 VAR m: REAL;
 BEGIN
  IF e > 0 THEN
    IF e > 256 THEN
      m := MathPower10.Calc(e DIV 2);
      x := (x * m) * m;
      IF ODD(e) THEN x := x * 10.0 END
    ELSE
      x := x * MathPower10.Calc(e)
    END
  ELSIF e < 0 THEN
    IF e < 256 THEN
      m := MathPower10.Calc((-e) DIV 2);
      x := (x / m) / m;
      IF ODD(e) THEN x := x / 10.0 END
    ELSE
      x := x / MathPower10.Calc(-e)
    END  
  END
 END Pack;

END Real10.
