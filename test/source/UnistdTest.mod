MODULE UnistdTest;

 IMPORT Unistd, Fcntl := PosixFcntl;

 PROCEDURE Go*;
 VAR f: INTEGER; data: ARRAY 4 OF BYTE;
 BEGIN
  f := Fcntl.Open("/dev/urandom", Fcntl.Rdonly, 0);
  IF f > 0 THEN
    ASSERT(4 = Unistd.Read(f, data, 0, 4));
    ASSERT(Fcntl.Close(f));
    ASSERT(f < 0)
  ELSE
    data[0] := 0;
    data[1] := 0;
    data[2] := 0;
    data[3] := 0
  END;
  f := Fcntl.Open("/dev/null", Fcntl.Wronly, 0);
  IF f > 0 THEN
    ASSERT(4 = Unistd.Write(f, data, 0, 4))
  END
 END Go;

END UnistdTest.
