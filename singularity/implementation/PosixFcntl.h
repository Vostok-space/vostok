/* Copyright 2026 ComdivByZero
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
#if !defined HEADER_GUARD_PosixFcntl
#    define  HEADER_GUARD_PosixFcntl 1

extern o7_set_t
  PosixFcntl_Rdonly,
  PosixFcntl_Wronly,
  PosixFcntl_Rdwr,

  PosixFcntl_Append,
  PosixFcntl_Async,
  PosixFcntl_Cloexec,
  PosixFcntl_Creat,
  PosixFcntl_Directory,
  PosixFcntl_Dsync,
  PosixFcntl_Excl,
  PosixFcntl_Noctty,
  PosixFcntl_Nofollow,
  PosixFcntl_Nonblock,
  PosixFcntl_Sync,
  PosixFcntl_Trunc;

extern o7_int_t PosixFcntl_Open(o7_int_t len, o7_char path[O7_VLA(len)], o7_set_t flags, o7_int_t mode);
extern o7_bool  PosixFcntl_Close(o7_int_t *fid);

O7_INLINE void PosixFcntl_init(void) { ; }
O7_INLINE void PosixFcntl_done(void) { ; }
#endif
