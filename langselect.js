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
  var url, lang;
  url = new URL(window.location);
  if (url.searchParams) {
    lang = url.searchParams.get("lang");
  } else {
    lang = null;
  }
  if (lang == null) {
    lang = window.navigator.language.slice(0, 2);
  }
  switchLang(lang);
}
