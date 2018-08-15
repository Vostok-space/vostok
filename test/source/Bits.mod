MODULE Bits;

 IMPORT Out, U64 := Uint64, B64 := Uint64Bits, U32 := Uint32, B32 := Uint32Bits;

 PROCEDURE Uint64;
 VAR u, u1: U64.Type;
 BEGIN
   U64.FromInt(u, 0, 0);
   B64.Not(u, u);
   ASSERT(U64.Cmp(U64.max, u) = 0);

   U64.FromInt(u, 0, 8204);
   B64.Shl(u1, u, 12);
   ASSERT(U64.ToInt(u) = 8204);
   ASSERT(U64.ToInt(u1) = 33603584);

   B64.Shr(u1, u1, 12);
   ASSERT(U64.ToInt(u1) = 8204)
 END Uint64;

 PROCEDURE Uint32;
 VAR u, u1: U32.Type;
 BEGIN
   U32.FromInt(u, 0);
   B32.Not(u, u);
   ASSERT(U32.Cmp(U32.max, u) = 0);

   U32.FromInt(u, 8204);
   B32.Shl(u1, u, 12);
   ASSERT(U32.ToInt(u) = 8204);
   ASSERT(U32.ToInt(u1) = 33603584);

   B32.Shr(u1, u1, 12);
   ASSERT(U32.ToInt(u1) = 8204)
 END Uint32;

 PROCEDURE Go*;
 BEGIN
   Uint64;
   Uint32
 END Go;

END Bits.
