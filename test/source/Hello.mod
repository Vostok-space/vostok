MODULE Hello;

IMPORT Out;

PROCEDURE Go*;
BEGIN
	Out.String("Hello");
	Out.Ln
END Go;

PROCEDURE Stop*();
BEGIN
	Out.String("Bye");
	Out.Ln
END Stop;

END Hello.
