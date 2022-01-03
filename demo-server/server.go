/*  HTTP server and Telegram-bot for translator demonstration
 *  Copyright (C) 2017-2019,2021 ComdivByZero
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
  "encoding/json"
  "bytes"
  "strconv"
)

const (
  kwModule = "MODULE";
  teleApi = "https://api.telegram.org/bot"

  webHelp =
    "/INFO - show this help\n" +
    "/LIST - list available modules\n" +
    "/INFO ModuleName - show info about module\n" +
    "/TO-(C|JS|JAVA) - convert code to appropriate language\n"

  teleHelp = webHelp +
    `/O7: log.s("Script mode")` +
    "\n/MODULE ModuleMode; END ModuleMode.\n"
)

var (
  moduleDirs = [] string {
    "vostok/library",
    "vostok/singularity/definition",
  }
)

type (
  teleChat struct {
    Id int `json:"id"`
  }
  teleMessage struct {
    Chat teleChat `json:"chat"`;
    Txt  string   `json:"text"`
  }
  teleUpdate struct {
    Id     int         `json:"update_id"`;
    Msg    teleMessage `json:"message"`;
    Edited teleMessage `json:"edited_message"`
  }
  teleUpdates struct {
    Ok bool              `json:"ok"`;
    Result []teleUpdate  `json:"result"`
  }
  teleAnswer struct {
    Chat int    `json:"chat_id"`;
    Txt  string `json:"text"`
  }
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
  return
}

func saveModule(name, source string) (tmp string, err error) {
  var (filename string)
  if 0 < len(name) {
    tmp = fmt.Sprintf("%s/ost", os.TempDir());
    err = os.Mkdir(tmp, 0777);
    tmp, err = ioutil.TempDir(tmp, name);
    if err == nil {
      filename = fmt.Sprintf("%v/%v.mod", tmp, name);
      err = ioutil.WriteFile(filename, []byte(source), 0666);
    }
  } else {
    tmp = "";
    err = errors.New("Can not found module name in source")
  }
  return
}

func saveSource(src, scrpt string) (tmp, name, source, script string, err error) {
  source = src;
  script = scrpt;
  tmp = "";
  name = "";
  err = nil;
  if source != "" {
    name = getModuleName(source);
    if name == "" && script == "" {
      script = source;
      source = "";
    } else {
      if script == "" {
        script = name
      }
      tmp, err = saveModule(name, source)
    }
  }
  return
}

func run(source, script, cc string, timeout int) (output []byte, err error) {
  var (
    name, tmp, bin, timeOut string;
    cmd *exec.Cmd
  )

  tmp, name, source, script, err = saveSource(source, script);
  if source == "" {
    name = "script-module";
    tmp, err = ioutil.TempDir(tmp, name)
  }
  if err == nil {
    if runtime.GOOS == "windows" {
      bin = fmt.Sprintf("%v\\%v.exe", tmp, name)
    } else {
      bin = fmt.Sprintf("%v/%v", tmp, name)
    }

    cmd = exec.Command("vostok/result/ost", "to-bin", script, bin,
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
  os.RemoveAll(tmp);
  return
}

func listModules(sep1, sep2 string) (list string) {
  var (
    files []os.FileInfo;
    err error;
    path, add string;
    i int
  )
  list = "";
  for i, path = range moduleDirs {
    files, err = ioutil.ReadDir(path);
    if err == nil {
      add = "";
      for _, f := range files {
        if strings.HasSuffix(f.Name(), ".mod") {
          list += add + strings.TrimSuffix(f.Name(), ".mod");
          add = sep1
        }
      }
      if i != len(moduleDirs) - 1 {
        list += sep2
      }
    }
  }
  return
}

func infoModule(name string) (info []byte) {
  var (
    cmd *exec.Cmd
  )
  cmd = exec.Command("vostok/result/ost", "to-modef", name, "",
                     "-infr", "vostok", "-cyrillic", "-multi-errors");
  info, _ = cmd.CombinedOutput();
  return
}

func toLang(source, vcmd string) (translated []byte) {
  var (
    tmp, name string;
    cmd *exec.Cmd;
  )
  tmp, name, _, source, _ = saveSource(source, "");
  cmd = exec.Command("vostok/result/ost", vcmd, name, "-",
                     "-m", tmp, "-infr", "vostok", "-cyrillic-same", "-multi-errors", "-C11",
                     "-init", "noinit", "-no-array-index-check", "-no-nil-check",
                     "-no-arithmetic-overflow-check");
  translated, _ = cmd.CombinedOutput();
  os.RemoveAll(tmp);
  return
}

func command(text, help, module string) (res []byte) {
  var (cmd string)
  cmd = strings.ToLower(text);
  if cmd == "info" || cmd == "help" {
    res = []byte(help)
  } else if cmd == "list" {
    res = []byte(listModules("\n", "\n\n"))
  } else if strings.HasPrefix(cmd, "info ") || strings.HasPrefix(cmd, "help ") {
    res = infoModule(text[5:])
  } else if cmd == "to-c" || cmd == "to-java" || cmd == "to-js" ||
            cmd == "to-mod" || cmd == "to-modef" {
    res = toLang(module, cmd)
  } else {
    res = []byte("Wrong command, use /INFO for help")
  }
  return
}

func handleInput(script, module, help, cc string, timeout int) (res []byte, err error) {
  script = strings.Trim(script, " \t\n\r");
  err = nil;
  if script == "" {
    res = []byte{}
  } else if strings.HasPrefix(script, "/") || strings.HasPrefix(script, ":") {
    res = command(script[1:], help, module)
  } else {
    res, err = run(module, script, cc, timeout)
  }
  return
}

func handler(w http.ResponseWriter, r *http.Request, cc string, timeout int, allow string) {
  var (
    out []byte
    err error
  )
  if r.Method != "POST" {
    http.NotFound(w, r)
  } else {
    if allow != "" {
      w.Header().Set("Access-Control-Allow-Origin", allow)
    }
    out, err = handleInput(r.FormValue("script"), r.FormValue("module"), webHelp, cc, timeout)
    if err == nil {
      w.Write(out)
    } else {
      fmt.Fprintf(w, "%v\n%v", err, string(out))
    }
  }
}

func webServer(port, timeout int, cc, allow string) (err error) {
  http.Handle("/", http.FileServer(http.Dir(".")));
  http.HandleFunc(
    "/run",
    func(w http.ResponseWriter, r *http.Request) {
      handler(w, r, cc, timeout, allow)
    });
  return http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
}

func teleGetUpdates(api string, ofs int) (upd []teleUpdate, err error) {
  var (
    resp *http.Response;
    data []byte;
    teleUpd teleUpdates
  )
  resp, err = http.Get(api + "getUpdates?offset=" + strconv.Itoa(ofs));
  if err == nil {
    data, err = ioutil.ReadAll(resp.Body);
    resp.Body.Close();

    err = json.Unmarshal(data, &teleUpd);
    if err == nil {
      upd = teleUpd.Result
    }
  } else {
    upd = nil
  }
  return
}

func teleSend(api, text string, chat int) (err error) {
  var (
    resp *http.Response;
    msg  teleAnswer;
    data []byte
  )
  msg.Chat = chat;
  msg.Txt = text;
  data, err = json.Marshal(&msg);
  if err == nil {
    resp, err = http.Post(api + "sendMessage", "application/json", bytes.NewBuffer(data));
    if err == nil {
      resp.Body.Close()
    }
  }
  return
}

func teleGetSrc(upd teleUpdate) (src string, chat int) {
  src = upd.Msg.Txt;
  if src == "" {
    src  = upd.Edited.Txt;
    chat = upd.Edited.Chat.Id
  } else {
    chat = upd.Msg.Chat.Id
  }
  if strings.HasPrefix(src, "/O7:") {
    src = src[4:]
  } else if strings.HasPrefix(src, "/MODULE ") {
    src = src[1:]
  } else if strings.HasPrefix(src, "/") {
    src = ""
  }
  return
}

func handleIfCommand(api, code, cc string, timeout, chat int) (err error) {
  var (i int; cmd string)
  err = nil;
  if len(code) > 0 && code[0] == '/' {
    i = strings.Index(code, " ");
    if i < 0 {
      i = len(code)
    }
    cmd = strings.ToLower(code[1:i]);
    if cmd == "start" || cmd == "help" || cmd == "info" && i == len(code) {
      err = teleSend(api, teleHelp, chat)
    } else if cmd == "list" {
      err = teleSend(api, listModules(" ", "\n\n"), chat)
    } else if cmd == "info" {
      for i < len(code) && code[i] == ' ' { i += 1 }
      err = teleSend(api, string(infoModule(code[i:])), chat)
    }
  }
  return
}

func teleBot(token, cc string, timeout int) (err error) {
  var (
    api, src string;
    upds []teleUpdate;
    lastUpdate, chat int;
    output []byte
  )
  api = teleApi + token + "/";
  err = nil;
  lastUpdate = -1;
  for err == nil {
    upds, err = teleGetUpdates(api, lastUpdate + 1);
    if err == nil {
      for _, upd := range upds {
        src, chat = teleGetSrc(upd);
        if src != "" {
          output, err = run(src, "", cc, timeout);
          err = teleSend(api, string(output), chat)
        } else {
          handleIfCommand(api, strings.Trim(upd.Msg.Txt, " \t\r\n"), cc, timeout, chat)
        }
        lastUpdate = upd.Id
      }
    }
  }
  return
}

func main() {
  var (
    port, timeout *int;
    cc *string;
    err error;
    telegram, access *string
  )
  port     = flag.Int("port", 8080, "tcp/ip");
  access   = flag.String("access", "", "web server's allowed clients mask");
  timeout  = flag.Int("timeout", 5, "in seconds");
  cc       = flag.String("cc", "tcc", "c compiler");
  telegram = flag.String("telegram", "", "telegram bot's token");
  flag.Parse();

  if *telegram != "" {
    err = teleBot(*telegram, *cc, *timeout)
  } else {
    err = webServer(*port, *timeout, *cc, *access)
  }
  if err != nil {
    fmt.Println(err);
    os.Exit(1)
  }
}
