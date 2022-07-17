var VostokBox;
(function(vb) {
  'use strict';

  function assert(cond) { if (!cond) { throw 'incorrectness'; } }

  function selectTab(box, ind) { assert(0 <= ind && ind < box.editors.length);
    var i;
    for (i = box.editors.length - 1; i >= 0; i -= 1) {
      box.editors[i].div.style.display  = 'none';
      box.editors[i].tab.className      = '';
    }
    box.selected = ind;
    box.editors[ind].div.style.display  = 'block';
    box.editors[ind].tab.className      = 'active';
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
    var ed, i, p;

    for (i = 0; i < box.editors.length; i += 1) {
      ed = box.editors[i];
      p = ed.tab.parentNode;
      ed.div.remove();
      ed.tab.remove();
    }
    box.editors = [];
    p.appendChild(box.tabAdder);
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
      if (box.selected != ed.index) {
        selectTab(box, ed.index);
      } else if (ed.ace.getSession().getValue() == '') {
        removeTab(box, ed.index);
      }
    };
    ed.tab = b;
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
    editor.ace.setTheme('ace/theme/idle_fingers');
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
    box.editorsContainer.appendChild(d);
    box.tabs.appendChild(tabCreate(box, getTabName(text, ind), ind));
    if (box.tabAdder != null && ind < 31) {
      box.tabs.appendChild(box.tabAdder);
    }
    selectTab(box, ind);
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

  function getTabName(text, ind) {
    var n, t, i, l;

    n = null;

    t = text;
    i = -1;
    do {
      i = t.indexOf('MODULE', i + 1);
    } while (i >= 0 && !((i == 0 || isBlank(t.charAt(i - 1))) && isBlank(t.charAt(i + 6))));
    if (i >= 0) {
      i += 7;
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

  function switchCtrl(box, ke, from, to) {
    var el, i;
    if (ke.keyCode == 17) {
      el = box.doc.getElementsByClassName(from);
      box.ctrl = ke.ctrlKey;
      for (i = el.length - 1; i >= 0; i -= 1) {
        el[i].className = to;
      }
    }
  }

  function storagePut(box, name, value) {
    console.log('put', box.storagePrefix + name, value);
    box.storage[box.storagePrefix + name] = value;
  }

  function storageGet(box, name) {
    console.log('get', box.storagePrefix + name, box.storage[box.storagePrefix + name]);
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

  function loadRunners(box) {
    var i, k, load, len;
    i = storageGet(box, 'runners-len');
    k = storageGet(box, 'button-runners-len');
    load = i != null || k != null;
    if (i != null) {
      len = parseInt(i);
      for (i = 0; i < len; i += 1) {
        addRunner(box, storageGet(box, 'runner-' + i), i == 0);
      }
    }
    if (k != null) {
      len = parseInt(k);
      for (i = 0; i < len; i += 1) {
        addButtonRunner(box, storageGet(box, 'button-runner-' + i));
      }
    }
    return load;
  }

  function addAllRunners(box, runners) {
    vb.addRootRunner(box, runners.rootRunner || '');
    vb.addRunners(box, runners.runners || []);
    vb.addButtonRunners(box, runners.buttonRunners || []);
  }

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
      runners : new Set(),
      buttons : new Set(),

      selected: 0,
      editorsContainer: null,
      tabAdder: null,
      ctrl    : false
    };

    editors = doc.getElementsByClassName('vostokbox-editor');
    if (editors.length > 0) {
      box.editorsContainer = editors[editors.length - 1].parentNode;
      len = parseInt(storageGet(box, 'texts-len'));
      if (len > 0) {
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
    box.tabs.appendChild(box.tabAdder);
    selectTab(box, 0);

    doc.onkeydown = function(ke) { switchCtrl(box, ke, 'ctrl-up', 'ctrl-down'); };
    doc.onkeyup   = function(ke) { switchCtrl(box, ke, 'ctrl-down', 'ctrl-up'); };

    log = box.storage['vostokbox-log'];
    if (log != null) {
      box.log.innerHTML = log;
      if (box.log.lastChild != null) {
        box.log.lastChild.scrollIntoView({ behavior: 'smooth', block: 'nearest'});
      }
    } else {
      box.log.innerText = 'This site uses web-storage to store input';
    }
    if (!loadRunners(box)) {
      addAllRunners(box, runners);
    }

    return box;
  };

  function logAppendChild(box, item) {
    var log, needScroll, end;
    log = box.log;
    needScroll = log.scrollHeight - log.scrollTop < log.clientHeight + 320;
    log.appendChild(item);

    box.storage['vostokbox-log'] = log.innerHTML;

    if (needScroll) {
      end = box.doc.createElement('div');
      log.appendChild(end);
      end.scrollIntoView({ behavior: 'smooth', block: 'nearest'});
    }
  }

  function log(box, className, text) {
    var pre, table;
    pre = box.doc.createElement('pre');
    pre.innerText = text;
    pre.className = className;
    table = box.doc.createElement('table');
    table.appendChild(pre);
    logAppendChild(box, table);
    return table;
  }

  function svgLog(box, className, text) {
    var div;
    div = box.doc.createElement('div');
    div.innerHTML = text;
    div.className = className;
    logAppendChild(box, div);
  }

  function errorLog(box, text) {
    log(box, 'vostokbox-log-error', text);
  }

  function normalLog(box, text) {
    log(box, 'vostokbox-log-out', text);
  }

  function scriptEcho(box, src) {
    var echo;
    echo = log(box, 'vostokbox-log-script', src);
    echo.onclick = function() { requestRun(box, src); };
  }

  function load(box, text) {
    var res, i;
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
      addRunners(box, res.info.runners || []);
      addButtonRunners(box, res.info.buttons || []);
    } else {
      errorLog(box, res.error);
    }
  }

  function requestRun(box, scr) {
    var req, data, i, text, texts, uscr, add;

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

      req.timeout = 6000;
      req.ontimeout = function (e) { errorLog(box, 'connection timeout'); };
      req.onerror   = function (e) { errorLog(box, 'connection error'); };
      if (uscr == '/TO-SCHEME') {
        req.onload = function (e) { svgLog(box, 'vostokbox-log-out', req.responseText); };
      } else if (uscr.startsWith('/LOAD ')) {
        req.onload = function (e) { load(box, req.responseText); };
      } else {
        if (uscr == '/INFO') {
          add = '/CLEAR - clear the log';
        } else {
          add = '';
        }
        req.onload  = function (e) { normalLog(box, req.responseText + add); };
      }
      req.open('POST', '/run');
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
        data.append('runner-' + i, inp.value);
        i += 1;
      });

      data.append('buttons-count', box.buttons.size);
      i = 0;
      box.buttons.forEach(function(cmd) {
        data.append('button-' + i, cmd);
        i += 1;
      });

      box.storage['vostokbox-log'] = box.log.innerHTML;
      storeRunners(box);

      data.append('script', scr);
      req.send(data);
    }
  }

  function addButtonRunner(box, command) {
    var b;
    if (command != '') {
      b = box.doc.createElement('button');
      b.className = 'vostokbox-button-runner';
      b.innerHTML = '<div class="ctrl-up"><div class="ctrl">-</div></div>';
      b.append(command);
      b.onclick = function(pe) {
        if (pe.ctrlKey) {
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

  function runOrFix(box, cmd, keyEvent) {
    if (keyEvent.ctrlKey) {
      addButtonRunner(box, cmd);
    } else {
      requestRun(box, cmd);
    }
  }

  function addRunner(box, command, root) { assert(command != null);
    var div, inp, run, add, del;
    div = box.doc.createElement('div');
    inp = box.doc.createElement('input', 'type="text"');
    inp.className = 'vostokbox-command-line';
    inp.value = command;
    inp.onkeyup = function(ke) {
      if (ke.keyCode == 13) {
        runOrFix(box, inp.value, ke);
        inp.select();
      }
    };

    run = box.doc.createElement('button');
    run.innerHTML = '<div class="ctrl-up"><div class="no-ctrl">Run</div><div class="ctrl">Fix</div></div>';
    run.onclick = function(pe) { runOrFix(box, inp.value, pe); };

    add = box.doc.createElement('button');
    if (root) {
      add.innerHTML = '+';
    } else {
      add.className = 'ctrl-up';
      add.innerHTML = '<div class="no-ctrl">+</div><div class="ctrl">-</div>';
    }
    add.onclick = function(pe) {
      var val;
      if (pe.ctrlKey) {
        val = '';
      } else {
        val = inp.value;
      }
      if (root || !pe.ctrlKey) {
        addRunner(box, val, false);
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
      addRunner(box, commands[i], false);
    }
  }

  function addButtonRunners(box, commands) {
    var i;
    for (i = 0; i < commands.length; i += 1) {
      addButtonRunner(box, commands[i]);
    }
  }

  vb.addRootRunner = function(box, command) {
    addRunner(box, command, true);
  };

  vb.addRunner = function(box, command) {
    addRunner(box, command, false);
  };

  vb.addRunners       = addRunners;
  vb.addButtonRunner  = addButtonRunner;
  vb.addButtonRunners = addButtonRunners;

})(VostokBox || (VostokBox = {}));
