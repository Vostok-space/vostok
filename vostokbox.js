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

  function logAppendChild(box, item) {
    var needScroll;
    needScroll = box.log.scrollHeight - box.log.scrollTop < box.log.clientHeight + 40;
    box.log.appendChild(table);
    if (needScroll) {
      table.scrollIntoView({ behavior: 'smooth', block: 'nearest'});
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
    log(box, 'vostokbox-log-script', src);
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
    if (scr.toUpperCase() == "/TO-SCHEME") {
      req.onload = function (e) {
        svgLog(box, 'vostokbox-log-out', req.responseText);
      };
    } else {
      req.onload = function (e) {
        normalLog(box, req.responseText);
      };
    }
    req.open('POST', 'http://176.32.33.19/run');
    data = new FormData();
    data.append('module', box.editorSession.getValue());
    data.append('script', scr);
    req.send(data);
  }

  function addRunner(box, command, root) {
    var div, inp, run, add, del;
    div = box.doc.createElement('div');
    inp = box.doc.createElement('input', 'type="text"');
    inp.className = 'vostokbox-command-line';
    inp.value = command;
    run = box.doc.createElement('button');
    run.innerText = 'Run';
    run.onclick = function() {
      requestRun(box, inp.value);
    };
    add = box.doc.createElement('button');
    box.script = inp;
    add.innerText = 'Add';
    add.onclick = function() {
      addRunner(box, inp.value, false);
    };
    div.appendChild(inp);
    div.appendChild(run);
    div.appendChild(add);

    del = box.doc.createElement('button');
    if (root) {
      del.innerText = 'Cln';
      del.onclick = function() {
        box.log.innerHTML = '';
      };
    } else {
      del.innerText = 'Del';
      del.onclick = function() {
        box.runners.removeChild(div);
      };
    }
    div.appendChild(del);

    box.runners.appendChild(div);
  }

  vb.addRootRunner = function(box, command) {
    addRunner(box, command, true);
  };

  vb.addRunner = function(box, command) {
    addRunner(box, command, false);
  };

})(VostokBox || (VostokBox = {}));
