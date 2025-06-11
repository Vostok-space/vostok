MODULE IsExtVarNotRecord;
TYPE R = RECORD END;
VAR i: INTEGER; b: BOOLEAN;
BEGIN
  b := i IS R;
END IsExtVarNotRecord.
