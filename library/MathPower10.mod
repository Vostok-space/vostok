Power of 10.0 for integer n: 308 ≤ n ≤ 308
More fast and precise than Math.Power(10.0, n)

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

MODULE MathPower10;

 IMPORT MathPowerInt10;

 VAR p8: ARRAY 7 OF REAL; p64: ARRAY 4 OF REAL;

 PROCEDURE Nat(n: INTEGER): REAL;
 VAR p: REAL;
 BEGIN
  p := FLT(MathPowerInt10.val[n MOD 8]);
  n := n DIV 8;
  IF n > 0 THEN
    IF n MOD 8 > 0 THEN
      p := p * p8[n MOD 8 - 1]
    END;
    n := n DIV 8;
    IF n > 0 THEN
      p := p * p64[n - 1]
    END 
  END
 RETURN
  p
 END Nat;

 (* -308 ≤ n ≤ 308 *)
 PROCEDURE Calc*(n: INTEGER): REAL;
 VAR p: REAL;
 BEGIN
  ASSERT((-308 <= n) & (n <= 308));

  IF n >= 0 THEN
    p := Nat(n)
  ELSE
    p := 1.0 / Nat(-n)
  END
 RETURN
  p
 END Calc;

BEGIN
  p8[0] := 1.0E+8;
  p8[1] := 1.0E+16;
  p8[2] := 1.0E+24;
  p8[3] := 1.0E+32;
  p8[4] := 1.0E+40;
  p8[5] := 1.0E+48;
  p8[6] := 1.0E+56;

  p64[0] := 1.0E+64;
  p64[1] := 1.0E+128;
  p64[2] := 1.0E+192;
  p64[3] := 1.0E+256
END MathPower10.
