MODULE CaseRangeLabelsTypeMismatch;
VAR x: INTEGER;
BEGIN
  CASE x OF
    1 .. 'a':
  END;
END CaseRangeLabelsTypeMismatch.
