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
)

const (
  kwModule = "MODULE"
)

func getModuleName(source string) (name string) {
  var (module, semicolon int)
  name = "";
  module = strings.Index(source, kwModule);
  if module >= 0 {
    module += len(kwModule);
    semicolon = strings.Index(source[module:], ";");
    if semicolon >= 0 {
      name = strings.TrimSpace(source[module: semicolon + module])
    }
  }
  return name
}

func saveModule(name, source string) (tmp string, err error) {
  var (filename string)
  if len(name) > 0 {
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

func run(source, script string) (output []byte, err error) {
  var (
    name, tmp, bin string;
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
                       "-infr", "vostok", "-m", tmp, "-cc", "tcc");
    output, err = cmd.CombinedOutput();
    fmt.Print(string(output));
    if err == nil {
      if runtime.GOOS == "windows" {
        cmd = exec.Command(bin)
      } else {
        cmd = exec.Command("timeout", "5", bin)
      }
      output, err = cmd.CombinedOutput();
      fmt.Print(string(output));
    }
  } else {
    output = nil
  }
  return output, err;
}

func handler(w http.ResponseWriter, r *http.Request) {
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
    out, err = run(m, s);
    if err == nil {
      w.Write(out)
    } else {
      fmt.Fprintf(w, "%v\n%v", err, string(out))
    }
  }
}

func main() {
  var (
    port *int;
    err error
  )
  port = flag.Int("port", 8080, "");
  flag.Parse();

  http.Handle("/", http.FileServer(http.Dir(".")));
  http.HandleFunc("/run", handler);
  err = http.ListenAndServe(fmt.Sprintf(":%d", *port), nil);
  if err != nil {
    fmt.Println(err);
    os.Exit(1)
  }
}
