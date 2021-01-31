(*  Base extensible records
 *  Copyright (C) 2016 ComdivByZero
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
(* база всего сущего, авось пригодится для чего-нибудь эдакого *)
MODULE V;

TYPE
	Message* = RECORD END;
	PMessage* = POINTER TO Message;

	Handle* = PROCEDURE(VAR this, mes: Message): BOOLEAN;

	Base* = RECORD(Message)
		do: Handle
	END;
	PBase* = POINTER TO Base;

	Error* = RECORD(Base) END;
	PError* = POINTER TO Error;

	MsgFinalize*    = RECORD(Base) END;
	MsgNeedMemory*  = RECORD(Base) END;
	MsgCopy*        = RECORD(Base)
	                      copy*: PBase
	                  END;
	MsgLinks*       = RECORD(Base)
	                      diff*, count*: INTEGER
	                  END;
	MsgHash*        = RECORD(Base)
	                      hash*: INTEGER
	                  END;

PROCEDURE Nothing(VAR this: Message; VAR mes: Message): BOOLEAN;
	RETURN FALSE
END Nothing;

PROCEDURE Init*(VAR base: Base);
BEGIN
	base.do := Nothing
END Init;

PROCEDURE SetDo*(VAR base: Base; do: Handle);
BEGIN
	ASSERT(base.do = Nothing);
	base.do := do
END SetDo;

PROCEDURE Do*(VAR handler: Base; VAR message: Message): BOOLEAN;
	RETURN handler.do(handler, message)
END Do;

END V.
