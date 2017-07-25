MODULE OsRand;

 IMPORT File := CFiles;

 CONST
   FileName = "/dev/urandom";

 VAR
   file: File.File;

 PROCEDURE Open*(): BOOLEAN;
 BEGIN
   IF file = NIL THEN
     file := File.Open(FileName, 0, "rb")
   END
   RETURN file # NIL
 END Open;

 PROCEDURE Close*;
 BEGIN
   File.Close(file)
 END Close;

 PROCEDURE Read*(VAR buf: ARRAY OF CHAR; VAR ofs: INTEGER; count: INTEGER): BOOLEAN;
 RETURN (file # NIL) & (count = File.Read(file, buf, ofs, count))
 END Read;

 PROCEDURE Int*(VAR i: INTEGER): BOOLEAN;
 VAR buf: ARRAY 4 OF CHAR;
     ofs: INTEGER;
     ret: BOOLEAN;
 BEGIN
   ofs := 0;
   ret := Read(buf, ofs, LEN(buf));
   IF ret THEN
     i := (ORD(buf[0])
         + ORD(buf[1])       * 100H
         + ORD(buf[2])       * 10000H
         + ORD(buf[3]) DIV 2 * 1000000H
          )
        * (ORD(buf[3]) MOD 2 * 2 - 1)
   END
   RETURN ret
 END Int;

BEGIN
 file := NIL
END OsRand.
