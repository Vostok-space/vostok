MODULE CallIgnoredReturn;
PROCEDURE F(): INTEGER;
BEGIN
  RETURN 0
END F;
BEGIN
  F;
END CallIgnoredReturn.
