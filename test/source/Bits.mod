MODULE Bits;

 IMPORT Out, Uint := Uint64, Bits := Uint64Bits;

 PROCEDURE Go*;
 VAR u: Uint.Type;
 BEGIN
   Uint.FromInt(u, 0, 0);
   Bits.Not(u, u);
   ASSERT(Uint.Cmp(Uint.max, u) = 0)
 END Go;

END Bits.
