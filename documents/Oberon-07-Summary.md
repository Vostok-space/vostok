## Oberon‑07 Summary (Revision 2013/2016)

[Full language report](https://vostok-space.github.io/Oberon-report/)

### 0. Operators and delimiters including reserved words (keywords)

```
+  :=  ARRAY  IMPORT  THEN
-  ^   BEGIN  IN      TO
*  =   BY     IS      TRUE
/  #   CASE   MOD     TYPE
~  <   CONST  MODULE  UNTIL
&  >   DIV    NIL     VAR
.  <=  DO     OF      WHILE
,  >=  ELSE   OR
;  ..  ELSIF  POINTER
|  :   END    PROCEDURE
(  )   FALSE  RECORD
[  ]   FOR    REPEAT
{  }   IF     RETURN
```

### 1. EBNF syntax of Oberon‑07

```ebnf
(* some lexemes *)
letter      = "A" | "B" | … | "Z" | "a" | "b" | … | "z".
digit       = "0" | "1" | … | "9".
hexDigit    = digit | "A" | "B" | "C" | "D" | "E" | "F".

ident       = letter { letter | digit } .
ExportMark  = "*" .

integer     = digit { digit } | digit { hexDigit } "H" .
real        = digit { digit } "." { digit } [ ScaleFactor ] .
ScaleFactor = "E" [ "+" | "-" ] digit { digit } .
number      = integer | real .
string      = """ { character } """ | digit { hexDigit } "X" .

and         = "&" .
not         = "~" .
```

```ebnf
qualident          = [ ModuleIdent "." ] ident .
ModuleIdent        = ident .

identdef           = ident [ ExportMark ] .

(* declarations *)
ConstDeclaration   = identdef "=" ConstExpression .
ConstExpression    = expression .

VariableDeclaration= IdentList ":" type .

TypeDeclaration    = identdef "=" type .

(* types *)
type               = qualident
                   | ArrayType | RecordType
                   | PointerType | ProcedureType .

ArrayType          = ARRAY length { "," length } OF type .
length             = ConstExpression .

RecordType         = RECORD [ "(" BaseType ")" ]
                     [ FieldListSequence ] END .
BaseType           = qualident .
FieldListSequence  = FieldList { ";" FieldList } .
FieldList          = IdentList ":" type .
IdentList          = identdef { "," identdef } .

PointerType        = POINTER TO type .
ProcedureType      = PROCEDURE [ FormalParameters ] .

(* expressions *)
expression         = SimpleExpression
                     [ relation SimpleExpression ] .
relation           = "=" | "#" | "<" | "<=" | ">" | ">=" | IN  | IS .

SimpleExpression   = [ "+" | "-" ] term { AddOperator term } .
AddOperator        = "+" | "-" | OR .

term               = factor { MulOperator factor } .
MulOperator        = "*" | "/" | DIV | MOD | and .

factor             = number | string | NIL | TRUE | FALSE | set
                   | FunctionCall | "(" expression ")" | not factor .
FunctionCall       = designator [ ActualParameters ] .

designator         = qualident { selector } .
selector           = FieldSel
                   | ArraySel
                   | dereference
                   | TypeGuard.
FieldSel           = "." ident .
ArraySel           = "[" ExpList "]" .
dereference        = "^" .
TypeGuard          = "(" qualident ")" .

set                = "{" [ element { "," element } ] "}" .
element            = expression [ ".." expression ] .
ExpList            = expression { "," expression } .
ActualParameters   = "(" [ ExpList ] ")" .

(* statements *)
statement          = [ assignment | ProcedureCall
                     | IfStatement | CaseStatement
                     | WhileStatement | RepeatStatement | ForStatement ] .

assignment         = designator ":=" expression .
ProcedureCall      = designator [ ActualParameters ] .
StatementSequence  = statement { ";" statement } .

IfStatement        = IF expression THEN StatementSequence
                     { ELSIF expression THEN StatementSequence }
                     [ ELSE StatementSequence ] END .

CaseStatement      = CASE expression OF case { "|" case } END .
case               = [ CaseLabelList ":" StatementSequence ] .
CaseLabelList      = LabelRange { "," LabelRange } .
LabelRange         = label [ ".." label ] .
label              = integer | string | qualident .

WhileStatement     = WHILE expression DO StatementSequence
                     { ELSIF expression DO StatementSequence } END .

RepeatStatement    = REPEAT StatementSequence UNTIL expression .

ForStatement       = FOR ident ":=" expression TO expression
                     [ BY ConstExpression ] DO StatementSequence END .

(* procedures *)
ProcedureDeclaration = ProcedureHeading ";" ProcedureBody ident .
ProcedureHeading     = PROCEDURE identdef [ FormalParameters ] .
ProcedureBody        = DeclarationSequence
                       [ BEGIN StatementSequence ]
                       [ RETURN expression ] END .

DeclarationSequence  = [ CONST { ConstDeclaration ";" } ]
                       [ TYPE  { TypeDeclaration ";" } ]
                       [ VAR   { VariableDeclaration ";" } ]
                       { ProcedureDeclaration ";" } .

FormalParameters     = "(" [ FPSection { ";" FPSection } ] ")"
                       [ ":" qualident ] .
FPSection            = [ VAR ] ident { "," ident } ":" FormalType .
FormalType           = { ARRAY OF } qualident .

(* modules *)
module              = MODULE ident ";"
                      [ ImportList ] DeclarationSequence
                      [ BEGIN StatementSequence ]
                      END ident "." .

ImportList          = IMPORT import { "," import } ";" .
import              = ident [ ":=" ident ] .
```

### 2. Pre‑declared procedures and functions

| Category        | Signature    | Effect                                      | Result type |
|-----------------|--------------|---------------------------------------------|-------------|
| **Numeric/bit** | `ABS(x)`     | absolute value                              | same as `x` |
|                 | `ODD(x)`     | `x MOD 2 = 1`                               | `BOOLEAN`   |
|                 | `LEN(v)`     | length of array `v`                         | `INTEGER`   |
|                 | `LSL(x,n)`   | logical shift left (`x*2^n`)                | `INTEGER`   |
|                 | `ASR(x,n)`   | arithmetic shift right (`x DIV 2^n`)        | `INTEGER`   |
|                 | `ROR(x,n)`   | rotate right by `n` bits                    | `INTEGER`   |
| **Conversions** | `FLOOR(x)`   | round toward −∞                             | `INTEGER`   |
|                 | `FLT(x)`     | identity (`INTEGER → REAL`)                 | `REAL`      |
|                 | `ORD(x)`     | ordinal number of `x`                       | `INTEGER`   |
|                 | `CHR(x)`     | character with code `x`                     | `CHAR`      |
| **Proper**      | `INC(v[,n])` | `v := v + n` (default `n = 1`)              |             |
| **procedures**  | `DEC(v[,n])` | `v := v − n` (default `n = 1`)              |             |
|                 | `INCL(s,i)`  | `s := s + {i}`                              |             |
|                 | `EXCL(s,i)`  | `s := s − {i}`                              |             |
|                 | `NEW(p)`     | allocate record instance that `p` points to |             |
|                 | `ASSERT(b)`  | abort program if `b = FALSE`                |             |
|                 | `PACK(x,n)`  | pack mantissa / exponent                    |             |
|                 | `UNPK(x,n)`  | unpack mantissa / exponent                  |             |
