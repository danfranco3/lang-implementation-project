/*
 * Heap allocation for SECD machine 
 * Pedro Vasconcelos, 2024
 */
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "heap.h"

static cell *heap ;     // global heap pointer
static int heap_size;   // heap size
static int heap_free;   // current free index

/* initialize the heap
 */
void init_heap(int size) {
  heap = (cell*)malloc(size*sizeof(cell));
  assert(heap != NULL);
  heap_size = size;
  heap_free = 0;
}

/* free the entire heap
 */
void free_heap(void) {
  free(heap);
}

/* allocate a new cell
 */
cell *alloc_cell(void) {
  if (heap_free < heap_size) {
      cell *ptr = &heap[heap_free++];
      return ptr;
  } else {
    fprintf(stderr, "out of heap\n");
    exit(-1);
  } 
}



