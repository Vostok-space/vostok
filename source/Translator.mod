(*  Command line interface for Oberon-07 translator
 *  Copyright (C) 2016-2019 ComdivByZero
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
	Log,
	Out,
	CLI,
	Stream := VDataStream,
	File := VFileStream,
	Utf8,
	Chars0X,
	Strings := StringStore,
	SpecIdentChecker,
	Parser,
	Scanner,
	Ast,
	AstTransform,
	GeneratorC,
	GeneratorJava,
	GeneratorJs,
	JavaStoreProcTypes,
	TranLim := TranslatorLimits,
	Exec := PlatformExec,
	CComp := CCompilerInterface,
	JavaComp := JavaCompilerInterface,
	JavaExec := JavaExecInterface,
	JsExec := JavascriptExecInterface,
	Message,
	Cli := CliParser,
	Platform,
	Files := CFiles,
	OsEnv,
	FileSys := FileSystemUtil,
	Text := TextGenerator,
	VCopy,
	Mem := VMemStream,
	JsEval, MemStreamToJsEval,
	ModulesStorage, ModulesProvider;

CONST
	ErrNo*             =  0;
	ErrParse*          = -1;
	ErrCantGenJsToMem* = -2;

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
		Message.AstError(code - Parser.ErrAstBegin, str)
	ELSE
		Message.ParseError(code)
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

PROCEDURE PrintErrors(multiErrors: BOOLEAN;
                      mc: ModulesStorage.Container; module: Ast.Module);
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
			Message.Text("Found errors in the module ");
			Out.String(m.name.block.s); Out.String(": "); Out.Ln;
			err := m.errors;
			WHILE err # NIL DO
				IF err.code # SkipError THEN
					INC(i);
					IndexedErrorMessage(i, err.code, err.str, err.line, err.column)
				END;
				IF multiErrors THEN
					err := err.next
				ELSE
					err := NIL
				END
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
                                name: Strings.String): BOOLEAN;
	RETURN Strings.CopyToChars(str, len, name)
	     & (~SpecIdentChecker.IsSpecModuleName(name)
	     OR Chars0X.CopyChar(str, len, "_")
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
	IF ~Chars0X.CopyString   (dir, destLen, Exec.dirSep)
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

				ret := ErrNo
			END
		END
	END
	RETURN ret
END OpenCOutput;

PROCEDURE OpenSingleOutput(VAR out: File.Out;
                           module: Ast.Module; orName, ext: ARRAY OF CHAR;
                           errOpen: INTEGER;
                           VAR dir: ARRAY OF CHAR; dirLen: INTEGER): INTEGER;
VAR destLen: INTEGER;
    ret: INTEGER;
BEGIN
	out := NIL;
	destLen := dirLen;
	IF ~Chars0X.CopyString(dir, destLen, Exec.dirSep)
	OR ~((module # NIL) & CopyModuleNameForFile(dir, destLen, module.name)
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
	                        dir, dirLen)
END OpenJavaOutput;

PROCEDURE OpenJsOutput(VAR out: File.Out;
                       module: Ast.Module; orName: ARRAY OF CHAR;
                       VAR dir: ARRAY OF CHAR; dirLen: INTEGER): INTEGER;

	RETURN OpenSingleOutput(out, module, orName, ".js", Cli.ErrOpenJs,
	                        dir, dirLen)
END OpenJsOutput;

PROCEDURE NewProvider(VAR p: ModulesStorage.Provider; VAR opt: Parser.Options;
                      args: Cli.Args);
VAR m: ModulesProvider.Provider;
BEGIN
	ModulesProvider.New(m, args.modPath, args.modPathLen, args.sing);
	ModulesStorage.New(p, m);

	Parser.DefaultOptions(opt);
	opt.printError  := ErrorMessage;
	opt.cyrillic    := args.cyrillic # Cli.CyrillicNo;
	opt.provider    := p;
	opt.multiErrors := args.multiErrors;

	ModulesProvider.SetParserOptions(m, opt)
END NewProvider;

(* TODO Возможно, вместо сcomp и usecc лучше процедурная переменная *)
PROCEDURE GenerateC(module: Ast.Module; isMain: BOOLEAN; cmd: Ast.Statement;
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
			WHILE ~sing & (cDirs[i] # Utf8.Null) DO
				nameLen := 0;
				cDirsLen := Chars0X.CalcLen(cDirs, i);
				(* TODO *)
				ASSERT(Chars0X.CopyChars (name, nameLen, cDirs, i, i + cDirsLen)
				     & Chars0X.CopyString(name, nameLen, Exec.dirSep)
				     & CopyModuleNameForFile(name, nameLen, module.name)
				     & Chars0X.CopyString(name, nameLen, ".c")
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
                     name: Strings.String; VAR tmp: ARRAY OF CHAR;
                     VAR listener: V.Base): BOOLEAN;
VAR i: INTEGER;
    ok, saveTemp: BOOLEAN;
    tmpCreated: MsgTempDirCreated;
BEGIN
	len := 0;
	IF tmp # "" THEN
		ok := TRUE;
		ASSERT(Chars0X.CopyString(dirOut, len, tmp))
	ELSIF Platform.Posix THEN
		ok := TRUE;
		ASSERT(Chars0X.CopyString (dirOut, len, "/tmp/ost-")
		     & Strings.CopyToChars(dirOut, len, name))
	ELSE ASSERT(Platform.Windows);
		ok := OsEnv.Get(dirOut, len, "temp")
		    & Chars0X.CopyString (dirOut, len, "\ost-")
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
					tmp[0] := Utf8.Null
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
	     & Chars0X.CopyString(bin, len, Exec.dirSep)
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
		enc := GeneratorC.IdentEncTranslit
	| CComp.Clang, CComp.Tiny:
		enc := GeneratorC.IdentEncSame
	| CComp.Gnu:
		enc := GeneratorC.IdentEncEscUnicode
	END
	RETURN enc
END IdentEncoderForCompiler;

PROCEDURE GenerateThroughC(res: INTEGER; VAR args: Cli.Args;
                           module: Ast.Module; call: Ast.Statement;
                           VAR listener: V.Base): INTEGER;
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
	              module: Ast.Module; call: Ast.Statement; opt: GeneratorC.Options;
	              cDirs, cc: ARRAY OF CHAR; VAR outC, bin: ARRAY OF CHAR;
	              VAR cmd: CComp.Compiler; VAR tmp: ARRAY OF CHAR;
	              VAR listener: V.Base): INTEGER;
	VAR outCLen: INTEGER;
	    ret: INTEGER;
	    i, nameLen, cDirsLen, ccEnd: INTEGER;
	    ok: BOOLEAN;
	    name: ARRAY 512 OF CHAR;
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
				    & CComp.AddInclude(cmd, outC, 0);
				i := 0;
				WHILE ok & (cDirs[i] # Utf8.Null) DO
					nameLen := 0;
					cDirsLen := Chars0X.CalcLen(cDirs, i);
					ok := CComp.AddInclude(cmd, cDirs, i)

					    & Chars0X.CopyChars (name, nameLen, cDirs, i, i + cDirsLen)
					    & Chars0X.CopyString(name, nameLen, Exec.dirSep)
					    & Chars0X.CopyString(name, nameLen, "o7.c")

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
			WHILE ~sing & (javaDirs[i] # Utf8.Null) DO
				nameLen := 0;
				javaDirsLen := Chars0X.CalcLen(javaDirs, i);
				(* TODO *)
				ASSERT(Chars0X.CopyChars(name, nameLen, javaDirs, i, i + javaDirsLen)
				     & Chars0X.CopyString(name, nameLen, Exec.dirSep)
				     & CopyModuleNameForFile(name, nameLen, module.name)
				     & Chars0X.CopyString(name, nameLen, ".java")
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
	                VAR outJava, mainClass: ARRAY OF CHAR;
	                VAR listener: V.Base): INTEGER;
	VAR ret: INTEGER;
	    i, nameLen, dirsLen, outJavaLen: INTEGER;
	    ok: BOOLEAN;
	    name: ARRAY 512 OF CHAR;
	BEGIN
		ok := GetTempOut(outJava, outJavaLen, m.name, args.tmp, listener);
		IF ~ok THEN
			ret := Cli.ErrCantCreateOutDir
		ELSE
			IF args.resPath[0] = Utf8.Null THEN
				args.resPathLen := 0;
				ASSERT(Chars0X.CopyChars(args.resPath, args.resPathLen,
				                         outJava, 0, outJavaLen))
			END;
			prov.dirLen := 0;
			ASSERT(Chars0X.CopyChars(prov.dir, prov.dirLen,
			                         outJava, 0, outJavaLen));

			ASSERT(GetMainClass(mainClass, m.name));
			IF args.javac[0] # Utf8.Null THEN
				ok := JavaComp.Set(prov.javac, args.javac)
			ELSE
				ok := JavaComp.Search(prov.javac) & JavaComp.Debug(prov.javac);
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
					dirsLen := Chars0X.CalcLen(args.javaDirs, i);
					ok := Chars0X.CopyChars (name, nameLen, args.javaDirs, i, i + dirsLen)
					    & Chars0X.CopyString(name, nameLen, Exec.dirSep)
					    & Chars0X.CopyString(name, nameLen, "O7.java")

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
	SetOptions(opt, args);
	ASSERT(JavaComp.Set(javac, "javac"));

	CASE res OF
	  Cli.ResultJava:
		prov.dirLen := 0;
		ASSERT(Chars0X.CopyChars(prov.dir, prov.dirLen,
		                         args.resPath, 0, args.resPathLen));
		prov.usejavac := FALSE;
		ret := GenerateJava(module, call,
		                    prov, opt,
		                    args.resPath, args.resPathLen, args.javaDirs,
		                    javac, FALSE)
	| Cli.ResultClass, Cli.ResultRunJava:
		ret := Class(module, args, call, prov, opt, out, mainClass, listener);
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

PROCEDURE CopyFileToOut(inName: ARRAY OF CHAR; out: Stream.POut): BOOLEAN;
VAR in: File.In; ok: BOOLEAN;
BEGIN
	in := File.OpenIn(inName);
	ok := in # NIL;
	IF ok THEN
		VCopy.UntilEnd(in^, out^);
		File.CloseIn(in)
	END
	RETURN ok
END CopyFileToOut;

PROCEDURE AppendModuleName(VAR name: ARRAY OF CHAR; VAR nameLen: INTEGER;
                           module: Ast.Module; ext: ARRAY OF CHAR
                           ): BOOLEAN;
BEGIN
	RETURN Chars0X.CopyString   (name, nameLen, Exec.dirSep)
	     & CopyModuleNameForFile(name, nameLen, module.name)
	     & Chars0X.CopyString   (name, nameLen, ext)
END AppendModuleName;

PROCEDURE GenerateJs1(module: Ast.Module; cmd: Ast.Statement;
                      outSingle: Stream.POut;
                      opt: GeneratorJs.Options;
                      VAR dir: ARRAY OF CHAR; dirLen: INTEGER;
                      jsDirs: ARRAY OF CHAR): INTEGER;
VAR imp: Ast.Declaration;
    ret, i, jsDirsLen, nameLen: INTEGER;
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
		sing := FALSE;
		IF module.mark THEN
			i := 0;
			WHILE ~sing & (jsDirs[i] # Utf8.Null) DO
				nameLen := 0;
				jsDirsLen := Chars0X.CalcLen(jsDirs, i);
				(* TODO *)
				ASSERT(Chars0X.CopyChars    (name, nameLen, jsDirs, i, i + jsDirsLen)
				     & Chars0X.CopyString   (name, nameLen, Exec.dirSep)
				     & CopyModuleNameForFile(name, nameLen, module.name)
				     & Chars0X.CopyString   (name, nameLen, ".js")
				);
				IF Files.Exist(name, 0) THEN
					sing := TRUE;
					IF outSingle # NIL THEN
						(* TODO *)
						ASSERT(CopyFileToOut(name, outSingle))
					END
				END;
				i := i + jsDirsLen + 1
			END
			(* TODO проверка ошибки ненайденного файла *)
		END;
		IF ~sing & (ret = ErrNo) THEN
			IF outSingle = NIL THEN
				ret := OpenJsOutput(out, module, "", dir, dirLen);
				IF ret = ErrNo THEN
					GeneratorJs.Generate(out, module, cmd, opt);
					File.CloseOut(out)
				END
			ELSE
				GeneratorJs.Generate(outSingle, module, cmd, opt)
			END;
		END
	END
	RETURN ret
END GenerateJs1;

PROCEDURE CopyO7js(jsDirs: ARRAY OF CHAR; out: Stream.POut);
VAR i: INTEGER; name: ARRAY 1024 OF CHAR;

	PROCEDURE Name(VAR name: ARRAY OF CHAR; dir: ARRAY OF CHAR; VAR ofs: INTEGER): BOOLEAN;
	VAR nameLen, dirLen: INTEGER; ok: BOOLEAN;
	BEGIN
		nameLen := 0;
		dirLen := Chars0X.CalcLen(dir, ofs);
		ok := Chars0X.CopyChars (name, nameLen, dir, ofs, ofs + dirLen)
		    & Chars0X.CopyString(name, nameLen, Exec.dirSep)
		    & Chars0X.CopyString(name, nameLen, "o7.js");
		INC(ofs, dirLen + 1)
		RETURN ok
	END Name;
BEGIN
	i := 0;
	WHILE (jsDirs[i] # Utf8.Null)
	    & Name(name, jsDirs, i)
	    & (~Files.Exist(name, 0) OR CopyFileToOut(name, out))
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

	PROCEDURE SetOptions(opt: GeneratorJs.Options; args: Cli.Args);
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
			IF args.resPath[0] = Utf8.Null THEN
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
	SetOptions(opt, args);

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

PROCEDURE Translate*(res: INTEGER; VAR args: Cli.Args; VAR listener: V.Base): INTEGER;
VAR ret: INTEGER;
    mp: ModulesStorage.Provider;
    module: Ast.Module;
    call: Ast.Call;
    cmd: Ast.Statement;
    tranOpt: AstTransform.Options;
    opt: Parser.Options;
    str: Strings.String;
BEGIN
	NewProvider(mp, opt, args);

	ASSERT(opt.provider # NIL);

	IF args.script THEN
		module := Parser.Script(args.src, opt)
	ELSE
		module := ModulesStorage.GetModule(mp, NIL, args.src, 0, args.srcNameEnd)
	END;
	IF module = NIL THEN
		ret := ErrParse
	ELSIF module.errors # NIL THEN
		ret := ErrParse;
		PrintErrors(args.multiErrors, ModulesStorage.Iterate(mp), module)
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
			Message.AstError(ret, str); Message.Ln;
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
		ELSE ASSERT(res IN Cli.ThroughC);
			ret := GenerateThroughC(res, args, module, cmd, listener)
		END
	END;
	ModulesStorage.Unlink(mp)
	RETURN ret
END Translate;

PROCEDURE Help*;
BEGIN
	Message.Usage(TRUE)
END Help;

PROCEDURE Handle(VAR args: Cli.Args; VAR ret: INTEGER; VAR listener: V.Base): BOOLEAN;
BEGIN
	IF ret = Cli.CmdHelp THEN
		Help
	ELSIF ret = Cli.CmdVersion THEN
		Message.Text("ost 0.0.2.dev")
	ELSE
		ret := Translate(ret, args, listener)
	END
	RETURN 0 <= ret
END Handle;

PROCEDURE Start*;
VAR ret: INTEGER;
    args: Cli.Args;
    nothing: V.Base;
BEGIN
	Out.Open;
	Log.Off;

	V.Init(nothing);
	IF ~Cli.Parse(args, ret) OR ~Handle(args, ret, nothing) THEN
		CLI.SetExitCode(Exec.Ok + 1);
		IF ret # ErrParse THEN
			Message.CliError(ret)
		END
	END
END Start;

END Translator.
