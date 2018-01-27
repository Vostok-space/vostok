MODULE Integers;

 IMPORT Out, I := Int64, U := Uint64;

 CONST Max = 2147483647;

 TYPE

 VAR

 PROCEDURE Int;
 VAR i1, i2, i3: I.Type;
     i: INTEGER;
 BEGIN
   I.FromInt(i1, 127, 0);
   I.FromInt(i2, 63, 0);

   ASSERT(I.Cmp(i1, i2) = +1);
   ASSERT(I.Cmp(i2, i1) = -1);
   ASSERT(I.Cmp(i2, i2) =  0);

   I.Div(i3, i1, i2);
   I.ToInt(i, i3);
   ASSERT(i = 2);

   I.Div(i3, i2, i1);
   I.ToInt(i, i3);
   ASSERT(i = 0);

   I.FromInt(i1, 0, Max);
   i2 := i1;
   ASSERT(I.Cmp(i2, i1) = 0);
   I.Mul(i3, i1, i2);
   I.Add(i3, i3, i2);
   I.FromInt(i1, Max, Max);
   ASSERT(I.Cmp(i3, i1) = 0)
 END Int;

 PROCEDURE Uint;
 VAR i1, i2, i3: I.Type;
     i: INTEGER;
 BEGIN
   U.FromInt(i1, 127, 0);
   U.FromInt(i2, 63, 0);

   ASSERT(U.Cmp(i1, i2) = +1);
   ASSERT(U.Cmp(i2, i1) = -1);
   ASSERT(U.Cmp(i2, i2) =  0);

   U.Div(i3, i1, i2);
   U.ToInt(i, i3);
   ASSERT(i = 2);

   U.Div(i3, i2, i1);
   U.ToInt(i, i3);
   ASSERT(i = 0);

   U.FromInt(i1, 0, Max);
   i2 := i1;
   ASSERT(U.Cmp(i2, i1) = 0);
   U.Mul(i3, i1, i2);
   U.Add(i3, i3, i2);
   U.FromInt(i1, Max, Max);
   ASSERT(U.Cmp(i3, i1) = 0)
 END Uint;

 PROCEDURE Go*;
 BEGIN
   Int;
   Uint
 END Go;

END Integers.
