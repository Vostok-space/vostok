function switchLang(lang) {
  const Languages = ["en", "ru"];

  function setDisplay(lang, value) {
    var els, i;
    els = document.querySelectorAll('[lang="' + lang + '"]');
    for (i = 0; i < els.length; i += 1) {
      els[i].style.display = value;
    }
  }

  var i;
  for (i = 0; i < Languages.length; i += 1) {
    setDisplay(Languages[i], "none");
  }
  if (Languages.indexOf(lang) == -1) {
    lang = Languages[0];
  }
  setDisplay(lang, "");
}

function switchLangToPreferable() {
  switchLang(window.navigator.language.slice(0, 2));
}
