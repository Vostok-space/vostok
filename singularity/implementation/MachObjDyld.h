/* Partial wrapper for macOS mach-o/dyld.h
 *
 * Copyright 2021 ComdivByZero
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
#if !defined HEADER_GUARD_MachObjDyld
#    define  HEADER_GUARD_MachObjDyld 1

extern o7_int_t MachObjDyld_NSGetExecutablePath(o7_int_t path_len, o7_char path[/*len*/]);

O7_INLINE void MachObjDyld_init(void) { ; }
#endif
