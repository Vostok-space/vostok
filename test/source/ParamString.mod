MODULE ParamString;

CONST
    Str = "String";

PROCEDURE Proc(str: ARRAY OF CHAR);
VAR s: ARRAY 32 OF CHAR;
BEGIN
    s := Str;
    ASSERT(s = str)
END Proc;

PROCEDURE Go*;
BEGIN
    Proc("String")
END Go;

END ParamString.
