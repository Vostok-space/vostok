MODULE ImportAlias;

 IMPORT Out := log, log := Out; 

 PROCEDURE Go*;
 BEGIN
  log.String("Import.Go"); Out.sn(", Import.Go")
 END Go;
 
END ImportAlias.
