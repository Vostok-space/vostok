(*  English messages for interface
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

IMPORT Env := OsEnv, Platform, Ru := MessageRu, En := MessageEn;

VAR ru: BOOLEAN;

PROCEDURE AstError*(code: INTEGER);
BEGIN
	IF ru THEN
		Ru.AstError(code)
	ELSE
		En.AstError(code)
	END
END AstError;

PROCEDURE ParseError*(code: INTEGER);
BEGIN
	IF ru THEN
		Ru.ParseError(code)
	ELSE
		En.ParseError(code)
	END
END ParseError;

PROCEDURE Usage*(full: BOOLEAN);
BEGIN
	IF ru THEN
		Ru.Usage(full)
	ELSE
		En.Usage(full)
	END
END Usage;

PROCEDURE CliError*(err: INTEGER; cmd: ARRAY OF CHAR);
BEGIN
	IF ru THEN
		Ru.CliError(err, cmd)
	ELSE
		En.CliError(err, cmd)
	END
END CliError;

PROCEDURE Text*(str: ARRAY OF CHAR);
BEGIN
	IF ru THEN
		Ru.Text(str)
	ELSE
		En.Text(str)
	END
END Text;

PROCEDURE InitLang;
VAR lang: ARRAY 16 OF CHAR;
    ofs: INTEGER;
BEGIN
	ofs := 0;
	ru := Platform.Posix & Env.Get(lang, ofs, "LANG") & (lang = "ru_RU.UTF-8")
END InitLang;

BEGIN
	InitLang
END Message.
