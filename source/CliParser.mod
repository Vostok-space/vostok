(*  Command line interface for Oberon-07 translator
 *
 *  Copyright (C) 2016-2021 ComdivByZero
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

IMPORT V, CLI, Utf8, Strings := StringStore, Platform,
       GenOptions, GeneratorOberon, GeneratorC,
       OsUtil, Chars0X;

CONST
	CmdHelp*       = 1;
	CmdVersion*    = 11;
	(* TODO переименовать *)
	ResultC*       = 2;
	ResultBin*     = 3;
	ResultRun*     = 4;

	ResultJava*    = 5;
	ResultClass*   = 6;
	ResultJar*     = 7;
	ResultRunJava* = 8;

	ResultJs*      = 9;
	ResultRunJs*   = 10;

	ResultMod*     = 11;

	ThroughC*    = {ResultC, ResultBin, ResultRun};
	ThroughJava* = {ResultJava, ResultClass, ResultJar, ResultRunJava};
	ThroughJs*   = {ResultJs, ResultRunJs};
	ThroughMod*  = {ResultMod};
	ForRun*      = {ResultRun, ResultRunJava, ResultRunJs};

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
	ErrTooLongJsDirs*        = -34;
	ErrTooLongJarArgs*       = -35;
	ErrJarExec*              = -36;
	ErrJarGetCurrentDir*     = -37;
	ErrJarSetDirBefore*      = -38;
	ErrJarSetDirAfter*       = -39;

	(* TODO *)
	ErrOpenJava*         = -40;
	ErrOpenJs*           = -41;
	ErrOpenOberon*       = -42;

	ErrDisabledGenC*      = -50;
	ErrDisabledGenJava*   = -51;
	ErrDisabledGenJs*     = -52;
	ErrDisabledGenOberon* = -53;

TYPE
	Args* = RECORD(V.Base)
		src*   : ARRAY 65536 OF CHAR;
		srcLen*: INTEGER;
		script*, toSingleFile*: BOOLEAN;
		resPath*, tmp*: ARRAY 1024 OF CHAR;
		resPathLen*, srcNameEnd*: INTEGER;
		modPath*, cDirs*, cc*, javaDirs*, jsDirs*, javac*: ARRAY 4096 OF CHAR;
		modPathLen*: INTEGER;
		sing*: SET;
		init*, memng*, arg*, cStd*, obStd*: INTEGER;
		noNilCheck*, noOverflowCheck*, noIndexCheck*, cPlan9*: BOOLEAN;
		cyrillic*: INTEGER;

		multiErrors*: BOOLEAN
	END;

VAR dirSep: CHAR;

PROCEDURE GetParam*(VAR err: INTEGER; errTooLong: INTEGER;
                    VAR str: ARRAY OF CHAR;
                    VAR i, arg: INTEGER): BOOLEAN;
VAR j: INTEGER;
    ret: BOOLEAN;
BEGIN
	IF arg >= CLI.count THEN
		err := ErrNotEnoughArgs;
		ret := FALSE
	ELSE
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
		i := j + Chars0X.Trim(str, j);
		IF ~ret OR (i >= LEN(str) - 1) THEN
			err := errTooLong
		END
	END
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

PROCEDURE CopyInfr(VAR args: Args;
                   VAR i, dirsOfs, javaDirsOfs, jsDirsOfs, count: INTEGER;
                   base: ARRAY OF CHAR): BOOLEAN;
VAR ok: BOOLEAN;

	PROCEDURE Copy(VAR str: ARRAY OF CHAR; VAR i: INTEGER;
	               base, add: ARRAY OF CHAR): BOOLEAN;
	VAR ret: BOOLEAN;
	BEGIN
		ret := Chars0X.CopyString(str, i, base)
		     & Chars0X.CopyString(str, i, add);
		IF ret THEN
			INC(i);
			str[i] := Utf8.Null
		END
		RETURN ret
	END Copy;
BEGIN
	IF Platform.Posix THEN
		ok := Copy(args.modPath, i, base, "/singularity/definition")
		    & Copy(args.modPath, i, base, "/library")
		    & Copy(args.cDirs, dirsOfs, base, "/singularity/implementation")
		    & Copy(args.javaDirs, javaDirsOfs, base, "/singularity/implementation.java")
		    & Copy(args.jsDirs, jsDirsOfs, base, "/singularity/implementation.js")
	ELSIF Platform.Windows THEN
		ok := Copy(args.modPath, i, base, "\singularity\definition")
		    & Copy(args.modPath, i, base, "\library")
		    & Copy(args.cDirs, dirsOfs, base, "\singularity\implementation")
		    & Copy(args.javaDirs, javaDirsOfs, base, "\singularity\implementation.java")
		    & Copy(args.jsDirs, jsDirsOfs, base, "\singularity\implementation.js")
	ELSE
		(* TODO сообщение об ошибке *)
		ok := FALSE
	END;
	IF ok THEN
		INCL(args.sing, count);
		INC(count, 2)
	END
	RETURN ok
END CopyInfr;

PROCEDURE ReadNearInfr(VAR infr: ARRAY OF CHAR): BOOLEAN;
VAR i, len: INTEGER; ok: BOOLEAN;
BEGIN
	ok := Platform.Posix
	    & OsUtil.PathToSelfExe(infr, len) & (len < LEN(infr));
	IF ok THEN
		i := 2;
		WHILE (len >= 0) & (i > 0) DO
			DEC(len);
			IF infr[len] = dirSep THEN
				DEC(i)
			END
		END;
		INC(len);
		ok := (i = 0) & Chars0X.CopyString(infr, len, "share/vostok")
	END
	RETURN ok
END ReadNearInfr;

PROCEDURE Options*(VAR args: Args; VAR arg: INTEGER): INTEGER;
VAR i, dirsOfs, javaDirsOfs, jsDirsOfs, ccLen, javacLen, count, optLen: INTEGER;
    ret: INTEGER;
    opt: ARRAY 256 OF CHAR;
    ignore: BOOLEAN;
BEGIN
	i := 0;
	dirsOfs := 0;
	javaDirsOfs := 0;
	jsDirsOfs := 0;
	ccLen := 0;
	javacLen := 0;
	count := 0;
	ret := ErrNo;
	optLen := 0;
	WHILE (ret = ErrNo) & (count < 32)
	    & (arg < CLI.count) & CLI.Get(opt, optLen, arg) & ~IsEqualStr(opt, 0, "--")
	DO
		optLen := 0;
		INC(arg);
		IF (opt = "-i") OR (opt = "-m") THEN
			IF GetParam(ret, ErrTooLongModuleDirs, args.modPath, i, arg) THEN
				IF opt = "-i" THEN
					INCL(args.sing, count)
				END;
				INC(i);
				args.modPath[i] := Utf8.Null;
				INC(count)
			END
		ELSIF opt = "-c" THEN
			IF GetParam(ret, ErrTooLongCDirs, args.cDirs, dirsOfs, arg) THEN
				INC(dirsOfs);
				args.cDirs[dirsOfs] := Utf8.Null
			END
		ELSIF opt = "-jv" THEN
			IF GetParam(ret, ErrTooLongJavaDirs, args.javaDirs, javaDirsOfs, arg) THEN
				INC(javaDirsOfs);
				args.javaDirs[javaDirsOfs] := Utf8.Null
			END
		ELSIF opt = "-js" THEN
			IF GetParam(ret, ErrTooLongJsDirs, args.jsDirs, jsDirsOfs, arg) THEN
				INC(jsDirsOfs);
				args.jsDirs[jsDirsOfs] := Utf8.Null
			END
		ELSIF opt = "-cc" THEN
			IF GetParam(ret, ErrTooLongCc, args.cc, ccLen, arg)
			 & (arg < CLI.count) & CLI.Get(opt, optLen, arg) & (opt = "...")
			THEN
				optLen := 0;
				INC(arg);
				INC(ccLen);
				ignore := GetParam(ret, ErrTooLongCc, args.cc, ccLen, arg)
			ELSIF ccLen < LEN(args.cc) - 1 THEN
				args.cc[ccLen + 1] := Utf8.Null
			END
		ELSIF opt = "-javac" THEN
			ignore := GetParam(ret, ErrTooLongCc, args.javac, javacLen, arg)
		ELSIF opt = "-infr" THEN
			IF GetParam(ret, ErrTooLongModuleDirs, opt, optLen, arg)
			 & ~CopyInfr(args,
			             i, dirsOfs, javaDirsOfs, jsDirsOfs, count,
			             opt)
			THEN
				ret := ErrTooLongModuleDirs
			END
		ELSIF opt = "-init" THEN
			IF ~GetParam(ret, ErrUnknownInit, opt, optLen, arg) THEN
				;
			ELSIF opt = "noinit" THEN
				args.init := GenOptions.VarInitNo
			ELSIF opt = "undef" THEN
				args.init := GenOptions.VarInitUndefined
			ELSIF opt = "zero" THEN
				args.init := GenOptions.VarInitZero
			ELSE
				ret := ErrUnknownInit
			END
		ELSIF opt = "-memng" THEN
			IF ~GetParam(ret, ErrUnknownMemMan, opt, optLen, arg) THEN
				;
			ELSIF opt = "nofree" THEN
				args.memng := GeneratorC.MemManagerNoFree
			ELSIF opt = "counter" THEN
				args.memng := GeneratorC.MemManagerCounter
			ELSIF opt = "gc" THEN
				args.memng := GeneratorC.MemManagerGC
			ELSE
				ret := ErrUnknownMemMan
			END
		ELSIF opt = "-t" THEN
			ignore := GetParam(ret, ErrTooLongTemp, args.tmp, optLen, arg)
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
		ELSIF opt = "-C90" THEN
			args.cStd := GeneratorC.IsoC90
		ELSIF opt = "-C99" THEN
			args.cStd := GeneratorC.IsoC99
		ELSIF opt = "-C11" THEN
			args.cStd := GeneratorC.IsoC11
		ELSIF opt = "-plan9" THEN
			args.cPlan9 := TRUE
		ELSIF opt = "-out:O7" THEN
			args.obStd := GeneratorOberon.StdO7
		ELSIF opt = "-out:AO" THEN
			args.obStd := GeneratorOberon.StdAo
		ELSIF opt = "-out:CP" THEN
			args.obStd := GeneratorOberon.StdCp
		ELSIF opt = "-multi-errors" THEN
			args.multiErrors := TRUE
		ELSE
			ret := ErrUnexpectArg
		END;
		optLen := 0
	END;
	IF (ret = ErrNo) & ReadNearInfr(opt)
	 & ~CopyInfr(args,
	             i, dirsOfs, javaDirsOfs, jsDirsOfs, count,
	             opt)
	THEN
		ret := ErrTooLongModuleDirs
	END;
	IF ret # ErrNo THEN
		;
	ELSIF i + 1 < LEN(args.modPath) THEN
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
	args.cDirs    := "";
	args.tmp      := "";
	args.cc       := "";
	args.cc[1]    := Utf8.Null;
	args.javac    := "";
	args.sing     := {};
	args.init     := -1;
	args.memng    := -1;
	args.cStd     := -1;
	args.cPlan9   := FALSE;
	args.obStd    := -1;
	args.noNilCheck      := FALSE;
	args.noOverflowCheck := FALSE;
	args.noIndexCheck    := FALSE;
	args.cyrillic        := CyrillicNo;
	args.toSingleFile    := FALSE;
	args.multiErrors     := FALSE
END ArgsInit;

PROCEDURE IsEndByShortExt(name: ARRAY OF CHAR; VAR dot, sep: INTEGER): BOOLEAN;
VAR i: INTEGER;
BEGIN
	i   := 0;
	dot := -988;
	sep := -977;
	WHILE name[i] # Utf8.Null DO
		IF name[i] = "." THEN
			dot := i
		ELSIF (name[i] = "/") OR (name[i] = "\") THEN
			sep := i
		END;
		INC(i)
	END
	RETURN (dot > sep) & (i - dot <= 4)
END IsEndByShortExt;

PROCEDURE ArgsForRunFile*(VAR args: Args; VAR ret: INTEGER): BOOLEAN;
VAR i, arg, dot, sep, methodLen: INTEGER;
    file: ARRAY 256 OF CHAR;
    method: ARRAY 64 OF CHAR;

	PROCEDURE Parse(VAR args: Args; VAR ret: INTEGER;
	                file: ARRAY OF CHAR; dot, sep: INTEGER;
	                method: ARRAY OF CHAR);
	VAR i, j, dirsOfs, javaDirsOfs, jsDirsOfs, count: INTEGER;
	    infr: ARRAY 256 OF CHAR;
	BEGIN
		dirsOfs := 0;
		javaDirsOfs := 0;
		jsDirsOfs := 0;
		count := 0;

		i := 0;
		IF sep >= 0 THEN
			j := 0;
			IF Chars0X.CopyChars(args.modPath, i, file, j, sep + 1) THEN
				args.modPathLen := i + 1;
				args.modPath[i + 1] := Utf8.Null;
				args.modPath[i + 2] := Utf8.Null;
				INC(count)
			ELSE
				ret := ErrTooLongModuleDirs
			END
		ELSE
			args.modPathLen := 1;
			args.modPath[0] := ".";
			args.modPath[1] := Utf8.Null;
			args.modPath[2] := Utf8.Null;
			INC(count)
		END;
		args.srcNameEnd := 0;
		ASSERT(Chars0X.CopyChars(args.src, args.srcNameEnd, file, i, dot));
		args.srcLen := args.srcNameEnd;
		IF method # "" THEN
			ASSERT(Chars0X.CopyString(args.src, args.srcLen, method));
			INC(args.srcLen)
		END;
		IF (ret = ErrNo)
		 & (   ReadNearInfr(infr)
		    & ~CopyInfr(args,
		                args.modPathLen, dirsOfs, javaDirsOfs, jsDirsOfs, count,
		                infr)
		   )
		THEN
			ret := ErrTooLongModuleDirs
		END
	END Parse;
BEGIN
	ArgsInit(args);
	args.script := FALSE;

	i := 0;
	arg := 0;
	ret := ErrNo;
	IF GetParam(ret, ErrTooLongSourceName, file, i, arg) THEN
		IF (file[0] = ".") & (file[1] # "/") THEN
			methodLen := 0;
			IF ~Chars0X.CopyString(method, methodLen, file) THEN
				(* TODO *)
				ret := ErrTooLongSourceName
			ELSE
				i := 0;
				IF GetParam(ret, ErrTooLongSourceName, file, i, arg)
				 & (   (method[1] # 0X)
				    OR GetParam(ret, ErrTooLongSourceName, method, methodLen, arg)
				   )
				THEN
					;
				END
			END
		ELSE
			method[0] := 0X
		END;
		IF ret # ErrNo THEN
			;
		ELSIF ~IsEndByShortExt(file, dot, sep) THEN
			(* TODO *)
			ret := ErrWrongArgs
		ELSE
			Parse(args, ret, file, dot, sep, method)
		END
	END;
	IF ret = ErrNo THEN
		ret := ResultRun;
		args.arg := arg
	END
	RETURN ret = ResultRun
END ArgsForRunFile;

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
	IF i = 0 THEN
		script := TRUE
	ELSIF src[i] = "." THEN
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
VAR argDest, cpRet, dot, sep: INTEGER;
    forRun: BOOLEAN;
BEGIN
	argDest := arg;
	INC(args.srcLen);

	forRun := ret IN ForRun;
	arg := arg + ORD(~forRun);
	cpRet := Options(args, arg);
	IF cpRet # ErrNo THEN
		ret := cpRet
	ELSE
		args.srcNameEnd :=
			ParseCommand(args.cyrillic # CyrillicNo, args.src, args.script);

		args.resPathLen := 0;
		args.resPath := "";
		IF forRun THEN
			;
		ELSIF GetParam(cpRet, ErrTooLongOutName,
		               args.resPath, args.resPathLen, argDest)
		THEN
			args.toSingleFile := IsEndByShortExt(args.resPath, dot, sep)
		ELSE
			ret := cpRet
		END
	END
	RETURN ret
END ParseOptions;

PROCEDURE Command(VAR args: Args; ret: INTEGER): INTEGER;
VAR arg: INTEGER;
BEGIN
	ASSERT(ret IN {ResultC .. ResultMod});

	ArgsInit(args);

	arg := 1;
	IF GetParam(ret, ErrTooLongSourceName, args.src, args.srcLen, arg) THEN
		ret := ParseOptions(args, ret, arg)
	END;
	args.arg := arg + 1
	RETURN ret
END Command;

PROCEDURE Parse*(VAR args: Args; VAR ret: INTEGER): BOOLEAN;
VAR cmdLen: INTEGER; cmd: ARRAY 100H OF CHAR; ignore: BOOLEAN;

	PROCEDURE SearchDot(str: ARRAY OF CHAR): BOOLEAN;
	VAR i: INTEGER;
	BEGIN
		i := 0;
		RETURN Chars0X.SearchChar(str, i, ".")
	END SearchDot;
BEGIN
	cmdLen := 0;
	IF CLI.count <= 0 THEN
		ret := ErrWrongArgs
	ELSIF ~CLI.Get(cmd, cmdLen, 0) THEN
		ret := ErrUnknownCommand
	ELSIF SearchDot(cmd) THEN
		ignore := ArgsForRunFile(args, ret)
	ELSIF (cmd = "help") OR (cmd = "--help") THEN
		ret := CmdHelp
	ELSIF (cmd = "version") OR (cmd = "--version") THEN
		ret := CmdVersion
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
	ELSIF cmd = "to-jar" THEN
		ret := Command(args, ResultJar)
	ELSIF cmd = "run-java" THEN
		ret := Command(args, ResultRunJava)
	ELSIF cmd = "to-js" THEN
		ret := Command(args, ResultJs)
	ELSIF cmd = "run-js" THEN
		ret := Command(args, ResultRunJs)
	ELSIF cmd = "to-mod" THEN
		ret := Command(args, ResultMod)
	ELSE
		ret := ErrUnknownCommand
	END
	RETURN 0 <= ret
END Parse;

BEGIN
	IF Platform.Posix THEN
		dirSep := "/"
	ELSE ASSERT(Platform.Windows);
		dirSep := "\"
	END
END CliParser.
