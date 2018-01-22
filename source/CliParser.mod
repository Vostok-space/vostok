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

IMPORT V, CLI, Utf8, Strings := StringStore, Platform, Log, GeneratorC;

CONST
	CmdHelp*   = 1;
	(* TODO переименовать *)
	ResultC*   = 2;
	ResultBin* = 3;
	ResultRun* = 4;

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
	ErrCantFoundCCompiler*   = -29;

TYPE
	Args* = RECORD(V.Base)
		src*: ARRAY 65536 OF CHAR;
		srcLen*: INTEGER;
		cmd*: ARRAY 32 OF CHAR;
		script*: BOOLEAN;
		outC*, resPath*, tmp*: ARRAY 1024 OF CHAR;
		resPathLen*, srcNameEnd*: INTEGER;
		modPath*, cDirs*, cc*: ARRAY 4096 OF CHAR;
		modPathLen*: INTEGER;
		sing*: SET;
		init*, arg*: INTEGER
	END;

PROCEDURE GetParam*(VAR str: ARRAY OF CHAR; VAR i, arg: INTEGER): BOOLEAN;
VAR ret: BOOLEAN;
    j: INTEGER;
BEGIN
	j := i;
	ret := CLI.Get(str, i, arg);
	INC(arg);
	IF ret & Platform.Windows & (str[j] = "'") & (arg < CLI.count) THEN
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

PROCEDURE IsEqualStr(str: ARRAY OF CHAR; ofs: INTEGER; sample: ARRAY OF CHAR)
                    : BOOLEAN;
