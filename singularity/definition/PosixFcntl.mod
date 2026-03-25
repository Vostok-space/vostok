Incomplete wrapper of POSIX fcntl.h

Copyright 2026 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE PosixFcntl;

 VAR
  Rdonly*, Wronly*, Rdwr*,
  Append*, Async*, Cloexec*, Creat*, Directory*, Dsync*, Excl*,
  Noctty*, Nofollow*, Nonblock*, Path*, Sync*, Trunc*: SET;

 PROCEDURE Open*(path: ARRAY OF CHAR; flags: SET; mode: INTEGER): INTEGER;
 RETURN
  -1
 END Open;

 PROCEDURE Close*(VAR fid: INTEGER): BOOLEAN;
 BEGIN
  fid := -1
 RETURN
  FALSE
 END Close;

END PosixFcntl.
