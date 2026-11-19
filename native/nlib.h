#if defined(_WIN32) && defined(BUILDLIB)
#define LIBAPI __declspec(dllexport)
#else
#define LIBAPI
#endif

#ifdef __CPP
#define CAPI extern "C"
#else
#define CAPI
#endif

// Return the argument unchanged.
CAPI int LIBAPI nfunc1(int input);

// Copy the value from input to output, return the copied value.
CAPI void LIBAPI nfunc2(int *input, int *output);
