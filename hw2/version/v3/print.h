#ifndef PRINT_H
#define PRINT_H

/*
 * Print string into stdout.
 * params:
 *   str: printed string
 *   strsize: size of string (includes ending '\0')
 */
void printstr(const char *str, uint32_t strsize);

/*
 * Print a single character into stdout.
 * params:
 *   input: input character
 */
void printchar(char input);

/*
 * Print an integer into into stdout.
 * params:
 *   input: input integer
 */
void printint(int32_t input);

#endif