MODULE MathTest;

 IMPORT Math;

 CONST

 TYPE

 VAR

 PROCEDURE Go*;
 BEGIN
   ASSERT(Math.sin(0.0) = 0.0);
   ASSERT(Math.sin(Math.pi) >= 0.0);
   ASSERT(Math.sin(Math.pi) < 1.E-8);
   ASSERT(1.0 <= Math.sin(Math.pi / 2.0));
   ASSERT(Math.sin(Math.pi / 2.0) < 1.0 + 1.E-8);

   ASSERT(Math.cos(0.0) >= 1.);
   ASSERT(Math.cos(0.0) < 1. + 1.E-8);
   ASSERT(Math.cos(Math.pi) = -1.0);
   ASSERT(-1.E-16 < Math.cos(Math.pi / 2.0));
   ASSERT(Math.cos(Math.pi / 2.0) < 1.E-16)
 END Go;

END MathTest.
