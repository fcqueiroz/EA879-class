%{
      #include <math.h>
      #include <stdio.h>
      #include <stdlib.h>
      #include <string.h>
      #include <stdint.h>

      extern int yylex();
      extern int yyparse();
      extern FILE* yyin;

      #define MAXVARSIZE 256
      #define MAXVARS    131071  // Prime numbers work best

      // Implement the symbol table as a hash table
      // Global variables are 0 ininitialized
      char *varNames[MAXVARS]; 
      float  varValues[MAXVARS];
      char *funcNames[MAXVARS];
      char *funcValues[MAXVARS];
      char *funcParameters[MAXVARS];
      
      void update(const char *name, float value);
      float read(const char *name);
      void update_func(const char *name, char *value, char *parameter);
      float read_func(const char *name, float parameter);

      void strreplace(char *src, char *str, char *rep);

      void yyerror(const char* s);

%}

%union {
    float	fval;
    char	sval[MAXVARSIZE];
}

%start input

%token<fval> FLOAT
%token<sval> VARNAME
%token EQUALS PLUS MINUS TIMES OVER RAISED
%token SEPARATOR
%token OPEN
%token CLOSE
%token LBRACKET
%token RBRACKET

%left SEPARATOR
%left EQUALS
%left MINUS PLUS
%left TIMES OVER
%right RAISED
%left NEG

%type<fval> exp
%type<sval> literalexp
%%

input :
  input SEPARATOR input
| statement
;

statement:
  exp                                         		{ printf("%f\n", $1);     }
| VARNAME EQUALS exp                              	{ update($1, $3);         }
| VARNAME LBRACKET VARNAME RBRACKET EQUALS literalexp   { update_func($1, $6, $3);}   
;

literalexp:
  FLOAT                                 { sprintf($$,"%f",$1);      }
| VARNAME                               { sprintf($$,"%s",$1);      }
| literalexp PLUS literalexp            { sprintf($$,"%s+%s",$1,$3);}
| literalexp MINUS literalexp           { sprintf($$,"%s-%s",$1,$3);}
| literalexp TIMES literalexp           { sprintf($$,"%s*%s",$1,$3);}
| literalexp OVER literalexp            { sprintf($$,"%s/%s",$1,$3);}
| MINUS literalexp  %prec NEG           { sprintf($$,"-%s",$2);     }
| literalexp RAISED literalexp          { sprintf($$,"%s^%s",$1,$3);}
| OPEN literalexp CLOSE                 { sprintf($$,"(%s)",$2);    }
;

exp:
  FLOAT                                 { $$ = $1;                }
| VARNAME                               { $$ = read($1);          }
| exp PLUS exp                          { $$ = $1 + $3;           }
| exp MINUS exp                         { $$ = $1 - $3;           }
| exp TIMES exp                         { $$ = $1 * $3;           }
| exp OVER exp                          { $$ = $1 / $3;           }
| MINUS exp  %prec NEG                  { $$ = -$2;               }
| exp RAISED exp                        { $$ = powf($1, $3);      }
| OPEN exp CLOSE                        { $$ = $2;                }
| VARNAME LBRACKET exp RBRACKET         { $$ = read_func($1, $3); }
;

%%

uint32_t hash(const char *name) {
    // Jenkins one at a time hash method
    uint32_t key = 0;
    while (*name != '\0') {
        key += *name;
        key += (key << 10);
        key ^= (key >> 6);
        name++;
    }
    key += (key << 3);
    key ^= (key >> 11);
    key += (key << 15);
    return key % MAXVARS;
}


void update(const char *name, float value) {
    uint32_t index = hash(name);
    for (int i=0; i<MAXVARS; i++, index=(index+1)%MAXVARS) {
            if (varNames[index]==NULL) {
                // Got an empty cell --- the name is not in the table: insert
                varNames[index] = strdup(name);
                varValues[index] = value;
                return;
            } else if (strcmp(varNames[index], name)==0) {
                // Found !
                varValues[index] = value;
                return;
            }
    }
    // We tested the entire table without finding : no more space
    fprintf(stderr, "Too many variables.\n");
    exit(2);
}


float read(const char *name) {
    uint32_t index = hash(name);
    for (int i=0; i<MAXVARS; i++, index=(index+1)%MAXVARS) {
        if (varNames[index]==NULL) {
            // Got an empty cell --- the name is not in the table: error
            fprintf(stderr, "Variable used before definition: %s\n", name);
            exit(2);
            }
        if (strcmp(varNames[index], name)==0) {
            // Found !
            return varValues[index];
        }
    }
    // We tested the entire table without finding
    fprintf(stderr, "Variable used before definition: %s\n", name);
    exit(2);
    return 0;
}

