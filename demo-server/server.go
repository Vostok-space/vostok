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
  "crypto/rand"
)

const (
  kwModule = "MODULE";
  teleApi = "https://api.telegram.org/bot";

  eng = 0;
  rus = 1;
  ukr = 2;
)

var (
  moduleDirs = [] string {
    "library",
    "singularity/definition",
  };

  langStrs = [] string {
    "eng",
    "rus",
    "ukr",
  };

  webHelp = [] string {
    "Module.Proc(Params) - run Oberon-code\n" +
    "/INFO - show this help\n" +
    "/LIST - list available modules\n" +
    "/INFO ModuleName - show info about module\n" +
    "/TO-(C|JS|JAVA|PUML|SCHEME)\n" +
    "    - convert code to appropriate language\n" +
    "/SAVE [name]|id - save project to server\n" +
    "      optional name for new save, id for existing\n" +
    "/LOAD id - load project from server\n",

    "Module.Proc(Params) - запуск кода на Oberon\n" +
    "/INFO - показ этой справки\n" +
    "/LIST - список доступных модулей\n" +
    "/INFO ModuleName - справка по модулю\n" +
    "/TO-(C|JS|JAVA|PUML|SCHEME)\n" +
    "    - преобразование модуля в соответствующий язык\n" +
    "/SAVE [name]|id - сохранить проект на сервер\n" +
    "      пусто или имя латиницей для 1-го сохранения, id для следующих\n" +
    "/LOAD id - загрузить проект с сервера\n",
  };
  teleHelp = [] string {
    `/O7: log.sn("Script mode")` +
    "\n/MODULE ModuleMode; END ModuleMode.\n",
  }
)

type (
  teleChat struct {
    Id int `json:"id"`
  }
  teleUser struct {
    Lang string `json:"language_code"`
  }
  teleMessage struct {
    Id    int           `json:"message_id"`;
    From  teleUser      `json:"from"`;
    Chat  teleChat      `json:"chat"`;
    Txt   string        `json:"text"`;
    Reply *teleMessage  `json:"reply_to_message,omitempty"`
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
    Txt  string `json:"text"`;
    ReplyId int `json:"reply_to_message_id,omitempty"`
  }

  source struct {
    name,
    cmd, par,
    script,
    input     string;

    texts,
    runners,
    buttons   []string
  }

  saveInfo struct {
    ViewId  string    `json:"viewId"`;
    Runners []string  `json:"runners"`;
    Buttons []string  `json:"buttons"`
  }

  project struct {
    Info  saveInfo    `json:"info"`;
    Texts []string    `json:"texts"`
  }
)

