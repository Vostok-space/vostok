MODULE GenericGarbage;

  TYPE
    Base = RECORD END;
    PExt = POINTER TO RECORD(Base) END;

  PROCEDURE WithoutParam(): POINTER;
  VAR a: POINTER;
  BEGIN
    a := NIL
  RETURN
    a
  END WithoutParam;

  PROCEDURE Same(a: POINTER): POINTER;
  VAR e: PExt;
  BEGIN
    e := NIL;
    (* Ошибка
    IF a IS PExt THEN
      e := a(PExt);
    END;
    *)
  RETURN
    a
  END Same;

  PROCEDURE Go*;
  VAR p: POINTER TO RECORD END;
      t: POINTER;
  BEGIN
    p := NIL;
    p := Same(p);
    t := Same(NIL);

    (*
    NEW(t);
    p := Same(t);
    t := Same(p);
    *)
    t := WithoutParam();
    t := Same(t);
  END Go;

END GenericGarbage.

