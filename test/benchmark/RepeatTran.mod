MODULE RepeatTran;

 IMPORT Translator;

 PROCEDURE Go*(count: INTEGER);
 VAR i: INTEGER;
 BEGIN
   FOR i := 1 TO count DO
     Translator.Start
   END
 END Go;

END RepeatTran.
