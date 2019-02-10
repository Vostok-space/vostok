MODULE MemStream;

  IMPORT Mem := VMemStream, Stream := VDataStream;

  CONST

  TYPE

  VAR

  PROCEDURE Fill(VAR buf: ARRAY OF BYTE);
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(buf) - 1 DO
      buf[i] := i MOD 256
    END
  END Fill;

  PROCEDURE Zero(VAR buf: ARRAY OF BYTE);
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(buf) - 1 DO
      buf[i] := 0
    END
  END Zero;

  PROCEDURE Check(buf: ARRAY OF BYTE);
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(buf) - 1 DO
      ASSERT(buf[i] = i MOD 256)
    END
  END Check;

  PROCEDURE FillChars(VAR buf: ARRAY OF CHAR);
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(buf) - 1 DO
      buf[i] := CHR(i MOD 256)
    END
  END FillChars;

  PROCEDURE ZeroChars(VAR buf: ARRAY OF CHAR);
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(buf) - 1 DO
      buf[i] := 0X
    END
  END ZeroChars;

  PROCEDURE CheckChars(buf: ARRAY OF CHAR);
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO LEN(buf) - 1 DO
      ASSERT(ORD(buf[i]) = i MOD 256)
    END
  END CheckChars;

  PROCEDURE Bytes;
  VAR out: Mem.Out; in: Mem.In; i: INTEGER;
      buf: ARRAY 725 OF BYTE;
  BEGIN
    Fill(buf);
    ASSERT(Mem.New(out));
    FOR i := 0 TO 2 DO
      ASSERT(LEN(buf) = Stream.Write(out^, buf, 0, LEN(buf)))
    END;
    ASSERT(Mem.NewIn(in, out));
    FOR i := 0 TO 2 DO
      Zero(buf);
      ASSERT(LEN(buf) = Stream.Read(in^, buf, 0, LEN(buf)));
      Check(buf)
    END;
    ASSERT(0 = Stream.Read(in^, buf, 0, 10))
  END Bytes;

  PROCEDURE Chars;
  VAR out: Mem.Out; in: Mem.In; i: INTEGER;
      buf: ARRAY 725 OF CHAR;
  BEGIN
    FillChars(buf);
    ASSERT(Mem.New(out));

    ASSERT(256 = Stream.WriteChars(out^, buf, 0,   256));
    ASSERT(255 = Stream.WriteChars(out^, buf, 256, 255));
    ASSERT(211 = Stream.WriteChars(out^, buf, 511, 211));
    ASSERT(3   = Stream.WriteChars(out^, buf, 722, 3));
    FOR i := 0 TO 1 DO
      ASSERT(LEN(buf) = Stream.WriteChars(out^, buf, 0, LEN(buf)))
    END;

    ASSERT(Mem.NewIn(in, out));
    ZeroChars(buf);
    ASSERT(256 = Stream.ReadChars(in^, buf, 0,   256));
    ASSERT(3   = Stream.ReadChars(in^, buf, 256, 3));
    ASSERT(252 = Stream.ReadChars(in^, buf, 259, 252));
    ASSERT(214 = Stream.ReadChars(in^, buf, 511, 214));
    CheckChars(buf);
    FOR i := 0 TO 1 DO
      ZeroChars(buf);
      ASSERT(LEN(buf) = Stream.ReadChars(in^, buf, 0, LEN(buf)));
      CheckChars(buf)
    END;
    ASSERT(0 = Stream.ReadChars(in^, buf, 0, 10))
  END Chars;

  PROCEDURE Go*;
  BEGIN
    Bytes;
    Chars
  END Go;

END MemStream.
