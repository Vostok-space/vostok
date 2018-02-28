MODULE Привіт;

 IMPORT Out;

 PROCEDURE Вивід(строка: ARRAY OF CHAR);
 BEGIN
   Out.String(строка);
   Out.Ln
 END Вивід;

 PROCEDURE Привіт*;
 BEGIN
   Вивід("Ну, привіт.")
 END Привіт;

END Привіт.
