MODULE CaseRecordNotParam;
TYPE R = RECORD END;
VAR r: R;
PROCEDURE P;
BEGIN
  CASE r OF | R: END;
END P;
END CaseRecordNotParam.
