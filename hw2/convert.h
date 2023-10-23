#ifndef CONVERT_H
#define CONVERT_H

/*
 * Convert integer into string form.
 * Will not convert if it lead to buffer overflow.
 * Only convert string up to converted size.
 * params:
 *   input: input integer
 *   str: output string
 *   strsize: capacity output string
 * return:
 *   convert size (includes ending '\0')
 */
uint32_t itos(int32_t input, char *str, uint32_t strsize);

#endif