(* Utility for copy from input to output
 * Copyright 2019 ComdivByZero
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
MODULE VCopy;

  IMPORT V, Stream := VDataStream;

  CONST BlockSize = 1000H;

  PROCEDURE UntilEnd*(VAR in: Stream.In; VAR out: Stream.Out);
  VAR buf: ARRAY BlockSize OF BYTE; size: INTEGER;
  BEGIN
    size := Stream.Read(in, buf, 0, LEN(buf));
    WHILE (size > 0)
        & (size = Stream.Write(out, buf, 0, size))
    DO
      size := Stream.Read(in, buf, 0, LEN(buf))
    END
  END UntilEnd;

END VCopy.
