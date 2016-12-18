(*  Some constants of Utf-8/ASC II
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
MODULE Utf8;

CONST
	Null*            = 00X;
	TransmissionEnd* = 04X;
	Bell*            = 07X;
	BackSpace*       = 08X;
	Tab*             = 09X;
	NewLine*         = 0AX;
	NewPage*         = 0CX;
	CarRet*          = 0DX;
	Idle*            = 16X;
	DQuote*          = 22X;
	Delete*          = 7FX;

END Utf8.
