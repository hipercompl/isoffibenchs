#define BUILDLIB
#include "nlib.h"

CAPI int LIBAPI nfunc1(int input)
{
	return input;
}

CAPI void LIBAPI nfunc2(int *input, int *output)
{
	*output = *input;
	return;
}
