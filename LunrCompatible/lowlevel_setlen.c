#include <blitz.h>

// Hack to forcibly set the length of a BlitzMax string
// Faster alternative to slicing
// Limitation: can't expand strings
// Limitation: unused memory will stay allocated
// Warning: string hash needs to be reset here
// 
// Shrinking in->buf with realloc() is not going to happen because it's not allocated separately
// But maybe it will be possible to shrink the entire BBString?
//
int setlen( BBString *in, int length ) {
	in->length = length;
	in->hash = 0;
}
