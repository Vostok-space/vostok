MODULE IsExtMeshupPtrAndRecord;
TYPE R0 = RECORD END;
TYPE P0 = POINTER TO R0;
VAR p: P0; b: BOOLEAN;
BEGIN
  b := p IS R0;
END IsExtMeshupPtrAndRecord.
