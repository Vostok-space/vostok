Interface of content provider.

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

MODULE InputProvider;

  IMPORT V, Stream := VDataStream;

  TYPE
    PIter* = POINTER TO Iter;
    NextInput* = PROCEDURE(VAR iter: V.Base; VAR declaration: BOOLEAN): Stream.PIn;
    Iter* = RECORD(V.Base)
      next: NextInput
    END;

    P* = POINTER TO R;
    GetIterator* = PROCEDURE(prov: P; name: ARRAY OF CHAR): PIter;
    R* = RECORD(V.Base)
      get: GetIterator
    END;

  PROCEDURE Init*(p: P; get: GetIterator);
  BEGIN
    ASSERT(get # NIL);
    V.Init(p^);
    p.get := get
  END Init;

  PROCEDURE InitIter*(it: PIter; next: NextInput);
  BEGIN
    ASSERT(next # NIL);
    V.Init(it^);
    it.next := next
  END InitIter;

  PROCEDURE Get*(p: P; VAR it: PIter; name: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    ASSERT(name # "");
    it := p.get(p, name)
  RETURN
    it # NIL
  END Get;

  (*TODO убрать declaration *)
  PROCEDURE Next*(VAR it: PIter; VAR in: Stream.PIn; VAR declaration: BOOLEAN): BOOLEAN;
  BEGIN
    in := it.next(it^, declaration);
    IF in = NIL THEN
      it := NIL
    END
  RETURN
    in # NIL
  END Next;

END InputProvider.
