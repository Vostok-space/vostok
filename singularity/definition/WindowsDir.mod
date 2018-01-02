MODULE WindowsDir;

 TYPE
   FindData* = POINTER TO RECORD
   END;

   FindId* = POINTER TO RECORD
   END;

 PROCEDURE FindFirst*(VAR id: FindId; VAR d: FindData;
                      filespec: ARRAY OF CHAR; ofs: INTEGER): BOOLEAN;
 BEGIN
   ASSERT(FALSE)
   RETURN FALSE
 END FindFirst;

 PROCEDURE FindNext*(VAR d: FindData; id: FindId): BOOLEAN;
 BEGIN
   ASSERT(FALSE)
   RETURN FALSE
 END FindNext;

 PROCEDURE Close*(VAR id: FindId): BOOLEAN;
 BEGIN
   ASSERT(FALSE)
   RETURN FALSE
 END Close;

 PROCEDURE CopyName*(VAR buf: ARRAY OF CHAR; VAR ofs: INTEGER; f: FindData): BOOLEAN;
 BEGIN
   ASSERT(FALSE)
   RETURN FALSE
 END CopyName;

END WindowsDir.
