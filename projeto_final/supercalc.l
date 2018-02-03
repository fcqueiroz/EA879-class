%pointer
%option noyywrap

%{
      #include <stdio.h>

      #define MAXVARSIZE 256
      #define YY_DECL int yylex()

      #include "supercalc.tab.h"

      void lexerror(const char* s);
%}

DIGIT        [0-9]
NUMBER       {DIGIT}+
FLOAT        {DIGIT}*\.{NUMBER}
LETTER       [A-Za-z]
VARNAME      {LETTER}({NUMBER}|{LETTER})*

%%

{NUMBER}	{ yylval.fval = atof(yytext);   
		    return FLOAT;  
		}
{FLOAT}		{ yylval.fval = atof(yytext);   
		    return FLOAT;  
		}
{VARNAME}	{ strncpy(yylval.sval, yytext, MAXVARSIZE);
		    yylval.sval[MAXVARSIZE-1] = '\0';
                    return VARNAME;
		}

\;		{ return SEPARATOR;	}
\=		{ return EQUALS;	}

\[		{ return LBRACKET;	}
\]		{ return RBRACKET;	}
\(		{ return OPEN;		}
\)		{ return CLOSE;		}

\+		{ return PLUS;		}
\- 		{ return MINUS;		}
\*		{ return TIMES;		}
\/		{ return OVER;		}
\^		{ return RAISED;	}

[ \t\n]+	// Eat up whitespace
.		{ lexerror(yytext);	}

%%

void lexerror(const char* s) {
      fprintf(stderr, "Unrecognized text: %s\n", s);
      exit(1);
}


