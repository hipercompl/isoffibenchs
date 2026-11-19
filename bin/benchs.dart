import 'package:benchs/benchs.dart' as benchs;

void main(List<String> arguments) async {
  var nlib = benchs.loadNativeLib();
  benchs.ffiBench1(nlib);
  benchs.ffiBench2(nlib);
  await benchs.isolateBench1();
  await benchs.isolateBench2();
}