func createTmp(name string) (tmp string, err error) {
  tmp = os.TempDir() + "/ost";
  os.Mkdir(tmp, 0700);
  tmp, err = ioutil.TempDir(tmp, name);
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

func ostToBin(ostDir, script, bin, tmp, cc string, multiErrors bool, lang int) (output []byte, err error) {
  var (cmd *exec.Cmd)
  cmd = exec.Command(ostDir + "/result/ost", "to-bin", script, bin,
                     "-infr", ostDir, "-m", tmp, "-cc", cc, "-cyrillic", "-multi-errors",
                     "-msg-lang:" + langStrs[lang]);
  if !multiErrors {
    cmd.Args = cmd.Args[:len(cmd.Args) - 1]
  }
  output, err = cmd.CombinedOutput();
  return
}

func run(ostDir string, src source, cc string, timeout, lang int) (output []byte, err error) {
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
    fmt.Println("(", src.script, ")");
    output, err = ostToBin(ostDir, src.script, bin, tmp, cc, true, lang);
    if err != nil && err.(*exec.ExitError).ExitCode() < 0 {
      output, err = ostToBin(ostDir, src.script, bin, tmp, cc, false, lang)
    }
    fmt.Print(string(output));
    if err == nil {
      cmd = exec.Command(bin);
      cmd.Stdin = strings.NewReader(src.input);
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

func listModules(ostDir, sep1, sep2 string) (list string) {
  var (
    files []os.FileInfo;
    f os.FileInfo;
    err error;
    path, add string;
    i int
  )
  list = "";
  for i, path = range moduleDirs {
    files, err = ioutil.ReadDir(ostDir + "/" + path);
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

func infoModule(ostDir, name string, lang int) (info []byte) {
  var (
    cmd *exec.Cmd
  )
  cmd = exec.Command(ostDir + "/result/ost", "to-modef", name, "",
                     "-infr", ostDir, "-cyrillic", "-multi-errors",
                     "-msg-lang:" + langStrs[lang]);
  info, _ = cmd.CombinedOutput();
  return
}

func toLang(ostDir string, src source, lang int) (translated []byte) {
  var (
    tmp, puml, svg, str string;
    cmd *exec.Cmd;
  )
  tmp, _ = saveSource(src);
  if src.cmd == "to-scheme" {
    puml = tmp + "/out.puml";
    svg  = tmp + "/out.svg";
    str = ostDir + "/result/ost to-puml " + src.name + " - -m " + tmp +
          " -infr " + ostDir + " -cyrillic -msg-lang:" + langStrs[lang] + " > " + puml +
          " && plantuml -tsvg " + puml + " && cat " + svg;
    cmd = exec.Command("sh", "-c", str)
  } else {
    cmd = exec.Command(ostDir + "/result/ost", src.cmd, src.name, "-",
                       "-m", tmp, "-infr", ostDir, "-cyrillic-same", "-multi-errors", "-C11",
                       "-init", "noinit", "-no-array-index-check", "-no-nil-check",
                       "-no-arithmetic-overflow-check", "-msg-lang:" + langStrs[lang])
  }
  translated, _ = cmd.CombinedOutput();
  os.RemoveAll(tmp);
  return
}

func randInt() (r int) {
  var (
    b [4]byte;
    err error
  )
  _, err = rand.Read(b[:]);
  if err == nil {
    r = int(b[0]) + int(b[1]) * 0x100 + int(b[2]) * 0x10000 + int(b[3]) % 0x80 * 0x1000000
  } else {
    // TODO
    r = 0
  }
  return
}

func checkName(s string) (err error) {
  err = nil;
  return
}

func checkId(s string) (err error) {
  err = nil;
  return
}

func parseIdAndName(str string) (id, name string, err error) {
  var (all []string)

  all = strings.SplitN(strings.Trim(str, " \t\n\r"), "-", 2);
  if len(all) > 1 {
    id = all[0];
    name = all[1]
  } else {
    id = "";
    name = all[0]
  }
  err = checkName(name);
  if err == nil {
    err = checkId(id)
  }
  return
}

func newId(forEdit bool) (id string, err error) {
  var (s [12]byte; i, lim int)

  _, err = rand.Read(s[:]);
  if err == nil {
    if forEdit {
      s[0] = 'a' + s[0] % 26
    } else {
      s[0] = '0' + s[0] % 10
    }
    lim = 1024;
    for i = 1; err == nil && i < len(s) && lim > 0; lim -= 1 {
      /* 0x40 вместо 36 для равномерности */
      s[i] %= 0x40;
      if s[i] < 36 {
        if s[i] < 10 {
          s[i] += '0'
        } else {
          s[i] += 'a' - 10
        }
        i += 1
      } else {
        _, err = rand.Read(s[i : i + 1])
      }
    }
    if err == nil && lim <= 0 {
      err = errors.New("Loop limit exceeded for ID generation")
    }
  }
  if err == nil {
    id = string(s[:])
  } else {
    id = ""
  }
  return
}

func fullId(id, name string) (fid string) {
  if name == "" {
    fid = id
  } else {
    fid = id + "-" + name
  }
  return
}

func getIdAndName(str string) (fid string, isNewId bool, name string, err error) {
  fid, name, err = parseIdAndName(str);
  if err == nil {
    isNewId = fid == "";
    if isNewId {
      fid, err = newId(true)
    }
    if err == nil {
      fid = fullId(fid, name)
    }
  }
  return
}

func readView(editdir string) (view string) {
  var (data []byte; err error; info saveInfo)

  view = "";
  data, err = os.ReadFile(editdir + "/info.json");
  if err == nil {
    err = json.Unmarshal(data, &info);
    if err == nil {
      view = info.ViewId
    }
  }
  return
}

func linkView(workdir, editId, name string) (id string, err error) {
  var (view string)

  id, err = newId(false);
  if err == nil {
    id = fullId(id, name);
    view = workdir + "/view/" + id;
    err = os.MkdirAll(workdir + "/view", 0700);
    if err == nil {
      err = os.Symlink("../edit/" + editId, view)
    }
  }
  return
}

func writeInfo(editdir string, view string, runners, buttons []string) (err error) {
  var (info saveInfo; data []byte)

  info.ViewId = view;
  info.Runners = runners;
  info.Buttons = buttons;
  data, err = json.Marshal(&info);
  if err == nil {
    err = os.WriteFile(editdir + "/" + "info.json", data, 0600)
  }
  return
}

func saveToWorkdir(src source, workdir, origin string, lang int) (resp []byte) {
  var (
    err error;
    tmp, dir, old, file, edit, view string;
    isNewId bool;
    id, name string;
    i int
  )

  if workdir == "" {
    err = errors.New(local([]string{
      "Saving is not allowed - working directory not set by server",
      "Сохранение недоступно - на сервере не выставлен рабочий каталог",
    }, lang))
  } else {
    id, isNewId, name, err = getIdAndName(src.par);
    if err == nil {
      edit = fmt.Sprintf("%v/edit", workdir);
      err = os.MkdirAll(edit, 0700);
      if err == nil {
        dir = fmt.Sprintf("%v/%v", edit, id);
        tmp = dir;
        err = os.Mkdir(dir, 0700);
        if isNewId == os.IsExist(err) {
          if !isNewId {
            err = fmt.Errorf(local([]string {
              "Project %v does not exist. Remove id to save as new.",
              "Проект %v не существует. Уберите идентификатор для сохранения как нового",
              }, lang), id)
          }
        } else {
          if isNewId {
            view = "";
            err = nil
          } else {
            view = readView(dir);
            i = randInt();
            tmp = fmt.Sprintf("%v/tmp-%v-%v", edit, i, id);
            old = fmt.Sprintf("%v/tmp-old-%v-%v", edit, i, id);
            err = os.Mkdir(tmp, 0700)
          }
          for i = 0; i < len(src.texts) && err == nil; i += 1 {
            file = fmt.Sprintf("%v/%v", tmp, i);
            err = ioutil.WriteFile(file, []byte(src.texts[i]), 0600)
          }
          if err != nil {
            ;
          } else if tmp != dir {
            err = os.Rename(dir, old);
            if err == nil {
              err = os.Rename(tmp, dir);
              if err != nil {
                os.Rename(old, dir);
                old = tmp
              }
            }
            if err == nil {
              tmp = old
            }
          } else {
            tmp = ""
          }
          if err == nil {
            if view == "" {
              view, err = linkView(workdir, id, name)
            }
            if err == nil {
              err = writeInfo(dir, view, src.runners, src.buttons)
            }
          }
        }
        if err == nil {
          resp = []byte(fmt.Sprintf(local([]string {
            "Project saved by EDIT id: %v. Don't share it.\n" +
            "    %v/sandbox.html?EDIT=%v\n\n" +
            "VIEW id: %v for sharing\n" +
            "    %v/sandbox.html?view=%v",

            "Сохранено под РЕДАКТОРСКИМ id: %v. Не делитесь им.\n" +
            "    %v/sandbox.html?EDIT=%v\n\n" +
            "Для просмотра и распространения - id: %v\n" +
            "    %v/sandbox.html?view=%v",
            }, lang), id, origin, id, view, origin, view))
        }
        if tmp != "" {
           os.RemoveAll(tmp)
        }
      }
    }
  }
  if err != nil {
    resp = []byte(fmt.Sprintf("Save error:\n    %v", err.Error()))
  }
  return
}

func isCommandSave(cmd string) (yes bool) {
  cmd = strings.ToUpper(cmd);
  yes = strings.HasPrefix(cmd, "/SAVE") || strings.HasPrefix(cmd, ":SAVE")
  return
}

func removeCommandSave(commands *[]string) {
  var (i, j int; s []string)
  j = 0;
  s = *commands;
  for i = 0; i < len(s); i += 1 {
    if !isCommandSave(s[i]) {
      s[j] = s[i];
      j += 1
    }
  }
  *commands = s[:j]
}

func load(workdir, id string) (res []byte) {
  var (
    pr project;
    forEdit bool;
    dir string;
    data []byte;
    e1, e2 error;
    i int;
    err struct {
      Error string `json:"error"`
    }
  )

  forEdit = 'a' <= id[0] && id[0] <= 'z';
  if forEdit {
    dir = "/edit/"
  } else {
    dir = "/view/"
  }
  dir = workdir + dir + id + "/";

  data, e1 = os.ReadFile(dir + "info.json");
  if e1 == nil {
    e1 = json.Unmarshal(data, &pr.Info); data = nil;
    if e1 != nil {
      pr.Info.Runners = []string{};
      pr.Info.Buttons = []string{}
    } else if !forEdit {
      removeCommandSave(&pr.Info.Runners);
      removeCommandSave(&pr.Info.Buttons)
    }
  }
  e2 = nil;
  pr.Texts = make([]string, 0, 32);
  for i = 0; i < 32 && e2 == nil; {
    data, e2 = os.ReadFile(dir + strconv.Itoa(i));
    if e2 == nil {
      pr.Texts = append(pr.Texts, string(data)); data = nil;
      i += 1
    }
  }
  if e1 != nil && i == 0 {
    err.Error = "Can't open project for " + id;
    res, e1 = json.Marshal(&err)
  } else {
    res, e1 = json.Marshal(&pr)
  }
  return
}

func command(ostDir string, src source, help, workdir string, skipUnknownCommand bool,
             origin string, lang int) (res []byte, ok bool) {
  var (cmd string)

  ok = true;
  cmd = src.cmd;
  if src.par == "" && (cmd == "info" || cmd == "help") {
    res = []byte(help)
  } else if src.par == "" && cmd == "list" {
    res = []byte(listModules(ostDir, "\n", "\n\n"))
  } else if cmd == "info" || cmd == "help" || cmd == "list" {
    res = infoModule(ostDir, src.par, lang)
  } else if cmd == "to-c" || cmd == "to-java" || cmd == "to-js" ||
            cmd == "to-mod" || cmd == "to-modef" ||
            cmd == "to-puml" || cmd == "to-scheme" {
    res = toLang(ostDir, src, lang)
  } else if cmd == "save" {
    res = saveToWorkdir(src, workdir, origin, lang)
  } else if cmd == "load" {
    res = load(workdir, src.par)
  } else if skipUnknownCommand {
    res = []byte{}
  } else {
    res = []byte("Wrong command, use /INFO for help");
    ok = false
  }
  return
}

func handleInput(ostDir string, src source, help, cc string, timeout int, workdir string,
                 skipUnknownCommand bool, origin string, lang int) (res []byte, err error) {
  err = nil;
  if src.script == "" {
    res = []byte{}
  } else if src.cmd == "run" {
    res, err = run(ostDir, src, cc, timeout, lang)
  } else {
    res, _ = command(ostDir, src, help, workdir, skipUnknownCommand, origin, lang)
  }
  return
}

func splitCommand(text string) (cmd, par string) {
  var (all []string)

  all = strings.SplitN(text, " ", 2);
  cmd = strings.ToLower(all[0]);
  if len(all) > 1 {
    par = strings.Trim(all[1], " \t\r\n")
  } else {
    par = ""
  }
  return
}

func normalizeSource(src *source) {
  if len(src.texts) > 0 {
    src.input = src.texts[0];
    src.name = getModuleName(src.texts[0]);
    if src.script == "" && src.name == "" {
      src.script = strings.Trim(src.texts[0], " \t\n\r");
      src.texts[0] = ""
    }
  }
  if strings.HasPrefix(src.script, "/") || strings.HasPrefix(src.script, ":") {
    src.cmd, src.par = splitCommand(src.script[1:])
  } else {
    if src.script == "" {
      src.script = src.name
    }
    src.cmd = "run";
    src.par = ""
  }
  if src.name == "" {
    src.name = "script"
  }
}

func getArrayOfStrings(r *http.Request, scount, sitem string) (arr []string, err error) {
  var (i, count int)
  count, err = strconv.Atoi(r.FormValue(scount));
  if err == nil {
    arr = make([]string, count);
    for i = 0; i < count; i += 1 {
      arr[i] = r.FormValue(sitem + strconv.Itoa(i))
    }
  }
  return
}

func getRunners(r *http.Request) (runners, buttons []string, err error) {
  runners, err = getArrayOfStrings(r, "runners-count", "runner-");
  if err == nil {
    buttons, err = getArrayOfStrings(r, "buttons-count", "button-");
  }
  return
}

func getTexts(r *http.Request) (src source, err error) {
  var (count, selected, scanned, i int)

  scanned, err = fmt.Sscanf(r.FormValue("texts-count"), "%v:%v", &selected, &count);
  if err != nil || scanned == 0 {
    ;
  } else if count < 0 || count > 32 {
    err = errors.New("Modules count out of range")
  } else if selected < 0 || selected >= count && selected != 0  {
    err = errors.New("Selected module out of range " + fmt.Sprint(selected, count));
  }
  if err == nil {
    src.script = strings.Trim(r.FormValue("script"), " \t\n\r");

    src.texts = make([]string, count);
    if count > 0 {
      src.texts[0] = r.FormValue(fmt.Sprint("text-", selected));
      for i = 0; i < selected; i += 1 {
        src.texts[i + 1] = r.FormValue(fmt.Sprint("text-", i))
      }
      for i = selected + 1; i < count; i += 1 {
        src.texts[i] = r.FormValue(fmt.Sprint("text-", i))
      }
    }
    normalizeSource(&src)
  }
  return
}

func getMsgLangId(l string) (lang int) {
  if l == "ru" {
    lang = rus
  } else if l == "uk" {
    lang = ukr
  } else {
    lang = eng
  }
  return
}

func getMsgLang(r *http.Request) (lang int) {
  lang = getMsgLangId(r.Header["Accept-Language"][0][:2])
  return
}

func webHandler(ostDir string, w http.ResponseWriter, r *http.Request, cc string,
                timeout int, allow, workdir string) {
  var (
    out []byte;
    err error;
    src source;
    lang int
  )
  fmt.Println();
  if r.Method != "POST" {
    http.NotFound(w, r)
  } else {
    if allow != "" {
      w.Header().Set("Access-Control-Allow-Origin", allow)
    }
    lang = getMsgLang(r);
    src, err = getTexts(r);
    if err == nil {
      src.runners, src.buttons, err = getRunners(r);
      out, err = handleInput(ostDir, src, local(webHelp, lang), cc, timeout, workdir, false,
                             r.Header["Origin"][0], lang)
    }
    if err == nil {
      w.Write(out)
    } else {
      fmt.Fprintf(w, "%v\n%v", err, string(out))
    }
  }
}

func webServer(ostDir, addr string, port, timeout int, cc, allow, workdir, crt, key string) (err error) {
  var (a string)
  http.Handle("/", http.FileServer(http.Dir("web")));
  http.HandleFunc("/run",
    func(w http.ResponseWriter, r *http.Request) { webHandler(ostDir, w, r, cc, timeout, allow, workdir) });
  a = fmt.Sprintf("%v:%d", addr, port);
  if crt != "" {
    err = http.ListenAndServeTLS(a, crt, key, nil)
  } else {
    err = http.ListenAndServe(a, nil)
  }
  return
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

func teleSend(api, text string, chat int, replyId int) (err error) {
  var (
    resp *http.Response;
    msg  teleAnswer;
    data []byte
  )
  msg.Chat = chat;
  msg.Txt = text;
  msg.ReplyId = replyId;
  data, err = json.Marshal(&msg);
  if err == nil {
    resp, err = http.Post(api + "sendMessage", "application/json", bytes.NewBuffer(data));
    if err == nil {
      resp.Body.Close()
    }
  }
  return
}

func teleGetSrc(upd teleUpdate) (src source, chat, msgId int) {
  var (txt, name, cmd string; i int)
  txt = upd.Msg.Txt;
  if txt == "" {
    txt = upd.Edited.Txt;
    msgId = upd.Edited.Id;
    chat = upd.Edited.Chat.Id
  } else {
    msgId = upd.Msg.Id;
    chat = upd.Msg.Chat.Id
  }
  txt = strings.Trim(txt, " \t\n\r");
  src.script = "";
  if strings.HasPrefix(txt, "/O7:") {
    txt = txt[4:]
  } else if strings.HasPrefix(txt, "/MODULE ") {
    txt = txt[1:]
  } else if strings.HasPrefix(txt, "/") {
    i = strings.IndexAny(txt, "\r\n");
    if i > 0 {
      cmd = txt[:i];
      src.script = cmd;
      if isCommandSave(cmd) {
        cmd = cmd[:5]
      }
      name = getModuleName(txt);
      if name == "" {
        src.runners = []string{cmd}
      } else {
        src.runners = []string{name, cmd}
      }
      txt = txt[i:]
    }
  }
  src.texts = []string{txt};
  normalizeSource(&src)
  return
}

func local(texts []string, lang int) (text string) {
  if lang < len(texts) && texts[lang] != "" {
    text = texts[lang]
  } else {
    text = texts[0]
  }
  return
}

func teleBot(token, cc, workdir string, timeout int) (err error) {
  var (
    api, lang string;
    src source;
    upds []teleUpdate;
    upd teleUpdate;
    lastUpdate, chat, msgId, lng int;
    output []byte
  )
  api = teleApi + token + "/";
  err = nil;
  lastUpdate = -1;
  for err == nil {
    upds, err = teleGetUpdates(api, lastUpdate + 1);
    if err == nil {
      for _, upd = range upds {
        src, chat, msgId = teleGetSrc(upd);
        if upd.Msg.Txt == "" {
          lang = upd.Msg.From.Lang
        } else {
          lang = upd.Edited.From.Lang
        }
        lng = getMsgLangId(lang);
        output, err = handleInput("vostok", src, local(webHelp, lng) + local(teleHelp, lng),
                                  cc, timeout, workdir, true,
                                  "https://vostok.oberon.org", lng);
        err = teleSend(api, string(output), chat, msgId);
        lastUpdate = upd.Id
      }
    }
  }
  return
}

func main() {
  var (
    port, timeout *int;
    addr, cc, telegram, allow, workdir, crt, key *string;
    ostDir string;
    full *bool;
    err error
  )
  addr     = flag.String("addr"     , ""    , "served tcp/ip address");
  port     = flag.Int   ("port"     , 8080  , "port tcp/ip");
  allow    = flag.String("allow"    , ""    , "web server's allowed clients mask");
  timeout  = flag.Int   ("timeout"  , 5     , "task restriction in seconds");
  cc       = flag.String("cc"       , "tcc" , "c compiler");
  telegram = flag.String("telegram" , ""    , "telegram bot's token");
  workdir  = flag.String("workdir"  , ""    , "directory for saves");
  crt      = flag.String("crt"      , ""    , "file with TLS certificate");
  key      = flag.String("key"      , ""    , "file with TLS private key");
  full     = flag.Bool  ("FULL-ACCESS", false , "to server from localhost-only by default");
  flag.Parse();

  if *telegram != "" {
    err = teleBot(*telegram, *cc, *workdir, *timeout)
  } else {
    if *full {
      if *addr == "" {
        *addr = "localhost"
      }
      ostDir = "vostok-full"
    } else {
      ostDir = "vostok"
    }
    err = webServer(ostDir, *addr, *port, *timeout, *cc, *allow, *workdir, *crt, *key)
  }
  if err != nil {
    fmt.Println(err);
    os.Exit(1)
  }
}
