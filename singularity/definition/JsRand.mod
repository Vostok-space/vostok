(* Copyright 2018 ComdivByZero
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
MODULE JsRand;

  PROCEDURE Open*(): BOOLEAN;
  RETURN
    FALSE
  END Open;

  PROCEDURE Close*;
  END Close;

  PROCEDURE Read*(VAR buf: ARRAY OF BYTE; ofs: INTEGER; count: INTEGER)
                 : BOOLEAN;
  BEGIN
    ASSERT(0 < count);
    ASSERT((0 <= ofs) & (ofs <= LEN(buf) - count))
  RETURN
    FALSE
  END Read;

END JsRand.
