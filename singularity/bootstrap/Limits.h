/*  Oberon-07 types limits
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
#if !defined(HEADER_GUARD_Limits)
#define HEADER_GUARD_Limits


#define Limits_IntegerMax_cnst 2147483647
#define Limits_IntegerMin_cnst (-2147483647)
#define Limits_CharMax_cnst "\xFF"
#define Limits_ByteMax_cnst 255
#define Limits_SetMax_cnst 31

extern o7c_bool Limits_IsNan(double r);

extern o7c_bool Limits_InByteRange(int v);

extern o7c_bool Limits_InCharRange(int v);

static inline void Limits_init(void) { ; }
#endif