void update_func(const char *name, char *value, char *parameter) {            
    uint32_t index = hash(name);
    for (int i=0; i<MAXVARS; i++, index=(index+1)%MAXVARS) {
            if (funcNames[index]==NULL) {
                // Got an empty cell --- the name is not in the table: insert
                funcNames[index] = strdup(name);
                funcValues[index] = strdup(value);
                funcParameters[index] = strdup(parameter);
                return;
            } else if (strcmp(funcNames[index], name)==0) {
                // Found !
                funcValues[index] = strdup(value);
                funcParameters[index] = strdup(parameter);
                return;
            }
    }
    // We tested the entire table without finding : no more space
    fprintf(stderr, "Too many functions.\n");
    exit(2);
}

float read_func(const char *name, float parameter) {
    uint32_t index = hash(name);
    for (int i=0; i<MAXVARS; i++, index=(index+1)%MAXVARS) {
        if (funcNames[index]==NULL) {
            // Got an empty cell --- the name is not in the table: error
            fprintf(stderr, "Function used before definition: %s\n", name);
            exit(2);
            }
        if (strcmp(funcNames[index], name)==0) {
            // Found !
            char sparameter[MAXVARS];
            sprintf(sparameter,"%f", parameter);
            char expression[MAXVARS];
            
            strcpy(expression, funcValues[index]);
            strreplace(expression, funcParameters[index], sparameter);
        
            FILE *e1,*e2;
            e1 = fopen("tmp.txt","w+");
            //salva a expressão em um arquivo temporário
            fprintf(e1,"%s", expression);
            //Fechar o arquivo para que as mudanças sejam salvas.
            fclose(e1);
	    //modo "r" para que popen LEIA do stream de saida do subprocesso. 'e2' aponta para o 
	    e2 = popen("./supercalc < tmp.txt","r");
	    //remove o arquivo temporário
	    system("rm tmp.txt");
	    
	    //le o resultado da expressão
	    char arhh[MAXVARS];
	    fscanf(e2,"%s", arhh);
	    pclose(e2);
	    
	    return atof(arhh);
        }
    }
    // We tested the entire table without finding
    fprintf(stderr, "Function used before definitions: %s\n", name);
    exit(2);
    return 0;
}

// Replace all occurrence of "str" with "rep" in "src"
void strreplace(char *src, char *str, char *rep)
{
    // p aponta para a posição da primeira ocorrência do parametro dentro da expressão
    char *p = strstr(src, str);
    
    //Faça enquanto (p não é apontador nulo && procura outra ocorrencia do parametro)
    do {   
        if(p) {
            char buf[MAXVARS];
            //preenche o array 'buf' com caracteres nulos
            memset(buf,'\0',strlen(buf));

	    //se a 1a ocorrência do parametro é no inicio do arquivo...
            if(src == p) {
		//...copia para 'buf' todo o conteudo do valor do parametro...
                strcpy(buf,rep);
                //...e encerra adicionando a 'buf' o pedaço da expressão que vem após o parametro literal
                strcat(buf,p+strlen(str));  
            }
            //caso a 1a ocorrencia esteja em outra posição...
            else {
		//...copia para 'buf' a parte inicial da expressão (todos os caracteres anteriores ao parametro)...
                strncpy(buf,src,strlen(src) - strlen(p));
                //strncpy não garante que 'buf' termine com o caractere '\0'
                //... então inserimos esse valor à força.
                buf[strlen(src) - strlen(p)]='\0';
                //adiciona em 'buf' o valor do parametro
                strcat(buf,rep);
                //completa 'buf' com o pedaço da expressão após a 1a ocorrencia do parametro literal
                strcat(buf,p+strlen(str));
            }
            //preenche o array da expressao com caracteres nulos
            memset(src,'\0',strlen(src));
            //então copia a string de 'buf' para o array da expressão
            strcpy(src,buf);
        }   
    } while(p && (p = strstr(src, str)));
}

int main(int argc, char *argv[]) {
    yyin = stdin;
    do {
            yyparse();
    } while(!feof(yyin));
}

void yyerror(const char* s) {
    fprintf(stderr, "Parse error: %s\n", s);
    exit(1);
}