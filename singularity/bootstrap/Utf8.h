/*  Some constants of Utf-8/ASC II
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
 */
#if !defined(HEADER_GUARD_Utf8)
#define HEADER_GUARD_Utf8


#define Utf8_Null_cnst (o7c_char *)"\x00"
#define Utf8_TransmissionEnd_cnst (o7c_char *)"\x04"
#define Utf8_Bell_cnst (o7c_char *)"\x07"
#define Utf8_BackSpace_cnst (o7c_char *)"\x08"
#define Utf8_Tab_cnst (o7c_char *)"\x09"
#define Utf8_NewLine_cnst (o7c_char *)"\x0A"
#define Utf8_NewPage_cnst (o7c_char *)"\x0C"
#define Utf8_CarRet_cnst (o7c_char *)"\x0D"
#define Utf8_Idle_cnst (o7c_char *)"\x16"
#define Utf8_DQuote_cnst (o7c_char *)"\x22"
#define Utf8_Delete_cnst (o7c_char *)"\x7F"

static inline void Utf8_init(void) { ; }
#endif
