MODULE Copy;

CONST

TYPE

VAR

PROCEDURE CopyChars*(VAR dest: ARRAY OF CHAR; VAR destOfs: INTEGER;
					 src: ARRAY OF CHAR; srcOfs, srcEnd: INTEGER): BOOLEAN;
VAR ret: BOOLEAN;
BEGIN

	ASSERT((destOfs >= 0)
		 & (srcOfs >= 0) & (srcEnd >= srcOfs)
		 & (srcEnd <= LEN(src)));

	ret := destOfs + srcEnd - srcOfs < LEN(dest) - 1;
	IF ret THEN
		WHILE srcOfs < srcEnd DO
			dest[destOfs] := src[srcOfs];
			INC(destOfs);
			INC(srcOfs)
		END
	END;
	dest[destOfs] := 0X
	RETURN ret
END CopyChars;

PROCEDURE Go*;
END Go;

END Copy.
