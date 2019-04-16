/*  HTTP server for translator demonstration
 *  Copyright (C) 2017-2018 ComdivByZero
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published
 *  by the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package main

import (
  "fmt"
  "net/http"
  "os"
  "os/exec"
  "flag"
  "strings"
  "io/ioutil"
  "errors"
  "runtime"
  "time"
)

const (
  kwModule = "MODULE"
)

func getModuleName(source string) (name string) {
  var (module, semicolon int)
  name = "";
  module = strings.Index(source, kwModule);
  if 0 <= module {
    module += len(kwModule);
    semicolon = strings.Index(source[module:], ";");
    if 0 <= semicolon {
      name = strings.TrimSpace(source[module: semicolon + module])
    }
  }
  return name
}

func saveModule(name, source string) (tmp string, err error) {
  var (filename string)
  if 0 < len(name) {
    tmp = fmt.Sprintf("%s/o7c", os.TempDir());
    err = os.Mkdir(tmp, 0777);
    tmp, err = ioutil.TempDir(tmp, name);
    if err == nil {
      filename = fmt.Sprintf("%v/%v.mod", tmp, name);
      err = ioutil.WriteFile(filename, []byte(source), 0666);
    }
  } else {
    err = errors.New("Can not found module name in source")
  }
  return tmp, err
}

func run(source, script, cc string, timeout int) (output []byte, err error) {
  var (
    name, tmp, bin, timeOut string;
    cmd *exec.Cmd
  )
  name = getModuleName(source);
  tmp, err = saveModule(name, source);
  if err == nil {
    if runtime.GOOS == "windows" {
      bin = fmt.Sprintf("%v\\%v.exe", tmp, name)
    } else {
      bin = fmt.Sprintf("%v/%v", tmp, name)
    }

    cmd = exec.Command("vostok/result/o7c", "to-bin", script, bin,
                       "-infr", "vostok", "-m", tmp, "-cc", cc, "-cyrillic", "-multi-errors");
    output, err = cmd.CombinedOutput();
    fmt.Print(string(output));
    if err == nil {
      cmd = exec.Command(bin);
      timeOut = "";
      output = nil;
      go func() {
        time.Sleep(time.Second * time.Duration(timeout));
        if output == nil {
          cmd.Process.Kill();
          timeOut = "<time is out>\n"
        }
      }();
      output, err = cmd.CombinedOutput();
      output = append(output, timeOut...);
      fmt.Print(string(output))
    }
  } else {
    output = nil
  }
  return output, err
}

func handler(w http.ResponseWriter, r *http.Request, cc string, timeout int) {
  var (
    m, s string
    out []byte
    err error
  )
  if r.Method != "POST" {
    http.NotFound(w, r)
  } else {
    m = r.FormValue("module");
    s = r.FormValue("script");
    out, err = run(m, s, cc, timeout);
    if err == nil {
      w.Write(out)
    } else {
      fmt.Fprintf(w, "%v\n%v", err, string(out))
    }
  }
}

func main() {
  var (
    port, timeout *int;
    cc *string;
    err error
  )
  port    = flag.Int("port", 8080, "tcp/ip");
  timeout = flag.Int("timeout", 5, "in seconds");
  cc      = flag.String("cc", "tcc", "c compiler");
  flag.Parse();

  http.Handle("/", http.FileServer(http.Dir(".")));
  http.HandleFunc(
    "/run",
    func(w http.ResponseWriter, r *http.Request) {
      handler(w, r, *cc, *timeout)
    });
  err = http.ListenAndServe(fmt.Sprintf(":%d", *port), nil);
  if err != nil {
    fmt.Println(err);
    os.Exit(1)
  }
}
