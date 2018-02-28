MODULE Env;

 IMPORT Out, OsEnv;

 PROCEDURE Go*;
 VAR val: ARRAY OsEnv.MaxLen OF CHAR;
     len: INTEGER;
 BEGIN
   len := 0;
   IF OsEnv.Get(val, len, "USER") THEN
     Out.Int(len, 0);
     Out.String(": ");
     Out.String(val);
     Out.Ln
   END
 END Go;

END Env.
