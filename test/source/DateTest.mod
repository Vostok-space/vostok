MODULE DateTest;

 IMPORT Date; 

 PROCEDURE Go*;
 VAR t: Date.T;
 BEGIN
  IF Date.Local(t) THEN
    ASSERT((1900 < t.year) & (t.year < 2111));
    ASSERT((0 <= t.month) & (t.month < 12));
    ASSERT((0 < t.day) & (t.day < 32));
    ASSERT((0 <= t.hour) & (t.hour < 24));
    ASSERT((0 <= t.minute) & (t.minute < 60));
    ASSERT((0 < t.second) & (t.second <= 60));
  END
 END Go;

END DateTest.
