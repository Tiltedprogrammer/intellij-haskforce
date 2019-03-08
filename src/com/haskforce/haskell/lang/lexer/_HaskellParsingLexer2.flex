package com.haskforce.haskell.lang.lexer;

// Mostly copy pasta from src/com/haskforce/parsing/_HaskellParsingLexer.flex
// Adapted to use different token types from the ones generated by grammar-kit.

import com.intellij.lexer.*;
import com.intellij.psi.tree.IElementType;
import static com.haskforce.haskell.lang.lexer.psi.Tokens.*;
import com.intellij.util.containers.ContainerUtil;
import com.intellij.openapi.util.Pair;
import java.util.*;
import com.intellij.util.containers.Stack;

/**
 * Hand-written lexer used for parsing in IntelliJ.
 *
 * We share token names with the grammar-kit generated
 * parser.
 *
 * Massively changed, but originally derived from the lexer generated by
 * Grammar-Kit at 29 April 2014.
 */


/*
 * To generate sources from this file -
 *   Click Tools->Run JFlex generator.
 *
 * Command-Shift-G should be the keyboard shortcut, but that is the same
 * shortcut as find previous.
 */


%%

%{
  private static final Pair<Integer, Integer> NO_LAYOUT = Pair.create(-1, -1);
  private int commentLevel;
  private int qqLevel;
  private int indent;
  private boolean retry;
  private int emptyblockPhase;
  private Stack<Pair<Integer,Integer>> indentationStack;
  private Stack<Integer> stateStack;
  public LinkedList<Pair<Pair<Integer,Integer>,Integer>> openBraces;
  // Shared varsym token to ensure that shebang lex failures return the same
  // token as normal varsyms.
  public static final IElementType SHARED_VARSYM_TOKEN = VARSYMTOKPLUS;
  // %line/%column/%char does not declare these.
  private int yyline;
  private int yycolumn;
  private int yychar;

  public _HaskellParsingLexer2() {
    this((java.io.Reader)null);
    commentLevel = 0;
    qqLevel = 0;
    retry = false;
    emptyblockPhase = 0;
    openBraces = ContainerUtil.newLinkedList();
    openBraces.push(Pair.create(Pair.create(-1,-1), 0));
    indentationStack = ContainerUtil.newStack();
    stateStack = ContainerUtil.newStack();
  }
%}

/*
 * Missing lexemes: by, haddock things.
 *
 * Comments: one line too many in dashes-comments.
 */

%public
%class _HaskellParsingLexer2
%implements FlexLexer
%function advance
%type IElementType
%unicode
%char
%line
%column

