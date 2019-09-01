(* Utils for work with 64 bit sets, when available only 32 bit sets
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
    Max* = Limits.SetMax * 2 + 1;

  TYPE
    Type* = ARRAY 2 OF SET;

  PROCEDURE CheckRange*(int: INTEGER): BOOLEAN;
  RETURN
    (0 <= int) & (int <= Max)
  END CheckRange;

  PROCEDURE Add*(VAR s: Type; a: Type);
  BEGIN
    s[0] := s[0] + a[0];
    s[1] := s[1] + a[1]
  END Add;

  PROCEDURE Sub*(VAR s: Type; a: Type);
  BEGIN
    s[0] := s[0] - a[0];
    s[1] := s[1] - a[1]
  END Sub;

  PROCEDURE Equal*(s1, s2: Type): BOOLEAN;
  RETURN
    (s1[0] = s2[0]) & (s1[1] = s2[1])
  END Equal;

  PROCEDURE In*(i: INTEGER; s: Type): BOOLEAN;
  RETURN
    CheckRange(i) & (i MOD (Limits.SetMax + 1) IN s[i DIV (Limits.SetMax + 1)])
  END In;

  PROCEDURE Neg*(VAR s: Type);
  BEGIN
    s[0] := -s[0];
    s[1] := -s[1]
  END Neg;

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

  PROCEDURE Empty*(VAR s: Type);
  BEGIN
    s[0] := {};
    s[1] := {}
  END Empty;

END LongSet.
