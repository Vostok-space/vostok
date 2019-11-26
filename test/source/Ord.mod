MODULE Ord;

  CONST
    True = 0 < 1111;
    Itrue = ORD(True);
    Ifalse = ORD(~True);
    Space = " ";
    Set = {1} + {18};

  PROCEDURE Go*;
  BEGIN
    ASSERT(True);
    ASSERT(Itrue = 1);
    ASSERT(0 = Ifalse);
    ASSERT(ORD(Space) = 32);
    ASSERT(262146 = ORD(Set))
  END Go;

END Ord.
