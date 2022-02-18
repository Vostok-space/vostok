/*
Partial wrapper for Windows-specific windows.h

Copyright 2022 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include <o7.h>

#if (defined(_WIN16) || defined(_WIN32) || defined(_WIN64))
#   include "Windows_.h"
#   include <windows.h>
    extern unsigned short GetUserDefaultUILanguage(void);
#else
    typedef o7_uint_t UINT;
    static int GetUserDefaultUILanguage(void)     { return 0; }
    static o7_cbool SetConsoleCP      (UINT code) { return 0 > 1; }
    static o7_cbool SetConsoleOutputCP(UINT code) { return 0 > 1; }
#endif

extern o7_int_t Windows_GetUserDefaultUILanguage(void) {
    return GetUserDefaultUILanguage();
}

extern o7_cbool Windows_SetConsoleCP(o7_int_t code) {
    return SetConsoleCP((UINT)code);
}

extern o7_cbool Windows_SetConsoleOutputCP(o7_int_t code) {
    return SetConsoleOutputCP((UINT)code);
}
