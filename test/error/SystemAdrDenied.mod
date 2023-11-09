MODULE SystemAdrDenied;

 IMPORT SYSTEM, Rand := OsRand, Variables;

 CONST Count* = 8;  AddrReserved = 8;

 PROCEDURE OutReserved*;
 VAR a: ARRAY AddrReserved + 1 OF INTEGER; i: INTEGER;
 BEGIN
  FOR i := 0 TO LEN(a) - 1 DO
    a[i] := SYSTEM.ADR(a[i])
  END;
  SYSTEM.GET(a[0], i)
 END OutReserved;

 PROCEDURE ParamValue(a: ARRAY OF CHAR);
  PROCEDURE Do(a: INTEGER);
  BEGIN
    SYSTEM.PUT(a, " ")
  END Do;
 BEGIN
  Do(SYSTEM.ADR(a[0]))
 END ParamValue;

 PROCEDURE ImportedVar*;
  PROCEDURE Do(a: INTEGER);
  VAR s: ARRAY 4 OF BYTE;
  BEGIN
    SYSTEM.COPY(SYSTEM.ADR(s), a, 1)
  END Do;
 BEGIN
  Do(SYSTEM.ADR(Variables.data))
 END ImportedVar;

 PROCEDURE PutOversizeInt*;
 VAR b: ARRAY 3 OF BYTE;
 BEGIN
  SYSTEM.PUT(SYSTEM.ADR(b), 111)
 END PutOversizeInt;

 PROCEDURE GetOversizeInt*;
 VAR b: ARRAY 2 OF BYTE; i: INTEGER;
 BEGIN
  SYSTEM.GET(SYSTEM.ADR(b), i)
 END GetOversizeInt;

 PROCEDURE GetOversizeReal*;
 VAR b: ARRAY 3 OF BYTE; ign: REAL;
 BEGIN
  SYSTEM.GET(SYSTEM.ADR(b), ign)
 END GetOversizeReal;

 PROCEDURE go*(p: INTEGER); VAR a: ARRAY 3 OF CHAR;
  PROCEDURE AdrLocal(): INTEGER;
  VAR i: INTEGER;
  RETURN
    SYSTEM.ADR(i)
  END AdrLocal;

  PROCEDURE AdrPartOfAllocated(): INTEGER;
  VAR p: POINTER TO RECORD i: INTEGER END;
  BEGIN
    NEW(p)
  RETURN
    SYSTEM.ADR(p.i)
  END AdrPartOfAllocated;

 BEGIN
  IF p DIV Count = 0 THEN
    CASE p OF
     0: SYSTEM.PUT(AdrLocal(), 233)
    |1: SYSTEM.PUT(AdrPartOfAllocated(), {1,3})
    |2: OutReserved
    |3: a := ""; ParamValue(a)
    |4: ImportedVar
    |5: PutOversizeInt
    |6: GetOversizeInt
    |7: GetOversizeReal
    END
  END
 END go;

 PROCEDURE Go*;
 VAR i: INTEGER;
 BEGIN
  i := 0;
  IF Rand.Open() & Rand.Int(i) THEN
    go(i MOD Count)
  END
 END Go;

END SystemAdrDenied.
