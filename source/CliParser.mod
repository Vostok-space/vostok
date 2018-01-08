(*  Command line interface for Oberon-07 translator
 *  Copyright (C) 2016-2018 ComdivByZero
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
MODULE CliParser;

IMPORT CLI, Utf8, Strings := StringStore;

CONST
	ResultC*   = 0;
	ResultBin* = 1;
	ResultRun* = 2;

	ErrNo*                   =   0;

	ErrWrongArgs*            = -10;
	ErrTooLongSourceName*    = -11;
	ErrTooLongOutName*       = -12;
	ErrOpenSource*           = -13;
	ErrOpenH*                = -14;
	ErrOpenC*                = -15;
	ErrUnknownCommand*       = -16;
	ErrNotEnoughArgs*        = -17;
	ErrTooLongModuleDirs*    = -18;
	ErrTooManyModuleDirs*    = -19;
	ErrTooLongCDirs*         = -20;
	ErrTooLongCc*            = -21;
	ErrTooLongTemp*          = -22;
	ErrCCompiler*            = -23;
	ErrTooLongRunArgs*       = -24;
	ErrUnexpectArg*          = -25;
	ErrUnknownInit*          = -26;
	ErrCantCreateOutDir*     = -27;
	ErrCantRemoveOutDir*     = -28;

PROCEDURE GetParam*(VAR str: ARRAY OF CHAR; VAR i, arg: INTEGER): BOOLEAN;
VAR ret: BOOLEAN;
    j: INTEGER;
BEGIN
	j := i;
	ret := CLI.Get(str, i, arg);
	INC(arg);
	IF ret & (str[j] = "'") & (arg < CLI.count) THEN
		str[j] := " ";
		WHILE (arg < CLI.count) & ret & (str[i - 2] # "'") DO
			str[i - 1] := " ";
			ret := CLI.Get(str, i, arg);
			INC(arg)
		END;
		str[i - 2] := Utf8.Null
	END;
	i := j + Strings.TrimChars(str, j) + 1
	RETURN ret
END GetParam;

END CliParser.