VAR i: INTEGER;
BEGIN
	i := 0;
	WHILE (str[ofs] = sample[i]) & (sample[i] # Utf8.Null)
	    & (ofs < LEN(str) - 1) & (ofs < LEN(sample) - 1)
	DO
		INC(ofs);
		INC(i)
	END
	RETURN str[ofs] = sample[i]
END IsEqualStr;

PROCEDURE CopyPath(VAR args: Args; VAR arg: INTEGER): INTEGER;
VAR i, dirsOfs, ccLen, count, optLen: INTEGER;
    ret: INTEGER;
    opt: ARRAY 256 OF CHAR;

	PROCEDURE CopyInfrPart(VAR str: ARRAY OF CHAR; VAR i, arg: INTEGER;
	                       add: ARRAY OF CHAR): BOOLEAN;
	VAR ret: BOOLEAN;
	BEGIN
		ret := CLI.Get(str, i, arg);
		IF ret THEN
			DEC(i);
			ret := Strings.CopyCharsNull(str, i, add);
			IF ret THEN
				INC(i);
				str[i] := Utf8.Null
			END;
		END
		RETURN ret
	END CopyInfrPart;
BEGIN
	i := 0;
	dirsOfs := 0;
	args.cDirs[0] := Utf8.Null;
	args.tmp[0] := Utf8.Null;
	ccLen := 0;
	count := 0;
	args.sing := {};
	ret := ErrNo;
	optLen := 0;
	args.init := -1;
	WHILE (ret = ErrNo) & (count < 32)
	    & (arg < CLI.count) & CLI.Get(opt, optLen, arg) & ~IsEqualStr(opt, 0, "--")
	DO
		optLen := 0;
		IF (opt = "-i") OR (opt = "-m") THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF CLI.Get(args.modPath, i, arg) THEN
				IF opt = "-i" THEN
					INCL(args.sing, count)
				END;
				INC(count)
			ELSE
				ret := ErrTooLongModuleDirs
			END
		ELSIF opt = "-c" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF CLI.Get(args.cDirs, dirsOfs, arg) & (dirsOfs < LEN(args.cDirs))
			THEN
				args.cDirs[dirsOfs] := Utf8.Null;
				Log.Str("cDirs = ");
				Log.StrLn(args.cDirs)
			ELSE
				ret := ErrTooLongCDirs
			END
		ELSIF opt = "-cc" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF GetParam(args.cc, ccLen, arg) THEN
				DEC(ccLen);
				DEC(arg)
			ELSE
				ret := ErrTooLongCc
			END
		ELSIF opt = "-infr" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF Platform.Posix
			    & CopyInfrPart(args.modPath, i, arg, "/singularity/definition")
			    & CopyInfrPart(args.modPath, i, arg, "/library")
			    & CopyInfrPart(args.cDirs, dirsOfs, arg, "/singularity/implementation")
			   OR Platform.Windows
			    & CopyInfrPart(args.modPath, i, arg, "\singularity\definition")
			    & CopyInfrPart(args.modPath, i, arg, "\library")
			    & CopyInfrPart(args.cDirs, dirsOfs, arg, "\singularity\implementation")
			THEN
				INCL(args.sing, count);
				INC(count, 2)
			ELSE
				ret := ErrTooLongModuleDirs
			END
		ELSIF opt = "-init" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF ~CLI.Get(opt, optLen, arg) THEN
				ret := ErrUnknownInit
			ELSIF opt = "no" THEN
				args.init := GeneratorC.VarInitNo
			ELSIF opt = "undef" THEN
				args.init := GeneratorC.VarInitUndefined
			ELSIF opt = "zero" THEN
				args.init := GeneratorC.VarInitZero
			ELSE
				ret := ErrUnknownInit
			END;
			optLen := 0
		ELSIF opt = "-t" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF ~CLI.Get(args.tmp, optLen, arg) THEN
				ret := ErrTooLongTemp
			END;
			optLen := 0
		ELSE
			ret := ErrUnexpectArg
		END;
		INC(arg)
	END;
	IF i + 1 < LEN(args.modPath) THEN
		args.modPathLen := i + 1;
		args.modPath[i + 1] := Utf8.Null;
		IF count >= 32 THEN
			ret := ErrTooManyModuleDirs
		END;
	ELSE
		ret := ErrTooLongModuleDirs;
		args.modPath[LEN(args.modPath) - 1] := Utf8.Null;
		args.modPath[LEN(args.modPath) - 2] := Utf8.Null;
		args.modPath[LEN(args.modPath) - 3] := "#"
	END
	RETURN ret
END CopyPath;

PROCEDURE ToC(VAR args: Args; ret: INTEGER): INTEGER;
VAR arg, argDest, cpRet: INTEGER;

	PROCEDURE ParseCommand(src: ARRAY OF CHAR; VAR script: BOOLEAN): INTEGER;
	VAR i, j, k: INTEGER;

		PROCEDURE Empty(src: ARRAY OF CHAR; VAR j: INTEGER);
		BEGIN
			WHILE (src[j] = " ") OR (src[j] = Utf8.Tab) DO
				INC(j)
			END
		END Empty;
	BEGIN
		i := 0;
		WHILE (src[i] # Utf8.Null) & (src[i] # ".") DO
			INC(i)
		END;
		IF src[i] = "." THEN
			j := i + 1;
			Empty(src, j);
			WHILE ("a" <= src[j]) & (src[j] <= "z")
			   OR ("A" <= src[j]) & (src[j] <= "Z")
			   OR ("0" <= src[j]) & (src[j] <= "9")
			DO
				INC(j)
			END;
			k := j;
			Empty(src, k);
			script := src[k] # Utf8.Null
		ELSE
			script := FALSE
		END
		RETURN i
	END ParseCommand;
BEGIN
	ASSERT(ret IN {ResultC .. ResultRun});

	args.srcLen := 0;
	arg := 2;
	IF CLI.count <= arg THEN
		ret := ErrNotEnoughArgs
	ELSIF ~GetParam(args.src, args.srcLen, arg) THEN
		(* TODO *)
		ret := ErrTooLongSourceName
	ELSE
		argDest := arg;
		arg := arg + ORD(ret # ResultRun);
		cpRet := CopyPath(args, arg);
		IF cpRet # ErrNo THEN
			ret := cpRet
		ELSE
			args.srcNameEnd := ParseCommand(args.src, args.script);

			args.resPathLen := 0;
			args.resPath[0] := Utf8.Null;
			IF (ret # ResultRun)
			 & ~CLI.Get(args.resPath, args.resPathLen, argDest)
			THEN
				ret := ErrTooLongOutName
			END
		END
	END;
	args.arg := arg
	RETURN ret
END ToC;

PROCEDURE Parse*(VAR args: Args; VAR ret: INTEGER): BOOLEAN;
VAR cmdLen: INTEGER;
BEGIN
	cmdLen := 0;
	V.Init(args);
	IF (CLI.count <= 1) OR ~CLI.Get(args.cmd, cmdLen, 1) THEN
		ret := ErrWrongArgs
	ELSIF args.cmd = "help" THEN
		ret := CmdHelp
	ELSIF args.cmd = "to-c" THEN
		ret := ToC(args, ResultC);
	ELSIF args.cmd = "to-bin" THEN
		ret := ToC(args, ResultBin)
	ELSIF args.cmd = "run" THEN
		ret := ToC(args, ResultRun)
	ELSE
		ret := ErrUnknownCommand
	END
	RETURN 0 <= ret
END Parse;

END CliParser.
