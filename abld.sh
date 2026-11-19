#!/bin/bash

dart pub get
dart build cli
echo "you can now run ./build/cli/linux_x64/bundle/bin/benchs"