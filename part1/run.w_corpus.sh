#!/bin/bash -eu

# CONFG
OSS_FUZZ="https://github.com/google/oss-fuzz.git"
PROJECT="libpng"
PROJECT_FUZZER="libpng_read_fuzzer"
TIMEOUT="14400" # 4h
WORKDIR="$(pwd)"
OSS_FUZZ_DIR="$WORKDIR/oss-fuzz"
BUILD_DIR="$OSS_FUZZ_DIR/build/out"
COVERAGE_DIR="$BUILD_DIR/libpng/report_target/libpng_read_fuzzer/linux"
CORPUS_DIR="$BUILD_DIR/corpus"

if [ ! -d "$OSS_FUZZ_DIR" ] ; then
    git clone "$OSS_FUZZ" "$OSS_FUZZ_DIR"
fi

# build the libpng fuzzers
cd "$OSS_FUZZ_DIR"
python3 infra/helper.py build_image "$PROJECT"
python3 infra/helper.py build_fuzzers "$PROJECT"

# 4h campain run
echo "[+] Running "$PROJECT_FUZZER" WITH seed corpus for $TIMEOUT"
# mkdir -p "$CORPUS_DIR"
# timeout --foreground -k 1 "$TIMEOUT" python3 infra/helper.py run_fuzzer "$PROJECT" "$PROJECT_FUZZER" \
#   --corpus-dir "$CORPUS_DIR"
docker run --rm --privileged \
  -v "$CORPUS_DIR":/corpus \
  -v "$BUILD_DIR/$PROJECT":/out \
  gcr.io/oss-fuzz/"$PROJECT" \
  /out/"$PROJECT_FUZZER" \
    -artifact_prefix=/corpus/ \
    -max_total_time="$TIMEOUT" \
    /corpus

echo "[+] Finished running $PROJECT_FUZZER"

# rebuild with coverage report html
echo "[+] Rebuilding with coverage report html"
python3 infra/helper.py build_fuzzers --sanitizer coverage "$PROJECT"
python3 infra/helper.py coverage "$PROJECT" \
  --corpus-dir "$CORPUS_DIR" \
  --fuzz-target "$PROJECT_FUZZER" \
  --no-serve

# copy the coverage report to the submission folder
DESTDIR="$WORKDIR/part1/report/w_corpus"
mkdir -p "$DESTDIR"
rm -rf "${DESTDIR:?}"/*

cp -r "$COVERAGE_DIR"/* "$DESTDIR"/

echo "[+] Coverage report with seeds at $DESTDIR/index.html"
