MODULE Uint64;

CONST
	Size = 8;

TYPE
	Type* = ARRAY Size OF CHAR;

VAR
	max*: Type;

PROCEDURE FromInt*(VAR v: Type; high, low: INTEGER);
END FromInt;

PROCEDURE ToInt*(VAR i: INTEGER; v: Type);
END ToInt;

PROCEDURE Add*(VAR sum: Type; a1, a2: Type);
END Add;

PROCEDURE Sub*(VAR diff: Type; m, s: Type);
END Sub;

PROCEDURE Mul*(VAR prod: Type; m1, m2: Type);
END Mul;

PROCEDURE Div*(VAR div: Type; n, d: Type);
END Div;

PROCEDURE Mod*(VAR mod: Type; n, d: Type);
END Mod;

PROCEDURE DivMod*(VAR div, mod: Type; n, d: Type);
END DivMod;

END Uint64.
