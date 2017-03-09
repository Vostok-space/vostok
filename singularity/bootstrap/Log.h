/*  Log for debug information
 *  Copyright (C) 2016  ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, eithersion 3 of the License, or
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
#if !defined(HEADER_GUARD_Log)
#define HEADER_GUARD_Log

#include "Out.h"

extern o7c_bool Log_state;

extern void Log_Str(o7c_char s[/*len0*/], int s_len0);

extern void Log_StrLn(o7c_char s[/*len0*/], int s_len0);

extern void Log_Char(o7c_char ch);

extern void Log_Int(int x);

extern void Log_Ln(void);

extern void Log_Real(double x);

extern void Log_Bool(o7c_bool b);

extern void Log_Turn(o7c_bool st);

extern void Log_init(void);
#endif
