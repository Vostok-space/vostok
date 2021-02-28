(*  Wrapper for modules with localized error messages in syntax and semantic.
 *  Extracted from Message module.
 *
 *  Copyright (C) 2018-2019,2021 ComdivByZero
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
MODULE MessageErrOberon;

IMPORT
	InterfaceLang, Out, Strings := StringStore,
	Uk := MessageErrOberonUk,
	Ru := MessageErrOberonRu,
	En := MessageErrOberonEn;

PROCEDURE Str(s: Strings.String);
VAR i: INTEGER; buf: ARRAY 256 OF CHAR;
BEGIN
	i := 0;
	IF Strings.CopyToChars(buf, i, s) THEN
		Out.String(buf)
	ELSE
		Out.String("...")
	END
END Str;

PROCEDURE Ast*(code: INTEGER; str: Strings.String);
BEGIN
	CASE InterfaceLang.lang OF
	  InterfaceLang.En: En.Ast(code)
	| InterfaceLang.Ru: Ru.Ast(code)
	| InterfaceLang.Uk: Uk.Ast(code)
	END;
	IF Strings.IsDefined(str) THEN
		Str(str)
	END
END Ast;

PROCEDURE Syntax*(code: INTEGER);
BEGIN
	CASE InterfaceLang.lang OF
	  InterfaceLang.En: En.Syntax(code)
	| InterfaceLang.Ru: Ru.Syntax(code)
	| InterfaceLang.Uk: Uk.Syntax(code)
	END
END Syntax;

PROCEDURE Text*(str: ARRAY OF CHAR);
BEGIN
	CASE InterfaceLang.lang OF
	  InterfaceLang.En: En.Text(str)
	| InterfaceLang.Ru: Ru.Text(str)
	| InterfaceLang.Uk: Uk.Text(str)
	END
END Text;

PROCEDURE Ln*;
BEGIN
	Out.Ln
END Ln;

END MessageErrOberon.
