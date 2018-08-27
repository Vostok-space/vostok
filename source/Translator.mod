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
	AstTransform,
	GeneratorC,
	GeneratorJava,
	JavaStoreProcTypes,
	TranLim := TranslatorLimits,
	Exec := PlatformExec,
	CComp := CCompilerInterface,
	JavaComp := JavaCompilerInterface,
	JavaExec := JavaExecInterface,
	Message,
	Cli := CliParser,
	Platform,
	Files := CFiles,
	OsEnv,
	FileSys := FileSystemUtil,
	Text := TextGenerator;

CONST
	ErrNo*    =  0;
	ErrParse* = -1;

TYPE
	Container = POINTER TO RContainer;
	RContainer = RECORD
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

	ProcNameProvider = POINTER TO RECORD(GeneratorJava.RProviderProcTypeName)
		javac   : JavaComp.Compiler;
		usejavac: BOOLEAN;

		store : JavaStoreProcTypes.Store;

		dir   : ARRAY 1024 OF CHAR;
		dirLen: INTEGER
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
	IF code <= Parser.ErrAstBegin THEN
		Message.AstError(code - Parser.ErrAstBegin)
	ELSE
		Message.ParseError(code)
	END
END ErrorMessage;

PROCEDURE IndexedErrorMessage(index, code, line, column: INTEGER);
BEGIN
	Out.String("  ");
	Out.Int(index, 2); Out.String(") ");

	ErrorMessage(code);

	Out.String(" "); Out.Int(line + 1, 0);
	Out.String(" : "); Out.Int(column, 0);
	Out.Ln
END IndexedErrorMessage;

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
					IndexedErrorMessage(i, err.code, err.line, err.column);
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
	RETURN Strings.CopyToChars(str, len, name)
	     & (~SpecIdentChecker.IsSpecModuleName(name)
	     OR Strings.CopyCharsNull(str, len, "_")
	       )
END CopyModuleNameForFile;

PROCEDURE OpenCOutput(VAR interface, implementation: File.Out;
                      module: Ast.Module; isMain: BOOLEAN;
                      VAR dir: ARRAY OF CHAR; dirLen: INTEGER;
                      VAR ccomp: CComp.Compiler; usecc: BOOLEAN): INTEGER;
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
			implementation := File.OpenOut(dir);
			IF implementation = NIL THEN
				File.CloseOut(interface);
				ret := Cli.ErrOpenC
			ELSE
				(* TODO *)
				ASSERT(~usecc OR CComp.AddC(ccomp, dir, 0));
				Log.StrLn(dir);

				ret := ErrNo
			END
		END
	END
	RETURN ret
END OpenCOutput;

PROCEDURE OpenJavaOutput(VAR out: File.Out;
                         module: Ast.Module; orName: ARRAY OF CHAR;
                         VAR dir: ARRAY OF CHAR; dirLen: INTEGER): INTEGER;
VAR destLen: INTEGER;
    ret: INTEGER;
