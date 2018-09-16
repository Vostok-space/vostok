@echo off
@SET CC=cl
@cl >NUL
@IF %ERRORLEVEL%==0 GOTO FOUND

@ECHO can not found C compiler: cl
@EXIT

:FOUND

@ECHO Compiler is %CC%

@MKDIR result\v0 result\v1 2>NUL

@CD singularity\bootstrap
:: @%CC% /c /TP - Режим C++
@%CC% /c Arithmetic.c Scanner.c Ast.c StringStore.c GeneratorC.c TextGenerator.c TypeLimits.c Translator.c Log.c Message.c V.c Out.c VDataStream.c Parser.c VFileStream.c PlatformExec.c CliParser.c singularity\CFiles.c singularity\CLI.c singularity\o7.c singularity\OsExec.c singularity\Platform.c singularity\OsEnv.c /I. /Isingularity
link *.obj /SUBSYSTEM:CONSOLE /out:..\..\result\bs-o7c.exe
@CD ..\..

@ECHO:
@ECHO Bootstrap version of translator was built. Info about next steps:
@ECHO   result\bs-o7c run make.Help -infr . -m source
