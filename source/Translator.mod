(*  Command line interface for Oberon-07 translator
 *  Copyright (C) 2016-2017 ComdivByZero
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
MODULE Translator;

IMPORT
	Log,
	Out,
	CLI,
	Stream := VDataStream,
	File := VFileStream,
	Utf8,
	Strings := StringStore,
	Parser,
	Scanner,
	Ast,
	GeneratorC,
	TranLim := TranslatorLimits,
	Exec := PlatformExec,
	Message := MessageEn,
	Cli := CliParser,
	Platform,
	Files := CFiles,
	OsEnv;

CONST
	ResultC   = 0;
	ResultBin = 1;
	ResultRun = 2;

	ErrNo    =  0;
	ErrParse = -1;

TYPE
	Container = POINTER TO RECORD
		next: Container;
		m: Ast.Module
	END;

	ModuleProvider = POINTER TO RECORD(Ast.RProvider)
		opt: Parser.Options;
		fileExt: ARRAY 32 OF CHAR;
		extLen: INTEGER;
		path: ARRAY 4096 OF CHAR;
		sing: SET;
		modules: RECORD
			first, last: Container
		END
	END;

VAR
	pathSep: ARRAY 2 OF CHAR;

PROCEDURE ErrorMessage(code: INTEGER);
BEGIN
	Out.Int(code - Parser.ErrAstBegin, 0); Out.String(" ");
	IF code <= Parser.ErrAstBegin THEN
		Message.AstError(code - Parser.ErrAstBegin)
	ELSE
		Message.ParseError(code)
	END
END ErrorMessage;

PROCEDURE PrintErrors(mc: Container);
CONST SkipError = Ast.ErrImportModuleWithError + Parser.ErrAstBegin;
VAR i: INTEGER;
	err: Ast.Error;
BEGIN
	i := 0;
	WHILE mc.m # NIL DO
		err := mc.m.errors;
		WHILE (err # NIL) & (err.code = SkipError) DO
			err := err.next
		END;
		IF err # NIL THEN
			Message.Text("Found errors in the module ");
			Out.String(mc.m.name.block.s); Out.String(": "); Out.Ln;
			err := mc.m.errors;
			WHILE err # NIL DO
				IF err.code # SkipError THEN
					INC(i);

					Out.String("  ");
					Out.Int(i, 2); Out.String(") ");
					ErrorMessage(err.code);
					Out.String(" "); Out.Int(err.line + 1, 0);
					Out.String(" : "); Out.Int(err.column + err.tabs * 3, 0);
					Out.Ln
				END;

				err := err.next
			END
		END;
		mc := mc.next
	END
END PrintErrors;

PROCEDURE IsEqualStr(str: ARRAY OF CHAR; ofs: INTEGER; sample: ARRAY OF CHAR)
                    : BOOLEAN;
VAR i: INTEGER;
BEGIN
	i := 0;
	WHILE (str[ofs] = sample[i]) & (sample[i] # Utf8.Null) DO
		INC(ofs);
		INC(i)
	END
	RETURN str[ofs] = sample[i]
END IsEqualStr;

PROCEDURE GetParam(VAR str: ARRAY OF CHAR; VAR i, arg: INTEGER): BOOLEAN;
VAR ret: BOOLEAN;
    j: INTEGER;
BEGIN
	j := i;
	ret := CLI.Get(str, i, arg);
	IF ret & (str[j] = "'") & (arg < CLI.count) THEN
		str[j] := " ";
		REPEAT
			str[i] := " ";
			INC(i);
			ret := CLI.Get(str, i, arg);
			INC(arg)
		UNTIL (arg >= CLI.count) OR ~ret OR (str[i - 1] = "'");
		str[i - 1] := " "
	END
	RETURN ret
END GetParam;

PROCEDURE CopyPath(VAR str: ARRAY OF CHAR; VAR sing: SET;
                   VAR cDirs: ARRAY OF CHAR; VAR cc: ARRAY OF CHAR;
                   VAR init: INTEGER;
                   VAR tmp: ARRAY OF CHAR;
                   VAR arg: INTEGER): INTEGER;
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
	cDirs[0] := Utf8.Null;
	tmp[0] := Utf8.Null;
	ccLen := 0;
	count := 0;
	sing := {};
	ret := ErrNo;
	optLen := 0;
	init := -1;
	WHILE (ret = ErrNo) & (count < 32)
	    & (arg < CLI.count) & CLI.Get(opt, optLen, arg) & ~IsEqualStr(opt, 0, "--")
	DO
		optLen := 0;
		IF (opt = "-i") OR (opt = "-m") THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := Cli.ErrNotEnoughArgs
			ELSIF CLI.Get(str, i, arg) THEN
				IF opt = "-i" THEN
					INCL(sing, count)
				END;
				INC(count)
			ELSE
				ret := Cli.ErrTooLongModuleDirs
			END
		ELSIF opt = "-c" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := Cli.ErrNotEnoughArgs
			ELSIF CLI.Get(cDirs, dirsOfs, arg) & (dirsOfs < LEN(cDirs)) THEN
				cDirs[dirsOfs] := Utf8.Null;
				Log.Str("cDirs = ");
				Log.StrLn(cDirs)
			ELSE
				ret := Cli.ErrTooLongCDirs
			END
		ELSIF opt = "-cc" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := Cli.ErrNotEnoughArgs
			ELSIF GetParam(cc, ccLen, arg) THEN
				DEC(ccLen)
			ELSE
				ret := Cli.ErrTooLongCc
			END
		ELSIF opt = "-infr" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := Cli.ErrNotEnoughArgs
			ELSIF Platform.Posix
			    & CopyInfrPart(str, i, arg, "/singularity/definition")
			    & CopyInfrPart(str, i, arg, "/library")
			    & CopyInfrPart(cDirs, dirsOfs, arg, "/singularity/implementation")
			   OR Platform.Windows
			    & CopyInfrPart(str, i, arg, "\singularity\definition")
			    & CopyInfrPart(str, i, arg, "\library")
			    & CopyInfrPart(cDirs, dirsOfs, arg, "\singularity\implementation")
			THEN
				INCL(sing, count);
				INC(count, 2)
			ELSE
				ret := Cli.ErrTooLongModuleDirs
			END
		ELSIF opt = "-init" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := Cli.ErrNotEnoughArgs
			ELSIF ~CLI.Get(opt, optLen, arg) THEN
				ret := Cli.ErrUnknownInit
			ELSIF opt = "no" THEN
				init := GeneratorC.VarInitNo
			ELSIF opt = "undef" THEN
				init := GeneratorC.VarInitUndefined
			ELSIF opt = "zero" THEN
				init := GeneratorC.VarInitZero
			ELSE
				ret := Cli.ErrUnknownInit
			END;
			optLen := 0
		ELSIF opt = "-t" THEN
			INC(arg);
			IF arg >= CLI.count THEN
				ret := Cli.ErrNotEnoughArgs
			ELSIF ~CLI.Get(tmp, optLen, arg) THEN
				ret := Cli.ErrTooLongTemp
			END;
			optLen := 0
		ELSE
			ret := Cli.ErrUnexpectArg
		END;
		INC(arg)
	END;
	IF i + 1 < LEN(str) THEN
		str[i + 1] := Utf8.Null;
		IF count >= 32 THEN
			ret := Cli.ErrTooManyModuleDirs
		END;
	ELSE
		ret := Cli.ErrTooLongModuleDirs;
		str[LEN(str) - 1] := Utf8.Null;
		str[LEN(str) - 2] := Utf8.Null;
		str[LEN(str) - 3] := "#"
	END
	RETURN ret
END CopyPath;

PROCEDURE SearchModule(mp: ModuleProvider;
                       name: ARRAY OF CHAR; ofs, end: INTEGER): Ast.Module;
VAR mc: Container;
BEGIN
	mc := mp.modules.first.next;
	WHILE (mc # mp.modules.first)
	    & ~Strings.IsEqualToChars(mc.m.name, name, ofs, end)
	DO
		mc := mc.next
	END
	RETURN mc.m
END SearchModule;

PROCEDURE AddModule(mp: ModuleProvider; m: Ast.Module);
VAR mc: Container;
BEGIN
	ASSERT(m.module = m);
	NEW(mc);
	mc.m := m;
	mc.next := mp.modules.first;

	mp.modules.last.next := mc;
	mp.modules.last := mc
END AddModule;

PROCEDURE GetModule(p: Ast.Provider; host: Ast.Module;
                    name: ARRAY OF CHAR; ofs, end: INTEGER): Ast.Module;
VAR m: Ast.Module;
	source: File.In;
	mp: ModuleProvider;
	pathOfs, pathInd: INTEGER;

	PROCEDURE Open(p: ModuleProvider; VAR pathOfs: INTEGER;
	               name: ARRAY OF CHAR; ofs, end: INTEGER): File.In;
	VAR n: ARRAY 1024 OF CHAR;
		len, l: INTEGER;
		in: File.In;
	BEGIN
		len := Strings.CalcLen(p.path, pathOfs);
		l := 0;
		IF (len > 0)
		 & Strings.CopyChars(n, l, p.path, pathOfs, pathOfs + len)
		 & Strings.CopyCharsNull(n, l, pathSep)
		 & Strings.CopyChars(n, l, name, ofs, end)
		 & Strings.CopyChars(n, l, p.fileExt, 0, p.extLen)
		THEN
			in := File.OpenIn(n)
		ELSE
			in := NIL
		END;
		pathOfs := pathOfs + len + 1
		RETURN in
	END Open;
BEGIN
	mp := p(ModuleProvider);
	m := SearchModule(mp, name, ofs, end);
	IF m # NIL THEN
		Log.StrLn("Найден уже разобранный модуль")
	ELSE
		pathInd := -1;
		pathOfs := 0;
		REPEAT
			source := Open(mp, pathOfs, name, ofs, end);
			INC(pathInd)
		UNTIL (source # NIL) OR (mp.path[pathOfs] = Utf8.Null);
		IF source # NIL THEN
			m := Parser.Parse(source, p, mp.opt);
			IF pathInd IN mp.sing THEN
				m.mark := TRUE
			END;
			File.CloseIn(source);
		ELSE
			Message.Text("Can not found or open file of module");
			Out.Ln
		END
	END
	RETURN m
END GetModule;

PROCEDURE RegModule(p: Ast.Provider; m: Ast.Module);
BEGIN
	Log.Str("RegModule "); Log.StrLn(m.name.block.s);
	AddModule(p(ModuleProvider), m)
END RegModule;

PROCEDURE CopyModuleNameForFile(VAR str: ARRAY OF CHAR; VAR len: INTEGER;
                                name: Strings.String): BOOLEAN;
BEGIN
	RETURN Strings.CopyToChars(str, len, name)
	     & (~GeneratorC.IsSpecModuleName(name)
	     OR Strings.CopyCharsNull(str, len, "_")
	       )
END CopyModuleNameForFile;

PROCEDURE OpenCOutput(VAR interface, implementation: File.Out;
                      module: Ast.Module; isMain: BOOLEAN;
                      VAR dir: ARRAY OF CHAR; dirLen: INTEGER;
                      VAR exec: Exec.Code): INTEGER;
VAR destLen: INTEGER;
    ret: INTEGER;
BEGIN
	interface := NIL;
	implementation := NIL;
	destLen := dirLen;
	IF ~Strings.CopyCharsNull(dir, destLen, pathSep)
	OR ~CopyModuleNameForFile(dir, destLen, module.name)
	OR (destLen > LEN(dir) - 3)
	THEN
		ret := Cli.ErrTooLongOutName
	ELSE
		dir[destLen] := ".";
		dir[destLen + 2] := Utf8.Null;
		IF ~isMain THEN
			dir[destLen + 1] := "h";
			interface := File.OpenOut(dir)
		END;
		IF  ~isMain & (interface = NIL) THEN
			ret := Cli.ErrOpenH
		ELSE
			dir[destLen + 1] := "c";
			(* TODO *)
			ASSERT(Exec.Add(exec, dir, 0));
			Log.StrLn(dir);
			implementation := File.OpenOut(dir);
			IF implementation = NIL THEN
				File.CloseOut(interface);
				ret := Cli.ErrOpenC
			ELSE
				ret := ErrNo
			END
		END
	END
	RETURN ret
END OpenCOutput;

PROCEDURE NewProvider(VAR mp: ModuleProvider);
BEGIN
	NEW(mp); Ast.ProviderInit(mp, GetModule, RegModule);
	Parser.DefaultOptions(mp.opt);
	mp.opt.printError := ErrorMessage;
	mp.extLen := 0;

	NEW(mp.modules.first);
	mp.modules.first.m := NIL;
	mp.modules.first.next := mp.modules.first;
	mp.modules.last := mp.modules.first
END NewProvider;

PROCEDURE GenerateC(module: Ast.Module; isMain: BOOLEAN; cmd: Ast.Call;
                    opt: GeneratorC.Options;
                    VAR dir: ARRAY OF CHAR; dirLen: INTEGER;
                    cDirs: ARRAY OF CHAR;
                    VAR exec: Exec.Code): INTEGER;
VAR imp: Ast.Declaration;
	ret, i, cDirsLen, nameLen: INTEGER;
	name: ARRAY 512 OF CHAR;
	iface, impl: File.Out;
BEGIN
	module.used := TRUE;

	ret := ErrNo;
	imp := module.import;
	WHILE (ret = ErrNo) & (imp # NIL) & (imp IS Ast.Import) DO
		IF ~imp.module.used THEN
			ret := GenerateC(imp.module, FALSE, NIL, opt, dir, dirLen, cDirs, exec)
		END;
		imp := imp.next
	END;
	IF ret # ErrNo THEN
		;
	ELSIF ~module.mark THEN
		ret := OpenCOutput(iface, impl, module, isMain, dir, dirLen, exec);
		IF ret = ErrNo THEN
			GeneratorC.Generate(iface, impl, module, cmd, opt);
			File.CloseOut(iface);
			File.CloseOut(impl)
		END
	ELSE
		i := 0;
		WHILE cDirs[i] # Utf8.Null DO
			nameLen := 0;
			cDirsLen := Strings.CalcLen(cDirs, i);
			(* TODO *)
			ASSERT(Strings.CopyChars(name, nameLen, cDirs, i, i + cDirsLen)
			     & Strings.CopyCharsNull(name, nameLen, pathSep)
			     & CopyModuleNameForFile(name, nameLen, module.name)
			     & Strings.CopyCharsNull(name, nameLen, ".c")

			     & (~Files.Exist(name, 0) OR Exec.Add(exec, name, 0))
			);
			i := i + cDirsLen + 1
		END
	END
	RETURN ret
END GenerateC;

PROCEDURE MakeDir(name: ARRAY OF CHAR): BOOLEAN;
VAR cmd: Exec.Code;
BEGIN
	IF Platform.Posix THEN
		ASSERT(Exec.Init(cmd, "mkdir")
		     & Exec.Add(cmd, name, 0)
		     & Exec.AddClean(cmd, " 2>/dev/null"))
	ELSE ASSERT(Platform.Windows);
		ASSERT(Exec.Init(cmd, "mkdir")
		     & Exec.Add(cmd, name, 0))
	END
	RETURN Exec.Do(cmd) = Exec.Ok
END MakeDir;

PROCEDURE RemoveDir(name: ARRAY OF CHAR): BOOLEAN;
VAR cmd: Exec.Code;
BEGIN
	IF Platform.Posix THEN
		ASSERT(Exec.Init(cmd, "rm")
		     & Exec.Add(cmd, "-r", 0)
		     & Exec.Add(cmd, name, 0)
		     & Exec.AddClean(cmd, " 2>/dev/null"))
	ELSE ASSERT(Platform.Windows);
		ASSERT(Exec.Init(cmd, "rmdir")
		     & Exec.AddClean(cmd, " /s/q")
		     & Exec.Add(cmd, name, 0))
	END
	RETURN Exec.Do(cmd) = Exec.Ok
END RemoveDir;

PROCEDURE GetTempOutC(VAR dirCOut: ARRAY OF CHAR; VAR len: INTEGER;
                      VAR bin: ARRAY OF CHAR; name: Strings.String;
                      tmp: ARRAY OF CHAR): BOOLEAN;
VAR binLen, i: INTEGER;
    ok: BOOLEAN;
BEGIN
	len := 0;
	IF tmp # "" THEN
		ok := TRUE;
		ASSERT(Strings.CopyCharsNull(dirCOut, len, tmp))
	ELSIF Platform.Posix THEN
		ok := TRUE;
		ASSERT(Strings.CopyCharsNull(dirCOut, len, "/tmp/o7c-")
		     & Strings.CopyToChars(dirCOut, len, name))
	ELSE ASSERT(Platform.Windows);
		ok := OsEnv.Get(dirCOut, len, "temp")
		    & Strings.CopyCharsNull(dirCOut, len, "\o7c-")
		    & Strings.CopyToChars(dirCOut, len, name)
	END;

	IF ok THEN
		i := 0;
		ok := MakeDir(dirCOut);
		IF ~ok & (tmp = "") THEN
			WHILE ~ok & (i < 100) DO
				IF i = 0 THEN
					ASSERT(Strings.CopyCharsNull(dirCOut, len, "-00"))
				ELSE
					dirCOut[len - 2] := CHR(ORD("0") + i DIV 10);
					dirCOut[len - 1] := CHR(ORD("0") + i MOD 10)
				END;
				ok := MakeDir(dirCOut);
				INC(i)
			END
		END;
		IF ok & (bin[0] = Utf8.Null) THEN
			binLen := 0;
			ASSERT(Strings.CopyCharsNull(bin, binLen, dirCOut)
			     & Strings.CopyCharsNull(bin, binLen, pathSep)
			     & Strings.CopyToChars(bin, binLen, name)
			     & (~Platform.Windows OR Strings.CopyCharsNull(bin, binLen, ".exe")))
		END
	END
	RETURN ok
END GetTempOutC;

PROCEDURE ToC(res: INTEGER): INTEGER;
VAR ret: INTEGER;
	src: ARRAY 65536 OF CHAR;
	srcLen, srcNameEnd: INTEGER;
	outC, resPath, tmp: ARRAY 1024 OF CHAR;
	resPathLen: INTEGER;
	cDirs, cc: ARRAY 4096 OF CHAR;
	mp: ModuleProvider;
	module: Ast.Module;
	opt: GeneratorC.Options;
	init, arg: INTEGER;
	call: Ast.Call;
	script: BOOLEAN;
	exec: Exec.Code;

	PROCEDURE Bin(module: Ast.Module; call: Ast.Call; opt: GeneratorC.Options;
	              cDirs, cc: ARRAY OF CHAR; VAR outC, bin: ARRAY OF CHAR;
	              VAR cmd: Exec.Code; tmp: ARRAY OF CHAR): INTEGER;
	VAR outCLen: INTEGER;
		ret, i, nameLen, cDirsLen: INTEGER;
		ok: BOOLEAN;
		name: ARRAY 512 OF CHAR;
	BEGIN
		ok := GetTempOutC(outC, outCLen, bin, module.name, tmp);
		IF ~ok THEN
			ret := Cli.ErrCantCreateOutDir
		ELSE
			IF cc[0] = Utf8.Null THEN
				ok := Exec.AddClean(cmd, "cc -g -O1")
			ELSE
				ok := Exec.AddClean(cmd, cc)
			END;
			ret := GenerateC(module, TRUE, call, opt, outC, outCLen, cDirs, cmd);
			outC[outCLen] := Utf8.Null;
			IF ret = ErrNo THEN
				ok := ok
				    & Exec.Add(cmd, "-o", 0)
				    & Exec.Add(cmd, bin, 0)
				    & Exec.Add(cmd, "-I", 0)
				    & Exec.Add(cmd, outC, 0);
				i := 0;
				WHILE ok & (cDirs[i] # Utf8.Null) DO
					nameLen := 0;
					cDirsLen := Strings.CalcLen(cDirs, i);
					ok := Exec.Add(cmd, "-I", 0)
					    & Exec.Add(cmd, cDirs, i)

					    & Strings.CopyChars(name, nameLen, cDirs, i, i + cDirsLen)
					    & Strings.CopyCharsNull(name, nameLen, pathSep)
					    & Strings.CopyCharsNull(name, nameLen, "o7.c")

					    & (~Files.Exist(name, 0) OR Exec.Add(cmd, name, 0));
					i := i + cDirsLen + 1
				END;
				ok := ok & (~Platform.Posix OR Exec.Add(cmd, "-lm", 0));
				Exec.Log(cmd);
				(* TODO *)
				ASSERT(ok);
				IF Exec.Do(cmd) # Exec.Ok THEN
					ret := Cli.ErrCCompiler
				END
			END
		END
		RETURN ret
	END Bin;

	PROCEDURE Run(bin: ARRAY OF CHAR; arg: INTEGER): INTEGER;
	VAR cmd: Exec.Code;
		buf: ARRAY 65536 OF CHAR;
		len: INTEGER;
		ret: INTEGER;
	BEGIN
		ret := Cli.ErrTooLongRunArgs;
		IF Exec.Init(cmd, bin) THEN
			INC(arg);
			len := 0;
			WHILE (arg < CLI.count)
			    & CLI.Get(buf, len, arg)
			    & Exec.Add(cmd, buf, 0)
			DO
				len := 0;
				INC(arg)
			END;
			IF arg >= CLI.count THEN
				CLI.SetExitCode(Exec.Do(cmd));
				ret := ErrNo
			END
		END
		RETURN ret
	END Run;

	PROCEDURE ParseCommand(src: ARRAY OF CHAR; VAR script: BOOLEAN): INTEGER;
	VAR i, j: INTEGER;

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
			Empty(src, j);
			script := src[j] # Utf8.Null
		ELSE
			script := FALSE
		END
		RETURN i
	END ParseCommand;
BEGIN
	ASSERT(res IN {ResultC .. ResultRun});

	srcLen := 0;
	arg := 3 + ORD(res # ResultRun);
	IF CLI.count < arg THEN
		ret := Cli.ErrNotEnoughArgs
	ELSIF ~CLI.Get(src, srcLen, 2) THEN
		ret := Cli.ErrTooLongSourceName
	ELSE
		NewProvider(mp);
		mp.fileExt := ".mod"; (* TODO *)
		mp.extLen := Strings.CalcLen(mp.fileExt, 0);
		ret := CopyPath(mp.path, mp.sing, cDirs, cc, init, tmp, arg);
		IF ret = ErrNo THEN
			srcNameEnd := ParseCommand(src, script);
			IF script THEN
				module := Parser.Script(src, mp, mp.opt);
				AddModule(mp, module)
			ELSE
				module := GetModule(mp, NIL, src, 0, srcNameEnd)
			END;
			resPathLen := 0;
			resPath[0] := Utf8.Null;
			IF module = NIL THEN
				ret := ErrParse
			ELSIF module.errors # NIL THEN
				PrintErrors(mp.modules.first.next);
				ret := ErrParse
			ELSIF (res # ResultRun) & ~CLI.Get(resPath, resPathLen, 3) THEN
				ret := Cli.ErrTooLongOutName
			ELSE
				IF ~script & (srcNameEnd < srcLen - 1) THEN
					ret := Ast.CommandGet(call, module,
					                      src, srcNameEnd + 1, srcLen - 1)
				ELSE
					call := NIL
				END;
				IF ret # Ast.ErrNo THEN
					Message.AstError(ret); Out.Ln;
					ret := ErrParse
				ELSE
					opt := GeneratorC.DefaultOptions();
					IF init >= 0 THEN
						opt.varInit := init
					END;
					ASSERT(Exec.Init(exec, ""));
					CASE res OF
					  ResultC:
						DEC(resPathLen);
						ret := GenerateC(module, (call # NIL) OR script, call,
						                 opt, resPath, resPathLen, cDirs, exec)
					| ResultBin, ResultRun:
						ret := Bin(module, call, opt, cDirs, cc, outC, resPath,
						           exec, tmp);
						IF (res = ResultRun) & (ret = ErrNo) THEN
							ret := Run(resPath, arg)
						END;
						IF (tmp = "") & ~RemoveDir(outC) & (ret = ErrNo) THEN
							ret := Cli.ErrCantRemoveOutDir
						END
					END
				END
			END
		END
	END
	RETURN ret
END ToC;

PROCEDURE Start*;
VAR cmd: ARRAY 1024 OF CHAR;
	cmdLen: INTEGER;
	ret: INTEGER;
BEGIN
	Out.Open;
	Log.Turn(FALSE);

	cmdLen := 0;
	IF (CLI.count <= 1) OR ~CLI.Get(cmd, cmdLen, 1) THEN
		ret := Cli.ErrWrongArgs
	ELSE
		IF cmd = "help" THEN
			ret := ErrNo;
			Message.Usage;
			Out.Ln
		ELSIF cmd = "to-c" THEN
			ret := ToC(ResultC)
		ELSIF cmd = "to-bin" THEN
			ret := ToC(ResultBin)
		ELSIF cmd = "run" THEN
			ret := ToC(ResultRun)
		ELSE
			ret := Cli.ErrUnknownCommand
		END
	END;
	IF ret # ErrNo THEN
		CLI.SetExitCode(1);
		IF ret # ErrParse THEN
			Message.CliError(ret, cmd)
		END
	END
END Start;

BEGIN
	IF Platform.Posix THEN
		pathSep := "/"
	ELSE ASSERT(Platform.Windows);
		pathSep := "\"
	END
END Translator.
