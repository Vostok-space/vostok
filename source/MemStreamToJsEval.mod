(* Copyright 2019 ComdivByZero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)
MODULE MemStreamToJsEval;

  IMPORT V, Mem := VMemStream, JsEval;

  TYPE Wrapper = RECORD(V.Base) code: JsEval.Code END;

  PROCEDURE Handle(ctx: V.Base; data: ARRAY OF BYTE; len: INTEGER): BOOLEAN;
  RETURN
    JsEval.AddBytes(ctx(Wrapper).code, data)
  END Handle;

  PROCEDURE Do*(mem: Mem.Out; arg: INTEGER): JsEval.Code;
  VAR w: Wrapper;
  BEGIN
    V.Init(w);
    IF ~JsEval.New(w.code)
    OR ~Mem.Pass(mem, w, Handle)
    OR ~JsEval.End(w.code, arg)
    THEN
      w.code := NIL;
    END
  RETURN
    w.code
  END Do;

END MemStreamToJsEval.