BEGIN
	out := NIL;
	destLen := dirLen;
	IF ~Strings.CopyCharsNull(dir, destLen, Exec.dirSep)
	OR ~((module # NIL) & CopyModuleNameForFile(dir, destLen, module.name)
	  OR (module = NIL) & Strings.CopyCharsNull(dir, destLen, orName)
	    )
	OR ~Strings.CopyCharsNull(dir, destLen, ".java")
	THEN
		ret := Cli.ErrTooLongOutName
	ELSE
		out := File.OpenOut(dir);
		IF out = NIL THEN
			ret := Cli.ErrOpenJava
		ELSE
			Log.StrLn(dir);
			ret := ErrNo
		END
	END
	RETURN ret
END OpenJavaOutput;

PROCEDURE NewProvider(VAR mp: ModuleProvider; args: Cli.Args);
VAR len: INTEGER;
BEGIN
	NEW(mp); Ast.ProviderInit(mp, GetModule, RegModule);
	Parser.DefaultOptions(mp.opt);
	mp.opt.printError := ErrorMessage;

	NEW(mp.modules.first);
	mp.modules.first.m := NIL;
	mp.modules.first.next := mp.modules.first;
	mp.modules.last := mp.modules.first;

	mp.firstNotOk := TRUE;

	mp.fileExt := ".mod"; (* TODO *)
	mp.extLen := Strings.CalcLen(mp.fileExt, 0);
	mp.opt.cyrillic := args.cyrillic # Cli.CyrillicNo;
	len := 0;
	ASSERT(Strings.CopyChars(mp.path, len, args.modPath, 0, args.modPathLen));
	mp.sing := args.sing
END NewProvider;

(* TODO Возможно, вместо сcomp и usecc лучше процедурная переменная *)
PROCEDURE GenerateC(module: Ast.Module; isMain: BOOLEAN; cmd: Ast.Call;
                    opt: GeneratorC.Options;
                    VAR dir: ARRAY OF CHAR; dirLen: INTEGER;
                    cDirs: ARRAY OF CHAR;
                    VAR ccomp: CComp.Compiler; usecc: BOOLEAN): INTEGER;
VAR imp: Ast.Declaration;
    ret, i, cDirsLen, nameLen: INTEGER;
    name: ARRAY 512 OF CHAR;
    iface, impl: File.Out;
    sing: BOOLEAN;
BEGIN
	module.used := TRUE;

	ret := ErrNo;
	imp := module.import;
	WHILE (ret = ErrNo) & (imp # NIL) & (imp IS Ast.Import) DO
		IF ~imp.module.m.used THEN
			ret := GenerateC(imp.module.m, FALSE, NIL, opt, dir, dirLen, cDirs, ccomp, usecc)
		END;
		imp := imp.next
	END;
	IF ret = ErrNo THEN
		sing := FALSE;
		IF module.mark THEN
			i := 0;
			WHILE cDirs[i] # Utf8.Null DO
				nameLen := 0;
				cDirsLen := Strings.CalcLen(cDirs, i);
				(* TODO *)
				ASSERT(Strings.CopyChars(name, nameLen, cDirs, i, i + cDirsLen)
				     & Strings.CopyCharsNull(name, nameLen, Exec.dirSep)
				     & CopyModuleNameForFile(name, nameLen, module.name)
				     & Strings.CopyCharsNull(name, nameLen, ".c")
				);
				IF Files.Exist(name, 0) THEN
					sing := TRUE;
					ASSERT(~usecc OR CComp.AddC(ccomp, name, 0))
				ELSE
					name[nameLen - 1] := "h";
					sing := Files.Exist(name, 0) OR sing
				END;
				i := i + cDirsLen + 1
			END
		END;
		IF ~sing THEN
			ret := OpenCOutput(iface, impl, module, isMain, dir, dirLen, ccomp, usecc);
			IF ret = ErrNo THEN
				GeneratorC.Generate(iface, impl, module, cmd, opt);
				File.CloseOut(iface);
				File.CloseOut(impl)
			END
		END
	END
	RETURN ret
END GenerateC;

PROCEDURE GetTempOut(VAR dirOut: ARRAY OF CHAR; VAR len: INTEGER;
                     name: Strings.String; tmp: ARRAY OF CHAR): BOOLEAN;
VAR i: INTEGER;
    ok: BOOLEAN;
BEGIN
	len := 0;
	IF tmp # "" THEN
		ok := TRUE;
		ASSERT(Strings.CopyCharsNull(dirOut, len, tmp))
	ELSIF Platform.Posix THEN
		ok := TRUE;
		ASSERT(Strings.CopyCharsNull(dirOut, len, "/tmp/o7c-")
		     & Strings.CopyToChars(dirOut, len, name))
	ELSE ASSERT(Platform.Windows);
		ok := OsEnv.Get(dirOut, len, "temp")
		    & Strings.CopyCharsNull(dirOut, len, "\o7c-")
		    & Strings.CopyToChars(dirOut, len, name)
	END;

	IF ok THEN
		i := 0;
		ok := FileSys.MakeDir(dirOut);
		IF ~ok & (tmp = "") THEN
			WHILE ~ok & (i < 100) DO
				IF i = 0 THEN
					ASSERT(Strings.CopyCharsNull(dirOut, len, "-00"))
				ELSE
					dirOut[len - 2] := CHR(ORD("0") + i DIV 10);
					dirOut[len - 1] := CHR(ORD("0") + i MOD 10)
				END;
				ok := FileSys.MakeDir(dirOut);
				INC(i)
			END
		END
	END
	RETURN ok
END GetTempOut;

PROCEDURE GetCBin(VAR bin: ARRAY OF CHAR; dir: ARRAY OF CHAR;
                  name: Strings.String): BOOLEAN;
VAR len: INTEGER;
BEGIN
	len := 0
	RETURN Strings.CopyCharsNull(bin, len, dir)
	     & Strings.CopyCharsNull(bin, len, Exec.dirSep)
	     & Strings.CopyToChars(bin, len, name)
	     & (~Platform.Windows OR Strings.CopyCharsNull(bin, len, ".exe"))
END GetCBin;

PROCEDURE GetMainClass(VAR bin: ARRAY OF CHAR; name: Strings.String): BOOLEAN;
VAR len: INTEGER;
BEGIN
	len := 0;
	RETURN Strings.CopyCharsNull(bin, len, "o7.")
	     & Strings.CopyToChars(bin, len, name)
END GetMainClass;

PROCEDURE GetTempOutC(VAR dirCOut: ARRAY OF CHAR; VAR len: INTEGER;
                      VAR bin: ARRAY OF CHAR; name: Strings.String;
                      tmp: ARRAY OF CHAR): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
	ok := GetTempOut(dirCOut, len, name, tmp);
	IF ok & (bin[0] = Utf8.Null) THEN
		ok := GetCBin(bin, dirCOut, name)
	END
	RETURN ok
END GetTempOutC;

PROCEDURE IdentEncoderForCompiler(id: INTEGER): INTEGER;
VAR enc: INTEGER;
BEGIN
	CASE id OF
	  CComp.Unknown, CComp.CompCert:
		enc := GeneratorC.IdentEncTranslit
	| CComp.Clang, CComp.Tiny:
		enc := GeneratorC.IdentEncSame
	| CComp.Gnu:
		enc := GeneratorC.IdentEncEscUnicode
	END
	RETURN enc
END IdentEncoderForCompiler;

PROCEDURE GenerateThroughC(res: INTEGER; VAR args: Cli.Args;
                           module: Ast.Module; call: Ast.Call): INTEGER;
VAR ret: INTEGER;
    opt: GeneratorC.Options;
    ccomp: CComp.Compiler;
    outC: ARRAY 1024 OF CHAR;

	PROCEDURE SetOptions(opt: GeneratorC.Options; args: Cli.Args);
	BEGIN
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
		IF 0 <= args.cStd THEN
			opt.std := args.cStd
		END;
		IF Cli.CyrillicSame <= args.cyrillic THEN
			opt.identEnc := args.cyrillic - Cli.CyrillicSame
		END
	END SetOptions;

	PROCEDURE Bin(res: INTEGER; args: Cli.Args;
	              module: Ast.Module; call: Ast.Call; opt: GeneratorC.Options;
	              cDirs, cc: ARRAY OF CHAR; VAR outC, bin: ARRAY OF CHAR;
	              VAR cmd: CComp.Compiler; tmp: ARRAY OF CHAR): INTEGER;
	VAR outCLen: INTEGER;
	    ret: INTEGER;
	    i, nameLen, cDirsLen: INTEGER;
	    ok: BOOLEAN;
	    name: ARRAY 512 OF CHAR;
	BEGIN
		ok := GetTempOutC(outC, outCLen, bin, module.name, tmp);
		IF ~ok THEN
			ret := Cli.ErrCantCreateOutDir
		ELSE
			IF cc[0] = Utf8.Null THEN
				ok := CComp.Search(cmd, res = Cli.ResultRun);
				IF ok & (args.cyrillic = Cli.CyrillicDefault) THEN
					opt.identEnc := IdentEncoderForCompiler(cmd.id)
				END
			ELSE
				ok := CComp.Set(cmd, cc)
			END;
			IF ~ok THEN
				ret := Cli.ErrCantFoundCCompiler
			ELSE
				ret := GenerateC(module, TRUE, call, opt, outC, outCLen, cDirs, cmd, TRUE)
			END;
			outC[outCLen] := Utf8.Null;
			IF ret = ErrNo THEN
				ok := ok
				    & CComp.AddOutput(cmd, bin)
				    & CComp.AddInclude(cmd, outC, 0);
				i := 0;
				WHILE ok & (cDirs[i] # Utf8.Null) DO
					nameLen := 0;
					cDirsLen := Strings.CalcLen(cDirs, i);
					ok := CComp.AddInclude(cmd, cDirs, i)

					    & Strings.CopyChars(name, nameLen, cDirs, i, i + cDirsLen)
					    & Strings.CopyCharsNull(name, nameLen, Exec.dirSep)
					    & Strings.CopyCharsNull(name, nameLen, "o7.c")

					    & (~Files.Exist(name, 0) OR CComp.AddC(cmd, name, 0));
					i := i + cDirsLen + 1
				END;
				ok := ok
				& (  (opt.memManager # GeneratorC.MemManagerCounter)
				  OR CComp.AddOpt(cmd, "-DO7_MEMNG_MODEL=O7_MEMNG_COUNTER")
				  )
				& (  (opt.memManager # GeneratorC.MemManagerGC)
				  OR CComp.AddOpt(cmd, "-DO7_MEMNG_MODEL=O7_MEMNG_GC")
				   & CComp.AddOpt(cmd, "-lgc")
				  )
				& (~Platform.Posix OR CComp.AddOpt(cmd, "-lm"));

				(* TODO *)
				ASSERT(ok);
				IF CComp.Do(cmd) # Exec.Ok THEN
					ret := Cli.ErrCCompiler
				END
			END
		END
		RETURN ret
	END Bin;

	PROCEDURE Run(bin: ARRAY OF CHAR; arg: INTEGER): INTEGER;
	VAR cmd: Exec.Code;
		buf: ARRAY Exec.CodeSize OF CHAR;
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
				CLI.SetExitCode(Exec.Ok + ORD(Exec.Do(cmd) # Exec.Ok));
				ret := ErrNo
			END
		END
		RETURN ret
	END Run;
BEGIN
	ASSERT(res IN Cli.ThroughC);

	opt := GeneratorC.DefaultOptions();
	SetOptions(opt, args);
	CASE res OF
	  Cli.ResultC:
		ASSERT(CComp.Set(ccomp, "cc"));
		ret := GenerateC(module, (call # NIL) OR args.script, call,
		                 opt, args.resPath, args.resPathLen, args.cDirs,
		                 ccomp, FALSE)
	| Cli.ResultBin, Cli.ResultRun:
		ret := Bin(res, args, module, call, opt, args.cDirs, args.cc, outC,
		           args.resPath, ccomp, args.tmp);
		IF (res = Cli.ResultRun) & (ret = ErrNo) THEN
			ret := Run(args.resPath, args.arg)
		END;
		IF (args.tmp = "") & ~FileSys.RemoveDir(outC) & (ret = ErrNo)
		THEN
			ret := Cli.ErrCantRemoveOutDir
		END
	END
	RETURN ret
END GenerateThroughC;

(* TODO *)
PROCEDURE GenerateProcType(name: Strings.String; t: Ast.ProcType;
                           VAR dir: ARRAY OF CHAR; dirLen: INTEGER;
                           VAR javac: JavaComp.Compiler; usejavac: BOOLEAN): File.Out;
VAR file: File.Out;
    ret, i: INTEGER;
    nm: ARRAY 4096 OF CHAR;
BEGIN
	i := 0;
	IF Strings.CopyToChars(nm, i, name) THEN
		ret := OpenJavaOutput(file, NIL, nm, dir, dirLen);
		(* TODO *)
		IF ret # ErrNo THEN
			file := NIL
		ELSIF usejavac THEN
			(* TODO *)
			ASSERT(JavaComp.AddJava(javac, dir, 0))
		END
	ELSE
		file := NIL
	END
	RETURN file
END GenerateProcType;

(* TODO *)
PROCEDURE ProvideProcTypeName(prov: GeneratorJava.ProviderProcTypeName;
                              proc: Ast.ProcType;
                              VAR name: Strings.String): File.Out;

	PROCEDURE Generate(VAR name: Strings.String;
	                   proc: Ast.ProcType; prov: ProcNameProvider): File.Out;
	VAR out: File.Out;
	BEGIN
		IF JavaStoreProcTypes.GenerateName(prov.store, proc, name) THEN
			out := GenerateProcType(name, proc,
		                 prov.dir, prov.dirLen,
		                 prov.javac, prov.usejavac)
		ELSE
			out := NIL
		END
		RETURN out
	END Generate;

	RETURN Generate(name, proc, prov(ProcNameProvider))
END ProvideProcTypeName;

PROCEDURE ProviderProcTypeNameNew(): ProcNameProvider;
VAR prov: ProcNameProvider;
BEGIN
	NEW(prov);
	IF (prov # NIL) & JavaStoreProcTypes.New(prov.store) THEN
		GeneratorJava.ProviderProcTypeNameInit(prov, ProvideProcTypeName)
	ELSE
		prov := NIL
	END
	RETURN prov
END ProviderProcTypeNameNew;

PROCEDURE GenerateJava(module: Ast.Module; cmd: Ast.Statement;
                       prov: GeneratorJava.ProviderProcTypeName;
                       opt: GeneratorJava.Options;
                       VAR dir: ARRAY OF CHAR; dirLen: INTEGER;
                       javaDirs: ARRAY OF CHAR;
                       VAR javac: JavaComp.Compiler; usejavac: BOOLEAN): INTEGER;
VAR imp: Ast.Declaration;
    ret, i, javaDirsLen, nameLen: INTEGER;
    name: ARRAY 512 OF CHAR;
    fileName: ARRAY 1024 OF CHAR;
    out: File.Out;
    sing: BOOLEAN;
BEGIN
	module.used := TRUE;

	ret := ErrNo;
	imp := module.import;
	WHILE (ret = ErrNo) & (imp # NIL) & (imp IS Ast.Import) DO
		IF ~imp.module.m.used THEN
			ret := GenerateJava(imp.module.m, NIL, prov, opt,
			                    dir, dirLen, javaDirs, javac, usejavac)
		END;
		imp := imp.next
	END;
	IF ret = ErrNo THEN
		sing := FALSE;
		IF module.mark THEN
			i := 0;
			WHILE javaDirs[i] # Utf8.Null DO
				nameLen := 0;
				javaDirsLen := Strings.CalcLen(javaDirs, i);
				(* TODO *)
				ASSERT(Strings.CopyChars(name, nameLen, javaDirs, i, i + javaDirsLen)
				     & Strings.CopyCharsNull(name, nameLen, Exec.dirSep)
				     & CopyModuleNameForFile(name, nameLen, module.name)
				     & Strings.CopyCharsNull(name, nameLen, ".java")
				);
				IF Files.Exist(name, 0) THEN
					sing := TRUE;
					ASSERT(~usejavac OR JavaComp.AddJava(javac, name, 0))
				END;
				i := i + javaDirsLen + 1
			END
			(* TODO проверка ошибки ненайденного файла *)
		END;
		IF ~sing & (ret = ErrNo) THEN
			ret := OpenJavaOutput(out, module, "", dir, dirLen);
			fileName := dir;
			IF ret = ErrNo THEN
				GeneratorJava.Generate(out, module, cmd, prov, opt);
				File.CloseOut(out);
				(* TODO *)
				ASSERT(JavaComp.AddJava(javac, fileName, 0))
			END
		END
	END
	RETURN ret
END GenerateJava;

PROCEDURE GenerateThroughJava(res: INTEGER; VAR args: Cli.Args;
                              module: Ast.Module; call: Ast.Statement): INTEGER;
VAR opt: GeneratorJava.Options;
    javac: JavaComp.Compiler;
    ret: INTEGER;
    out, mainClass: ARRAY 1024 OF CHAR;
    prov: ProcNameProvider;

	PROCEDURE SetOptions(opt: GeneratorJava.Options; args: Cli.Args);
	BEGIN
		IF 0 <= args.init THEN
			(* TODO проверять соответствие *)
			opt.varInit := args.init
		END;
		IF args.noOverflowCheck THEN
			opt.checkArith := FALSE
		END;
		IF Cli.CyrillicSame <= args.cyrillic THEN
			opt.identEnc := args.cyrillic - Cli.CyrillicSame
		END
	END SetOptions;

	PROCEDURE Class(m: Ast.Module; VAR args: Cli.Args; call: Ast.Statement;
	                prov: ProcNameProvider;
	                opt: GeneratorJava.Options;
	                VAR outJava, mainClass: ARRAY OF CHAR): INTEGER;
	VAR ret: INTEGER;
	    i, nameLen, dirsLen, outJavaLen: INTEGER;
	    ok: BOOLEAN;
	    name: ARRAY 512 OF CHAR;
	BEGIN
		ok := GetTempOut(outJava, outJavaLen, m.name, args.tmp);
		IF ~ok THEN
			ret := Cli.ErrCantCreateOutDir
		ELSE
			IF args.resPath[0] = Utf8.Null THEN
				args.resPathLen := 0;
				ASSERT(Strings.CopyChars(args.resPath, args.resPathLen,
				                         outJava, 0, outJavaLen))
			END;
			prov.dirLen := 0;
			ASSERT(Strings.CopyChars(prov.dir, prov.dirLen,
			                         outJava, 0, outJavaLen));

			ASSERT(GetMainClass(mainClass, m.name));
			IF args.javac[0] # Utf8.Null THEN
				ok := JavaComp.Set(prov.javac, args.javac)
			ELSE
				ok := JavaComp.Search(prov.javac);
				opt.identEnc := GeneratorJava.IdentEncSame
			END;
			ok := ok & JavaComp.AddClassPath(prov.javac, args.resPath, 0);
			prov.usejavac := TRUE;
			IF ~ok THEN
				ret := Cli.ErrCantFoundJavaCompiler
			ELSE
				ret := GenerateJava(m, call, prov, opt,
				                    outJava, outJavaLen,
				                    args.javaDirs, prov.javac, TRUE)
			END;
			outJava[outJavaLen] := Utf8.Null;
			IF ret = ErrNo THEN
				ok := JavaComp.AddDestinationDir(prov.javac, args.resPath);

				i := 0;
				WHILE ok & (args.javaDirs[i] # Utf8.Null) DO
					nameLen := 0;
					dirsLen := Strings.CalcLen(args.javaDirs, i);
					ok := Strings.CopyChars(name, nameLen, args.javaDirs, i, i + dirsLen)
					    & Strings.CopyCharsNull(name, nameLen, Exec.dirSep)
					    & Strings.CopyCharsNull(name, nameLen, "O7.java")

					    & ( ~Files.Exist(name, 0)
					     OR JavaComp.AddJava(prov.javac, name, 0)
					      );
					i := i + dirsLen + 1
				END;
				(* TODO *)
				ASSERT(ok);
				IF JavaComp.Do(prov.javac) # Exec.Ok THEN
					ret := Cli.ErrJavaCompiler
				END
			END
		END
		RETURN ret
	END Class;

	PROCEDURE Run(outClass, mainClass: ARRAY OF CHAR; arg: INTEGER): INTEGER;
	VAR cmd: Exec.Code;
	    buf: ARRAY Exec.CodeSize OF CHAR;
	    len: INTEGER;
	    ret: INTEGER;
	BEGIN
		JavaExec.Init(cmd);
		ret := Cli.ErrTooLongRunArgs;
		IF JavaExec.AddClassPath(cmd, outClass, 0)
		 & Exec.Add(cmd, mainClass, 0)
		THEN
			INC(arg);
			len := 0;
			WHILE (arg < CLI.count)
			    & CLI.Get(buf, len, arg)
			    & Exec.Add(cmd, buf, 0)
			DO
				len := 0;
				INC(arg)
			END;
			IF CLI.count <= arg THEN
				CLI.SetExitCode(Exec.Ok + ORD(Exec.Do(cmd) # Exec.Ok));
				ret := ErrNo
			END
		END
		RETURN ret
	END Run;
BEGIN
	ASSERT(res IN Cli.ThroughJava);

	prov := ProviderProcTypeNameNew();
	opt := GeneratorJava.DefaultOptions();
	SetOptions(opt, args);
	ASSERT(JavaComp.Set(javac, "javac"));

	CASE res OF
	  Cli.ResultJava:
		prov.dirLen := 0;
		ASSERT(Strings.CopyChars(prov.dir, prov.dirLen,
		                         args.resPath, 0, args.resPathLen));
		prov.usejavac := FALSE;
		IF (call = NIL) & args.script THEN
			call := Ast.NopNew()
		END;
		ret := GenerateJava(module, call,
		                    prov, opt,
		                    args.resPath, args.resPathLen, args.javaDirs,
		                    javac, FALSE)
	| Cli.ResultClass, Cli.ResultRunJava:
		IF call = NIL THEN
			call := Ast.NopNew()
		END;
		ret := Class(module, args, call, prov, opt, out, mainClass);
		IF (res = Cli.ResultRunJava) & (ret = ErrNo) THEN
			ret := Run(out, mainClass, args.arg)
		END;
		IF (args.tmp = "") & ~FileSys.RemoveDir(out) & (ret = ErrNo)
		THEN
			ret := Cli.ErrCantRemoveOutDir
		END
	END

	RETURN ret
END GenerateThroughJava;

PROCEDURE Translate*(res: INTEGER; VAR args: Cli.Args): INTEGER;
VAR ret: INTEGER;
    mp: ModuleProvider;
    module: Ast.Module;
    call: Ast.Call;
    tranOpt: AstTransform.Options;
BEGIN
	NewProvider(mp, args);

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
			Message.AstError(ret); Message.Ln
		ELSIF res IN Cli.ThroughJava THEN
			Ast.ModuleReopen(module);
			AstTransform.DefaultOptions(tranOpt);
			AstTransform.Do(module, tranOpt);
			ret := GenerateThroughJava(res, args, module, call)
		ELSE
			ret := GenerateThroughC(res, args, module, call)
		END
	END;
	IF mp.modules.last # NIL THEN
		mp.modules.last.next := NIL;
		Unlink(mp.modules.first.next)
	END
	RETURN ret
END Translate;

PROCEDURE Help*;
BEGIN
	Message.Usage(TRUE)
END Help;

PROCEDURE Handle(VAR args: Cli.Args; VAR ret: INTEGER): BOOLEAN;
BEGIN
	IF ret = Cli.CmdHelp THEN
		Help
	ELSE
		ret := Translate(ret, args)
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
		CLI.SetExitCode(Exec.Ok + 1);
		IF ret # ErrParse THEN
			Message.CliError(ret)
		END
	END
END Start;

END Translator.
