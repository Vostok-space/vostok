(*  Command line interface for Oberon-07 translator
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
MODULE Translator;

IMPORT
	V,
	Log := DLog,
	Out,
	CLI,
	Stream := VDataStream,
	File := VFileStream,
	Utf8,
	Chars0X,
	Strings := StringStore,
	SpecIdentChecker,
	Parser,
	Ast,
	AstTransform,
	GeneratorOberon,
	GeneratorC,
	GeneratorJava,
	GeneratorJs,
	GenOptions,
	JavaStoreProcTypes,
	Exec := PlatformExec,
	CComp := CCompilerInterface,
	JavaComp := JavaCompilerInterface,
	JavaExec := JavaExecInterface,
	Jar := JarInterface,
	Message,
	MessageErrOberon,
	InterfaceLang,
	PlatformMessagesLang,
	DirForTemp,
	Cli := CliParser,
	Platform,
	Files := CFiles,
	OsEnv, OsUtil,
	FileSys := FileSystemUtil,
	VCopy,
	Mem := VMemStream,
	JsExec := JavaScriptExecInterface, JsEval, MemStreamToJsEval,
	ModulesStorage, ModulesProvider, InputProvider, FileProvider,
	OsSelfMemInfo,
	TranslatorVersion;

CONST
	ErrNo*             =  0;
	ErrParse*          = -1;
	ErrCantGenJsToMem* = -2;

	OptLog*     = 0;
	OptMemInfo* = 1;
	OptAll*     = {0 .. 1};

	LangC   = 1;
	Java    = 2;
	Js      = 3;
	Oberon  = 4;

TYPE
	ProcNameProvider = POINTER TO RECORD(GeneratorJava.RProviderProcTypeName)
		javac   : JavaComp.Compiler;
		usejavac: BOOLEAN;

		store : JavaStoreProcTypes.Store;

		dir   : ARRAY 1024 OF CHAR;
		dirLen: INTEGER
	END;

	MsgTempDirCreated* = RECORD(V.Message)
	END;

PROCEDURE ErrorMessage(code: INTEGER; str: Strings.String);
BEGIN
	IF code <= Parser.ErrAstBegin THEN
		MessageErrOberon.Ast(code - Parser.ErrAstBegin, str)
	ELSE
		MessageErrOberon.Syntax(code)
	END
END ErrorMessage;

PROCEDURE IndexedErrorMessage(index, code: INTEGER; str: Strings.String;
                              line, column: INTEGER);
BEGIN
	Out.String("  ");
	Out.Int(index, 2); Out.String(") ");

	ErrorMessage(code, str);

	Out.String(" "); Out.Int(line + 1, 0);
	Out.String(" : "); Out.Int(column, 0);
	Out.Ln
END IndexedErrorMessage;

PROCEDURE PrintErrors(mc: ModulesStorage.Container; module: Ast.Module);
CONST SkipError = Ast.ErrImportModuleWithError + Parser.ErrAstBegin;
VAR i: INTEGER;
    err: Ast.Error;
    m: Ast.Module;
BEGIN
	i := 0;
	m := ModulesStorage.Next(mc);
	WHILE m # NIL DO
		err := m.errors;
		WHILE (err # NIL) & (err.code = SkipError) DO
			err := err.next
		END;
		IF err # NIL THEN
			MessageErrOberon.Text("Found errors in the module ");
			(*TODO*)
			Out.String(m.name.block.s); Out.String(": "); Out.Ln;
			err := m.errors;
			WHILE err # NIL DO
				IF err.code # SkipError THEN
					INC(i);
					IndexedErrorMessage(i, err.code, err.str, err.line, err.column)
				END;
				err := err.next
			END
		END;
		m := ModulesStorage.Next(mc)
	END;
	IF i = 0 THEN
		IndexedErrorMessage(i, module.errors.code, module.errors.str,
		                    module.errors.line, module.errors.column)
	END
END PrintErrors;

PROCEDURE CopyModuleNameForFile(VAR str: ARRAY OF CHAR; VAR len: INTEGER;
                                name: Strings.String;
                                lang: INTEGER): BOOLEAN;
BEGIN
	ASSERT(lang IN {LangC, Java, Js, Oberon});

	RETURN Strings.CopyToChars(str, len, name)
	     & (~(   SpecIdentChecker.IsSpecModuleName(name)
	          OR (lang = LangC) & SpecIdentChecker.IsSpecCHeaderName(name)
	         )
	     OR Chars0X.PutChar(str, len, "_")
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
	IF ~Chars0X.CopyString   (dir, destLen, OsUtil.DirSep)
	OR ~CopyModuleNameForFile(dir, destLen, module.name, LangC)
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

				ret := ErrNo
			END
		END
	END
	RETURN ret
END OpenCOutput;

PROCEDURE OpenSingleOutput(VAR out: File.Out;
                           module: Ast.Module; orName, ext: ARRAY OF CHAR;
                           errOpen: INTEGER;
                           VAR dir: ARRAY OF CHAR; dirLen: INTEGER;
                           lang: INTEGER): INTEGER;
VAR destLen: INTEGER;
    ret: INTEGER;
BEGIN
	out := NIL;
	destLen := dirLen;
	IF ~Chars0X.CopyString(dir, destLen, OsUtil.DirSep)
	OR ~((module # NIL) & CopyModuleNameForFile(dir, destLen, module.name, lang)
	  OR (module = NIL) & Chars0X.CopyString   (dir, destLen, orName)
	    )
	OR ~Chars0X.CopyString(dir, destLen, ext)
	THEN
		ret := Cli.ErrTooLongOutName
	ELSE
		out := File.OpenOut(dir);
		IF out = NIL THEN
			ret := errOpen
		ELSE
			ret := ErrNo
		END
	END
	RETURN ret
END OpenSingleOutput;

PROCEDURE OpenJavaOutput(VAR out: File.Out;
                         module: Ast.Module; orName: ARRAY OF CHAR;
                         VAR dir: ARRAY OF CHAR; dirLen: INTEGER): INTEGER;

	RETURN OpenSingleOutput(out, module, orName, ".java", Cli.ErrOpenJava,
	                        dir, dirLen, Java)
END OpenJavaOutput;

PROCEDURE OpenJsOutput(VAR out: File.Out;
                       module: Ast.Module; orName: ARRAY OF CHAR;
                       VAR dir: ARRAY OF CHAR; dirLen: INTEGER): INTEGER;

	RETURN OpenSingleOutput(out, module, orName, ".js", Cli.ErrOpenJs,
	                        dir, dirLen, Js)
END OpenJsOutput;

PROCEDURE OpenOberonOutput(VAR out: File.Out;
                           module: Ast.Module; ext: ARRAY OF CHAR;
                           VAR dir: ARRAY OF CHAR; dirLen: INTEGER): INTEGER;

	RETURN OpenSingleOutput(out, module, "", ext, Cli.ErrOpenOberon,
	                        dir, dirLen, Oberon)
END OpenOberonOutput;

PROCEDURE NewProvider(VAR p: ModulesStorage.Provider; VAR opt: Parser.Options;
                      args: Cli.Args);
VAR inp: InputProvider.P; m: ModulesProvider.Provider;
BEGIN
	IF FileProvider.New(inp, args.modPath, args.modPathLen, args.sing)
	 & ModulesProvider.New(m, inp)
	THEN
		ModulesStorage.New(p, m);

		Parser.DefaultOptions(opt);
		opt.printError  := ErrorMessage;
		opt.cyrillic    := args.cyrillic # Cli.CyrillicNo;
		opt.multiErrors := args.multiErrors;
		opt.provider    := p;
		ModulesProvider.SetParserOptions(m, opt)
	ELSE
		(* TODO *)
	END
END NewProvider;

PROCEDURE IsModuleInSingularity(module: Ast.Module; dirs: ARRAY OF CHAR;
                                lang: INTEGER; ext: ARRAY OF CHAR;
                                VAR name: ARRAY OF CHAR): BOOLEAN;
VAR sing: BOOLEAN; nameLen, i: INTEGER;
BEGIN
	sing := FALSE;
	IF module.mark THEN
		i := 0;
		WHILE ~sing & (dirs[i] # Utf8.Null) DO
			nameLen := 0;
			(* TODO *)
			ASSERT(Chars0X.Copy      (name, nameLen, dirs, i)
			     & Chars0X.CopyString(name, nameLen, OsUtil.DirSep)
			     & CopyModuleNameForFile(name, nameLen, module.name, lang)
			     & Chars0X.CopyString(name, nameLen, ext)
			);
			INC(i);
			IF Files.Exist(name, 0) THEN
				sing := TRUE
			ELSIF lang = LangC THEN
				name[nameLen - 1] := "h";
				sing := Files.Exist(name, 0);
				name[0] := Utf8.Null
				(* TODO *)
			END
		END
	END
	RETURN sing
END IsModuleInSingularity;

(* TODO Возможно, вместо сcomp и usecc лучше процедурная переменная *)
PROCEDURE GenerateC(module: Ast.Module; isMain: BOOLEAN; cmd: Ast.Statement;
                    opt: GeneratorC.Options;
                    VAR dir: ARRAY OF CHAR; dirLen: INTEGER;
                    cDirs: ARRAY OF CHAR;
                    VAR ccomp: CComp.Compiler; usecc: BOOLEAN): INTEGER;
VAR imp: Ast.Declaration;
    ret: INTEGER;
    name: ARRAY 512 OF CHAR;
    iface, impl: File.Out;
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
		IF ~IsModuleInSingularity(module, cDirs, LangC, ".c", name) THEN
			ret := OpenCOutput(iface, impl, module, isMain, dir, dirLen, ccomp, usecc);
			IF ret = ErrNo THEN
				GeneratorC.Generate(iface, impl, module, cmd, opt);
				File.CloseOut(iface);
				File.CloseOut(impl)
			END
		ELSIF name[0] # Utf8.Null THEN
			ASSERT(~usecc OR CComp.AddC(ccomp, name, 0))
		END
	END
	RETURN ret
END GenerateC;

PROCEDURE GetTempOut(VAR dirOut: ARRAY OF CHAR; VAR len: INTEGER;
                     name: Strings.String; VAR tmp: ARRAY OF CHAR;
                     VAR listener: V.Base): BOOLEAN;
VAR i: INTEGER;
    ok, saveTemp: BOOLEAN;
    tmpCreated: MsgTempDirCreated;
BEGIN
	len := 0;
	IF tmp # "" THEN
		ok := Chars0X.CopyString(dirOut, len, tmp)
	ELSE
		ok := DirForTemp.Get     (dirOut, len)
		    & Chars0X.CopyString (dirOut, len, "ost-")
		    & Strings.CopyToChars(dirOut, len, name)
	END;

	IF ok THEN
		i := 0;
		ok := FileSys.MakeDir(dirOut);
		IF ~ok & (tmp = "") THEN
			WHILE ~ok & (i < 100) DO
				IF i = 0 THEN
					ASSERT(Chars0X.CopyString(dirOut, len, "-00"))
				ELSE
					dirOut[len - 2] := CHR(ORD("0") + i DIV 10);
					dirOut[len - 1] := CHR(ORD("0") + i MOD 10)
				END;
				ok := FileSys.MakeDir(dirOut);
				INC(i)
			END
		END;
		IF ok THEN
			i := 0;
			IF tmp # "" THEN
				saveTemp := V.Do(listener, tmpCreated)
			ELSE
				ok := Chars0X.CopyString(tmp, i, dirOut);
				saveTemp := V.Do(listener, tmpCreated);
				IF ~saveTemp THEN
					tmp := ""
				END
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
	RETURN Chars0X.CopyString(bin, len, dir)
	     & Chars0X.CopyString(bin, len, OsUtil.DirSep)
	     & Strings.CopyToChars(bin, len, name)
	     & (~Platform.Windows OR Chars0X.CopyString(bin, len, ".exe"))
END GetCBin;

PROCEDURE GetMainClass(VAR bin: ARRAY OF CHAR; name: Strings.String): BOOLEAN;
VAR len: INTEGER;
BEGIN
	len := 0;
	RETURN Chars0X.CopyString (bin, len, "o7.")
	     & Strings.CopyToChars(bin, len, name)
END GetMainClass;

PROCEDURE GetTempOutC(VAR dirCOut: ARRAY OF CHAR; VAR len: INTEGER;
                      VAR bin: ARRAY OF CHAR; name: Strings.String;
                      VAR tmp: ARRAY OF CHAR;
                      VAR listener: V.Base): BOOLEAN;
VAR ok: BOOLEAN;
BEGIN
	ok := GetTempOut(dirCOut, len, name, tmp, listener);
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
		enc := GenOptions.IdentEncTranslit
	| CComp.Zig, CComp.Clang, CComp.Tiny:
		enc := GenOptions.IdentEncSame
	| CComp.Gnu:
		enc := GenOptions.IdentEncEscUnicode
	END
	RETURN enc
END IdentEncoderForCompiler;

PROCEDURE SetCommonOptions(VAR opt: GenOptions.R; args: Cli.Args);
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
	END;
	IF args.noIndexCheck THEN
		opt.checkIndex := FALSE
	END;
END SetCommonOptions;

PROCEDURE GenerateThroughC(res: INTEGER; VAR args: Cli.Args;
                           module: Ast.Module; call: Ast.Statement;
                           VAR listener: V.Base): INTEGER;
VAR ret: INTEGER;
    opt: GeneratorC.Options;
    ccomp: CComp.Compiler;
    outC: ARRAY 1024 OF CHAR;

	PROCEDURE SetOptions(opt: GeneratorC.Options; args: Cli.Args);
	BEGIN
		opt.plan9 := args.cPlan9;
		SetCommonOptions(opt^, args);
		IF 0 <= args.memng THEN
			opt.memManager := args.memng
		END;
		IF args.noNilCheck THEN
			opt.checkNil := FALSE
		END;
		IF 0 <= args.cStd THEN
			opt.std := args.cStd
		END
	END SetOptions;

	PROCEDURE Bin(res: INTEGER; args: Cli.Args;
	              module: Ast.Module; call: Ast.Statement; opt: GeneratorC.Options;
	              cDirs, cc: ARRAY OF CHAR; VAR outC, bin: ARRAY OF CHAR;
	              VAR cmd: CComp.Compiler; VAR tmp: ARRAY OF CHAR;
	              VAR listener: V.Base): INTEGER;
	VAR outCLen: INTEGER;
	    ret: INTEGER;
	    ccEnd: INTEGER;
	    ok: BOOLEAN;

	    PROCEDURE IncludeCdirsAndAddO7c(VAR cmd: CComp.Compiler; cDirs: ARRAY OF CHAR): BOOLEAN;
	    VAR ok, o7c: BOOLEAN; i, nameLen: INTEGER; name: ARRAY 512 OF CHAR;
		BEGIN
			i := 0;
			o7c := FALSE;
			ok := TRUE;
			WHILE ok & (cDirs[i] # Utf8.Null) DO
				nameLen := 0;
				ok := CComp.AddInclude(cmd, cDirs, i);
				IF ~o7c & ok THEN
					ok := Chars0X.Copy      (name, nameLen, cDirs, i)
					    & Chars0X.CopyString(name, nameLen, OsUtil.DirSep)
					    & Chars0X.CopyString(name, nameLen, "o7.c");
					o7c := ok & Files.Exist(name, 0);
					IF o7c THEN
						ok := CComp.AddC(cmd, name, 0)
					END;
					INC(i)
				ELSE
					INC(i, Chars0X.CalcLen(cDirs, i) + 1)
				END
			END
			RETURN ok
		END IncludeCdirsAndAddO7c;
	BEGIN
		ok := GetTempOutC(outC, outCLen, bin, module.name, tmp, listener);
		IF ~ok THEN
			ret := Cli.ErrCantCreateOutDir
		ELSE
			ccEnd := Chars0X.CalcLen(cc, 0);
			IF ccEnd = 0 THEN
				ok := CComp.Search(cmd, res = Cli.ResultRun)
			ELSE
				ok := CComp.Set(cmd, cc)
			END;

			IF ~ok THEN
				ret := Cli.ErrCantFoundCCompiler
			ELSE
				IF args.cyrillic = Cli.CyrillicDefault THEN
					opt.identEnc := IdentEncoderForCompiler(cmd.id)
				END;
				ret := GenerateC(module, TRUE, call, opt, outC, outCLen, cDirs, cmd, TRUE)
			END;
			outC[outCLen] := Utf8.Null;
			IF ret = ErrNo THEN
				ok := ok
				    & CComp.AddOutputExe(cmd, bin)
				    & CComp.AddInclude(cmd, outC, 0)
				    & IncludeCdirsAndAddO7c(cmd, cDirs)
				    & (  (opt.memManager # GeneratorC.MemManagerCounter)
				      OR CComp.AddOpt(cmd, "-DO7_MEMNG_MODEL=O7_MEMNG_COUNTER")
				      )
				    & (  (opt.memManager # GeneratorC.MemManagerGC)
				      OR CComp.AddOpt(cmd, "-DO7_MEMNG_MODEL=O7_MEMNG_GC")
				       & CComp.AddOpt(cmd, "-lgc")
				      )
				    & (~Platform.Posix OR CComp.AddOpt(cmd, "-lm"));

				IF ok & (ccEnd < LEN(cc) - 1) & (cc[ccEnd + 1] # Utf8.Null)
				THEN
					ok := CComp.AddOptByOfs(cmd, cc, ccEnd + 1)
				END;

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
			len := 0;
			WHILE (arg < CLI.count)
			    & CLI.Get(buf, len, arg)
			    & Exec.Add(cmd, buf)
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
		           args.resPath, ccomp, args.tmp, listener);
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
                              VAR name: Strings.String): Stream.POut;

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
    ret: INTEGER;
    name: ARRAY 512 OF CHAR;
    fileName: ARRAY 1024 OF CHAR;
    out: File.Out;
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
		IF IsModuleInSingularity(module, javaDirs, Java, ".java", name) THEN
			(* TODO *)
			ASSERT(~usejavac OR JavaComp.AddJava(javac, name, 0))
		ELSE
			ret := OpenJavaOutput(out, module, "", dir, dirLen);
			fileName := dir;
			IF ret = ErrNo THEN
				GeneratorJava.Generate(out, module, cmd, prov, opt);
				File.CloseOut(out);
				(* TODO *)
				ASSERT(~usejavac OR JavaComp.AddJava(javac, fileName, 0))
			END
		END
	END
	RETURN ret
END GenerateJava;

PROCEDURE GenerateThroughJava(res: INTEGER; VAR args: Cli.Args;
                              module: Ast.Module; call: Ast.Statement;
                              VAR listener: V.Base): INTEGER;
VAR opt: GeneratorJava.Options;
    javac: JavaComp.Compiler;
    ret: INTEGER;
    out, mainClass: ARRAY 1024 OF CHAR;
    prov: ProcNameProvider;

	PROCEDURE Class(m: Ast.Module; res: INTEGER; VAR args: Cli.Args; call: Ast.Statement;
	                prov: ProcNameProvider;
	                opt: GeneratorJava.Options;
	                VAR outJava, mainClass: ARRAY OF CHAR;
	                VAR listener: V.Base): INTEGER;
	VAR ret: INTEGER;
	    i, nameLen, outJavaLen: INTEGER;
	    ok: BOOLEAN;
	    name: ARRAY 512 OF CHAR;
	BEGIN
		ok := GetTempOut(outJava, outJavaLen, m.name, args.tmp, listener);
		IF ~ok THEN
			ret := Cli.ErrCantCreateOutDir
		ELSE
			IF args.resPath = "" THEN
				args.resPathLen := 0;
				ASSERT(Chars0X.CopyChars(args.resPath, args.resPathLen,
				                         outJava, 0, outJavaLen))
			END;
			prov.dirLen := 0;
			ASSERT(Chars0X.CopyChars(prov.dir, prov.dirLen,
			                         outJava, 0, outJavaLen));

			ASSERT(GetMainClass(mainClass, m.name));
			IF args.javac # "" THEN
				ok := JavaComp.Set(prov.javac, args.javac)
			ELSE
				ok := JavaComp.Search(prov.javac) & JavaComp.Debug(prov.javac);
				opt.identEnc := GenOptions.IdentEncSame
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
				IF res = Cli.ResultJar THEN
					ok := JavaComp.AddDestinationDir(prov.javac, outJava)
				ELSE
					ok := JavaComp.AddDestinationDir(prov.javac, args.resPath)
				END;

				i := 0;
				WHILE ok & (args.javaDirs[i] # Utf8.Null) DO
					nameLen := 0;
					ok := Chars0X.Copy      (name, nameLen, args.javaDirs, i)
					    & Chars0X.CopyString(name, nameLen, OsUtil.DirSep)
					    & Chars0X.CopyString(name, nameLen, "O7.java")

					    & ( ~Files.Exist(name, 0)
					     OR JavaComp.AddJava(prov.javac, name, 0)
					      );
					INC(i)
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

	PROCEDURE ToJar(out, mainClass, res: ARRAY OF CHAR): INTEGER;
	VAR jar: Jar.T; ret: INTEGER;
	BEGIN
		Jar.Init(jar);
		IF Jar.Create(jar, res)
		 & Jar.MainClass(jar, mainClass)
		 & Jar.Clean(jar, " o7/*.class ")
		THEN
			ret := Jar.Do(jar, out);
			IF ret # Jar.ErrNo THEN
				IF ret > 0 THEN
					ret := Cli.ErrJarExec
				ELSE
					ASSERT(Cli.ErrJarSetDirBefore - Cli.ErrJarGetCurrentDir = Jar.ErrGetCurrentDir);
					INC(ret, Cli.ErrJarGetCurrentDir + 1)
				END
			END
		ELSE
			ret := Cli.ErrTooLongJarArgs
		END
		RETURN ret
	END ToJar;

	PROCEDURE Run(outClass, mainClass: ARRAY OF CHAR; arg: INTEGER): INTEGER;
	VAR cmd: Exec.Code;
	    buf: ARRAY Exec.CodeSize OF CHAR;
	    len: INTEGER;
	    ret: INTEGER;
	BEGIN
		JavaExec.Init(cmd);
		ret := Cli.ErrTooLongRunArgs;
		IF JavaExec.AddClassPath(cmd, outClass, 0)
		 & Exec.Add(cmd, mainClass)
		THEN
			len := 0;
			WHILE (arg < CLI.count)
			    & CLI.Get(buf, len, arg)
			    & Exec.Add(cmd, buf)
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
	SetCommonOptions(opt^, args);
	ASSERT(JavaComp.Set(javac, "javac"));

	IF res = Cli.ResultJava THEN
		prov.dirLen := 0;
		ASSERT(Chars0X.CopyChars(prov.dir, prov.dirLen,
		                         args.resPath, 0, args.resPathLen));
		prov.usejavac := FALSE;
		ret := GenerateJava(module, call,
		                    prov, opt,
		                    args.resPath, args.resPathLen, args.javaDirs,
		                    javac, FALSE)
	ELSE
		ret := Class(module, res, args, call, prov, opt, out, mainClass, listener);

		IF ret # ErrNo THEN
			;
		ELSIF res = Cli.ResultRunJava THEN
			ret := Run(out, mainClass, args.arg)
		ELSIF res = Cli.ResultJar THEN
			ret := ToJar(out, mainClass, args.resPath)
		END;
		IF (args.tmp = "") & ~FileSys.RemoveDir(out) & (ret = ErrNo) THEN
			ret := Cli.ErrCantRemoveOutDir
		END
	END
	RETURN ret
END GenerateThroughJava;

PROCEDURE CopyFileToOutIfExist(inName: ARRAY OF CHAR; out: Stream.POut; VAR opened: BOOLEAN): BOOLEAN;
VAR in: File.In;
BEGIN
	in := File.OpenIn(inName);
	opened := in # NIL;
	IF opened THEN
		VCopy.UntilEnd(in^, out^);
		File.CloseIn(in)
	END
	RETURN TRUE(*TODO*)
END CopyFileToOutIfExist;

PROCEDURE AppendModuleName(VAR name: ARRAY OF CHAR; VAR nameLen: INTEGER;
                           module: Ast.Module; ext: ARRAY OF CHAR
                           ): BOOLEAN;
BEGIN
	RETURN Chars0X.CopyString   (name, nameLen, OsUtil.DirSep)
	     & CopyModuleNameForFile(name, nameLen, module.name, Js)
	     & Chars0X.CopyString   (name, nameLen, ext)
END AppendModuleName;

PROCEDURE GenerateJs1(module: Ast.Module; cmd: Ast.Statement;
                      outSingle: Stream.POut;
                      opt: GeneratorJs.Options;
                      VAR dir: ARRAY OF CHAR; dirLen: INTEGER;
                      jsDirs: ARRAY OF CHAR): INTEGER;
VAR imp: Ast.Declaration;
    ret: INTEGER;
    name: ARRAY 512 OF CHAR;
    sing: BOOLEAN;
    out: File.Out;
BEGIN
	module.used := TRUE;

	ret := ErrNo;
	imp := module.import;
	WHILE (ret = ErrNo) & (imp # NIL) & (imp IS Ast.Import) DO
		IF ~imp.module.m.used THEN
			ret := GenerateJs1(imp.module.m, NIL, outSingle, opt, dir, dirLen, jsDirs)
		END;
		imp := imp.next
	END;
	IF ret = ErrNo THEN
		IF IsModuleInSingularity(module, jsDirs, Js, ".js", name) THEN
			(* TODO *)
			ASSERT((outSingle = NIL) OR CopyFileToOutIfExist(name, outSingle, sing))
		ELSIF outSingle = NIL THEN
			ret := OpenJsOutput(out, module, "", dir, dirLen);
			IF ret = ErrNo THEN
				GeneratorJs.Generate(out, module, cmd, opt);
				File.CloseOut(out)
			END
		ELSE
			GeneratorJs.Generate(outSingle, module, cmd, opt)
		END
	END
	RETURN ret
END GenerateJs1;

PROCEDURE CopyO7js(jsDirs: ARRAY OF CHAR; out: Stream.POut);
VAR i: INTEGER; name: ARRAY 1024 OF CHAR; ignore: BOOLEAN;

	PROCEDURE Name(VAR name: ARRAY OF CHAR; dir: ARRAY OF CHAR; VAR ofs: INTEGER): BOOLEAN;
	VAR len: INTEGER; ok: BOOLEAN;
	BEGIN
		len := 0;
		ok := Chars0X.Copy      (name, len, dir, ofs)
		    & Chars0X.CopyString(name, len, OsUtil.DirSep)
		    & Chars0X.CopyString(name, len, "o7.js");
		INC(ofs)
		RETURN ok
	END Name;
BEGIN
	i := 0;
	WHILE (jsDirs[i] # Utf8.Null)
	    & Name(name, jsDirs, i)
	    & CopyFileToOutIfExist(name, out, ignore)
	DO
		;
	END
END CopyO7js;

PROCEDURE GenerateJs(module: Ast.Module; cmd: Ast.Statement;
                     toSingleFile: BOOLEAN;
                     opt: GeneratorJs.Options;
                     VAR dir: ARRAY OF CHAR; dirLen: INTEGER;
                     jsDirs: ARRAY OF CHAR): INTEGER;
VAR out: File.Out; ret: INTEGER;
BEGIN
	ret := ErrNo;
	out := NIL;
	IF toSingleFile THEN
		out := File.OpenOut(dir);

		IF out = NIL THEN
			ret := Cli.ErrOpenJs
		ELSE
			GeneratorJs.GenerateOptions(out, opt);
			CopyO7js(jsDirs, out)
		END
	END;
	IF ret = ErrNo THEN
		ret := GenerateJs1(module, cmd, out, opt, dir, dirLen, jsDirs)
	END;
	File.CloseOut(out)
	RETURN ret
END GenerateJs;

PROCEDURE GenerateThroughJs(res: INTEGER; VAR args: Cli.Args;
                            module: Ast.Module; call: Ast.Statement;
                            VAR listener: V.Base): INTEGER;
VAR opt: GeneratorJs.Options;
    ret: INTEGER;
    out: ARRAY 1024 OF CHAR;
    outLen: INTEGER;

	PROCEDURE TempJs(m: Ast.Module; VAR args: Cli.Args; call: Ast.Statement;
	                 opt: GeneratorJs.Options;
	                 VAR out: ARRAY OF CHAR; VAR dirLen: INTEGER;
	                 VAR listener: V.Base): INTEGER;
	VAR ret: INTEGER;
	    outLen: INTEGER;
	    ok: BOOLEAN;
	BEGIN
		ok := GetTempOut(out, dirLen, m.name, args.tmp, listener);
		IF ~ok THEN
			ret := Cli.ErrCantCreateOutDir
		ELSE
			IF args.resPath = "" THEN
				args.resPathLen := 0;
				ASSERT(Chars0X.CopyChars(args.resPath, args.resPathLen,
				                         out, 0, dirLen))
			END;
			(* TODO *)
			outLen := dirLen;
			ASSERT(AppendModuleName(out, outLen, m, ".js"));

			ret := GenerateJs(m, call, TRUE, opt,
			                  out, outLen,
			                  args.jsDirs);
		END
		RETURN ret
	END TempJs;

	PROCEDURE RunJs(m: Ast.Module; call: Ast.Statement;
	                opt: GeneratorJs.Options; jsDirs: ARRAY OF CHAR;
	                arg: INTEGER): INTEGER;
	VAR ret: INTEGER; out: Mem.Out; code: JsEval.Code;
	    blank: ARRAY 1 OF CHAR; blankLen: INTEGER;
	BEGIN
		IF ~Mem.New(out) THEN
			(* TODO *)
			ret := Cli.ErrOpenJs
		ELSE
			blankLen := 0;
			GeneratorJs.GenerateOptions(out, opt);
			CopyO7js(jsDirs, out);
			ret := GenerateJs1(m, call, out, opt,
			                   blank, blankLen,
			                   jsDirs);
			IF ret = ErrNo THEN
				code := MemStreamToJsEval.Do(out, arg);
				IF code = NIL THEN
					ret := ErrCantGenJsToMem
				ELSE
					CLI.SetExitCode(Exec.Ok + ORD(~JsEval.Do(code)))
				END
			END
		END
		RETURN ret
	END RunJs;

	PROCEDURE Run(file: ARRAY OF CHAR; arg: INTEGER): INTEGER;
	VAR cmd: Exec.Code;
	    buf: ARRAY Exec.CodeSize OF CHAR;
	    len: INTEGER;
	    ret: INTEGER;
	BEGIN
		JsExec.Init(cmd);
		ret := Cli.ErrTooLongRunArgs;
		IF JsExec.File(cmd, file, 0) THEN
			len := 0;
			WHILE (arg < CLI.count)
			    & CLI.Get(buf, len, arg)
			    & Exec.Add(cmd, buf)
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
	ASSERT(res IN Cli.ThroughJs);

	opt := GeneratorJs.DefaultOptions();
	SetCommonOptions(opt^, args);

	CASE res OF
	  Cli.ResultJs:
		ret := GenerateJs(module, call, args.toSingleFile, opt,
		                  args.resPath, args.resPathLen, args.jsDirs)
	| Cli.ResultRunJs:
		IF JsEval.supported THEN
			ret := RunJs(module, call, opt, args.jsDirs, args.arg)
		ELSE
			ret := TempJs(module, args, call, opt, out, outLen, listener);
			IF (res = Cli.ResultRunJs) & (ret = ErrNo) THEN
				ret := Run(out, args.arg)
			END;
			out[outLen] := Utf8.Null;
			IF (args.tmp = "") & ~FileSys.RemoveDir(out) & (ret = ErrNo)
			THEN
				ret := Cli.ErrCantRemoveOutDir
			END
		END
	END

	RETURN ret
END GenerateThroughJs;

PROCEDURE GenerateOberon(module: Ast.Module; opt: GeneratorOberon.Options;
                         VAR dir: ARRAY OF CHAR; dirLen: INTEGER): INTEGER;
VAR imp: Ast.Declaration; ret: INTEGER; out: File.Out; ext: ARRAY 5 OF CHAR;
BEGIN
	module.used := TRUE;

	ret := ErrNo;
	imp := module.import;
	WHILE (ret = ErrNo) & (imp # NIL) & (imp IS Ast.Import) DO
		IF ~imp.module.m.used THEN
			ret := GenerateOberon(imp.module.m, opt, dir, dirLen)
		END;
		imp := imp.next
	END;
	IF (ret = ErrNo)
	 & (~module.mark OR (opt.std # GeneratorOberon.StdO7(*TODO*)) OR opt.declaration)
	THEN
		IF opt.declaration THEN
			ext := ".dfn"
		ELSIF opt.std = GeneratorOberon.StdAo THEN
			ext := ".Mod"
		ELSE
			ext := ".mod"
		END;
		ret := OpenOberonOutput(out, module, ext, dir, dirLen);
		IF ret = ErrNo THEN
			GeneratorOberon.Generate(out, module, opt);
			File.CloseOut(out);
		END
	END
	RETURN ret
END GenerateOberon;

PROCEDURE GenerateThroughOberon(res: INTEGER;
                                VAR args: Cli.Args; module: Ast.Module;
                                VAR listener: V.Base): INTEGER;
VAR opt: GeneratorOberon.Options;
    ret: INTEGER;
BEGIN
	opt := GeneratorOberon.DefaultOptions();
	SetCommonOptions(opt^, args);
	IF args.obStd >= 0 THEN
		opt.std := args.obStd;
		IF args.obStd # GeneratorOberon.StdO7 THEN
			opt.multibranchWhile := FALSE
		END;
	END;
	opt.declaration := res = Cli.ResultDecl;

	ret := GenerateOberon(module, opt, args.resPath, args.resPathLen)

	RETURN ret
END GenerateThroughOberon;

PROCEDURE Translate*(res: INTEGER; VAR args: Cli.Args; VAR listener: V.Base): INTEGER;
VAR ret: INTEGER;
    mp: ModulesStorage.Provider;
    module: Ast.Module;
    call: Ast.Call;
    cmd: Ast.Statement;
    tranOpt: AstTransform.Options;
    opt: Parser.Options;
    str: Strings.String;
    save: CHAR;
BEGIN
	NewProvider(mp, opt, args);

	ASSERT(opt.provider # NIL);

	IF args.script THEN
		module := Parser.Script(args.src, opt)
	ELSE
		save := args.src[args.srcNameEnd];
		args.src[args.srcNameEnd] := Utf8.Null;
		module := Ast.ProvideModule(mp, NIL, args.src);
		args.src[args.srcNameEnd] := save
	END;
	IF module = NIL THEN
		ret := ErrParse
	ELSIF module.errors # NIL THEN
		ret := ErrParse;
		PrintErrors(ModulesStorage.Iterate(mp), module)
	ELSE
		IF ~args.script & (args.srcNameEnd < args.srcLen - 1) THEN
			ret := Ast.CommandGet(call, module,
			                      args.src, args.srcNameEnd + 1, args.srcLen - 1);
			cmd := call
		ELSE
			ret := ErrNo;
			cmd := NIL
		END;
		IF ret # Ast.ErrNo THEN
			Strings.Undef(str);
			MessageErrOberon.Ast(ret, str); MessageErrOberon.Ln;
			ret := ErrParse
		ELSIF res IN Cli.ThroughJava + Cli.ThroughJs THEN
			Ast.ModuleReopen(module);
			AstTransform.DefaultOptions(tranOpt);
			AstTransform.Do(module, tranOpt);
			IF res IN Cli.ThroughJava THEN
				ret := GenerateThroughJava(res, args, module, cmd, listener)
			ELSE ASSERT(res IN Cli.ThroughJs);
				ret := GenerateThroughJs(res, args, module, cmd, listener)
			END
		ELSIF res IN Cli.ThroughC THEN
			ret := GenerateThroughC(res, args, module, cmd, listener)
		ELSE ASSERT(res IN Cli.ThroughMod);
			ret := GenerateThroughOberon(res, args, module, listener)
		END
	END;
	(*
	ModulesStorage.Unlink(mp)
	*)
	RETURN ret
END Translate;

PROCEDURE Help*;
BEGIN
	Message.Usage(TRUE)
END Help;

PROCEDURE Version*;
BEGIN
	MessageErrOberon.Text("ost ");
	MessageErrOberon.Text(TranslatorVersion.Val);
	MessageErrOberon.Ln
END Version;

PROCEDURE Handle(VAR args: Cli.Args; VAR ret: INTEGER; VAR listener: V.Base): BOOLEAN;
BEGIN
	IF ret = Cli.CmdHelp THEN
		Help
	ELSIF ret = Cli.CmdVersion THEN
		Version
	ELSE
		ret := Translate(ret, args, listener)
	END
	RETURN 0 <= ret
END Handle;

PROCEDURE MemInfo*;
VAR size: INTEGER;
BEGIN
	size := OsSelfMemInfo.Get();
	IF size > 0 THEN
		Out.String("Used memory: ");
		Out.Int(size, 0);
		Out.String(" KiB");
		Out.Ln
	END
END MemInfo;

PROCEDURE GoOpt*(set: SET);
VAR ret, lang: INTEGER;
    args: Cli.Args;
    nothing: V.Base;

	PROCEDURE Enabled(VAR ret: INTEGER): BOOLEAN;
	BEGIN
		IF    (ret IN Cli.ThroughC   ) & ~GeneratorC     .Supported THEN
			ret := Cli.ErrDisabledGenC
		ELSIF (ret IN Cli.ThroughJava) & ~GeneratorJava  .Supported THEN
			ret := Cli.ErrDisabledGenJava
		ELSIF (ret IN Cli.ThroughJs  ) & ~GeneratorJs    .Supported THEN
			ret := Cli.ErrDisabledGenJs
		ELSIF (ret IN Cli.ThroughMod ) & ~GeneratorOberon.Supported THEN
			ret := Cli.ErrDisabledGenOberon
		END
		RETURN ret >= 0
	END Enabled;
BEGIN
	ASSERT(set - OptAll = {});

	Out.Open;
	IF ~(OptLog IN set) THEN
		Log.Off
	END;

	IF PlatformMessagesLang.Get(lang) THEN
		InterfaceLang.Set(lang)
	END;

	V.Init(nothing);
	IF ~Cli.Parse(args, ret) OR ~Enabled(ret) OR ~Handle(args, ret, nothing) THEN
		CLI.SetExitCode(Exec.Ok + 1);
		IF ret # ErrParse THEN
			Message.CliError(ret)
		END
	END;

	IF OptMemInfo IN set THEN
		MemInfo
	END
END GoOpt;

PROCEDURE Go*;
BEGIN
	GoOpt({})
END Go;

END Translator.
