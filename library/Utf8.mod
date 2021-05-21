(*  Some constants and subroutines for Utf-8/ASC II
 *
 *  Copyright (C) 2016,2020-2021 ComdivByZero
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

IMPORT TypesLimits;

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

TYPE
	R* = RECORD
		val*, len*: INTEGER
	END;

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

	PROCEDURE DecodeFirst(first: CHAR; VAR rest: INTEGER): INTEGER;
	VAR v, b, l: INTEGER;
	BEGIN
		v := ORD(first);
		IF v < 80H THEN
			l := 1;
			rest := v
		ELSIF v >= 0C0H THEN
			DEC(v, 0C0H);
			l := 2;
			b := 20H;
			WHILE v > b DO
				DEC(v, b);
				INC(l);
				b := b DIV 2
			END;
			IF v = b THEN
				INC(l);
				DEC(v, b)
			END;
			rest := v
		ELSE
			l := 0;
			rest := -1
		END
	RETURN
		l
	END DecodeFirst;

	PROCEDURE Len*(first: CHAR): INTEGER;
	VAR rest: INTEGER;
	RETURN
		DecodeFirst(first, rest)
	END Len;

	PROCEDURE Begin*(VAR state: R; first: CHAR): BOOLEAN;
	BEGIN
		state.len := DecodeFirst(first, state.val) - 1;
	RETURN
		state.len > 0
	END Begin;

	PROCEDURE Next*(VAR state: R; src: CHAR): BOOLEAN;
	VAR v: INTEGER;
	BEGIN
		ASSERT(state.len > 0);
		v := ORD(src);
		IF (v DIV 40H = 2) & (state.val <= TypesLimits.IntegerMax DIV 40H) THEN
			state.val := state.val * 40H + v MOD 40H;
			DEC(state.len)
		ELSE
			state.len := -state.len;
			state.val := -1 - state.val
		END
	RETURN
		state.len > 0
	END Next;

	PROCEDURE IsBegin*(ch: CHAR): BOOLEAN;
	RETURN
		ORD(ch) DIV 40H # 2
	END IsBegin;

END Utf8.
