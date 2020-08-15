(*  Some constants and subroutines for Utf-8/ASC II
 *  Copyright (C) 2016,2020 ComdivByZero
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
MODULE Utf8;

CONST
	Null*            = 00X;
	TransmissionEnd* = 04X;
	Bell*            = 07X;
	BackSpace*       = 08X;
	Tab*             = 09X;
	NewLine*         = 0AX;
	NewPage*         = 0CX;
	CarRet*          = 0DX;
	Idle*            = 16X;
	DQuote*          = 22X;
	Delete*          = 7FX;

	PROCEDURE Up*(ch: CHAR): CHAR;
	BEGIN
		IF ("a" <= ch) & (ch <= "z") THEN
			ch := CHR(ORD(ch) - (ORD("a") - ORD("A")))
		END
	RETURN
		ch
	END Up;

	PROCEDURE Down*(ch: CHAR): CHAR;
	BEGIN
		IF ("A" <= ch) & (ch <= "Z") THEN
			ch := CHR(ORD(ch) + (ORD("a") - ORD("A")))
		END
	RETURN
		ch
	END Down;

	PROCEDURE EqualIgnoreCase*(a, b: CHAR): BOOLEAN;
	VAR equal: BOOLEAN;
	BEGIN
		IF a = b THEN
			equal := TRUE
		ELSIF ("a" <= a) & (a <= "z") THEN
			equal := ORD("a") - ORD("A") = ORD(a) - ORD(b)
		ELSIF ("A" <= a) & (a <= "Z") THEN
			equal := ORD("a") - ORD("A") = ORD(b) - ORD(a)
		ELSE
			equal := FALSE
		END
	RETURN
		equal
	END EqualIgnoreCase;

END Utf8.
