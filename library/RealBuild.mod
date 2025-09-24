Builder of REAL value digit by digit

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

MODULE RealBuild;

 IMPORT Real := Real64, Real10, Int10 := MathPowerInt10;

 CONST DotUndef = -10000H;

 TYPE
  T* = RECORD
    digits, high, i, n, dot: INTEGER;
    valuable*: BOOLEAN
  END;

 PROCEDURE Begin*(VAR b: T);
 BEGIN
  b.i := -1;
  b.n := 1;
  b.high := 0;
  b.digits := 0;
  b.dot := DotUndef;
  b.valuable := TRUE
 END Begin;

 PROCEDURE UncheckedDigit*(VAR b: T; dec: INTEGER);
 BEGIN
  INC(b.i);
  b.digits := b.digits * 10 + dec;
  IF b.i = 8 THEN
    INC(b.n, 8);
    b.i := 0;

    b.valuable := b.high = 0;
    IF b.valuable THEN
      b.high := b.digits;
      b.digits := 0
    END
  END
 END UncheckedDigit;

 PROCEDURE Digit*(VAR b: T; dec: INTEGER);
 VAR use: BOOLEAN;
 BEGIN
  ASSERT((0 <= dec) & (dec < 10));

  use := TRUE;
  IF (dec # 0) OR (b.i # -1) THEN
      ;
  ELSIF b.dot # DotUndef THEN
    use := FALSE;
    DEC(b.dot)
  END;
  IF use & b.valuable THEN
    UncheckedDigit(b, dec)
  END
 END Digit;

 PROCEDURE UncheckedDot*(VAR b: T);
 BEGIN
  b.dot := b.i + b.n
 END UncheckedDot;

 PROCEDURE Dot*(VAR b: T);
 BEGIN
  ASSERT(b.dot = DotUndef);
  b.dot := b.i + b.n
 END Dot;
 
 PROCEDURE End*(VAR b: T; VAR v: REAL);
 VAR i, dot: INTEGER;
 BEGIN
  i := b.i + b.n;
  dot := b.dot;
  IF dot = DotUndef THEN dot := i END;

  IF i <= 9 THEN
    v := FLT(b.digits);
    Real10.Pack(v, dot - i)
  ELSIF i <= 17 THEN
    v := FLT(b.high) * FLT(Int10.val[i - 9]) + FLT(b.digits);
    Real10.Pack(v, dot - i)
  ELSE
    v := FLT(b.high) * 1.0E8 + FLT(b.digits);
    Real10.Pack(v, dot - 17)
  END
 END End;

END RealBuild.
