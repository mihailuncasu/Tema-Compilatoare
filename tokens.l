%{
    #include "y.tab.h"

    int lineNo = 1;
    int colNo = 1;
%}





%%

"TO"                            { colNo+=2; return TOK_TO; }
"DO"                            { colNo+=2; return TOK_DO; }
"DIV"                           { colNo+=3; return TOK_DIV; }
"FOR"                           { colNo+=3; return TOK_FOR; }
"END"                           { colNo+=3; return TOK_END; }
"VAR"                           { colNo+=3; return TOK_VAR; }
"READ"                          { colNo+=4; return TOK_READ; }
"BEGIN"                         { colNo+=5; return TOK_BEGIN; }
"WRITE"                         { colNo+=5; return TOK_WRITE; }
"INTEGER"                       { colNo+=7; return TOK_INTEGER; }
"PROGRAM"                       { colNo+=7; return TOK_PROGRAM; }  
[_a-zA-Z][_a-zA-Z0-9]*          { 
    yylloc.first_line = lineNo; 
    yylloc.first_column = colNo; 
    colNo+=strlen(yytext); 
    yylval.str = new char[strlen(yytext)+1]; 
    strcpy(yylval.str,yytext); 
    return TOK_ID; 
}
0|[1-9][0-9]*                   { 
    yylloc.first_line = lineNo; 
    yylloc.first_column = colNo; 
    colNo+=strlen(yytext);  
    yylval.val = atoi(yytext);
    return TOK_INT; 
}  
[ ]                             { colNo++; }
";"                             { colNo++; return ';'; }
":"                             { colNo++; return ':'; }
","                             { colNo++; return ','; }
"+"                             { colNo++; return TOK_PLUS; }
"-"                             { colNo++; return TOK_MINUS; }
"*"                             { colNo++; return TOK_MULTIPLY; }
"("                             { colNo++; return TOK_LEFT; }
")"                             { colNo++; return TOK_RIGHT; }
":="                            { colNo+=2; return TOK_ATTRIBUTION; }
.                               { colNo++; return TOK_ERROR; }
[\n]                            { colNo=1; lineNo++; }

%%