Wrapper for CLI of jar-utility

Copyright 2021 ComdivByZero

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

MODULE JarInterface;

  IMPORT V, Exec := PlatformExec, Dir := CDir;

  CONST
    ErrNo*            =  0;
    ErrGetCurrentDir* = -1;
    ErrSetDirBefore*  = -2;
    ErrSetDirAfter*   = -3;

  TYPE
    T* = RECORD(V.Base)
      cmd: Exec.Code
    END;

  PROCEDURE Init*(VAR ji: T);
  BEGIN
    V.Init(ji);
    ASSERT(Exec.Init(ji.cmd, "jar"))
  END Init;

  PROCEDURE Create*(VAR ji: T; fileName: ARRAY OF CHAR): BOOLEAN;
  RETURN
    Exec.Add(ji.cmd, "--create")
  & (   (fileName = "")
     OR Exec.Add(ji.cmd, "--file")
      & Exec.AddFullPath(ji.cmd, fileName)
    )
  END Create;

  PROCEDURE MainClass*(VAR ji: T; name: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    ASSERT(name # "")
  RETURN
    Exec.Add(ji.cmd, "--main-class")
  & Exec.Add(ji.cmd, name)
  END MainClass;

  PROCEDURE Class*(VAR ji: T; fileName: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    ASSERT(fileName # "")
  RETURN
    Exec.Add(ji.cmd, fileName)
  END Class;

  PROCEDURE Clean*(VAR ji: T; text: ARRAY OF CHAR): BOOLEAN;
  BEGIN
    ASSERT(text # "")
  RETURN
    Exec.AddClean(ji.cmd, text)
  END Clean;

  PROCEDURE Do*(VAR ji: T; baseDir: ARRAY OF CHAR): INTEGER;
  VAR ret, len: INTEGER; cur: ARRAY (*TODO*)256 OF CHAR;
  BEGIN
    len := 0;
    ret := ErrNo;
    IF baseDir = "" THEN
      ;
    ELSIF ~Dir.GetCurrent(cur, len) THEN
      ret := ErrGetCurrentDir
    ELSIF ~Dir.SetCurrent(baseDir, 0) THEN
      ret := ErrSetDirBefore
    END;
    IF ret = ErrNo THEN
      ret := Exec.Do(ji.cmd)
    END;
    IF (baseDir # "") & (ret # ErrGetCurrentDir)
     & ~Dir.SetCurrent(cur, 0) & (ret = ErrNo)
    THEN
      ret := ErrSetDirAfter
    END
  RETURN
    ret
  END Do;

END JarInterface.
