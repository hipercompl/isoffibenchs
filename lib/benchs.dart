import 'dart:io';
import 'dart:ffi';
import 'dart:isolate';

import 'package:benchs/nlib_ffi_bindings.dart';
import 'package:ffi/ffi.dart';

const callCnt = 100000;
const messageCount = 10000;
const listSize = 10000;
const quitMessage = -1;

int dfunc1(int n) {
  return n;
}

void dfunc2(List<int> input, List<int> output) {
  output.add(input[0]);
}

void ffiBench1(DynamicLibrary nativeLib) {
  print("FFI benchmark 1: int func(int)");
  print("Timing Dart native function");

  final sw1 = Stopwatch()..start();
  int r = 0;
  for (var i = 0; i < callCnt; i++) {
    r = dfunc1(r);
  }
  sw1.stop();

  final nativePerCall = sw1.elapsedMicroseconds / callCnt;

  print("Timing FFI function");
  final nlib = NLib(nativeLib);
  final sw2 = Stopwatch()..start();
  r = 0;
  for (var i = 0; i < callCnt; i++) {
    r = nlib.nfunc1(r + 1);
  }
  sw2.stop();
  final ffiPerCall = sw2.elapsedMicroseconds / callCnt;

  print("Native Dart call: $nativePerCall us");
  print("FFI call: $ffiPerCall us");
  print("FFI / native: ${ffiPerCall / nativePerCall}");
  print("");
}

void ffiBench2(DynamicLibrary nativeLib) {
  print(
    "FFI benchmark 2: void func(int*, int*) vs void func(List<int>, List<int>)",
  );
  print("Timing Dart native function");

  final sw1 = Stopwatch()..start();
  for (var i = 0; i < callCnt; i++) {
    // to be fair, if we are to allocate native memory before each FFI call,
    // we create a new list before each native call
    final inList = [0];
    final List<int> outList = [];
    dfunc2(inList, outList);
    // and clear the list afterwards
    inList.clear();
    outList.clear();
  }
  sw1.stop();

  final nativePerCall = sw1.elapsedMicroseconds / callCnt;

  print("Timing FFI function");
  final nlib = NLib(nativeLib);
  final sw2 = Stopwatch()..start();
  for (var i = 0; i < callCnt; i++) {
    Pointer<Int> inRef = malloc<Int>(1);
    Pointer<Int> outRef = malloc<Int>(1);
    nlib.nfunc2(inRef, outRef);
    malloc.free(inRef);
    malloc.free(outRef);
  }
  sw2.stop();
  final ffiPerCall = sw2.elapsedMicroseconds / callCnt;

  print("Native Dart call: $nativePerCall us");
  print("FFI call: $ffiPerCall us");
  print("FFI / native: ${ffiPerCall / nativePerCall}");
  print("");
}

Future<void> isolateBench1() async {
  print("Isolates test 1: I1 -> int + port -> I2 -> int -> I1");

  print("Spawning a background isolate");

  final fromBg = ReceivePort();
  Isolate.spawn<SendPort>(runner1, fromBg.sendPort);
  SendPort toBg = await fromBg.first;

  print("Timing isolate communication");
  final w = Stopwatch()..start();
  for (int i = 0; i < messageCount; i++) {
    var fromBgData = ReceivePort();
    toBg.send((i, fromBgData.sendPort));
    await fromBgData.first;
  }
  w.stop();
  toBg.send((quitMessage, null));
  final perMessage = w.elapsedMicroseconds / messageCount;

  print("Single int roundtrip: $perMessage us");
  print("");
}

Future<void> isolateBench2() async {
  print(
    "Isolates test 1: I1 -> [$listSize ints] + port -> I2 -> [$listSize ints] -> I1",
  );
  print("Spawning a background isolate");

  final fromBg = ReceivePort();
  Isolate.spawn<SendPort>(runner2, fromBg.sendPort);
  SendPort toBg = await fromBg.first;

  print("Timing isolate communication");
  final payload = List<int>.filled(listSize, 1);
  final w = Stopwatch()..start();
  for (int i = 0; i < messageCount; i++) {
    var fromBgData = ReceivePort();
    toBg.send((payload, fromBgData.sendPort));
    await fromBgData.first;
  }
  w.stop();
  toBg.send(([], null));
  final perMessage = w.elapsedMicroseconds / messageCount;

  print("[$listSize ints] roundtrip: $perMessage us");
  print("Single int roundtrip: ${perMessage / listSize} us");
  print("");
}

DynamicLibrary loadNativeLib() {
  if (Platform.isWindows) {
    return DynamicLibrary.open("nlib.dll");
  } else if (Platform.isLinux || Platform.isAndroid) {
    return DynamicLibrary.open("./libnlib.so");
  } else {
    throw Exception("Only Linux and Windows platforms are currently supported");
  }
}

Future<void> runner1(SendPort toMain) async {
  print("BG :: isolate spawned");
  var fromMain = ReceivePort();
  toMain.send(fromMain.sendPort);
  print("BG :: port sent to main isolate");
  await for (var (val, port) in fromMain) {
    if (val != quitMessage) {
      port.send(val);
    } else {
      break;
    }
  }
  fromMain.close();
}

Future<void> runner2(SendPort toMain) async {
  print("BG :: isolate spawned");
  var fromMain = ReceivePort();
  toMain.send(fromMain.sendPort);
  print("BG :: port sent to main isolate");
  await for (var (val, port) in fromMain) {
    if (val.isNotEmpty) {
      port.send(val);
    } else {
      break;
    }
  }
  fromMain.close();
}
