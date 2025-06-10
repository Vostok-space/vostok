MODULE UnexpectStringInCaseLabel;
PROCEDURE Foo(c: CHAR);
BEGIN
  CASE c OF "abc": END;
END Foo;
END UnexpectStringInCaseLabel.
