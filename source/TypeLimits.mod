(*  Oberon-07 types limits
 *  Copyright (C) 2016-2017 ComdivByZero
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
MODULE TypeLimits;

CONST
	IntegerMax* = 7FFFFFFFH;
	(* минимальное значение отброшено как усложняющее жизнь и для использования
	   в качестве имитации недопустимого значения *)
	IntegerMin* = -IntegerMax;
	CharMax* = 0FFX;
	ByteMax* = 0FFH;

	SetMax* = 31;

PROCEDURE IsNan*(r: REAL): BOOLEAN;
	RETURN r # r
END IsNan;

PROCEDURE InByteRange*(v: INTEGER): BOOLEAN;
	RETURN (0 <= v) & (v <= ByteMax)
END InByteRange;

PROCEDURE InCharRange*(v: INTEGER): BOOLEAN;
	RETURN (0 <= v) & (v <= ORD(CharMax))
END InCharRange;

END TypeLimits.
