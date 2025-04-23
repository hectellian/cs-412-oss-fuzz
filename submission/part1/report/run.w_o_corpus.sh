#!/usr/bin/env bash
set -euo pipefail

# CONFG
OSS_FUZZ="https://github.com/hectellian/oss-fuzz.git"
LIBPNG_REPO="https://github.com/hectellian/libpng.git"
BRANCH="no-seed-corpus"
TIMEOUT="4h"
WORKDIR="$(pwd)"
OSS_FUZZ_DIR="$WORKDIR/oss-fuzz"
LIBPNG_DIR="$WORKDIR/libpng"
REPORT_DIR="$WORKDIR/submission/part1/report"

rm -rf "$OSS_FUZZ_DIR" "$LIBPNG_DIR"

git clone "$LIBPNG_REPO" "$LIBPNG_DIR" --branch "$BRANCH"
git clone "$OSS_FUZZ" "$OSS_FUZZ_DIR" --branch "$BRANCH"

# generate diff files (oss-fuzz and libpng as project)
mkdir -p "$REPORT_DIR"

pushd "$LIBPNG_DIR" >/dev/null
git diff HEAD^ > "$REPORT_DIR/project.diff"
echo "[+] Wrote libpng diff to $REPORT_DIR/project.diff"
popd >/dev/null

pushd "$OSS_FUZZ_DIR" >/dev/null
git diff HEAD^ > "$REPORT_DIR/oss-fuzz.diff"
echo "[+] Wrote oss-fuzz diff to $REPORT_DIR/oss-fuzz.diff"
popd >/dev/null

# build the libpng fuzzers
cd "$OSS_FUZZ_DIR"
python3 infra/helper.py build_image libpng
python3 infra/helper.py build_fuzzers libpng


# build the libpng fuzzers
python3 infra/helper.py build_image  libpng
python3 infra/helper.py build_fuzzers libpng

# 4h campain run
mkdir -p build/out/without_corpus/
timeout "$TIMEOUT" -k 1 python3 infra/helper.py run_fuzzer libpng libpng_read_fuzzer --corpus-dir build/out/without_corpus

# rebuild with coverage report html
python3 infra/helper.py build_fuzzers --sanitizer coverage libpng
python3 infra/helper.py coverage libpng --corpus-dir build/out/without_corpus --fuzz-target libpng_read_fuzzer --no-serve

# copy the coverage report to the submission folder
DESTDIR="$WORKDIR/submission/part1/report/w_o_corpus"
mkdir -p "$DESTDIR"
rm -rf "$DESTDIR"/*
cp -r coverage-report/* "$DESTIR"/ || cp -r coverage-report/* "$DESTDIR"/
echo "[+] Coverage report with seeds at $DESTDIR/index.html"