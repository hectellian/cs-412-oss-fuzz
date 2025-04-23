#!/usr/bin/env bash
set -euo pipefail

# CONFG
OSS_FUZZ="https://github.com/google/oss-fuzz.git"
LIBPNG_REPO="https://github.com/pnggroup/libpng.git"
TIMEOUT="4h"
WORKDIR="$(pwd)"
OSS_FUZZ_DIR="$WORKDIR/oss-fuzz"
LIBPNG_DIR="$WORKDIR/libpng"

rm -rf "$OSS_FUZZ_DIR" "$LIBPNG_DIR"

git clone "$LIBPNG_REPO" "$LIBPNG_DIR"
git clone "$OSS_FUZZ" "$OSS_FUZZ_DIR"

# build the libpng fuzzers
cd "$OSS_FUZZ_DIR"
python3 infra/helper.py build_image libpng
python3 infra/helper.py build_fuzzers libpng

# 4h campain run
echo "[+] Running libpng_read_fuzzer WITH seed corpus for $TIMEOUT"
mkdir -p build/out/corpus/
timeout "$TIMEOUT" python3 infra/helper.py run_fuzzer libpng libpng_read_fuzzer \
  --corpus-dir build/out/corpus

# rebuild with coverage report html
python3 infra/helper.py build_fuzzers --sanitizer coverage libpng
python3 infra/helper.py coverage libpng \
  --corpus-dir build/out/corpus \
  --fuzz-target libpng_read_fuzzer \
  --no-serve

# copy the coverage report to the submission folder
DESTDIR="$WORKDIR/submission/part1/report/w_corpus"
mkdir -p "$DESTDIR"
rm -rf "$DESTDIR"/*
cp -r coverage-report/* "$DESTIR"/ || cp -r coverage-report/* "$DESTDIR"/
echo "[+] Coverage report with seeds at $DESTDIR/index.html"