EOL=\r|\n|\r\n
LINE_WS=[\ \t\f]
WHITE_SPACE=({LINE_WS}|{EOL})+
VARIDREGEXP=([a-z_][a-zA-Z_0-9']+)|[a-z]
CONID=([A-Z][a-zA-Z_0-9']*)|(\(\))
CHARTOKEN='(\\.|[^'])'#?
INTEGERTOKEN=(0(o|O)[0-7]+|0(x|X)[0-9a-fA-F]+|[0-9]+)#?#?
FLOATTOKEN=([0-9]+\.[0-9]+((e|E)(\+|\-)?[0-9]+)?|[0-9]+((e|E)(\+|\-)?[0-9]+))#?#?
COMMENT=--([^\!\#\$\%\&\*\+\.\/\<\=\>\?\@\\\^\|\~\:\r\n][^\r\n]*\n?|[\r\n])
HADDOCK=--\ [\^\|]([^\r\n]*\n?|[\r\n])
CPPIF=#if[^\r\n]*
CPPIFDEF=#ifdef[^\r\n]*
CPPELIF=#elif[^\r\n]*
CPPELSE=#else[^\r\n]*
CPPENDIF=#endif[^\r\n]*
CPPDEFINE=#define[^\r\n]*
CPPUNDEF=#undef[^\r\n]*
CPPINCLUDE=#include[^\r\n]*
CPPLINE=#line[^\r\n]*
CPPPRAGMA=#pragma[^\r\n]*
// Unicode syntax also supported: https://www.haskell.org/ghc/docs/7.2.1/html/users_guide/syntax-extns.html
ASCSYMBOL=[\!\#\$\%\&\*\+\.\/\<\=\>\?\@\\\^\|\-\~\:↢↣⤛⤜★]
MAYBEQVARID=({CONID}\.)*{VARIDREGEXP}

STRINGGAP=\\[ \t\n\x0B\f\r]*\n[ \t\n\x0B\f\r]*\\

// Avoid "COMMENT" since that collides with the token definition above.
%state REALLYYINITIAL, INCOMMENT, INSTRING, INPRAGMA, ININDENTATION, FINDINGINDENTATIONCONTEXT, INQUASIQUOTE
%state INQUASIQUOTEHEAD, INSHEBANG, INIMPORT

%%

<<EOF>>             {
                        if (indentationStack.size() > 0) {
                            Pair<Integer, Integer> p = indentationStack.pop();
                            if (!NO_LAYOUT.equals(p)) {
                                int lastNum = openBraces.peek().getSecond();
                                openBraces.push(Pair.create(Pair.create(yyline,yycolumn), --lastNum));
                            }
                            return NO_LAYOUT.equals(p) ? RBRACE : WHITESPACERBRACETOK;
                        }
                        openBraces.removeLast();
                        return null;
                    }

<YYINITIAL,ININDENTATION,FINDINGINDENTATIONCONTEXT> {
    {HADDOCK}       { indent = 0; return HADDOCK; }
    {COMMENT}       { indent = 0; return COMMENT; }
    {CPPIFDEF}      { indent = 0; return CPPIFDEF; }
    {CPPIF}         { indent = 0; return CPPIF; }
    {CPPELIF}       { indent = 0; return CPPELIF; }
    {CPPELSE}       { indent = 0; return CPPELSE; }
    {CPPENDIF}      { indent = 0; return CPPENDIF; }
    {CPPDEFINE}     { indent = 0; return CPPDEFINE; }
    {CPPUNDEF}      { indent = 0; return CPPUNDEF; }
    {CPPINCLUDE}    { indent = 0; return CPPINCLUDE; }
    {CPPLINE}       { indent = 0; return CPPLINE; }
    {CPPPRAGMA}     { indent = 0; return CPPPRAGMA; }
}

<YYINITIAL> {
    "#!"            {
                      if (yychar == 0) {
                          yybegin(INSHEBANG);
                          return SHEBANGSTART;
                      }
                      return SHARED_VARSYM_TOKEN;
                    }
    {EOL}+          {
                        indent = 0;
                        return com.intellij.psi.TokenType.WHITE_SPACE;
                    }
    [\ \f]          {
                        indent++;
                        return com.intellij.psi.TokenType.WHITE_SPACE;
                    }
    [\t]            {
                        indent = indent + (indent + 8) % 8;
                        return com.intellij.psi.TokenType.WHITE_SPACE;
                    }
    "{-#"           {
                        stateStack.push(YYINITIAL);
                        yybegin(INPRAGMA);
                        return OPENPRAGMA;
                    }
    "{-"            {
                        commentLevel++;
                        stateStack.push(YYINITIAL);
                        yybegin(INCOMMENT);
                        return OPENCOM;
                    }
    ("{"[^\-])      {
                        yybegin(REALLYYINITIAL);
                        yypushback(2);
                    }
    "module"        {
                        yybegin(REALLYYINITIAL);
                        yypushback(6);
                    }
    [^]             {
                        indentationStack.push(Pair.create(yyline, yycolumn));
                        yybegin(REALLYYINITIAL);
                        yypushback(1);
                        int lastNum = openBraces.peek().getSecond();
                        openBraces.push(Pair.create(Pair.create(yyline,yycolumn), ++lastNum));
                        return WHITESPACELBRACETOK;
                    }

}

<REALLYYINITIAL> {
  {EOL}               {
                        yybegin(ININDENTATION);
                        indent = 0;
                        return com.intellij.psi.TokenType.WHITE_SPACE;
                      }
  [\ \f]              {
                          indent++;
                          return com.intellij.psi.TokenType.WHITE_SPACE;
                      }
  [\t]                {
                          indent = indent + (indent + 8) % 8;
                          return com.intellij.psi.TokenType.WHITE_SPACE;
                      }
  {HADDOCK}           { indent = 0; yybegin(ININDENTATION); return HADDOCK; }
  {COMMENT}           { indent = 0; yybegin(ININDENTATION); return COMMENT; }
  {CPPIF}             { indent = 0; yybegin(ININDENTATION); return CPPIF; }
  {CPPELIF}           { indent = 0; yybegin(ININDENTATION); return CPPELIF; }
  {CPPELSE}           { indent = 0; yybegin(ININDENTATION); return CPPELSE; }
  {CPPENDIF}          { indent = 0; yybegin(ININDENTATION); return CPPENDIF; }
  "class"             { return CLASSTOKEN; }
  "data"              { return DATA; }
  "default"           { return DEFAULT; }
  "deriving"          { return DERIVING; }
  "export"            { return EXPORTTOKEN; }
  "foreign"           { return FOREIGN; }
  "instance"          { return INSTANCE; }
  "family"            { return FAMILYTOKEN; }
  "module"            { return MODULETOKEN; }
  "newtype"           { return NEWTYPE; }
  "type"              { return TYPE; }
  "where"               {
                            yybegin(FINDINGINDENTATIONCONTEXT);
                            indent = yycolumn;
                            return WHERE;
                        }
  "as"                { return AS; }
  "import"            { return IMPORT; }
  "infix"             { return INFIX; }
  "infixl"            { return INFIXL; }
  "infixr"            { return INFIXR; }
  "qualified"         { return QUALIFIED; }
  "hiding"            { return HIDING; }
  "\\" {LINE_WS}* "case" {
                          yybegin(FINDINGINDENTATIONCONTEXT);
                          indent = yycolumn;
                          return LCASETOK;
                         }
  "case"              { return CASE; }
  "mdo"                 {
                            yybegin(FINDINGINDENTATIONCONTEXT);
                            indent = yycolumn;
                            return MDOTOK;
                        }
  "do"                  {
                            yybegin(FINDINGINDENTATIONCONTEXT);
                            indent = yycolumn;
                            return DO;
                        }
  "rec"                 {
                            yybegin(FINDINGINDENTATIONCONTEXT);
                            indent = yycolumn;
                            return RECTOK;
                        }
  "else"              { return ELSE; }
  "if"                { return IF; }
  "in"                {
                            if (retry) {
                                retry = false;
                            } else if (!indentationStack.isEmpty() &&
                                        yyline ==
                                           indentationStack.peek().getFirst()) {
                                indentationStack.pop();
                                yypushback(2);
                                retry = true;
                                int lastNum = openBraces.peek().getSecond();
                                openBraces.push(Pair.create(Pair.create(yyline,yycolumn), --lastNum));
                                return WHITESPACERBRACETOK;
                            }
                            return IN;
                        }
  "let"                 {
                            yybegin(FINDINGINDENTATIONCONTEXT);
                            indent = yycolumn;
                            return LET;
                        }
  "of"                  {
                            yybegin(FINDINGINDENTATIONCONTEXT);
                            indent = yycolumn;
                            return OF;
                        }
  "then"              { return THEN; }
  ("forall"|"∀")      { return FORALLTOKEN; }

  ("<-"|"←")          { return LEFTARROW; }
  ("->"|"→")          { return RIGHTARROW; }
  ("=>"|"⇒")          { return DOUBLEARROW; }
  "\\&"               { return NULLCHARACTER; }
  "(#"                { return LUNBOXPAREN; }
  "#)"                { return RUNBOXPAREN; }
  "("                 { return LPAREN; }
  ")"                 { return RPAREN; }
  "|]"                { return RTHCLOSE; }
  "|"                 { return PIPE; }
  ","                 { return COMMA; }
  ";"                 { return SEMICOLON; }
  "[|"                { return LTHOPEN; }
  ("["{MAYBEQVARID}"|") {
                            yypushback(yytext().length() - 1);
                            qqLevel++;
                            stateStack.push(REALLYYINITIAL);
                            yybegin(INQUASIQUOTEHEAD);
                            return QQOPEN;
                        }
  "["                 { return LBRACKET; }
  "]"                 { return RBRACKET; }
  "''"                { return THQUOTE; }
  "`"                 { return BACKTICK; }
  "\""                {
                        yybegin(INSTRING);
                        return DOUBLEQUOTE;
                      }
  "{-#"               {
                        stateStack.push(REALLYYINITIAL);
                        yybegin(INPRAGMA);
                        return OPENPRAGMA;
                      }
  "{-"                {
                        commentLevel++;
                        stateStack.push(REALLYYINITIAL);
                        yybegin(INCOMMENT);
                        return OPENCOM;
                      }
  "{"               {
                        indentationStack.push(NO_LAYOUT);
                        return LBRACE;
                    }
  "}"               {
                        if (indentationStack.size() > 0) {
                            Pair<Integer, Integer> p = indentationStack.peek();
                            if (NO_LAYOUT.equals(p)) {
                                indentationStack.pop();
                            }
                        }
                        return RBRACE;
                    }
  "'"                 { return SINGLEQUOTE; }
  "!"                 { return EXCLAMATION; }
  "##"                { return DOUBLEHASH; }
  "#"                 { return HASH; }
  "$("                { return PARENSPLICE; }
  ("$"{VARIDREGEXP})  { return IDSPLICE; }
  "$"                 { return DOLLAR; }
  "%"                 { return PERCENT; }
  "&"                 { return AMPERSAND; }
  "*"                 { return ASTERISK; }
  "+"                 { return PLUS; }
  ".."                { return DOUBLEPERIOD; }
  "."                 { return PERIOD; }
  "/"                 { return SLASH; }
  "<"                 { return LESSTHAN; }
  "="                 { return EQUALS; }
  ">"                 { return GREATERTHAN; }
  "?"                 { return QUESTION; }
  "@"                 { return AMPERSAT; }
  "\\"                { return BACKSLASH; }
  "^"                 { return CARET; }
  "-"                 { return MINUS; }
  "~"                 { return TILDE; }
  "_"                 { return UNDERSCORE; }
  ("::"|"∷")          { return DOUBLECOLON; }
  ":"                 { return COLON; }
  (":"{ASCSYMBOL}+)     { return CONSYMTOK; }
  ({ASCSYMBOL}+)      { return SHARED_VARSYM_TOKEN; }

  {VARIDREGEXP}       { return VARIDREGEXP; }
  {CONID}             { return CONIDREGEXP; }
  {CHARTOKEN}         { return CHARTOKEN; }
  {INTEGERTOKEN}      { return INTEGERTOKEN; }
  {FLOATTOKEN}        { return FLOATTOKEN; }
  [^] { return com.intellij.psi.TokenType.BAD_CHARACTER; }
}

<INSHEBANG> {
  [^\n\r]+  { yybegin(YYINITIAL); return SHEBANGPATH; }
  [\n\r]    { yybegin(YYINITIAL); return com.intellij.psi.TokenType.WHITE_SPACE; }
}

<INCOMMENT> {
    "-}"              {
                        commentLevel--;
                        if (commentLevel == 0) {
                            yybegin(stateStack.pop());
                            return CLOSECOM;
                        }
                        return COMMENTTEXT;
                      }

    "{-"              {
                        commentLevel++;
                        return COMMENTTEXT;
                      }

    [^-{}]+           { return COMMENTTEXT; }
    [^]               { return COMMENTTEXT; }
}

<INSTRING> {
    \"                              {
                                        yybegin(REALLYYINITIAL);
                                        return DOUBLEQUOTE;
                                    }
    \\(\\|{EOL}|[a-z0-9])           { return STRINGTOKEN; }
    ({STRINGGAP}|\\\"|[^\"\\\n])+   { return STRINGTOKEN; }

    [^]                             { return BADSTRINGTOKEN; }
}

<INPRAGMA> {
    "#-}"           {
                        yybegin(stateStack.pop());
                        return CLOSEPRAGMA;
                    }
    [^ \n\r\t\f#]+  { return PRAGMA; }
    {WHITE_SPACE}   { return com.intellij.psi.TokenType.WHITE_SPACE; }
    [^]             { return PRAGMA; }
}

<ININDENTATION> {
    // We need to look ahead for an operator before lexing the indent.
    // If an operator is indeed next but we haven't actually indented or dedented
    // (i.e. equal indent) then we should exit this state.
    // The difference is that we shouldn't do this for something that
    // looks like a TemplateHaskell splice $(
    // While this is somewhat ambiguous because we don't know really know if the user
    // has enabled TemplateHaskell, we'll just guess in this case that they are.
    // See https://github.com/carymrobbins/intellij-haskforce/issues/333
    [\ \f]("$("|{ASCSYMBOL})?
                    {
                        indent++;
                        // We looked ahead and found a splice or operator.
                        if (yylength() > 1) {
                            CharSequence lookahead = yytext().subSequence(1, yytext().length());
                            // Only consume the first space char, we just needed to look ahead.
                            yypushback(yylength() - 1);
                            boolean equalIndent = !indentationStack.isEmpty() && indent == indentationStack.peek().getSecond();
                            // If the next token is an operator, is not a splice, and we haven't
                            // changed indentation level, don't process this as an indent/dedent.
                            if (!lookahead.toString().equals("$(") && equalIndent) yybegin(REALLYYINITIAL);
                        }
                        return com.intellij.psi.TokenType.WHITE_SPACE;
                    }
    [\t]            {
                        indent = indent + (indent + 8) % 8;
                        return com.intellij.psi.TokenType.WHITE_SPACE;
                    }
    [\n]            {
                        indent = 0;
                        return com.intellij.psi.TokenType.WHITE_SPACE;
                    }
    "{-#"           {
                        stateStack.push(ININDENTATION);
                        yybegin(INPRAGMA);
                        return OPENPRAGMA;
                    }
    "{-"            {
                        commentLevel++;
                        stateStack.push(ININDENTATION);
                        yybegin(INCOMMENT);
                        return OPENCOM;
                    }
   "--"[^\r\n]*     {   // DO NOT REMOVE.
                        // Workaround for {COMMENT} not affecting this rule.
                        // See Comment00004.hs for test case.
                        indent = 0;
                        return COMMENT;
                    }

    ("where"|[^])   {
                        boolean isWhere = yytext().toString().equals("where");
                        boolean equalIndent = !indentationStack.isEmpty() && indent == indentationStack.peek().getSecond();
                        boolean isDedent = !indentationStack.isEmpty() && indent < indentationStack.peek().getSecond();
                        if (!isWhere && equalIndent) {
                            yybegin(REALLYYINITIAL);
                            yypushback(yylength());
                            return WHITESPACESEMITOK;
                        // "where" clauses can be equally indented with do blocks.  If this happens, we should close out
                        // the previous do block with a synthetic rbrace, essentially the same as a dedent.
                        // See https://github.com/carymrobbins/intellij-haskforce/issues/81
                        }
                        if (isDedent || (isWhere && equalIndent)) {
                            indentationStack.pop();
                            yypushback(yylength());
                            int lastNum = openBraces.peek().getSecond();
                            openBraces.push(Pair.create(Pair.create(yyline,yycolumn), --lastNum));
                            return WHITESPACERBRACETOK;
                        }
                        yybegin(REALLYYINITIAL);
                        yypushback(yylength());
                    }
}

<FINDINGINDENTATIONCONTEXT> {
    [\ \f]          {
                        indent++;
                        return com.intellij.psi.TokenType.WHITE_SPACE;
                    }
    [\t]            {
                        indent = indent + (indent + 8) % 8;
                        return com.intellij.psi.TokenType.WHITE_SPACE;
                    }
    [\n]            {
                        indent = 0;
                        return com.intellij.psi.TokenType.WHITE_SPACE;
                    }
    "{-#"           {
                        stateStack.push(FINDINGINDENTATIONCONTEXT);
                        yybegin(INPRAGMA);
                        return OPENPRAGMA;
                    }
    "{-"            {
                        commentLevel++;
                        stateStack.push(FINDINGINDENTATIONCONTEXT);
                        yybegin(INCOMMENT);
                        return OPENCOM;
                    }
    "{"             {
                        yybegin(REALLYYINITIAL);
                        yypushback(1);
                    }
    <<EOF>>         {   // Deal with "module Modid where \n\n\n".
                        indentationStack.push(Pair.create(yyline, yycolumn));
                        yybegin(REALLYYINITIAL);
                        int lastNum = openBraces.peek().getSecond();
                        openBraces.push(Pair.create(Pair.create(yyline,yycolumn), ++lastNum));
                        return WHITESPACELBRACETOK;
                    }
   "--"[^\r\n]*     {   // DO NOT REMOVE.
                        // Workaround for {COMMENT} not affecting this rule.
                        // See Module00001.hs for test case.
                        indent = 0;
                        return COMMENT;
                    }
    [^]             {
                        yypushback(1);
                        if (emptyblockPhase == 1) {
                            emptyblockPhase = 2;
                            int lastNum = openBraces.peek().getSecond();
                            openBraces.push(Pair.create(Pair.create(yyline,yycolumn), --lastNum));
                            return WHITESPACERBRACETOK;
                        } else if (emptyblockPhase == 2) {
                            emptyblockPhase = 0;
                            yybegin(REALLYYINITIAL);
                            return WHITESPACESEMITOK;
                        } else if (!indentationStack.isEmpty() &&
                                indent == indentationStack.peek().getSecond()) {
                            emptyblockPhase = 1;
                            int lastNum = openBraces.peek().getSecond();
                            openBraces.push(Pair.create(Pair.create(yyline,yycolumn), ++lastNum));
                            return WHITESPACELBRACETOK;
                        } else {
                            indentationStack.push(Pair.create(yyline, yycolumn));
                            yybegin(REALLYYINITIAL);
                            int lastNum = openBraces.peek().getSecond();
                            openBraces.push(Pair.create(Pair.create(yyline,yycolumn), ++lastNum));
                            return WHITESPACELBRACETOK;
                        }
                    }
}

<INQUASIQUOTE> {
    "|]"                    {
                                qqLevel--;
                                yybegin(stateStack.pop());
                                if (qqLevel == 0) {
                                    return RTHCLOSE;
                                }
                                return QQTEXT;
                            }

    ("["{MAYBEQVARID}"|")   {
                                yypushback(yytext().length() - 1);
                                qqLevel++;
                                stateStack.push(INQUASIQUOTE);
                                yybegin(INQUASIQUOTEHEAD);
                                return QQTEXT;
                            }
    [^|\]\[]+               { return QQTEXT; }
    [^]                     { return QQTEXT; }
}

<INQUASIQUOTEHEAD> {
  "|"                       {
                                yybegin(INQUASIQUOTE);
                                return PIPE;
                            }
  {VARIDREGEXP}             { return VARIDREGEXP; }
  {CONID}                   { return CONIDREGEXP; }
  "."                       { return PERIOD;}
  {EOL}+                    {
                                indent = 0;
                                return com.intellij.psi.TokenType.WHITE_SPACE;
                            }
  [\ \f\t]+                 { return com.intellij.psi.TokenType.WHITE_SPACE; }
  [^]                       { return com.intellij.psi.TokenType.BAD_CHARACTER; }
}

