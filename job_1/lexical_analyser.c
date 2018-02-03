/* Lexical analyser for separating numbers, operators and parentesis
   with a line break.
   (c) 2016 Fernanda C Queiroz
   Non-commercial use of this code for educational purposes allowed. */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int imprimeEl(char *buf) {
    int i,j=0;
    int tam=strlen(buf);
    int flag=0; //numero = 0, operador = 1, delimitador = 2
    char oper[5] = {'+','-','/','*','='};
    char nume[10] = {'0','1','2','3','4','5','6','7','8','9'};
    char deli[2] = {'(',')'};

    for (j=0; j<tam; j++) {
        for (i=0; i<10; i++) {
            if (buf[j] == nume[i]) {
                if (flag==0) {
                    printf("%c", buf[j]);
                }
                else {
                    printf("\n%c", buf[j]);
                }
                flag=0;
                i=10;
            }
        }
        for (i=0; i<5; i++) {
            if (buf[j] == oper[i]) {
                if (flag == 1) {
                    printf("%c", buf[j]);
                }
                else {
                    printf("\n%c", buf[j]);
                }
                flag=1;
                i=5;
            }
        }
        for (i=0; i<2; i++) {
            if (buf[j] == deli[i]) {
                if (flag == 2) {
                    printf("%c", buf[j]);
                }
                else {
                    printf("\n%c",buf[j]);
                }
                flag=2;
                i=2;
            }
        }
    }
    printf("\n");
    return 0;
}

int main() {
    char buffer[30];
    fgets(buffer, 30, stdin);
    imprimeEl(buffer);
    return 0;
}
