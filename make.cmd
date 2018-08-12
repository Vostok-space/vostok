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

@ECHO Compiler is %CC%

@SET SING=..\..\singularity\bootstrap\singularity

@MKDIR result\v0 result\v1 2>NUL

@CD singularity\bootstrap
@%CC% Arithmetic.c Scanner.c Ast.c StringStore.c GeneratorC.c TextGenerator.c TypeLimits.c Translator.c TranslatorLimits.c Log.c Message.c V.c Out.c VDataStream.c Parser.c VFileStream.c PlatformExec.c CliParser.c singularity\CFiles.c singularity\CLI.c singularity\o7.c singularity\OsExec.c singularity\Platform.c singularity\OsEnv.c -I . -I singularity -o ..\..\result\bs-o7c.exe
@CD ..\..

@ECHO:
@ECHO Bootstrap version of translator was built. Info about next steps:
@ECHO   result\bs-o7c run make.Help -infr . -m source
