var VostokBox;
(function(vb) {
  'use strict';

  function assert(cond) { if (!cond) { throw "incorrectness"; } }

  function selectTab(box, ind) { assert(0 <= ind && ind < box.editors.length);
    var i;
    for (i = box.editors.length - 1; i >= 0; i -= 1) {
      box.editors[i].div.style.display  = "none";
      box.editors[i].tab.className      = "";
    }
    box.selected = ind;
    box.editors[ind].div.style.display  = "block";
    box.editors[ind].tab.className      = "active";
  }
  vb.selectTab = selectTab;

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
    b = box.doc.createElement("button");
    b.innerText = name;
    ed = box.editors[ind];
    b.onclick = function() {
      if (box.selected != ed.index) {
        selectTab(box, ed.index);
      } else if (ed.ace.getSession().getValue() == "") {
        removeTab(box, ed.index);
      }
    };
    ed.tab = b;
    return b;
  }

  function createAceEditor(ace, div, index) {
    var editor;
    editor = {
      div   : div,
      ace   : ace.edit(div),
      index : index
    };
    editor.ace.setDisplayIndentGuides(true);
    editor.ace.setTheme('ace/theme/idle_fingers');
    editor.ace.getSession().setOptions({
      tabSize: 2,
      useSoftTabs: true,
      navigateWithinSoftTabs: true
    });
    return editor;
  }

  function tabAdder(box) {
    var b;
    b = box.doc.createElement("button");
    b.innerText = "[ + ]";
    b.onclick = function() {
      var d, lc, ind, p;
      p = b.parentNode;
      lc = p.lastChild;
      lc.remove();
      d = box.doc.createElement("div");
      d.className = "vostokbox-editor";
      ind = box.editors.length;
      box.editors[ind] = createAceEditor(box.ace, d, ind);
      box.editorsContainer.appendChild(d);
      p.appendChild(tabCreate(box, getTabName("", ind), ind));
      if (ind < 31) {
        p.appendChild(lc);
      }
      selectTab(box, ind);
    };
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
    return " \t\r\n".indexOf(ch) >= 0;
  }

  function getTabName(text, ind) {
    var n, t, i, l;

    n = null;

    t = text;
    i = -1;
    do {
      i = t.indexOf("MODULE", i + 1);
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
      n = "[  " + ind + "  ]";
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

  vb.createByDefaultIdentifiers = function(doc, ace) {
    var box, editor, editors, i, tabs, text;

    tabs = doc.getElementById("vostokbox-tabs");
    box = {
      ace     : ace,
      doc     : doc,
      runners : doc.getElementById('vostokbox-runners'),
      buttons : doc.getElementById('vostokbox-button-runners'),
      log     : doc.getElementById('vostokbox-log'),
      editors : [],
      selected: 0,
      editorsContainer: null,
      tabAdder: null,
      ctrl    : false
    };

    editors = doc.getElementsByClassName("vostokbox-editor");
    if (editors.length > 0) {
      for (i = 0; i < editors.length; i += 1) {
        text = editors[i].innerText;
        box.editors[i] = createAceEditor(ace, editors[i], i);
        tabs.appendChild(tabCreate(box, getTabName(text, i), i));
      }
      box.editorsContainer = editors[i - 1].parentNode;
    }
    box.tabAdder = tabAdder(box);
    tabs.appendChild(box.tabAdder);
    selectTab(box, 0);

    doc.onkeydown = function(ke) { switchCtrl(box, ke, "ctrl-up", "ctrl-down"); };
    doc.onkeyup   = function(ke) { switchCtrl(box, ke, "ctrl-down", "ctrl-up"); };

    return box;
  };

  function logAppendChild(box, item) {
    var log, needScroll, end;
    log = box.log;
    needScroll = log.scrollHeight - log.scrollTop < log.clientHeight + 320;
    log.appendChild(item);

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

  function requestRun(box, scr) {
    var req, data, i, text, uscr, add;

    scriptEcho(box, scr);

    uscr = scr.toUpperCase();
    if (uscr == "/CLEAR" || uscr == "/CLS") {
      box.log.innerHTML = "";
    } else {
      req = new XMLHttpRequest();

      req.timeout = 6000;
      req.ontimeout = function (e) { errorLog(box, 'connection timeout'); };
      req.onerror   = function (e) { errorLog(box, 'connection error'); };
      if (uscr == "/TO-SCHEME" || uscr == ":TO-SCHEME") {
        req.onload  = function (e) { svgLog(box, 'vostokbox-log-out', req.responseText); };
      } else {
        if (uscr == "/INFO" || uscr == ":INFO") {
          add = "/CLEAR - clear the log";
        } else {
          add = "";
        }
        req.onload  = function (e) { normalLog(box, req.responseText + add); };
      }
      req.open('POST', '/run');
      data = new FormData();
      i = box.editors.length;
      console.log(box.selected, i);
      data.append("texts-count", [box.selected, ":", i].join(""));
      while (i > 0) {
        i -= 1;
        text = box.editors[i].ace.getSession().getValue();
        data.append('text-' + i, text);
        box.editors[i].tab.innerText = getTabName(text, i);
      }
      data.append('script', scr);
      req.send(data);
    }
  }

  function addButtonRunner(box, command) {
    var b;
    if (command != "") {
      b = box.doc.createElement("button");
      b.className = "vostokbox-button-runner";
      b.innerHTML = "<div class='ctrl-up'><div class='ctrl'>-</div></div>";
      b.append(command);
      b.onclick = function(pe) {
        if (pe.ctrlKey) {
          b.remove();
        } else {
          requestRun(box, command);
        }
      }
      box.buttons.appendChild(b);
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
        requestRun(box, inp.value);
        inp.select();
      }
    };

    run = box.doc.createElement('button');
    run.innerHTML = "<div class='ctrl-up'><div class='no-ctrl'>Run</div><div class='ctrl'>Fix</div></div>";
    run.onclick = function(pe) {
      if (pe.ctrlKey) {
        addButtonRunner(box, inp.value);
      } else {
        requestRun(box, inp.value);
      }
    };

    add = box.doc.createElement('button');
    if (root) {
      add.innerHTML = "+";
    } else {
      add.className = "ctrl-up";
      add.innerHTML = "<div class='no-ctrl'>+</div><div class='ctrl'>-</div>";
    }
    add.onclick = function(pe) {
      var val;
      if (pe.ctrlKey) {
        val = "";
      } else {
        val = inp.value;
      }
      if (root || !pe.ctrlKey) {
        addRunner(box, val, false);
      } else {
        div.remove();
      }
    };
    div.appendChild(inp);
    div.appendChild(run);
    div.appendChild(add);

    box.runners.appendChild(div);
  }

  vb.addRootRunner = function(box, command) {
    addRunner(box, command, true);
  };

  vb.addRunner = function(box, command) {
    addRunner(box, command, false);
  };

  vb.addRunners = function(box, commands) {
    var i;
    for (i = 0; i < commands.length; i += 1) {
      addRunner(box, commands[i], false);
    }
  };

  vb.addButtonRunner = addButtonRunner;

  vb.addButtonRunners = function(box, commands) {
    var i;
    for (i = 0; i < commands.length; i += 1) {
      addButtonRunner(box, commands[i]);
    }
  }

})(VostokBox || (VostokBox = {}));
