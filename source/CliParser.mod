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
	CmdHelp*       = 1;
	(* TODO переименовать *)
	ResultC*       = 2;
	ResultBin*     = 3;
	ResultRun*     = 4;

	ResultJava*    = 5;
	ResultClass*   = 6;
	ResultRunJava* = 7;

	ThroughC*    = {ResultC, ResultBin, ResultRun};
	ThroughJava* = {ResultJava, ResultClass, ResultRunJava};

	CyrillicNo*       = 0;
	CyrillicDefault*  = 1;
	CyrillicSame*     = 2;
	CyrillicTranslit* = 3;
	CyrillicEscape*   = 4;

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
	ErrUnknownMemMan*        = -27;
	ErrCantCreateOutDir*     = -28;
	ErrCantRemoveOutDir*     = -29;
	ErrCantFoundCCompiler*   = -30;
	ErrJavaCompiler*         = -31;
	ErrCantFoundJavaCompiler*= -32;
	ErrTooLongJavaDirs*      = -33;

	ErrOpenJava*         = -40;

TYPE
	Args* = RECORD(V.Base)
		src*   : ARRAY 65536 OF CHAR;
		srcLen*: INTEGER;
		script*: BOOLEAN;
		outC*, resPath*, tmp*: ARRAY 1024 OF CHAR;
		resPathLen*, srcNameEnd*: INTEGER;
		modPath*, cDirs*, cc*, javaDirs*, javac*: ARRAY 4096 OF CHAR;
		modPathLen*: INTEGER;
		sing*: SET;
		init*, memng*, arg*: INTEGER;
		noNilCheck*, noOverflowCheck*, noIndexCheck*: BOOLEAN;
		cyrillic*: INTEGER
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
		WHILE (arg < CLI.count) & ret & (str[i - 1] # "'") DO
			str[i] := " ";
			INC(i);
			ret := CLI.Get(str, i, arg);
			INC(arg)
		END;
		str[i - 1] := Utf8.Null
	END;
	i := j + Strings.TrimChars(str, j)
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

PROCEDURE Options*(VAR args: Args; VAR arg: INTEGER): INTEGER;
VAR i, dirsOfs, javaDirsOfs, ccLen, javacLen, count, optLen: INTEGER;
    ret: INTEGER;
    opt: ARRAY 256 OF CHAR;

	PROCEDURE CopyInfrPart(VAR str: ARRAY OF CHAR; VAR i, arg: INTEGER;
	                       add: ARRAY OF CHAR): BOOLEAN;
	VAR ret: BOOLEAN;
	BEGIN
		ret := CLI.Get(str, i, arg) & Strings.CopyCharsNull(str, i, add);
		IF ret THEN
			INC(i);
			str[i] := Utf8.Null
		END
		RETURN ret
	END CopyInfrPart;
BEGIN
	i := 0;
	dirsOfs := 0;
	javaDirsOfs := 0;
	ccLen := 0;
	javacLen := 0;
	count := 0;
	ret := ErrNo;
	optLen := 0;
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
				INC(i);
				args.modPath[i] := Utf8.Null;
				INC(count)
			ELSE
				ret := ErrTooLongModuleDirs
			END
		ELSIF opt = "-c" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF CLI.Get(args.cDirs, dirsOfs, arg) & (dirsOfs < LEN(args.cDirs) - 1)
			THEN
				INC(dirsOfs);
				args.cDirs[dirsOfs] := Utf8.Null;
				Log.Str("cDirs = ");
				Log.StrLn(args.cDirs)
			ELSE
				ret := ErrTooLongCDirs
			END
		ELSIF opt = "-j" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF CLI.Get(args.javaDirs, javaDirsOfs, arg) & (javaDirsOfs < LEN(args.cDirs) - 1)
			THEN
				INC(javaDirsOfs);
				args.cDirs[javaDirsOfs] := Utf8.Null;
				Log.Str("javaDirs = ");
				Log.StrLn(args.javaDirs)
			ELSE
				ret := ErrTooLongJavaDirs
			END
		ELSIF opt = "-cc" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF GetParam(args.cc, ccLen, arg) THEN
				DEC(arg)
			ELSE
				ret := ErrTooLongCc
			END
		ELSIF opt = "-javac" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF GetParam(args.javac, javacLen, arg) THEN
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
			    & CopyInfrPart(args.javaDirs, javaDirsOfs, arg, "/singularity/implementation.java")
			   OR Platform.Windows
			    & CopyInfrPart(args.modPath, i, arg, "\singularity\definition")
			    & CopyInfrPart(args.modPath, i, arg, "\library")
			    & CopyInfrPart(args.cDirs, dirsOfs, arg, "\singularity\implementation")
			    & CopyInfrPart(args.javaDirs, javaDirsOfs, arg, "\singularity\implementation.java")
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
			ELSIF opt = "noinit" THEN
				args.init := GeneratorC.VarInitNo
			ELSIF opt = "undef" THEN
				args.init := GeneratorC.VarInitUndefined
			ELSIF opt = "zero" THEN
				args.init := GeneratorC.VarInitZero
			ELSE
				ret := ErrUnknownInit
			END;
			optLen := 0
		ELSIF opt = "-memng" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := ErrNotEnoughArgs
			ELSIF ~CLI.Get(opt, optLen, arg) THEN
				ret := ErrUnknownMemMan
			ELSIF opt = "nofree" THEN
				args.memng := GeneratorC.MemManagerNoFree
			ELSIF opt = "counter" THEN
				args.memng := GeneratorC.MemManagerCounter
			ELSIF opt = "gc" THEN
				args.memng := GeneratorC.MemManagerGC
			ELSE
				ret := ErrUnknownMemMan
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
		ELSIF opt = "-no-array-index-check" THEN
			args.noIndexCheck := TRUE
		ELSIF opt = "-no-nil-check" THEN
			args.noNilCheck := TRUE
		ELSIF opt = "-no-arithmetic-overflow-check" THEN
			args.noOverflowCheck := TRUE
		ELSIF opt = "-cyrillic" THEN
			args.cyrillic := CyrillicDefault
		ELSIF opt = "-cyrillic-same" THEN
			args.cyrillic := CyrillicSame
		ELSIF opt = "-cyrillic-translit" THEN
			args.cyrillic := CyrillicTranslit
		ELSIF opt = "-cyrillic-escape" THEN
			args.cyrillic := CyrillicEscape
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
END Options;

(* TODO убрать экспорт *)
PROCEDURE ArgsInit*(VAR args: Args);
BEGIN
	V.Init(args);

	args.srcLen   := 0;
	args.cDirs[0] := Utf8.Null;
	args.tmp[0]   := Utf8.Null;
	args.cc[0]    := Utf8.Null;
	args.javac[0] := Utf8.Null;
	args.sing     := {};
	args.init     := -1;
	args.memng    := -1;
	args.noNilCheck      := FALSE;
	args.noOverflowCheck := FALSE;
	args.noIndexCheck    := FALSE;
	args.cyrillic        := CyrillicNo;
END ArgsInit;

PROCEDURE ParseCommand*(cyr: BOOLEAN; src: ARRAY OF CHAR; VAR script: BOOLEAN)
                       : INTEGER;
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
		   OR cyr & (80X <= src[j])
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

PROCEDURE ParseOptions(VAR args: Args; ret: INTEGER; VAR arg: INTEGER): INTEGER;
VAR argDest, cpRet: INTEGER;
    forRun: BOOLEAN;
BEGIN
	argDest := arg;
	INC(args.srcLen);

	forRun := ret IN {ResultRun, ResultRunJava};
	arg := arg + ORD(~forRun);
	cpRet := Options(args, arg);
	IF cpRet # ErrNo THEN
		ret := cpRet
	ELSE
		args.srcNameEnd :=
			ParseCommand(args.cyrillic # CyrillicNo, args.src, args.script);

		args.resPathLen := 0;
		args.resPath[0] := Utf8.Null;
		IF ~forRun & ~CLI.Get(args.resPath, args.resPathLen, argDest) THEN
			ret := ErrTooLongOutName
		END
	END
	RETURN ret
END ParseOptions;

PROCEDURE Command(VAR args: Args; ret: INTEGER): INTEGER;
VAR arg: INTEGER;
BEGIN
	ASSERT(ret IN {ResultC .. ResultRunJava});

	ArgsInit(args);

	arg := 1;
	IF CLI.count <= arg THEN
		ret := ErrNotEnoughArgs
	ELSIF ~GetParam(args.src, args.srcLen, arg) THEN
		(* TODO *)
		ret := ErrTooLongSourceName
	ELSE
		ret := ParseOptions(args, ret, arg)
	END;
	args.arg := arg
	RETURN ret
END Command;

PROCEDURE Parse*(VAR args: Args; VAR ret: INTEGER): BOOLEAN;
VAR cmdLen: INTEGER; cmd: ARRAY 16 OF CHAR;
BEGIN
	cmdLen := 0;
	IF (CLI.count <= 0) OR ~CLI.Get(cmd, cmdLen, 0) THEN
		ret := ErrWrongArgs
	ELSIF cmd = "help" THEN
		ret := CmdHelp
	ELSIF cmd = "to-c" THEN
		ret := Command(args, ResultC)
	ELSIF cmd = "to-bin" THEN
		ret := Command(args, ResultBin)
	ELSIF cmd = "run" THEN
		ret := Command(args, ResultRun)
	ELSIF cmd = "to-java" THEN
		ret := Command(args, ResultJava)
	ELSIF cmd = "to-class" THEN
		ret := Command(args, ResultClass)
	ELSIF cmd = "run-java" THEN
		ret := Command(args, ResultRunJava)
	ELSE
		ret := ErrUnknownCommand
	END
	RETURN 0 <= ret
END Parse;

END CliParser.
