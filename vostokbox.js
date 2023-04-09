var VostokBox;
(function(vb) {
  'use strict';

  var version = '0.2.0';

  function assert(cond) { if (!cond) { throw 'incorrectness'; } }

  function getLangInd(code) {
    var ind;
    if (code == 'ru') {
      ind = 1;
    } else if (code == 'uk') {
      ind = 2;
    } else { /* en */
      ind = 0;
    }
    return ind;
  }

  function local(box, texts) {
    var t;
    if (box.lang < texts.length && texts[box.lang] != null) {
      t = texts[box.lang];
    } else {
      t = texts[0];
    }
    return t;
  }

  function deactivateTabs(box) {
    var i;
    box.editorSizeListener.disconnect();
    for (i = box.editors.length - 1; i >= 0; i -= 1) {
      box.editors[i].div.classList.add('inactive');
      box.editors[i].tab.classList.remove('active');
    }
  }

  function selectLog(box) {
    if (box.logInTab) {
      deactivateTabs(box);
      box.log.classList.remove('inactive');
      box.logSelected = true;
    }
  }

  function selectTab(box, ind) { assert(0 <= ind && ind < box.editors.length);
    var ed, s, r;
    r = box.editorSize;
    deactivateTabs(box);
    box.logSelected = false;
    if (box.logInTab) { box.log.classList.add('inactive'); }
    box.selected = ind;
    ed = box.editors[ind];
    ed.tab.classList.add('active');
    box.editorSizeListener.observe(ed.div);
    ed.div.classList.remove('inactive');
    s = ed.div.style;
    s.width  = r.width  + 'px';
    s.height = r.height + 'px';
    ed.ace.resize();
  }
  vb.selectTab = selectTab;

  function removeAllRunners(box) {
    box.runners.forEach(function(inp) {
      inp.parentNode.remove();
    });
    box.runners.clear();
  }

  function removeAllButtons(box) {
    var bs, i;
    bs = box.doc.getElementsByClassName('vostokbox-button-runner');
    i = bs.length;
    while (i > 0) {
      i -= 1;
      bs[i].remove();
    }
    box.buttons.clear();
  }

  function removeAllTabs(box) {
    var ed, i;

    for (i = 0; i < box.editors.length; i += 1) {
      ed = box.editors[i];
      ed.div.remove();
      ed.tab.remove();
    }
    box.editors = [];
    if (i > 0) {
      box.tabs.appendChild(box.tabAdder);
    }
  }

  function removeTab(box, ind) { assert(0 <= ind && ind < box.editors.length);
    var ed, text, i, p;
    ed = box.editors[ind];
    p = ed.tab.parentNode;
    ed.div.remove();
    ed.tab.remove();
    i = ind;
    while (i < box.editors.length - 1) {
      box.editors[i] = box.editors[i + 1];
      box.editors[i].index = i;
      text = box.editors[i].ace.getSession().getValue();
      box.editors[i].tab.innerText = getTabName(text, i);
      i += 1;
    }
    box.editors.length = i;
    if (i > 0) {
      if (ind == i) {
        ind -= 1;
      }
      selectTab(box, ind);
      if (i == 31) {
        p.appendChild(box.tabAdder);
      }
    }
  }

  function tabCreate(box, name, ind) {
    var b, ed;
    b = box.doc.createElement('button');
    b.innerText = name;
    ed = box.editors[ind];
    b.onclick = function() {
      if (box.logSelected || box.selected != ed.index) {
        selectTab(box, ed.index);
      } else if (ed.ace.getSession().getValue() == '') {
        removeTab(box, ed.index);
      }
    };
    ed.tab = b;
    return b;
  }

  function createLogTab(box) {
    var b;
    b = box.doc.createElement('button');
    b.innerHTML = '<strong>' + local(box, ['Log', 'Журнал']) + '</strong>';
    b.onclick = function() {
      selectLog(box);
    };
    return b;
  }

  function createAceEditor(ace, div, index) {
    var editor, s;
    editor = {
      div   : div,
      ace   : ace.edit(div),
      index : index
    };

    editor.ace.setDisplayIndentGuides(true);
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      editor.ace.setTheme('ace/theme/idle_fingers');
    }
    s = editor.ace.getSession();
    s.setMode("ace/mode/oberon");
    s.setOptions({
      tabSize               : 2,
      useSoftTabs           : true,
      navigateWithinSoftTabs: true
    });
    editor.ace.setOptions({
      enableBasicAutocompletion : true,
      enableSnippets            : true,
      enableLiveAutocompletion  : true
    });
    return editor;
  }

  function addEditor(box, text) {
    var d, ind;
    if (box.tabAdder != null) {
      box.tabAdder.remove();
    }
    d = box.doc.createElement('div');
    d.className = 'vostokbox-editor';
    d.append(text);
    ind = box.editors.length;
    box.editors[ind] = createAceEditor(box.ace, d, ind);

    box.editorsContainer.prepend(d);
    box.tabs.appendChild(tabCreate(box, getTabName(text, ind), ind));
    if (box.tabAdder != null && ind < 31) {
      box.tabs.appendChild(box.tabAdder);
    }
    selectTab(box, ind);

    box.log.style.resize = 'none';
  }

  function tabAdder(box) {
    var b;
    b = box.doc.createElement('button');
    b.innerText = '[ + ]';
    b.onclick = function() { addEditor(box, ''); };
    return b;
  }

  function isForIdent(code) {
    return (code >= 65 && code < 91)
        || (code >= 97 && code < 123)
        || (code >= 48 && code < 58)
        || (code == 95)
        || (code >= 0x400 && code < 0x530);
  }

  function isBlank(ch) {
    return ' \t\r\n'.indexOf(ch) >= 0;
  }

  function searchWord(text, word) {
    var i;
    i = -1;
    do {
      i = text.indexOf(word, i + 1);
    } while (i >= 0 && !((i == 0 || isBlank(text.charAt(i - 1))) && isBlank(text.charAt(i + word.length))));
    if (i >= 0) {
      i += word.length + 1;
    }
    return i;
  }

  function getTabName(text, ind) {
    var n, t, i, l;

    n = null;

    t = text;
    i = searchWord(t, 'MODULE');
    if (i < 0) {
      i = searchWord(t, 'PROCEDURE');
    }
    if (i >= 0) {
      while (isBlank(t.charAt(i))) { i += 1; }
      l = i;
      while ((l - i < 32) && isForIdent(t.charCodeAt(l))) { l += 1; }
      if (l > i) {
        n = t.substring(i, l);
      }
    }
    if (n == null) {
      n = '[  ' + ind + '  ]';
    }
    return n;
  }

  function switchClassName(doc, from, to) {
    var el, i;
    el = doc.getElementsByClassName(from);
    for (i = el.length - 1; i >= 0; i -= 1) {
      assert(el[i].classList.replace(from, to));
    }
  }

  function switchCtrl(doc, ke, from, to) {
    if (ke.keyCode == 17) {
      switchClassName(doc, from, to);
    }
  }

  function storagePut(box, name, value) {
    box.storage[box.storagePrefix + name] = value;
  }

  function storageGet(box, name) {
    return box.storage[box.storagePrefix + name];
  }

  function storeRunners(box) {
    var i;
    i = 0;
    box.runners.forEach(function(inp) {
      storagePut(box, 'runner-' + i, inp.value);
      i += 1;
    });
    storagePut(box, 'runners-len', i);

    i = 0;
    box.buttons.forEach(function(cmd) {
      storagePut(box, 'button-runner-' + i, cmd);
      i += 1;
    });
    storagePut(box, 'button-runners-len', i);
  }

  function storageGetCommand(box, storageId, saveId) {
    var s, t, cmd;
    cmd = storageGet(box, storageId);
    if (saveId != null) {
      t = cmd.trim();
      s = t.toUpperCase();
      /* TODO */
      if (s.startsWith('/SAVE') || s.startsWith(':SAVE')) {
        cmd = t.substring(0, 5) + ' ' + saveId;
        storagePut(box, storageId, cmd);
      }
    }
    return cmd;
  }

  function loadRunners(box, saveId) {
    var i, k, load, len;
    i = storageGet(box, 'runners-len');
    k = storageGet(box, 'button-runners-len');
    load = i != null || k != null;
    if (i != null) {
      len = parseInt(i);
      for (i = 0; i < len; i += 1) {
        addRunner(box, storageGetCommand(box, 'runner-' + i, saveId));
      }
    }
    if (k != null) {
      len = parseInt(k);
      for (i = 0; i < len; i += 1) {
        addButtonRunner(box, storageGetCommand(box, 'button-runner-' + i, saveId));
      }
    }
    return load;
  }

  function checkPageParams(box, params) {
    var id;
    id = params.get("EDIT") || params.get("view");
    if (id != null) {
      requestRun(box, "/LOAD " + id);
    }
  }

  function createLink(box, text, onclick) {
    var link;
    link = box.doc.createElement('code');
    link.innerText = text;
    link.className = 'vostokbox-log-script';
    link.onclick = onclick;
    return link;
  }

  function ln(box, node) {
    node.appendChild(box.doc.createElement('br'));
  }

  function createHref(box, text, ref) {
    var a;
    a = box.doc.createElement('a');
    a.innerText = text;
    a.href = ref;
    return a;
  }

  function defaultLog(box, empty, savedLog) {
    var div, list, add, runners;

    div = box.doc.createElement('div');
    box.log.append(div);
    if (savedLog == null) {
      div.append(local(box, ['Sandbox v' + version + ' of Vostok - Oberon translator.',
                             'Среда ' + version + ' Востока - транслятора Oberon.']));
      ln(box, div);
    }
    if (empty) {
      runners = ['/INFO', '/LIST', '/TO-C', '/TO-JAVA', '/TO-JS', '/TO-SCHEME', '/CLEAR'];
      div.append(
        local(box, ['Use this links to add ', 'Используйте эти ссылки, чтобы добавить ']),
        createLink(box, local(box, ['editor', 'редактор']),
                   function() { addEditor(box, ''); }),
        ', ',
        createLink(box, local(box, ['commands runner', 'командную строку']),
                   function() { addRunner(box, '/INFO Out'); }),
        ', ',
        createLink(box, local(box, ['predefined buttons', 'предопределённые кнопки']),
                   function() {addButtonRunners(box, runners); }),
        '.'
      );
      ln(box, div);
    }
    if (savedLog == null) {
      div.append(local(box, ['Use Ctrl-key for an additional possibility to modify environment.',
            'Используйте клавишу Ctrl для дополнительной возможности редактирования окружения.']));
      ln(box, div);
      div.append(
        local(box, ['See ', 'Посмотрите ']),
        createHref(box, local(box, ['examples', 'примеры']), 'https://vostok.oberon.org/examples.html'),
        '.'
      );
      ln(box, div);
      div.append(local(box, ['Note that sandbox uses web-storage to store input.',
                             'Среда использует web-хранилище для сохранения ввода.']));
    }
  }

  function logAppendChild(box, item) {
    var log, needScroll;
    selectLog(box);
    log = box.log;
    needScroll = box.logInTab || log.scrollHeight - log.scrollTop < log.clientHeight + 320;
    log.appendChild(item);

    box.storage['vostokbox-log'] = log.innerHTML;

    if (needScroll) {
      item.scrollIntoView({ behavior: 'smooth', block: 'end'});
    }
  }

  function log(box, tag, className, text) {
    var pre;
    pre = box.doc.createElement(tag);
    pre.innerText = text;
    pre.className = className;
    pre.style.width = "fit-content";
    logAppendChild(box, pre);
    return pre;
  }

  function svgLog(box, className, text) {
    var div;
    div = box.doc.createElement('div');
    div.innerHTML = text;
    div.className = className;
    logAppendChild(box, div);
  }

  function errorLog(box, text) {
    log(box, 'pre', 'vostokbox-log-error', text);
  }

  function normalLog(box, text) {
    log(box, 'pre', 'vostokbox-log-out', text);
  }

  function scriptEcho(box, src) {
    var echo;
    echo = log(box, 'code', 'vostokbox-log-script', src);
    echo.onclick = function() { requestRun(box, src); };
  }

  function addIdToCommandSave(id, cmds) {
    var i, s;
    for (i = 0; i < cmds.length; i += 1) {
      s = cmds[i].toUpperCase();
      if (s == "/SAVE" || s == ":SAVE") {
        cmds[i] += " " + id;
      }
    }
    return cmds;
  }

  function load(box, id, text) {
    var res, i, loc;
    try {
      res = JSON.parse(text);
      /* TODO */
    } catch(e) {
      res = null;
    }
    if (!(res instanceof Object)) {
      res = {error: 'Invalid format of /LOAD response'};
    }
    if (res.error == null) {
      removeAllTabs(box);
      removeAllRunners(box);
      removeAllButtons(box);

      for (i = 0; i < res.texts.length; i += 1) {
        addEditor(box, res.texts[i]);
      }
      if (res.texts.length > 0) {
        selectTab(box, 0);
      }
      addRunners(box, addIdToCommandSave(id, res.info.runners || []));
      addButtonRunners(box, addIdToCommandSave(id, res.info.buttons || []));

      loc = window.location;
      svgLog(box, '', local(box, ['Successfully loaded', 'Загружено']) +
        '. <a href="' + loc.origin + loc.pathname + '">' +
        local(box, ['Cancel', 'Отменить']) + '</a>');
    } else {
      errorLog(box, res.error);
    }
  }

  function onSave(box, text) {
    var s, i, pref, id;
    pref = ' id: ';
    s = text.indexOf(pref);
    if (s >= 0) {
      id = text.substring(s + pref.length, text.indexOf('.', s + pref.length));
      removeAllRunners(box);
      removeAllButtons(box);
      loadRunners(box, id);
    }
    normalLog(box, text);
  }

  function trimCommandForServer(cmd) {
    var s;
    cmd = cmd.trim();
    s = cmd.toUpperCase();
    if (s.startsWith('/SAVE ') || s.startsWith(':SAVE ')) {
      cmd = cmd.substring(0, 5);
    }
    return cmd;
  }

  function requestRun(box, scr) {
    var req, data, i, text, texts, uscr, add, id;

    scriptEcho(box, scr);

    uscr = scr.trim().toUpperCase();
    if (uscr.charAt(0) == ':') {
      uscr = '/' + uscr.substring(1);
    }
    if (uscr == '/CLEAR' || uscr == '/CLS') {
      box.log.innerHTML = '';
      box.storage.removeItem('vostokbox-log');
    } else {
      req = new XMLHttpRequest();

      req.timeout = box.runTimeout;
      req.ontimeout = function (e) {
        errorLog(box, local(box, ['connection timeout', 'соединение просрочено']));
      };
      req.onerror   = function (e) {
        errorLog(box, local(box, ['connection error', 'ошибка соединения']));
      };
      if (uscr == '/TO-SCHEME') {
        req.onload = function (e) { svgLog(box, 'vostokbox-log-out', e.target.responseText); };
      } else if (uscr.startsWith('/LOAD ')) {
        id = scr.trim().substring(5).trim();
        req.onload = function (e) { load(box, id, e.target.responseText); };
      } else if (uscr.startsWith('/SAVE')) {
        req.onload = function (e) { onSave(box, e.target.responseText); };
      } else {
        if (uscr == '/INFO') {
          add = '/CLEAR - ' + local(box, ['clear the log', 'чистка журнала']);
        } else {
          add = '';
        }
        req.onload = function (e) { normalLog(box, e.target.responseText + add); };
      }
      req.open('POST', box.runUrl);
      data = new FormData();
      i = box.editors.length;
      data.append('texts-count', [box.selected, ':', i].join(''));

      box.storage.clear();
      storagePut(box, 'texts-len', i);
      while (i > 0) {
        i -= 1;
        text = box.editors[i].ace.getSession().getValue();
        data.append('text-' + i, text);
        box.editors[i].tab.innerText = getTabName(text, i);
        storagePut(box, 'texts-' + i, text);
      }

      data.append('runners-count', box.runners.size);
      i = 0;
      box.runners.forEach(function(inp) {
        data.append('runner-' + i, trimCommandForServer(inp.value));
        i += 1;
      });

      data.append('buttons-count', box.buttons.size);
      i = 0;
      box.buttons.forEach(function(cmd) {
        data.append('button-' + i, trimCommandForServer(cmd));
        i += 1;
      });

      box.storage['vostokbox-log'] = box.log.innerHTML;
      storeRunners(box);

      data.append('script', scr);
      req.send(data);
    }
  }

  function addButtonRunner(box, command) {
    var b, c;
    if (command != '') {
      b = box.doc.createElement('button');
      b.className = 'vostokbox-button-runner';
      b.innerHTML = '<div class="ctrl-up"><div class="ctrl">-</div></div>';
      c = box.doc.createElement('code');
      c.innerText = command;
      b.appendChild(c);
      b.onclick = function(pe) {
        if (pe.ctrlKey || box.ctrl) {
          b.remove();
          box.buttons.delete(command);
        } else {
          requestRun(box, command);
        }
      }
      box.buttons.add(command);
      box.buttonsContainer.appendChild(b);
    }
  }

  function createButtonCtrl(box) {
    var b;
    b = box.doc.createElement('button');
    b.id = 'vostokbox-button-ctrl';
    b.innerHTML = '<strong class="ctrl-up"><div class="no-ctrl">ctrl</div>' +
                  '<div class="ctrl">Ctrl</div></strong>';
    b.onclick = function(pe) {
      var cl;
      cl = b.childNodes[0].classList;
      box.ctrl = cl.contains('ctrl-up');
      if (box.ctrl) {
        switchClassName(box.doc, 'ctrl-up', 'ctrl-down');
      } else {
        switchClassName(box.doc, 'ctrl-down', 'ctrl-up');
      }
    }
    return b;
  }

  function runOrFix(box, cmd, keyEvent) {
    if (keyEvent.ctrlKey || box.ctrl) {
      addButtonRunner(box, cmd);
    } else {
      requestRun(box, cmd);
    }
  }

  function addRunner(box, command) { assert(command != null);
    var div, inp, run, add, del, root;
    div = box.doc.createElement('div');
    div.className = 'vostokbox-command-line';
    inp = box.doc.createElement('input');
    inp.type = 'text';
    inp.value = command;
    inp.onkeyup = function(ke) {
      if (ke.keyCode == 13) {
        runOrFix(box, inp.value, ke);
        inp.select();
      }
    };

    run = box.doc.createElement('button');
    run.innerHTML = '<div class="ctrl-up"><div class="no-ctrl"><strong>⏎</strong></div><div class="ctrl">' +
                    local(box, ['Button', 'Кнопка']) + '</div></div>';
    run.onclick = function(pe) { runOrFix(box, inp.value, pe); };

    add = box.doc.createElement('button');
    root = box.runners.size == 0;
    if (root) {
      add.innerHTML = '+';
    } else {
      add.className = 'ctrl-up';
      add.innerHTML = '<div class="no-ctrl">+</div><div class="ctrl">-</div>';
    }
    add.onclick = function(pe) {
      var val;
      if (pe.ctrlKey || box.ctrl) {
        val = '';
      } else {
        val = inp.value;
      }
      if (root || !(pe.ctrlKey || box.ctrl)) {
        addRunner(box, val);
      } else {
        div.remove();
        box.runners.delete(inp);
      }
    };
    div.appendChild(inp);
    div.appendChild(run);
    div.appendChild(add);

    box.runners.add(inp);
    box.runnersContainer.appendChild(div);
  }

  function addRunners(box, commands) {
    var i;
    for (i = 0; i < commands.length; i += 1) {
      addRunner(box, commands[i]);
    }
  }

  function addAllRunners(box, runners) {
    if (!runners.empty) {
      addRunners(box, runners.runners || []);
      addButtonRunners(box, runners.buttonRunners || []);
    }
  }

  function addButtonRunners(box, commands) {
    var i;
    for (i = 0; i < commands.length; i += 1) {
      addButtonRunner(box, commands[i]);
    }
  }

  vb.addRunner        = addRunner;
  vb.addRunners       = addRunners;
  vb.addButtonRunner  = addButtonRunner;
  vb.addButtonRunners = addButtonRunners;

  vb.createByDefaultIdentifiers = function(doc, ace, runners) {
    var box, editor, editors, i, text, texts, log, len;

    box = {
      ace     : ace,
      doc     : doc,
      storage : window.localStorage,
      storagePrefix: 'vostokbox(' + new URL(window.location.href).pathname + ")-",
      runnersContainer : doc.getElementById('vostokbox-runners'),
      buttonsContainer : doc.getElementById('vostokbox-button-runners'),
      log     : doc.getElementById('vostokbox-log'),
      tabs    : doc.getElementById('vostokbox-tabs'),
      editors : [],
      editorSize: null,
      editorSizeListener: new ResizeObserver(function(es) {
          var r, s;
          r = es[0].contentRect;
          s = box.log.style;
          if (r.width > 0 && r.height > 0) {
            box.editorSize = r;
            s.height = r.height + "px";
          } else {
            s.resize = 'vertical';
          }
        }),
      runners : new Set(),
      buttons : new Set(),

      selected: 0,
      editorsContainer: null,
      tabAdder: null,

      runUrl  : null,
      runTimeout: VostokBoxConfig.timeout,

      lang: getLangInd(window.navigator.language.slice(0, 2)),

      logInTab    : window.innerWidth < 934,
      logSelected : false,
      ctrl        : false
    };

    if (window.location.protocol == 'https:') {
      box.runUrl = VostokBoxConfig.runUrl.https;
    } else {
      box.runUrl = VostokBoxConfig.runUrl.http;
    }

    if (box.logInTab) {
      box.tabs.appendChild(createLogTab(box));
      box.buttonsContainer.appendChild(createButtonCtrl(box));
    }

    editors = doc.getElementsByClassName('vostokbox-editor');
    if (editors.length > 0) {
      editor = editors[editors.length - 1];
      box.editorsContainer = editor.parentNode;
      box.editorSize = {
        width: editor.offsetWidth,
        height: editor.offsetHeight
      };
      len = parseInt(storageGet(box, 'texts-len'));
      if (len > 0 || runners.empty) {
        for (i = 0; i < editors.length; i += 1) {
          editors[i].remove();
        }
        for (i = 0; i < len; i += 1) {
          addEditor(box, storageGet(box, 'texts-' + i));
        }
      } else {
        for (i = 0; i < editors.length; i += 1) {
          text = editors[i].innerText;
          box.editors[i] = createAceEditor(ace, editors[i], i);
          box.tabs.appendChild(tabCreate(box, getTabName(text, i), i));
        }
      }
    }
    box.tabAdder = tabAdder(box);
    if (box.editors.length > 0) {
      box.tabs.appendChild(box.tabAdder);
      selectTab(box, 0);
    }

    doc.onkeydown = function(ke) { switchCtrl(box.doc, ke, 'ctrl-up', 'ctrl-down'); };
    doc.onkeyup   = function(ke) { switchCtrl(box.doc, ke, 'ctrl-down', 'ctrl-up'); };

    log = box.storage['vostokbox-log'];
    if (log != null) {
      box.log.innerHTML = log;
    }
    if (!loadRunners(box, null)) {
      addAllRunners(box, runners);
    }
    if (log == null || box.runners.size == 0 || box.editors.length == 0) {
      defaultLog(box, runners.empty, log);
    }
    if (box.log.lastChild != null) {
      box.log.lastChild.scrollIntoView({ block: 'nearest'});
    }
    checkPageParams(box, new URL(window.location.href).searchParams);

    return box;
  };

})(VostokBox || (VostokBox = {}));
