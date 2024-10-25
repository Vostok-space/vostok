MODULE Привіт;

 IMPORT Out;

 PROCEDURE Вивід(об'єкт: ARRAY OF CHAR);
 BEGIN
   Out.String(об'єкт);
   Out.Ln
 END Вивід;

 PROCEDURE Привіт*;
 BEGIN
   Вивід("Ну, привіт.")
 END Привіт;

END Привіт.
