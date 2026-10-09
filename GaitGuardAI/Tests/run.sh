#!/bin/sh
# Compile the pure analysis code together with the tests and run them.
set -e
cd "$(dirname "$0")/.."
OUT="${TMPDIR:-/tmp}/gaitguard_tests"
xcrun swiftc -O "GaitGuardAI Watch App/GaitAnalysis.swift" Tests/main.swift -o "$OUT"
"$OUT"
