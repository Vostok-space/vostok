(* Deprecated module. Use HexDigit instead
 *
 * Copyright 2025 ComdivByZero
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
MODULE Hex;

IMPORT HexDigit;

CONST
  Range* = HexDigit.Range;

  PROCEDURE To*(d: INTEGER): CHAR;
  RETURN
    HexDigit.From(d)
  END To;

  PROCEDURE InRange*(ch: CHAR): BOOLEAN;
  RETURN
    HexDigit.Is(ch)
  END InRange;

  PROCEDURE InRangeWithLowCase*(ch: CHAR): BOOLEAN;
  RETURN
    HexDigit.WithLowCaseIs(ch)
  END InRangeWithLowCase;

  PROCEDURE From*(d: CHAR): INTEGER;
  RETURN
    HexDigit.ToInt(d)
  END From;

  PROCEDURE FromWithLowCase*(d: CHAR): INTEGER;
  RETURN
    HexDigit.WithLowCaseToInt(d)
  END FromWithLowCase;

END Hex.
