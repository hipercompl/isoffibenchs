# Simple benchmarks of FFI calls and message passing between isolates in Dart

## Build and run

Get the dependencies:

```
dart pub get
```

Re-generate the FFI bindings (optional, the bindings are already included in this repository):
```
dart run ffigen
```

Next, refer to a subsection below related to your operating system.

### Linux
Build the native library (the scripts in this repo use LLVM's clang):
```bash
cd native
./build_so.sh
cd ..
```

Build the benchmark Dart executable:
```bash
dart build cli
```
or
```bash
./abld.sh
```

Run `./build/cli/linux_x64/bundle/bin/benchs`.

### Windows
Build the native library (the batch files in this repo use LLVM's clang):
```cmd
cd native
build_dll.bat
cd ..
```
Build the benchmark Dart executable:
```bash
dart build cli
```
or
```cmd
abld.bat
```

Copy the native DLL to the directory containing the executable:
```cmd
copy /B /Y native\nlib.dll build\cli\windows_x64\bundle\bin
```

Run `build\cli\windows_x64\bundle\bin\benchs.exe`.

## Benchmarks

### FFI benchmark 1
Measures a simple function of the form:
```C
int function(int)
```
which takes a single integer (by value) as an argument and returns a single integer (by value) as a result.

Compares the mean invocation (and execution) time in pure Dart vs an equivalent invocation from a shared library via FFI.

### FFI benchmark 2
Measures a function requiring pre-allocated memory to be passed by pointer:
```C
void function(int* input, int* output)
```
versus a Dart function operating on lists:
```dart
void function(List<int> input, List<int> output)
```

The pure Dart call puts a single integer into the `input` list, and the function being called puts a single integer into the `output` list (simulating passing data via memory buffers).

The FFI calls actually allocate native buffers for each call:
```dart
Pointer<Int> inRef = malloc<Int>(1);
Pointer<Int> outRef = malloc<Int>(1);
nlib.nfunc2(inRef, outRef); // FFI call
malloc.free(inRef);
malloc.free(outRef);
```



### Isolates benchmark 1

```
main → int + SendPort → background → int → main
```

Measures the time required to send a single integer (together with a `SendPort` instance for returning the data) from the main isolate to a background isolate and get that integer sent back from the background isolate to the main isolate. Displays the mean round-trip time.

### Isolates benchmark 2
```
main → [10000 ints] + SendPort → background → [10000 ints] → main
```

Measures the time required to send a list of 10000 integers (together with a `SendPort` instance for returning the data) from the main isolate to a background isolate and get the same list sent back from the background isolate to the main isolate.

Displays both the mean round-trip time and the amortized time per single integer (to be compared with the result of *Isolates benchmark 1*).

## Sample results
- Windows tests performed on AMD Ryzen AI 9 HX-370, 32 GB RAM, Windows 11 64-bit. 
- Linux tests performed on Intel Xeon E-2124, 16 GB RAM, Debian 13 64-bit.


### FFI benchmark 1
#### Windows
```
FFI benchmark 1: int func(int)
Native Dart call: 0.00021 us
FFI call: 0.0132 us
FFI / native: 62.857142857142854
```

#### Linux
```
FFI benchmark 1: int func(int)
Native Dart call: 0.00111 us
FFI call: 0.01655 us
FFI / native: 14.909909909909908
```

### FFI benchmark 2
#### Windows
```
FFI benchmark 2: void func(int*, int*) vs void func(List<int>, List<int>)
Native Dart call: 0.02098 us
FFI call: 0.08762 us
FFI / native: 4.176358436606292
```

#### Linux
```
FFI benchmark 2: void func(int*, int*) vs void func(List<int>, List<int>)
Native Dart call: 0.03836 us
FFI call: 0.10242 us
FFI / native: 2.669968717413973
```

### Isolates benchmark 1
#### Windows
```
Isolates benchmark 1: I1 -> int + port -> I2 -> int -> I1
Single int roundtrip: 3.2752 us
```

#### Linux
```
Isolates benchmark 1: I1 -> int + port -> I2 -> int -> I1
Single int roundtrip: 4.5244 us
```

### Isolates benchmark 2
#### Windows
```
Isolates benchmark 2: I1 -> [10000 ints] + port -> I2 -> [10000 ints] -> I1
[10000 ints] roundtrip: 10.0955 us
Single int roundtrip: 0.00100955 us
```

#### Linux
```
Isolates benchmark 2: I1 -> [10000 ints] + port -> I2 -> [10000 ints] -> I1
[10000 ints] roundtrip: 21.9833 us
Single int roundtrip: 0.00219833 us
```
