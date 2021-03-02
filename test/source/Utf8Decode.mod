MODULE Utf8Decode;

  IMPORT Utf8;

  VAR A, B, S: ARRAY 5 OF CHAR;

  PROCEDURE Correct*;
  VAR r: Utf8.R;
  BEGIN
    ASSERT(Utf8.IsBegin("a"));
    ASSERT(Utf8.Len("a") = 1);
    ASSERT(~Utf8.Begin(r, "a"));
    ASSERT(r.val = ORD("a"));

    ASSERT(Utf8.IsBegin(A[0]));
    ASSERT(Utf8.Len(A[0]) = 2);
    ASSERT(Utf8.Begin(r, A[0]));
    ASSERT(~Utf8.Next(r, A[1]));
    ASSERT(r.val = 0A2H);

    ASSERT(Utf8.IsBegin(B[0]));
    ASSERT(Utf8.Len(B[0]) = 3);
    ASSERT(Utf8.Begin(r, B[0]));
    ASSERT(Utf8.Next(r, B[1]));
    ASSERT(~Utf8.Next(r, B[2]));
    ASSERT(r.val = 0D55CH);

    ASSERT(Utf8.IsBegin(S[0]));
    ASSERT(Utf8.Len(S[0]) = 4);
    ASSERT(Utf8.Begin(r, S[0]));
    ASSERT(Utf8.Next(r, S[1]));
    ASSERT(Utf8.Next(r, S[2]));
    ASSERT(~Utf8.Next(r, S[3]));
    ASSERT(r.val = 10348H)
  END Correct;

  PROCEDURE Incorrect*;
  VAR r: Utf8.R;
  BEGIN
    ASSERT(Utf8.Len(A[1]) = 0);
    ASSERT(~Utf8.IsBegin(A[1]));
    ASSERT(Utf8.Len(B[2]) = 0);
    ASSERT(~Utf8.IsBegin(B[1]));
    ASSERT(Utf8.Len(S[3]) = 0);
    ASSERT(~Utf8.IsBegin(S[3]));

    ASSERT(~Utf8.Begin(r, A[1]));
    ASSERT(r.val < 0);
    ASSERT(r.len < 0);

    ASSERT(Utf8.Begin(r, A[0]));
    ASSERT(~Utf8.Next(r, "9"));
    ASSERT(r.val < 0);
    ASSERT(r.len < 0);

    ASSERT(Utf8.Begin(r, B[0]));
    ASSERT(Utf8.Next(r, B[1]));
    ASSERT(~Utf8.Next(r, B[0]));
    ASSERT(r.val < 0);
    ASSERT(r.len < 0);

    ASSERT(Utf8.Begin(r, S[0]));
    ASSERT(Utf8.Next(r, S[1]));
    ASSERT(~Utf8.Next(r, B[0]));
    ASSERT(r.val < 0);
    ASSERT(r.len < 0)
  END Incorrect;

  PROCEDURE Go*;
  BEGIN
    Correct;
    Incorrect
  END Go;

BEGIN
  A := "¢";
  B := "한";
  S := "𐍈"
END Utf8Decode.
