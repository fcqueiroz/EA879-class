/* Syntactical analyser for evaluating integer numerical expressions
   (c) 2016 Fernanda C Queiroz
   Based on Syntactical analyser made by Eduardo Valle, eduadovalle.com/
   All rights reserved
   Non-comercial use of this code for educational purposes allowed. */

#include <ctype.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TOKEN_LEN   1024
#define OPERAND_LEN 1024
#define OPERATOR_LEN    1024
#define PRECEDENCE_OFFSET   10

int main() {

    // Creates stack for handling operands and operators
    // Index points to the free position in the respective array
    long operands[OPERAND_LEN];
    int operandsIdx = 0;
    int operators[OPERATOR_LEN];
    int operatorsIdx = 0;

    // Increase precedence constant for operators inside parentesis
    int globalPrecendence = 0;

    // Initialize operators array; Inserts lowest precedence operator
    operators[operatorsIdx] = 0;
    operatorsIdx++;

    while (true) {
        // Now keeps executing chain, alternating operators and operands...
        // CAPTURE_DATA: gets next token
        char token[TOKEN_LEN];
        char *returned = fgets(token, TOKEN_LEN, stdin);
        if (returned == NULL) {
            break;
        }
        // ...uses strtok to remove any eventual trailing blankspace
        returned = strtok(returned, " \n\r\t");
        if (returned == NULL) {
            // Blank line -- tries again
            continue;
        }

        // CATEGORIZA DATA:
        // ...if token is parentesis, changes global precedence for operators
        if (strcmp(token, "(") == 0) {
            globalPrecendence += PRECEDENCE_OFFSET;
        }
        else if (strcmp(token, ")") == 0) {
            globalPrecendence -= PRECEDENCE_OFFSET;
        }

        // ...if token is number, saves it for later
        else if (isdigit(token[0]) ) {
            operands[operandsIdx] = atol(token);
            operandsIdx++;
        }

        // ...if token is operator, saves it for later with a numeric identifier
        else if (strcmp(token, "-") == 0) {
            operators[operatorsIdx] = 2 + globalPrecendence;
            operatorsIdx++;
        }
        else if (strcmp(token, "+") == 0) {
            operators[operatorsIdx] = 3 + globalPrecendence;
            operatorsIdx++;
        }
        else if (strcmp(token, "/") == 0) {
            operators[operatorsIdx] = 5 + globalPrecendence;
            operatorsIdx++;
        }
        else if (strcmp(token, "*") == 0) {
            operators[operatorsIdx] = 6 + globalPrecendence;
            operatorsIdx++;
        }
        else if (strcmp(token, "**") == 0) {
            operators[operatorsIdx] = 8 + globalPrecendence;
            operatorsIdx++;
        }
        else if (strcmp(token, "$") == 0) {
            operators[operatorsIdx] = 0;
            operatorsIdx++;
        }
        // ...unknown token
        else {
            fprintf(stderr, "Lexical error: unknown token %s\n", token);
            return 1;
        }

        // Dealing with Syntax errors...
        if (operandsIdx>operatorsIdx) {
            long num1 = operands[operandsIdx - 2];
            long num2 = operands[operandsIdx - 1];
            fprintf(stderr, "Syntax error: operand %ld followed by operand %ld.\n", num1, num2);
            return 2;
        }
        else if (operatorsIdx>operandsIdx+1) {
            fprintf(stderr, "Syntax error: operator followed by operator.\n");
            return 2;
        }

        // EVALUEATE EXPRESSION
        // Checks if it should perform operation or wait
        while (operators[operatorsIdx - 2] >= operators[operatorsIdx - 1] - 1 && operandsIdx > 1) {
            if (operators[operatorsIdx - 2] % PRECEDENCE_OFFSET == 2) {
                operands[operandsIdx - 2] -= operands[operandsIdx - 1];
            }
            else if (operators[operatorsIdx - 2] % PRECEDENCE_OFFSET == 3) {
                operands[operandsIdx - 2] += operands[operandsIdx - 1];
            }
            else if (operators[operatorsIdx - 2] % PRECEDENCE_OFFSET == 5) {
                if (operands[operandsIdx - 1] == 0) {
                    fprintf(stderr, "Fatal error: Division by zero.\n");
                    return 3;
                }
                operands[operandsIdx - 2] /= operands[operandsIdx - 1];
            }
            else if (operators[operatorsIdx - 2] % PRECEDENCE_OFFSET == 6) {
                operands[operandsIdx - 2] *= operands[operandsIdx - 1];
            }
            else if (operators[operatorsIdx - 2] % PRECEDENCE_OFFSET == 8) {
                long base = operands[operandsIdx - 2];
                long power = operands[operandsIdx - 1];
                operands[operandsIdx -2] = powl(base, power);
            }
            operators[operatorsIdx - 2] = operators[operatorsIdx - 1];
            operandsIdx--;
            operatorsIdx--;
        }

        // If we reached the end-of-expression and the stack is empty, exits
        if (operatorsIdx == 2 && operators[1] == 0) {
            if (globalPrecendence > 0) {
                fprintf(stderr, "Syntax error: extra \"(\" found.\n");
                return 2;
            }
            else if (globalPrecendence < 0) {
                fprintf(stderr, "Syntax error: extra \")\" found.\n");
                return 2;
            }
            else {
                break;
            }
        }
    }

    printf("%ld\n", operands[operandsIdx - 1]);
    return 0;
}
