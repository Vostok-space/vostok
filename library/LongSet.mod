(* Utils for work with 64 bit sets, when available only 32 bit sets
 *
 * Copyright 2019 ComdivByZero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)
MODULE LongSet;

  IMPORT Limits := TypesLimits;

  CONST
    Mod  = Limits.SetMax + 1;
    Max* = Limits.SetMax * 2 + 1;

  TYPE
    Type* = ARRAY 2 OF SET;

  PROCEDURE Empty*(VAR s: Type);
  BEGIN
    s[0] := {};
    s[1] := {}
  END Empty;

  PROCEDURE Set*(VAR s: Type; low, high: SET);
  BEGIN
    s[0] := low;
    s[1] := high
  END Set;

  PROCEDURE InRange*(i: INTEGER): BOOLEAN;
  RETURN
    (0 <= i) & (i <= Max)
  END InRange;

  PROCEDURE Incl*(VAR s: Type; i: INTEGER);
  BEGIN
    ASSERT(InRange(i));
    INCL(s[i DIV Mod], i MOD Mod)
  END Incl;

  PROCEDURE Excl*(VAR s: Type; i: INTEGER);
  BEGIN
    ASSERT(InRange(i));
    EXCL(s[i DIV Mod], i MOD Mod)
  END Excl;

  PROCEDURE Union*(VAR s: Type; a: Type);
  BEGIN
    s[0] := s[0] + a[0];
    s[1] := s[1] + a[1]
  END Union;

  PROCEDURE Diff*(VAR s: Type; a: Type);
  BEGIN
    s[0] := s[0] - a[0];
    s[1] := s[1] - a[1]
  END Diff;

  PROCEDURE Inter*(VAR s: Type; a: Type);
  BEGIN
    s[0] := s[0] * a[0];
    s[1] := s[1] * a[1];
  END Inter;

  PROCEDURE SymDiff*(VAR s: Type; a: Type);
  BEGIN
    s[0] := s[0] / a[0];
    s[1] := s[1] / a[1];
  END SymDiff;

  PROCEDURE Equal*(s1, s2: Type): BOOLEAN;
  RETURN
    (s1[0] = s2[0]) & (s1[1] = s2[1])
  END Equal;

  PROCEDURE In*(i: INTEGER; s: Type): BOOLEAN;
  RETURN
    InRange(i) & (i MOD (Limits.SetMax + 1) IN s[i DIV (Limits.SetMax + 1)])
  END In;

  PROCEDURE Not*(VAR s: Type);
  BEGIN
    s[0] := -s[0];
    s[1] := -s[1]
  END Not;

  PROCEDURE ConvertableToInt*(s: Type): BOOLEAN;
  RETURN
    ~(Limits.SetMax IN s[0]) & (s[1] = {})
  END ConvertableToInt;

  PROCEDURE Ord*(s: Type): INTEGER;
  BEGIN
    ASSERT(ConvertableToInt(s))
  RETURN
    ORD(s[0])
  END Ord;

END LongSet.
