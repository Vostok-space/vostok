/*  HTTP server and Telegram-bot for translator demonstration
 *  Copyright (C) 2017-2019,2021-2022 ComdivByZero
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
    "/TO-(C|JS|JAVA|PUML|SCHEME)\n" +
    "    - convert code to appropriate language\n"

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

  source struct {
    name,
    cmd, par,
    script    string

    texts     []string;
    selected  int
  }
)

func createTmp(name string) (tmp string, err error) {
  tmp = fmt.Sprintf("%s/ost", os.TempDir());
  err = os.Mkdir(tmp, 0700);
  if err != nil {
    tmp, err = ioutil.TempDir(tmp, name)
  }
  return
}

func saveModule(tmp, name, source string) (err error) {
  var (filename string)
  filename = fmt.Sprintf("%v/%v.mod", tmp, name);
  err = ioutil.WriteFile(filename, []byte(source), 0600);
  return
}

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

func saveSource(src source) (tmp string, err error) {
  tmp, err = createTmp(src.name)

  for i := 0; i < len(src.texts) && err == nil; i += 1 {
    var (nm string)
    nm = getModuleName(src.texts[i]);
    if nm != "" {
      err = saveModule(tmp, nm, src.texts[i])
    }
  }
  return
}

func run(src source, cc string, timeout int) (output []byte, err error) {
  var (
    tmp, bin, timeOut string;
    cmd *exec.Cmd
  )

  tmp, err = saveSource(src);
  if err == nil {
    bin = tmp + "/" + src.name;
    if runtime.GOOS == "windows" {
      bin += ".exe"
    }

    cmd = exec.Command("vostok/result/ost", "to-bin", src.script, bin,
                       "-infr", "vostok", "-m", tmp, "-cc", cc, "-cyrillic", "-multi-errors");
    fmt.Println("(", src.script, ")");
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
    f os.FileInfo;
    err error;
    path, add string;
    i int
  )
  list = "";
  for i, path = range moduleDirs {
    files, err = ioutil.ReadDir(path);
    if err == nil {
      add = "";
      for _, f = range files {
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

func toLang(src source) (translated []byte) {
  var (
    tmp, puml, svg, str string;
    cmd *exec.Cmd;
  )
  tmp, _ = saveSource(src);
  if src.cmd == "to-scheme" {
    puml = tmp + "/out.puml";
    svg  = tmp + "/out.svg";
    str = "vostok/result/ost to-puml " + src.name + " - -m " + tmp + " -infr vostok > " +
          puml + " && plantuml -tsvg " + puml + " && cat " + svg;
    cmd = exec.Command("sh", "-c", str)
  } else {
    cmd = exec.Command("vostok/result/ost", src.cmd, src.name, "-",
                       "-m", tmp, "-infr", "vostok", "-cyrillic-same", "-multi-errors", "-C11",
                       "-init", "noinit", "-no-array-index-check", "-no-nil-check",
                       "-no-arithmetic-overflow-check")
  }
  translated, _ = cmd.CombinedOutput();
  os.RemoveAll(tmp);
  return
}

func command(src source, help string, skipUnknownCommand bool) (res []byte, ok bool) {
  var (cmd, par string)

  ok = true;
  cmd = src.cmd;
  par = src.par;
  if par == "" && (cmd == "info" || cmd == "help") {
    res = []byte(help)
  } else if par == "" && cmd == "list" {
    res = []byte(listModules("\n", "\n\n"))
  } else if cmd == "info" || cmd == "help" || cmd == "list" {
    res = infoModule(par)
  } else if cmd == "to-c" || cmd == "to-java" || cmd == "to-js" ||
            cmd == "to-mod" || cmd == "to-modef" ||
            cmd == "to-puml" || cmd == "to-scheme" {
    res = toLang(src)
  } else if skipUnknownCommand {
    res = []byte{}
  } else {
    res = []byte("Wrong command, use /INFO for help");
    ok = false
  }
  return
}

func handleInput(src source, help, cc string, timeout int, skipUnknownCommand bool) (res []byte, err error) {
  err = nil;
  if src.script == "" {
    res = []byte{}
  } else if src.cmd == "run" {
    res, err = run(src, cc, timeout)
  } else {
    res, _ = command(src, help, skipUnknownCommand)
  }
  return
}

func splitCommand(text string) (cmd, par string) {
  var (all []string)

  all = strings.SplitN(text, " ", 2);
  cmd = strings.ToLower(all[0]);
  if len(all) > 1 {
    par = all[1]
  } else {
    par = ""
  }
  return
}

func normalizeSource(src *source) {
  src.name = getModuleName(src.texts[0]);
  if src.script == "" && src.name == "" {
    src.script = strings.Trim(src.texts[0], " \t\n\r");
    src.texts[0] = ""
  }
  if strings.HasPrefix(src.script, "/") || strings.HasPrefix(src.script, ":") {
    src.cmd, src.par = splitCommand(src.script[1:])
  } else {
    if src.script == "" {
      src.script = src.name
    }
    src.cmd = "run"
    src.par = ""
  }
  if src.name == "" {
    src.name = "script"
  }
}

func getTexts(r *http.Request) (src source, err error) {
  var (count, selected, scanned int)

  scanned, err = fmt.Sscanf(r.FormValue("texts-count"), "%v:%v", &selected, &count);
  if err != nil || scanned == 0 {
    ;
  } else if count < 0 || count > 32 {
    err = errors.New("modules count out of range")
  } else if selected < 0 || selected >= count {
    err = errors.New("selected module out of range " + fmt.Sprint(selected, count));
  }
  if err == nil {
    src.script = strings.Trim(r.FormValue("script"), " \t\n\r");

    src.texts = make([]string, count);
    src.texts[0] = r.FormValue(fmt.Sprint("text-", selected));
    for i := 0; i < selected; i += 1 {
      src.texts[i + 1] = r.FormValue(fmt.Sprint("text-", i))
    }
    for i := selected + 1; i < count; i += 1 {
      src.texts[i] = r.FormValue(fmt.Sprint("text-", i))
    }
    normalizeSource(&src)
  }
  return
}

func handler(w http.ResponseWriter, r *http.Request, cc string, timeout int, allow string) {
  var (
    out []byte;
    err error;
    src source
  )
  if r.Method != "POST" {
    http.NotFound(w, r)
  } else {
    if allow != "" {
      w.Header().Set("Access-Control-Allow-Origin", allow)
    }
    src, err = getTexts(r);
    if err == nil {
      out, err = handleInput(src, webHelp, cc, timeout, false)
    }
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

func teleGetSrc(upd teleUpdate) (src source, chat int) {
  var (txt string)
  txt = upd.Msg.Txt;
  if txt == "" {
    txt = upd.Edited.Txt;
    chat = upd.Edited.Chat.Id
  } else {
    chat = upd.Msg.Chat.Id
  }
  if strings.HasPrefix(txt, "/O7:") {
    txt = txt[4:]
  } else if strings.HasPrefix(txt, "/MODULE ") {
    txt = txt[1:]
  } else if strings.HasPrefix(txt, "/") {
    txt = ""
  }
  src.script = "";
  src.texts = []string{txt};
  normalizeSource(&src)
  return
}

func teleBot(token, cc string, timeout int) (err error) {
  var (
    api string;
    src source;
    upds []teleUpdate;
    upd teleUpdate;
    lastUpdate, chat int;
    output []byte
  )
  api = teleApi + token + "/";
  err = nil;
  lastUpdate = -1;
  for err == nil {
    upds, err = teleGetUpdates(api, lastUpdate + 1);
    if err == nil {
      for _, upd = range upds {
        src, chat = teleGetSrc(upd);
        output, err = handleInput(src, teleHelp, cc, timeout, true);
        err = teleSend(api, string(output), chat);
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
  port     = flag.Int   ("port"     , 8080  , "tcp/ip");
  access   = flag.String("access"   , ""    , "web server's allowed clients mask");
  timeout  = flag.Int   ("timeout"  , 5     , "in seconds");
  cc       = flag.String("cc"       , "tcc" , "c compiler");
  telegram = flag.String("telegram" , ""    , "telegram bot's token");
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
