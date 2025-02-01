Приводило к ошибке, найденной AlexBogy

MODULE PtrRecCfg0;

 IMPORT SYSTEM;

 PROCEDURE Go*;
 TYPE
  P = POINTER TO R;
  R = RECORD END;
 BEGIN
  IF SYSTEM.SIZE(P) > 0 THEN ; END
 END Go;
 
END PtrRecCfg0.
