(*  Wrapper for modules with localized messages for interface
 *  Copyright (C) 2018 ComdivByZero
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
MODULE Message;

IMPORT Env := OsEnv, Platform, LocaleParser,
       MessageUa, MessageRu, MessageEn, Out;

CONST
	En = 0;
	Ru = 1;
	Ua = 2;

VAR lang: INTEGER;

PROCEDURE AstError*(code: INTEGER);
BEGIN
	CASE lang OF
	  En: MessageEn.AstError(code)
	| Ru: MessageRu.AstError(code)
	| Ua: MessageUa.AstError(code)
	END
END AstError;

PROCEDURE ParseError*(code: INTEGER);
BEGIN
	CASE lang OF
	  En: MessageEn.ParseError(code)
	| Ru: MessageRu.ParseError(code)
	| Ua: MessageUa.ParseError(code)
	END
END ParseError;

PROCEDURE Usage*(full: BOOLEAN);
BEGIN
	CASE lang OF
	  En: MessageEn.Usage(full)
	| Ru: MessageRu.Usage(full)
	| Ua: MessageUa.Usage(full)
	END
END Usage;

PROCEDURE CliError*(err: INTEGER);
BEGIN
	CASE lang OF
	  En: MessageEn.CliError(err)
	| Ru: MessageRu.CliError(err)
	| Ua: MessageUa.CliError(err)
	END
END CliError;

PROCEDURE Text*(str: ARRAY OF CHAR);
BEGIN
	CASE lang OF
	  En: MessageEn.Text(str)
	| Ru: MessageRu.Text(str)
	| Ua: MessageUa.Text(str)
	END
END Text;

PROCEDURE InitLang;
VAR env: ARRAY 16 OF CHAR;
    ofs: INTEGER;
    lng, state: ARRAY 2 OF CHAR;
    enc: ARRAY 5 OF CHAR;
BEGIN
	ofs := 0;
	IF ~(  Platform.Posix & Env.Get(env, ofs, "LANG")
	     & LocaleParser.Parse(env, lng, state, enc) & (enc = "UTF-8")  )
	THEN
		lang := En
	ELSIF lng = "ru" THEN
		lang := Ru
	ELSIF lng = "uk" THEN
		lang := Ua
	ELSE
		lang := En
	END
END InitLang;

PROCEDURE Ln*;
BEGIN
  Out.Ln
END Ln;

BEGIN
	InitLang
END Message.
