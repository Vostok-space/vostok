(* Copyright 2016, 2018 ComdivByZero
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

(* Arithmetic operations with checks on overflow and natural divisor.
 *
 * Арифметические операции на целыми числами с контролем корректности входных
 * данных. Проверяется возможность переполнения для сложения, вычитания и
 * умножения, а для деления допускается только положительный делитель.
 * Каждая функция возвращает TRUE только в случае успешной проверки
 * корректности, и только в этом случае производит вычисление результата
 * действия.
 *)
MODULE CheckIntArithmetic;

IMPORT TypesLimits;

CONST
	Min = TypesLimits.IntegerMin;
	Max = TypesLimits.IntegerMax;

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

PROCEDURE Div*(VAR frac: INTEGER; n, d: INTEGER): BOOLEAN;
BEGIN
	IF     0 < d THEN frac := n DIV d END
	RETURN 0 < d
END Div;

PROCEDURE Mod*(VAR mod: INTEGER; n, d: INTEGER): BOOLEAN;
BEGIN
	IF     0 < d THEN mod := n MOD d END
	RETURN 0 < d
END Mod;

PROCEDURE DivMod*(VAR frac, mod: INTEGER; n, d: INTEGER): BOOLEAN;
BEGIN
	IF     0 < d THEN
		frac := n DIV d;
		mod  := n MOD d
	END
	RETURN 0 < d
END DivMod;

END CheckIntArithmetic.
