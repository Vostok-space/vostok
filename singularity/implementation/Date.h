/* Copyright 2025 ComdivByZero
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
 */
#if !defined HEADER_GUARD_Date
#    define  HEADER_GUARD_Date 1

typedef struct Date_T {
    o7_int_t year;
    o7_int_t month;
    o7_int_t day;
    o7_int_t hour;
    o7_int_t minute;
    o7_int_t second;
} Date_T;
#define Date_T_tag o7_base_tag

O7_ALWAYS_INLINE
void Date_T_undef(void *v) {
    struct Date_T*r = (struct Date_T*)v;
    r->year = O7_INT_UNDEF;
    r->month = O7_INT_UNDEF;
    r->day = O7_INT_UNDEF;
    r->hour = O7_INT_UNDEF;
    r->minute = O7_INT_UNDEF;
    r->second = O7_INT_UNDEF;
}

extern o7_cbool Date_Local(struct Date_T *date);

O7_ALWAYS_INLINE void Date_init(void) {}
O7_ALWAYS_INLINE void Date_done(void) {}
#endif
