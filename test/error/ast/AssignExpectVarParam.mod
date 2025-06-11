MODULE AssignExpectVarParam;
PROCEDURE Fn(): INTEGER;
BEGIN
  RETURN 0
END Fn;
BEGIN
  Fn() := 1;
END AssignExpectVarParam.
