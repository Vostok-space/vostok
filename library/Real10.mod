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

 IMPORT MathPower10, Real64, Real64Pack10, Limits := TypesLimits;

 (* x' := x / 10**e'; e' := round(lg(x)); 1.0 ≤ x' < 10.0 *)
 PROCEDURE Unpk*(VAR x: REAL; VAR e: INTEGER);
 VAR e10, e2, de: INTEGER; tx, xx, tens: REAL; pos: BOOLEAN;
 BEGIN
  tx := x;
  pos := tx >= 0.0;
  tx := ABS(tx);
  xx := tx;

  UNPK(tx, e2);
  e10 := ABS(e2) * 1233 DIV 4096;(*  *lg10(2) *)
  de := e10 - 308;
  IF de > 0 THEN e10 := 308 END;
  tens := MathPower10.Calc(e10);
  IF e2 < 0 THEN
    xx := xx * tens;
    IF de > 0 THEN
      xx := xx * MathPower10.Calc(de);
      INC(e10, de)
    END;
    WHILE xx < 1.0 DO
      INC(e10);
      xx := xx * 10.0
    END;
    e10 := -e10
  ELSE
    IF 10.0 <= xx THEN
      xx := xx / tens;
      WHILE 10.0 <= xx DO
        INC(e10);
        xx := xx / 10.0
      END
    ELSE
      e10 := 0
    END
  END;
  ASSERT((1.0 <= xx) & (xx < 10.0));

  e := e10;
  IF pos THEN x := xx ELSE x := -xx END
 END Unpk;

 (* x' := x * 10**e; ABS(e) ≤ TypesLimits.RealScaleMax - TypesLimits.RealScaleMin *)
 PROCEDURE Pack*(VAR x: REAL; e: INTEGER);
 VAR x64: Real64.T; overflow: BOOLEAN;
 BEGIN
  Real64.From(x64, x);
  Real64Pack10.Do(x64, e);
  overflow := ~Real64.To(x, x64);
  ASSERT(~overflow);
 END Pack;

END Real10.
