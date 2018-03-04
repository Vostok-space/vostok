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
MODULE Translator;

IMPORT
	Log,
	Out,
	CLI,
	Stream := VDataStream,
	File := VFileStream,
	Utf8,
	Strings := StringStore,
	SpecIdentChecker,
	Parser,
	Scanner,
	Ast,
	GeneratorC,
	TranLim := TranslatorLimits,
	Exec := PlatformExec,
	Message,
	Cli := CliParser,
	Platform,
	Files := CFiles,
	OsEnv;

CONST
	ErrNo    =  0;
	ErrParse = -1;

	UnknownCc = 0;
	TinyCc    = 1;
	GnuCc     = 2;
	Clang     = 3;
	CompCert  = 4;

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
		END;

		expectName: ARRAY TranLim.LenName + 1 OF CHAR;
		nameLen   : INTEGER;
		nameOk,
		firstNotOk: BOOLEAN
	END;

PROCEDURE Unlink(c: Container);
VAR tc: Container;
BEGIN
	WHILE c # NIL DO
		tc := c;
		c := c.next;
		Log.StrLn(tc.m.name.block.s);
		Ast.Unlinks(tc.m);
		tc.m.provider := NIL;
		tc.m := NIL
	END
END Unlink;

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
	ASSERT(m.module.m = m);
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
		IF (0 < len)
		 & Strings.CopyChars(n, l, p.path, pathOfs, pathOfs + len)
		 & Strings.CopyCharsNull(n, l, Exec.dirSep)
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
		mp.nameLen := 0;
		ASSERT(Strings.CopyChars(mp.expectName, mp.nameLen, name, ofs, end));

		pathInd := -1;
		pathOfs := 0;
		REPEAT
			source := Open(mp, pathOfs, name, ofs, end);
			IF source # NIL THEN
				m := Parser.Parse(source, p, mp.opt);
				File.CloseIn(source);
				IF ~mp.nameOk THEN
					m := NIL
				END
			END;
			INC(pathInd)
		UNTIL (m # NIL) OR (mp.path[pathOfs] = Utf8.Null);
		IF m # NIL THEN
			IF pathInd IN mp.sing THEN
				m.mark := TRUE
			END
		ELSIF mp.firstNotOk THEN
			mp.firstNotOk := FALSE;
			Message.Text("Can not found or open file of module ");
			Out.String(mp.expectName);
			Out.Ln
		END
	END
	RETURN m
END GetModule;

PROCEDURE RegModule(p: Ast.Provider; m: Ast.Module): BOOLEAN;
	PROCEDURE Reg(p: ModuleProvider; m: Ast.Module): BOOLEAN;
	BEGIN
		Log.Str(m.name.block.s); Log.Str(" : "); Log.StrLn(p.expectName);
		p.nameOk := m.name.block.s = p.expectName;
		IF p.nameOk THEN
			AddModule(p, m)
		END
		RETURN p.nameOk
	END Reg;
BEGIN
	Log.Str("RegModule "); Log.StrLn(m.name.block.s)
	RETURN Reg(p(ModuleProvider), m)
END RegModule;

PROCEDURE CopyModuleNameForFile(VAR str: ARRAY OF CHAR; VAR len: INTEGER;
                                name: Strings.String): BOOLEAN;
BEGIN
	RETURN Strings.CopyToChars(str, len, name)
	     & (~SpecIdentChecker.IsSpecModuleName(name)
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
	IF ~Strings.CopyCharsNull(dir, destLen, Exec.dirSep)
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
	mp.modules.last := mp.modules.first;

	mp.firstNotOk := TRUE
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
		IF ~imp.module.m.used THEN
			ret := GenerateC(imp.module.m, FALSE, NIL, opt, dir, dirLen, cDirs, exec)
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
			     & Strings.CopyCharsNull(name, nameLen, Exec.dirSep)
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
			     & Strings.CopyCharsNull(bin, binLen, Exec.dirSep)
			     & Strings.CopyToChars(bin, binLen, name)
			     & (~Platform.Windows OR Strings.CopyCharsNull(bin, binLen, ".exe")))
		END
	END
	RETURN ok
END GetTempOutC;

PROCEDURE SearchCCompiler(VAR cc: INTEGER; VAR cmd: Exec.Code;
                          res: INTEGER): BOOLEAN;

	PROCEDURE Test(VAR idCc: INTEGER; id: INTEGER; c, ver: ARRAY OF CHAR): BOOLEAN;
	VAR exec: Exec.Code; ok: BOOLEAN;
	BEGIN
		ok := Exec.Init(exec, c) & Exec.Add(exec, ver, 0)
		    & ((Platform.Posix & Exec.AddClean(exec, " 1,2>/dev/null"))
		    OR (Platform.Windows & Exec.AddClean(exec, ">NUL 2>NUL"))
		      )
		    & (Exec.Ok = Exec.Do(exec));
		IF ok THEN
			idCc := id
		END
		RETURN ok
	END Test;

	RETURN (res = Cli.ResultRun)
	     & Test(cc, TinyCc, "tcc",   "-dumpversion") & Exec.AddClean(cmd, "tcc -g -w")

	    OR (
	       Test(cc, GnuCc, "gcc",    "-dumpversion") & Exec.AddClean(cmd, "gcc -g -O1")
	    OR Test(cc, Clang, "clang",  "-dumpversion") & Exec.AddClean(cmd, "clang -g -O1")

	    OR (res # Cli.ResultRun)
	     & Test(cc, TinyCc, "tcc",   "-dumpversion") & Exec.AddClean(cmd, "tcc -g")

	    OR Test(cc, CompCert, "ccomp", "--version")  & Exec.AddClean(cmd, "ccomp -g -O")

	    OR Test(cc, UnknownCc, "cc", "-dumpversion") & Exec.AddClean(cmd, "cc -g -O1")
	       ) & ((res # Cli.ResultRun) OR Exec.AddClean(cmd, " -w"))
END SearchCCompiler;

PROCEDURE ToC(res: INTEGER; VAR args: Cli.Args): INTEGER;
VAR ret, len: INTEGER;
    outC: ARRAY 1024 OF CHAR;
    mp: ModuleProvider;
    module: Ast.Module;
    opt: GeneratorC.Options;
    call: Ast.Call;
    exec: Exec.Code;

	PROCEDURE Bin(res: INTEGER; args: Cli.Args;
	              module: Ast.Module; call: Ast.Call; opt: GeneratorC.Options;
	              cDirs, cc: ARRAY OF CHAR; VAR outC, bin: ARRAY OF CHAR;
	              VAR cmd: Exec.Code; tmp: ARRAY OF CHAR): INTEGER;
	VAR outCLen: INTEGER;
	    ret, idCc: INTEGER;
	    i, nameLen, cDirsLen: INTEGER;
	    ok: BOOLEAN;
	    name: ARRAY 512 OF CHAR;
	BEGIN
		ok := GetTempOutC(outC, outCLen, bin, module.name, tmp);
		IF ~ok THEN
			ret := Cli.ErrCantCreateOutDir
		ELSE
			IF cc[0] = Utf8.Null THEN
				ok := SearchCCompiler(idCc, cmd, res);
				IF ok & (args.cyrillic = Cli.CyrillicDefault) THEN
					CASE idCc OF
					  UnknownCc, CompCert:
						opt.identEnc := GeneratorC.IdentEncTranslit
					| Clang, TinyCc:
						opt.identEnc := GeneratorC.IdentEncSame
					| GnuCc:
						opt.identEnc := GeneratorC.IdentEncEscUnicode
					END
				END
			ELSE
				ok := Exec.AddClean(cmd, cc)
			END;
			IF ~ok THEN
				ret := Cli.ErrCantFoundCCompiler
			ELSE
				ret := GenerateC(module, TRUE, call, opt, outC, outCLen, cDirs, cmd)
			END;
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
					    & Strings.CopyCharsNull(name, nameLen, Exec.dirSep)
					    & Strings.CopyCharsNull(name, nameLen, "o7.c")

					    & (~Files.Exist(name, 0) OR Exec.Add(cmd, name, 0));
					i := i + cDirsLen + 1
				END;
				ok := ok
				& (  (opt.memManager # GeneratorC.MemManagerCounter)
				  OR Exec.Add(cmd, "-DO7_MEMNG_MODEL=O7_MEMNG_COUNTER", 0)
				  )
				& (  (opt.memManager # GeneratorC.MemManagerGC)
				  OR Exec.Add(cmd, "-DO7_MEMNG_MODEL=O7_MEMNG_GC", 0)
				   & Exec.Add(cmd, "-lgc", 0)
				  )
				& (~Platform.Posix OR Exec.Add(cmd, "-lm", 0));
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
BEGIN
	ASSERT(res IN {Cli.ResultC .. Cli.ResultRun});

	NewProvider(mp);
	mp.fileExt := ".mod"; (* TODO *)
	mp.extLen := Strings.CalcLen(mp.fileExt, 0);
	mp.opt.cyrillic := args.cyrillic # Cli.CyrillicNo;
	len := 0;
	ASSERT(Strings.CopyChars(mp.path, len, args.modPath, 0, args.modPathLen));
	mp.sing := args.sing;
	IF args.script THEN
		module := Parser.Script(args.src, mp, mp.opt);
		AddModule(mp, module)
	ELSE
		module := GetModule(mp, NIL, args.src, 0, args.srcNameEnd)
	END;
	IF module = NIL THEN
		ret := ErrParse
	ELSIF module.errors # NIL THEN
		ret := ErrParse;
		PrintErrors(mp.modules.first.next)
	ELSE
		IF ~args.script & (args.srcNameEnd < args.srcLen - 1) THEN
			ret := Ast.CommandGet(call, module,
			                      args.src, args.srcNameEnd + 1, args.srcLen - 1)
		ELSE
			ret := ErrNo;
			call := NIL
		END;
		IF ret # Ast.ErrNo THEN
			ret := ErrParse;
			Message.AstError(ret); Out.Ln
		ELSE
			opt := GeneratorC.DefaultOptions();
			IF 0 <= args.init THEN
				opt.varInit := args.init
			END;
			IF 0 <= args.memng THEN
				opt.memManager := args.memng
			END;
			IF args.noNilCheck THEN
				opt.checkNil := FALSE
			END;
			IF args.noOverflowCheck THEN
				opt.checkArith := FALSE
			END;
			IF args.noIndexCheck THEN
				opt.checkIndex := FALSE
			END;
			IF Cli.CyrillicSame <= args.cyrillic THEN
				opt.identEnc := args.cyrillic - Cli.CyrillicSame
			END;
			ASSERT(Exec.Init(exec, ""));
			CASE res OF
			  Cli.ResultC:
				DEC(args.resPathLen);
				ret := GenerateC(module, (call # NIL) OR args.script, call,
				                 opt, args.resPath, args.resPathLen, args.cDirs, exec)
			| Cli.ResultBin, Cli.ResultRun:
				ret := Bin(res, args, module, call, opt, args.cDirs, args.cc, outC,
				           args.resPath, exec, args.tmp);
				IF (res = Cli.ResultRun) & (ret = ErrNo) THEN
					ret := Run(args.resPath, args.arg)
				END;
				IF (args.tmp = "") & ~RemoveDir(outC) & (ret = ErrNo) THEN
					ret := Cli.ErrCantRemoveOutDir
				END
			END
		END
	END;
	IF mp.modules.last # NIL THEN
		mp.modules.last.next := NIL;
		Unlink(mp.modules.first.next)
	END
	RETURN ret
END ToC;

PROCEDURE Handle(VAR args: Cli.Args; VAR ret: INTEGER): BOOLEAN;
BEGIN
	IF ret = Cli.CmdHelp THEN
		Message.Usage(TRUE)
	ELSE
		ret := ToC(ret, args)
	END
	RETURN 0 <= ret
END Handle;

PROCEDURE Start*;
VAR ret: INTEGER;
    args: Cli.Args;
BEGIN
	Out.Open;
	Log.Turn(FALSE);

	IF ~Cli.Parse(args, ret) OR ~Handle(args, ret) THEN
		CLI.SetExitCode(1);
		IF ret # ErrParse THEN
			Message.CliError(ret, args.cmd)
		END
	END
END Start;

END Translator.
