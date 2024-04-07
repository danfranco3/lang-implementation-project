#include <stdint.h>

/* a heap cell: a pair of ints or pointers
 */
typedef struct {
  intptr_t fst;
  intptr_t snd;
} cell;


cell *alloc_cell(void);
void free_heap(void);
void init_heap(int);
