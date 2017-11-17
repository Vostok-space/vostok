@set CC=tcc
@set SING_BS=..\singularity\bootstrap\singularity
@set SING_IMPL=..\..\singularity\implementation

@mkdir result\self

@cd singularity\bootstrap
%CC% Arithmetic.c Scanner.c Ast.c StringStore.c GeneratorC.c TextGenerator.c Limits.c Translator.c TranslatorLimits.c Log.c Utf8.c MessageEn.c V.c Out.c VDataStream.c Parser.c VFileStream.c PlatformExec.c singularity\CFiles.c singularity\CLI.c singularity\o7c.c singularity\OsExec.c -I . -I singularity -o ..\..\result\bs-o7c.exe
@cd ..\..

result\bs-o7c to-c Translator.Start result -infr . -m source

@cd result
%CC% Arithmetic.c Scanner.c Ast.c StringStore.c GeneratorC.c TextGenerator.c TypeLimits.c Translator.c TranslatorLimits.c Log.c Utf8.c MessageEn.c V.c Out.c VDataStream.c Parser.c VFileStream.c PlatformExec.c %SING_BS%\CFiles.c %SING_BS%\CLI.c %SING_BS%\o7c.c %SING_BS%\OsExec.c %SING_BS%\OsEnv.c %SING_BS%\Platform.c -I . -I %SING_BS% -o o7c.exe
@cd ..

result\o7c.exe to-c Translator.Start result\self -infr . -m source

@cd result\self
%CC% Arithmetic.c Scanner.c Ast.c StringStore.c GeneratorC.c TextGenerator.c TypeLimits.c Translator.c TranslatorLimits.c Log.c Utf8.c MessageEn.c V.c Out.c VDataStream.c Parser.c VFileStream.c PlatformExec.c %SING_IMPL%\CFiles.c %SING_IMPL%\CLI.c %SING_IMPL%\o7.c %SING_IMPL%\OsExec.c %SING_IMPL%\OsEnv.c %SING_IMPL%\Platform.c -I . -I %SING_IMPL% -o o7c.exe
@cd ..\..

