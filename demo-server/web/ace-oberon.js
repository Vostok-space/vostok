define("ace/mode/oberon_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

function OberonHighlightRules() {

this.$rules = {
start: [
{
	token: 'comment',
	regex: '\\(\\*',
	push: [
	{
		token: 'comment',
		regex: '\\*\\)',
		next: 'pop'
	},
	{
		defaultToken: 'comment'
	}
	]
},
{
	token: 'string',
	regex: '"',
	push: [
	{
		token: 'string',
		regex: '"',
		next: 'pop'
	},
	{
		defaultToken: 'string'
	}
	]
},
{
	token: 'string',
	regex: '[0-9]([0-9]|[A-F])*X'
}
]
};
this.normalizeRules();
}

oop.inherits(OberonHighlightRules, TextHighlightRules);

exports.OberonHighlightRules = OberonHighlightRules;
});

define("ace/mode/oberon",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/oberon_highlight_rules"], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var OberonHighlightRules = require("./oberon_highlight_rules").OberonHighlightRules;

function Mode() {
    this.HighlightRules = OberonHighlightRules;
    this.$behaviour = this.$defaultBehaviour;
}
oop.inherits(Mode, TextMode);

(function() {
    this.blockComment = [{start: "(*", end: "*)"}];
    this.$id = "ace/mode/oberon";
    this.snippetFileId = "ace/snippets/oberon";
}).call(Mode.prototype);

exports.Mode = Mode;
});

(function() {
    window.require(["ace/mode/oberon"], function(m) {
        if (typeof module == "object" && typeof exports == "object" && module) {
            module.exports = m;
        }
    });
})();


define("ace/snippets/oberon",["require","exports","module"], function(require, exports, module) {
"use strict";

exports.snippetText = "snippet M\n\
	MOD\n\
\n\
snippet MOD\n\
	MODULE\n\
\n\
snippet MODULE\n\
	Author: anonymous\n\
	License: LGPL-3.0\n\
\n\
	MODULE ${1};\n\
\n\
	IMPORT ${2:Out};\n\
\n\
	CONST\n\
\n\
	TYPE\n\
\n\
	VAR\n\
\n\
	${3}\n\
\n\
	BEGIN\n\
	END ${1}.\n\
\n\
snippet IM\n\
	IMPORT ${1};\n\
\n\
snippet T\n\
	TYPE\n\
		${1}\n\
\n\
snippet R\n\
	REAL\n\
\n\
snippet REAL\n\
	RECORD\n\
		${1}\n\
	END\n\
\n\
snippet REC\n\
	RECORD\n\
		${1}\n\
	END\n\
\n\
snippet PO\n\
	POINTER TO\n\
\n\
snippet POINTER TO\n\
	POINTER TO RECORD\n\
		${1}\n\
	END\n\
\n\
snippet I\n\
	INTEGER\n\
\n\
snippet B\n\
	BOOLEAN\n\
\n\
snippet C\n\
	CHAR\n\
\n\
snippet A\n\
	ARRAY ${1}OF ${2}\n\
\n\
snippet AC\n\
	ARRAY ${1}OF CHAR\n\
\n\
snippet P\n\
	PROCEDURE\n\
\n\
snippet PROCEDURE\n\
	PROCEDURE ${1}*(${2});\n\
	VAR\n\
	BEGIN\n\
	  ${3}\n\
	END ${1};\n\
\n\
snippet PR\n\
	PROCEDURE ${1}*(${2}): ${3};\n\
	VAR\n\
	BEGIN\n\
	  ${4}\n\
	RETURN\n\
	  ${5}\n\
	END ${1};\n\
\n\
snippet FN\n\
	PROCEDURE ${1}*(${2}): ${3};\n\
	RETURN\n\
	  ${4}\n\
	END ${1};\n\
\n\
snippet BE\n\
	BEGIN\n\
\n\
snippet RET\n\
	RETURN\n\
	  ${1}\n\
\n\
snippet PG\n\
	PROCEDURE Go*;\n\
	VAR\n\
	BEGIN\n\
	  ${1}\n\
	END Go;\n\
\n\
snippet W\n\
	WHILE ${1} DO\n\
	  ${2}\n\
	END;\n\
\n\
snippet REP\n\
	REPEAT\n\
	  ${1}\n\
	UNTIL ${2};\n\
\n\
snippet U\n\
	UNTIL ${1};\n\
\n\
snippet F\n\
	FOR ${1:i} := ${2} TO ${3} DO\n\
	  ${4}\n\
	END;\n\
\n\
snippet CA\n\
	CASE ${1} OF\n\
	  ${2}:\n\
		${3}\n\
	| ${4}:\n\
		${5}\n\
	END;\n\
\n\
snippet IF\n\
	IF ${1} THEN\n\
	  ${2}\n\
	END;\n\
\n\
snippet E\n\
	ELSE\n\
\n\
snippet V\n\
	VAR\n\
\n\
snippet ELSE\n\
	ELSIF ${1} THEN\n\
	  ${2}\n\
\n\
snippet AS\n\
	ASSERT(${1});\n\
\n\
snippet OS\n\
	Out.String(${1});\n\
\n\
snippet OI\n\
	Out.Int(${1}, 0);\n\
\n\
snippet OR\n\
	Out.Real(${1}, 0);\n\
\n\
snippet OC\n\
	Out.Char(${1});\n\
\n\
snippet OL\n\
	Out.Ln;\n\
\n\
snippet IS\n\
	In.String(${1});\n\
\n\
snippet II\n\
	In.Int(${1});\n\
\n\
snippet IR\n\
	In.Real(${1});\n\
\n\
snippet IC\n\
	In.Char(${1});\n\
\n\
snippet ID\n\
	In.Done\n\
\n\
snippet IO\n\
	In.Open;\n\
	IF In.Done THEN\n\
		${1}\n\
	END;\n\
";
exports.scope = "oberon";

});

(function() {
	window.require(["ace/snippets/oberon"], function(m) {
		if (typeof module == "object" && typeof exports == "object" && module) {
			module.exports = m;
		}
	});
})();
