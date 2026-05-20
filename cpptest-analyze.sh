#!/bin/bash

# This script should run the C/C++test static analysis with additional build and verification steps.
# It should be located in the root of the project. It is intended to be executed by C/C++test skills.
#
# Adjust the build and analysis steps as needed for your project.

# == Makefile project ==

# Build
cpptesttrace make clean all

# Analyze
cpptestcli -quiet -compiler gcc_14-aarch64 -config "builtin://Recommended Rules" -module . -input cpptestscan.bdf

# == CMake project ==

# Configure
# cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -S . -B .build

# Build
# cmake --build .build

# Analyze
# cpptestcli -quiet -compiler gcc_14-aarch64 -config "builtin://Recommended Rules" -module . -input .build/compile_commands.json
