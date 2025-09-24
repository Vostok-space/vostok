(* Copyright 2016-2018,2025 ComdivByZero
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

(* Oberon-07 types limits / Численные границы стандартных типов Oberon-07 *)
MODULE TypesLimits;

CONST
	IntegerMax* = 7FFFFFFFH;
	(* минимальное значение в дополнительном коде (-1 - IntegerMax) не входит
	   в основной диапазон для упрощения работы с целыми числами без
	   необходимости учёта особого отрицательного значения, а также для
	   использования в качестве недопустимого значения *)
	IntegerMin* = -IntegerMax;

	CharMax* = 0FFX;

	ByteMax* = 0FFH;

	SetMax* = 31;

	RealScaleMax* = 308;
	RealScaleMin* = -324;
	RealExp10Max* = 1.0E308;
	RealExp10Min* = 1.0E-324;

PROCEDURE InByteRange*(v: INTEGER): BOOLEAN;
	RETURN (0 <= v) & (v <= ByteMax)
END InByteRange;

PROCEDURE InCharRange*(v: INTEGER): BOOLEAN;
	RETURN (0 <= v) & (v <= ORD(CharMax))
END InCharRange;

PROCEDURE InSetRange*(v: INTEGER): BOOLEAN;
	RETURN (0 <= v) & (v <= SetMax)
END InSetRange;

PROCEDURE InScaleRange*(v: INTEGER): BOOLEAN;
	RETURN (RealScaleMin <= v) & (v <= RealScaleMax)
END InScaleRange;

END TypesLimits.
