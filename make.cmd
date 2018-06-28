@SET CC=tcc
@tcc -version >NUL
@IF %ERRORLEVEL%==0 GOTO FOUND

@SET CC=gcc
@gcc --version >NUL
@IF %ERRORLEVEL%==0 GOTO FOUND

@SET CC=clang
@clang --version >NUL
@IF %ERRORLEVEL%==0 GOTO FOUND

@ECHO can not found C compiler: tcc, gcc, clang
@EXIT

:FOUND

@ECHO C compiler is %CC%

@SET SING=..\..\singularity\bootstrap\singularity

@MKDIR result\v0 result\v1

@CD singularity\bootstrap
%CC% Arithmetic.c Scanner.c Ast.c StringStore.c GeneratorC.c TextGenerator.c TypeLimits.c Translator.c TranslatorLimits.c Log.c Utf8.c Message.c MessageEn.c MessageRu.c V.c Out.c VDataStream.c Parser.c VFileStream.c PlatformExec.c CliParser.c singularity\CFiles.c singularity\CLI.c singularity\o7.c singularity\OsExec.c singularity\Platform.c singularity\OsEnv.c -I . -I singularity -o ..\..\result\bs-o7c.exe
@CD ..\..

result\bs-o7c to-c Translator.Start result\v0 -infr . -m source

@CD result\v0

%CC% Arithmetic.c Scanner.c Ast.c StringStore.c GeneratorC.c TextGenerator.c TypeLimits.c Translator.c TranslatorLimits.c Log.c Utf8.c Message.c MessageEn.c MessageRu.c MessageUa.c LocaleParser.c Chars0X.c V.c Out.c VDataStream.c Parser.c VFileStream.c PlatformExec.c CliParser.c OberonSpecIdent.c Utf8Transform.c SpecIdentChecker.c CCompilerInterface.c FileSystemUtil.c %SING%\CFiles.c %SING%\CLI.c %SING%\o7.c %SING%\OsExec.c %SING%\OsEnv.c %SING%\Platform.c -I . -I %SING% -o ..\o7c.exe
@CD ..\..

result\o7c to-bin Translator.Start result\v1\o7c.exe -infr . -m source -cc %CC%
