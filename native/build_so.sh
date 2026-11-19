#!/bin/bash

clang -shared -o libnlib.so nlib.c
cp libnlib.so ..
