MODULE CallIncompatibleParamType;
PROCEDURE P(x: INTEGER); END P;
BEGIN
  P(1.5);
END CallIncompatibleParamType.
