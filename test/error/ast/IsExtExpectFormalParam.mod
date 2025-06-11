MODULE IsExtExpectFormalParam;
TYPE Base = RECORD END;
TYPE Ext = RECORD(Base) END;
VAR b: Base;

PROCEDURE P(x: Base);
VAR r: BOOLEAN;
BEGIN
  r := b IS Ext;
END P;

END IsExtExpectFormalParam.
