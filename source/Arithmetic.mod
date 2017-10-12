(*  Arithmetic operations with overflow check
 *  Copyright (C) 2016 ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)
MODULE Arithmetic;

IMPORT Limits;

CONST
	Min = Limits.IntegerMin;
	Max = Limits.IntegerMax;

PROCEDURE Add*(VAR sum: INTEGER; a1, a2: INTEGER): BOOLEAN;
VAR norm: BOOLEAN;
BEGIN
	IF a2 > 0
	THEN   norm := a1 <= Max - a2
	ELSE   norm := a1 >= Min - a2
	END;
	IF     norm THEN sum := a1 + a2 END
	RETURN norm
END Add;

PROCEDURE Sub*(VAR diff: INTEGER; m, s: INTEGER): BOOLEAN;
VAR norm: BOOLEAN;
BEGIN
	IF s > 0
	THEN   norm := m >= Min + s
	ELSE   norm := m <= Max + s
	END;
	IF     norm THEN diff := m - s END
	RETURN norm
END Sub;

PROCEDURE Mul*(VAR prod: INTEGER; m1, m2: INTEGER): BOOLEAN;
VAR norm: BOOLEAN;
BEGIN
	       norm := (m2 = 0) OR (ABS(m1) <= Max DIV ABS(m2));
	IF     norm THEN prod := m1 * m2 END
	RETURN norm
END Mul;

(* Для полноты картины *)
PROCEDURE Div*(VAR frac: INTEGER; n, d: INTEGER): BOOLEAN;
BEGIN
	IF     d # 0 THEN frac := n DIV d END
	RETURN d # 0
END Div;

PROCEDURE Mod*(VAR mod: INTEGER; n, d: INTEGER): BOOLEAN;
BEGIN
	IF     d # 0 THEN mod := n MOD d END
	RETURN d # 0
END Mod;

END Arithmetic.
