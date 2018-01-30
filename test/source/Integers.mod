MODULE Integers;

 IMPORT Out, I64 := Int64, U64 := Uint64, U32 := Uint32, I32 := Int32;

 CONST Max = 2147483647;

 PROCEDURE Int64;
 VAR i1, i2, i3: I64.Type;
     i: INTEGER;
 BEGIN
   I64.FromInt(i1, 127, 0);
   I64.FromInt(i2, 63, 0);

   ASSERT(I64.Cmp(i1, i2) = +1);
   ASSERT(I64.Cmp(i2, i1) = -1);
   ASSERT(I64.Cmp(i2, i2) =  0);

   I64.Div(i3, i1, i2);
   I64.ToInt(i, i3);
   ASSERT(i = 2);

   I64.Div(i3, i2, i1);
   I64.ToInt(i, i3);
   ASSERT(i = 0);

   I64.FromInt(i1, 0, Max);
   i2 := i1;
   ASSERT(I64.Cmp(i2, i1) = 0);
   I64.Mul(i3, i1, i2);
   I64.Add(i3, i3, i2);
   I64.FromInt(i1, Max, Max);
   ASSERT(I64.Cmp(i3, i1) = 0)
 END Int64;

 PROCEDURE Int32;
 VAR i1, i2, i3: I32.Type;
     i: INTEGER;
 BEGIN
   I32.FromInt(i1, 127);
   I32.FromInt(i2, 63);

   ASSERT(I32.Cmp(i1, i2) = +1);
   ASSERT(I32.Cmp(i2, i1) = -1);
   ASSERT(I32.Cmp(i2, i2) =  0);

   I32.Div(i3, i1, i2);
   I32.ToInt(i, i3);
   ASSERT(i = 2);

   I32.Div(i3, i2, i1);
   I32.ToInt(i, i3);
   ASSERT(i = 0);

   I32.FromInt(i1, Max DIV 3);
   i2 := i1;
   ASSERT(I32.Cmp(i2, i1) = 0);
   I32.FromInt(i2, 3);
   I32.Mul(i3, i1, i2);
   I32.FromInt(i2, 1);
   I32.Add(i3, i3, i2);
   I32.FromInt(i1, Max);
   ASSERT(I32.Cmp(i3, i1) = 0)
 END Int32;

 PROCEDURE Uint64;
 VAR i1, i2, i3: U64.Type;
     i: INTEGER;
 BEGIN
   U64.FromInt(i1, 127, 0);
   U64.FromInt(i2, 63, 0);

   ASSERT(U64.Cmp(i1, i2) = +1);
   ASSERT(U64.Cmp(i2, i1) = -1);
   ASSERT(U64.Cmp(i2, i2) =  0);

   U64.Div(i3, i1, i2);
   U64.ToInt(i, i3);
   ASSERT(i = 2);

   U64.Div(i3, i2, i1);
   U64.ToInt(i, i3);
   ASSERT(i = 0);

   U64.FromInt(i1, 0, Max);
   i2 := i1;
   ASSERT(U64.Cmp(i2, i1) = 0);
   U64.Mul(i3, i1, i2);
   U64.Add(i3, i3, i2);
   U64.FromInt(i1, Max, Max);
   ASSERT(U64.Cmp(i3, i1) = 0)
 END Uint64;

 PROCEDURE Uint32;
 VAR i1, i2, i3: U32.Type;
     i: INTEGER;
 BEGIN
   U32.FromInt(i1, 127);
   U32.FromInt(i2, 63);

   ASSERT(U32.Cmp(i1, i2) = +1);
   ASSERT(U32.Cmp(i2, i1) = -1);
   ASSERT(U32.Cmp(i2, i2) =  0);

   U32.Div(i3, i1, i2);
   U32.ToInt(i, i3);
   ASSERT(i = 2);

   U32.Div(i3, i2, i1);
   U32.ToInt(i, i3);
   ASSERT(i = 0);

   U32.FromInt(i1, Max DIV 2);
   i2 := i1;
   ASSERT(U32.Cmp(i2, i1) = 0);
   U32.FromInt(i2, 2);
   U32.Mul(i3, i1, i2);
   U32.FromInt(i2, 1);
   U32.Add(i3, i3, i2);
   U32.FromInt(i1, Max);
   ASSERT(U32.Cmp(i3, i1) = 0)
 END Uint32;

 PROCEDURE Go*;
 BEGIN
   Int64;
   Uint64;
   Uint32;
   Int32;
 END Go;

END Integers.
