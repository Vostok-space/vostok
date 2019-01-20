var VostokBox;
(function(vb) {
  'use strict';

  vb.createByDefaultIdentifiers = function(doc, ace) {
    var box, editor;
    box = { doc: doc };
    editor = ace.edit('vostokbox-editor');
    editor.setDisplayIndentGuides(true);
    box.editorSession = editor.getSession();
    box.editorSession.setOptions({
      tabSize: 2,
      useSoftTabs: true,
      navigateWithinSoftTabs: true}
    );
    box.script = doc.getElementById('vostokbox-script');
    box.runners = doc.getElementById('vostokbox-runners');
    box.log = doc.getElementById('vostokbox-log');
    return box;
  };

  function errorLog(box, text) {
    var div;
    div = box.doc.createElement('div');
    div.innerText = text;
    div.className = 'vostokbox-log-error';
    box.log.appendChild(div);
    div.scrollIntoView();
  }

  function normalLog(box, text) {
    var pre;
    pre = box.doc.createElement('pre');
    pre.innerText = text;
    pre.className = 'vostokbox-log-out';
    box.log.appendChild(pre);
    pre.scrollIntoView();
  }

  function scriptEcho(box, src) {
    var pre, table;
    pre = box.doc.createElement('pre');
    pre.innerText = src;
    pre.className = 'vostokbox-log-script';
    table = box.doc.createElement('table');
    table.appendChild(pre);
    box.log.appendChild(table);
  }

  function requestRun(box, scr) {
    var req, data;

    scriptEcho(box, scr);

    req = new XMLHttpRequest();

    req.timeout = 6000;
    req.ontimeout = function (e) {
      errorLog(box, 'connection timeout');
    };
    req.onerror = function (e) {
      errorLog(box, 'connection error');
    };
    req.onload = function (e) {
      normalLog(box, req.responseText);
    };
    req.open('POST', '/run');
    data = new FormData();
    data.append('module', box.editorSession.getValue());
    data.append('script', scr);
    req.send(data);
  }

  function addRunner(box, command, root) {
    var div, inp, run, addel;
    div = box.doc.createElement('div');
    inp = box.doc.createElement('input', 'type="text"');
    inp.className = 'vostokbox-command-line';
    inp.value = command;
    run = box.doc.createElement('button');
    run.innerText = 'Run';
    run.onclick = function() {
      requestRun(box, inp.value);
    };
    addel = box.doc.createElement('button');
    if (root) {
      box.script = inp;
      addel.innerText = 'Add';
      addel.onclick = function() {
        addRunner(box, inp.value, false);
      };
    } else {
      addel.innerText = 'Del';
      addel.onclick = function() {
        box.runners.removeChild(div);
      };
    }

    div.appendChild(inp);
    div.appendChild(run);
    div.appendChild(addel);

    box.runners.appendChild(div);
  }

  vb.addRootRunner = function(box, command) {
    addRunner(box, command, true);
  };

  vb.addRunner = function(box, command) {
    addRunner(box, command, false);
  };

})(VostokBox || (VostokBox = {}));
