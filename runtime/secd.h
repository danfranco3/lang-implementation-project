/*
 * SECD-like bytecode interpreter in C
 * Pedro Vasconcelos, 2013
 */
#include <stdint.h>
#include "heap.h"

/* opcodes for SECD instructions;
 * these have to be kept in sync with the Haskell compiler!
 */
#define HALT    0
#define LDC     1
#define LD      2
#define ADD     3
#define SUB     4
#define MUL     5
#define SEL     6
#define LDF     7
#define LDRF    8
#define AP      9
#define RTN     10
#define JOIN    11

/* values: 
   either an int or a pointer
 */
typedef intptr_t value_t;

/* environments:
   single linked list of cells
*/
typedef cell *env_t;

/* getters and setters for envionment fields
 */
#define GET_ELM(ptr)    ((value_t)((ptr)->fst))
#define GET_NEXT(ptr)   ((env_t)((ptr)->snd))
#define SET_ELM(ptr,v)  ((ptr)->fst = (intptr_t)(v))
#define SET_NEXT(ptr,e) ((ptr)->snd = (intptr_t)(e))

/* closures 
*/
typedef cell closure_t;

/* getters and setters for closure fields
 */
#define GET_CODE(ptr)   ((int)((ptr)->fst))
#define GET_ENV(ptr)    ((env_t)((ptr)->snd))
#define SET_CODE(ptr,c) ((ptr)->fst = (intptr_t)(c))
#define SET_ENV(ptr,e)  ((ptr)->snd = (intptr_t)(e))

/* dump entry
   pair of program counter and environment pointer
 */
typedef struct {
  int pc;
  env_t env;
} dump_t;

/* global segment sizes 
 */
#define CODE_MAX  1000
#define STACK_MAX 1000
#define DUMP_MAX  1000
#define HEAP_MAX  10000
