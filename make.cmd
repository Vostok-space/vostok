@set CC=tcc
@set SING=..\singularity\bootstrap\singularity

@mkdir result\self

@cd singularity\bootstrap
%CC% Arithmetic.c Scanner.c Ast.c StringStore.c GeneratorC.c TextGenerator.c Limits.c Translator.c TranslatorLimits.c Log.c Utf8.c MessageEn.c V.c Out.c VDataStream.c Parser.c VFileStream.c PlatformExec.c singularity\CFiles.c singularity\CLI.c singularity\o7c.c singularity\OsExec.c -I . -I singularity -o ..\..\result\bs-o7c.exe
@cd ..\..

result\bs-o7c to-c Translator.Start result -infr . -m source

@cd result
%CC% Arithmetic.c Scanner.c Ast.c StringStore.c GeneratorC.c TextGenerator.c TypeLimits.c Translator.c TranslatorLimits.c Log.c Utf8.c MessageEn.c V.c Out.c VDataStream.c Parser.c VFileStream.c PlatformExec.c %SING%\CFiles.c %SING%\CLI.c %SING%\o7c.c %SING%\OsExec.c %SING%\OsEnv.c %SING%\Platform.c -I . -I %SING% -o o7c.exe
@cd ..

result\o7c.exe to-bin Translator.Start result\self\o7c.exe -infr . -m source -cc %CC%
