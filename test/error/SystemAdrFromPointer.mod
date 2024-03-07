MODULE SystemAdrFromPointer;

 IMPORT SYSTEM;

 PROCEDURE Go*;
 VAR adr: INTEGER; r: RECORD a: ARRAY 11 OF POINTER TO RECORD END END;
 BEGIN
  adr := SYSTEM.ADR(adr);
  adr := SYSTEM.ADR(r)
 END Go;

END SystemAdrFromPointer.
