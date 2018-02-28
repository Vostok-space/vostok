MODULE Hello;

IMPORT Out;

PROCEDURE Come*;
BEGIN
	Out.String("Hello");
	Out.Ln
END Come;

PROCEDURE Gone*();
BEGIN
	Out.String("Bye");
	Out.Ln
END Gone;

END Hello.
