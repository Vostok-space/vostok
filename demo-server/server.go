package main

import (
  "fmt"
  "net/http"
  "os/exec"
  "strings"
  "io/ioutil"
  "errors"
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

func saveModule(source string) (tmp string, err error) {
  var (name, filename string)
  name = getModuleName(source);
  err = nil;
  if len(name) > 0 {
    tmp, err = ioutil.TempDir("/tmp/o7c", name);
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
    tmp string;
    cmd *exec.Cmd
  )
  tmp, err = saveModule(source);
  if err == nil {
    cmd = exec.Command("vostok/result/o7c", "run", script,
                       "-infr", "vostok", "-m", tmp, "-cc", "tcc");
    output, err = cmd.CombinedOutput();
    fmt.Print(string(output))
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
  http.Handle("/", http.FileServer(http.Dir(".")));
  http.HandleFunc("/run", handler);
  http.ListenAndServe(":8080", nil)
}
