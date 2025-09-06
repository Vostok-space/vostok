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
#include <o7.h>

#include "Date.h"

#include <time.h>

extern o7_cbool Date_Local(Date_T *date) {
    time_t t;
    struct tm *tm;
    o7_cbool ok;

    t = time(NULL);
    ok = t != (time_t)-1;
    if (ok) {
        tm = localtime(&t);
        date->year = tm->tm_year + 1900;
        date->month = tm->tm_mon;
        date->day = tm->tm_mday;
        date->hour = tm->tm_hour;
        date->minute = tm->tm_min;  
        date->second = tm->tm_sec;  
    }
    return ok;
}
