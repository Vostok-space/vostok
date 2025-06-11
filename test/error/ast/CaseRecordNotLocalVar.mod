MODULE CaseRecordNotLocalVar;
TYPE R = RECORD a: INTEGER END;
VAR g: R;
PROCEDURE P;
BEGIN
  CASE g OF | R: END;
END P;
END CaseRecordNotLocalVar.
