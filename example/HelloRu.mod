MODULE HelloRu;

 IMPORT Out;

 PROCEDURE Вывод(строка: ARRAY OF CHAR);
 BEGIN
   Out.String(строка);
   Out.Ln
 END Вывод;

 PROCEDURE Привет*;
 BEGIN
   Вывод("Ну, привет.")
 END Привет;

 PROCEDURE Go*;
 BEGIN
   Привет
 END Go;

END HelloRu.
