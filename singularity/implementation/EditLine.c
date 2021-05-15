/* Copyright 2018,2021 ComdivByZero
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

#include "EditLine.h"

#include <editline/readline.h>
#include <editline/history.h>

extern o7_cbool EditLine_Read(o7_int_t plen, o7_char const prompt[O7_VLA(plen)],
                              o7_int_t llen, o7_char line[O7_VLA(llen)]) {
    char* input;
    o7_int_t i;
    o7_cbool ok;

    input = readline((char *)prompt);
    ok = (NULL != input);
    if (ok) {
        add_history(input);
        i = 0;
        while ((i < llen - 1) && (input[i] != '\0')) {
            line[i] = input[i];
            i += 1;
        }
        ok = '\0' == input[i];
        free(input);
    } else {
        i = 0;
    }
    line[i] = '\0';
    return ok;
}
