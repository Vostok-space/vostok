(*  Base extensible records for Translator
 *  Copyright (C) 2016  ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)
(* база всего сущего, авось пригодится для чего-нибудь эдакого *)
MODULE V;

CONST
	ContentPassOpen*  = 0;
	ContentPassNext*  = 1;
	ContentPassClose* = 2;

TYPE
	Message* = RECORD END;
	PMessage* = POINTER TO Message;

	Base* = RECORD(Message)
		do: PROCEDURE(VAR this: Base; VAR mes: Message): BOOLEAN
	END;
	PBase* = POINTER TO Base;

	Error* = RECORD(Base) END;
	PError* = POINTER TO Error;

	Handle* = PROCEDURE(VAR this: Base; VAR mes: Message): BOOLEAN;

	MsgFinalize*	= RECORD(Base) END;
	MsgNeedMemory*	= RECORD(Base) END;
	MsgCopy*		= RECORD(Base)
		copy*: PBase
	END;
	MsgLinks*		= RECORD(Base)
		diff*, count*: INTEGER
	END;
	MsgContentPass* = RECORD(Base)
		id*: INTEGER 
	END;
	MsgHash* = RECORD(Base)
		hash*: INTEGER
	END;

PROCEDURE Nothing(VAR this: Base; VAR mes: Message): BOOLEAN;
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
