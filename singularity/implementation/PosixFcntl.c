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
#include <o7.h>
#include "PosixFcntl.h"

#include <fcntl.h>

o7_set_t
  PosixFcntl_Rdonly    = O_RDONLY,
  PosixFcntl_Wronly    = O_WRONLY,
  PosixFcntl_Rdwr      = O_RDWR,
  
  PosixFcntl_Append    = O_APPEND,
  PosixFcntl_Async     = O_ASYNC,
  PosixFcntl_Cloexec   = O_CLOEXEC,
  PosixFcntl_Creat     = O_CREAT,
  PosixFcntl_Directory = O_DIRECTORY,
  PosixFcntl_Dsync     = O_DSYNC,
  PosixFcntl_Excl      = O_EXCL,
  PosixFcntl_Noctty    = O_NOCTTY,
  PosixFcntl_Nofollow  = O_NOFOLLOW,
  PosixFcntl_Nonblock  = O_NONBLOCK,
  PosixFcntl_Sync      = O_SYNC,
  PosixFcntl_Trunc     = O_TRUNC;

extern o7_int_t PosixFcntl_Open(o7_int_t len, o7_char path[O7_VLA(len)], o7_set_t flags, o7_int_t mode) {
  return open((char *)path, flags, mode % 0x10 + mode / 0x10 % 0x10 * 010 + mode / 0x100 % 0x10 * 0100 + mode / 0x1000  * 01000);
}

extern o7_bool PosixFcntl_Close(o7_int_t *fid) {
  o7_bool ok;
  ok = 0 == close(*fid);
  *fid = -1;
  return ok;
}

