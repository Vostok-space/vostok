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

MODULE Real64Pack10;

 IMPORT Real64, TypesLimits, MathPower10;

 PROCEDURE Do*(VAR x: Real64.T; e: INTEGER);
 VAR m: Real64.T;
 BEGIN
  ASSERT(ABS(e) <= TypesLimits.RealScaleMax - TypesLimits.RealScaleMin);

  Real64.From(m, 1.0E308);

  IF Real64.CmpReal(x, 0.0) = 0 THEN
    ;
  ELSIF e > 0 THEN
    WHILE e >= 308 DO
      DEC(e, 308);
      Real64.Mul(x, x, m)
    END;
    Real64.From(m, MathPower10.Calc(e));
    Real64.Mul(x, x, m)
  ELSIF e < 0 THEN
    WHILE e <= -308 DO
      INC(e, 308);
      Real64.Div(x, x, m)
    END;
    Real64.From(m, MathPower10.Calc(-e));
    Real64.Div(x, x, m)
  END
 END Do;

END Real64Pack10.
