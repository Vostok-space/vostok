Provider of the content source from the file system

Copyright (C) 2021 ComdivByZero

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

MODULE FileProvider;

  IMPORT
    V,
    InputProvider,
    TranLim := TranslatorLimits,
    OsUtil,
    Stream := VDataStream,
    File := VFileStream,
    Chars0X,
    ArrayCopy,
    Log := DLog;

  CONST
    PathesMaxLen* = 4096;

    Exts = "mod;Mod;ob07;ob;obn;";

  TYPE
    Provider = POINTER TO RECORD(InputProvider.R)
      path: ARRAY PathesMaxLen OF CHAR;
      pathForDecl: SET
    END;

    Iter = RECORD(InputProvider.Iter)
      p: Provider;
      name: ARRAY TranLim.LenName + 1 OF CHAR;
      exts: ARRAY 32 OF CHAR;
      pathInd, pathOfs, extOfs: INTEGER
    END;

  PROCEDURE Next(VAR it: V.Base; VAR declaration: BOOLEAN): Stream.PIn;

    PROCEDURE Search(VAR it: Iter; VAR declaration: BOOLEAN): Stream.PIn;
    VAR in: Stream.PIn;

      PROCEDURE Open(VAR it: Iter; VAR declaration: BOOLEAN): File.In;
      VAR n: ARRAY 1024 OF CHAR;
          l, ofs: INTEGER;
          in: File.In;
      BEGIN
        l := 0;
        ofs := it.extOfs;
        IF Chars0X.Copy          (n, l, it.p.path, it.pathOfs)
         & Chars0X.CopyString    (n, l, OsUtil.DirSep)
         & Chars0X.CopyString    (n, l, it.name)
         & Chars0X.CopyChar      (n, l, ".")
         & Chars0X.CopyCharsUntil(n, l, Exts, ofs, ";")
        THEN
          Log.Str("Open "); Log.StrLn(n);
          in := File.OpenIn(n);
          declaration := it.pathInd IN it.p.pathForDecl
        ELSE
          in := NIL
        END;
        INC(it.pathOfs);
        INC(it.pathInd);
        IF it.p.path[it.pathOfs] = 0X THEN
          it.extOfs  := ofs + 1;
          it.pathOfs := 0;
          it.pathInd := 0
        END
      RETURN
        in
      END Open;

    BEGIN
      in := NIL;
      WHILE (in = NIL) & (it.exts[it.extOfs] # 0X) DO
        in := Open(it, declaration)
      END
    RETURN
      in
    END Search;
  RETURN
    Search(it(Iter), declaration)
  END Next;

  PROCEDURE GetIterator(p: InputProvider.P; name: ARRAY OF CHAR): InputProvider.PIter;
  VAR it: POINTER TO Iter;
  BEGIN
    NEW(it);
    IF it # NIL THEN
      InputProvider.InitIter(it, Next);
      it.p    := p(Provider);
      it.name := name;
      it.exts := Exts;
      it.pathInd := 0;
      it.pathOfs := 0;
      it.extOfs  := 0
    END
  RETURN
    it
  END GetIterator;

  PROCEDURE New*(VAR out: InputProvider.P;
                 searchPathes: ARRAY OF CHAR; pathesLen: INTEGER; pathForDecl: SET): BOOLEAN;
  VAR p: Provider;
  BEGIN
    ASSERT((0 < pathesLen) & (pathesLen <= LEN(searchPathes)) & (pathesLen < LEN(p.path)));

    NEW(p);
    IF p # NIL THEN
      InputProvider.Init(p, GetIterator);

      ArrayCopy.Chars(p.path, 0, searchPathes, 0, pathesLen);
      p.pathForDecl := pathForDecl
    END;
    out := p
  RETURN
    p # NIL
  END New;

END FileProvider.
