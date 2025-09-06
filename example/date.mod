MODULE date;

 IMPORT Date, Out;

 PROCEDURE out*;
 VAR d: Date.T;
 BEGIN
  IF ~Date.Local(d) THEN
    Out.String("Дата не получена")
  ELSE
    Out.Int(d.year, 1); Out.String("-");
    Out.Int(d.month, 1); Out.String("-");
    Out.Int(d.day, 1); Out.String(" ");
    Out.Int(d.hour, 1); Out.String(":");
    Out.Int(d.minute, 1); Out.String(":");
    Out.Int(d.second, 1)
  END;
  Out.Ln
 END out;

END date.
