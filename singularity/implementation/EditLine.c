/* Copyright 2016 ComdivByZero
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
#include <stdbool.h>

#define O7_BOOL_UNDEFINED
#include <o7.h>

#include "EditLine.h"

#include <editline/readline.h>
#include <editline/history.h>

extern o7_cbool EditLine_Read(o7_int_t plen, o7_char prompt[O7_VLA(plen)],
                              o7_int_t llen, o7_char line[O7_VLA(llen)]) {
    o7_char* input;
    o7_int_t i;
    o7_cbool ok;
    char pr[64];

    i = 0;
    while ((i < plen) && (i < sizeof(pr) - 1) && (prompt[i] != '\0')) {
        pr[i] = (o7_char)prompt[i];
        i += 1;
    }
    pr[i] = '\0';
    input = (o7_char *)readline(pr);
    ok = (NULL != input);
    if (ok) {
        add_history(input);
        i = 0;
        while ((i < llen) && (input[i] != '\0')) {
            line[i] = input[i];
            i += 1;
        }
        free(input);
        if (i < llen) {
            line[i] = '\0';
        }
        ok = '\0' == input[i];
    } else {
        line[0] = '\0';
    }
    return ok;
}

