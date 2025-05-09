#!/bin/bash -eu

# CONFIG
OSS_FUZZ="https://github.com/hectellian/oss-fuzz.git"
LIBPNG_REPO="https://github.com/hectellian/libpng.git"
PROJECT="libpng"
PROJECT_FUZZER="libpng_read_fuzzer"
BRANCH="improve2"
TIMEOUT="14400" # 4h
WORKDIR="$(pwd)"
OSS_FUZZ_DIR="$WORKDIR/oss-fuzz-improve2"
LIBPNG_DIR="$WORKDIR/libpng-improve2"
REPORT_DIR="$WORKDIR/part3/improve2/coverage_improve2"
DIFF_DIR="$WORKDIR/part3/improve2"
BUILD_DIR="$OSS_FUZZ_DIR/build/out"
COVERAGE_DIR="$BUILD_DIR/libpng/report_target/libpng_read_fuzzer/linux"
CORPUS_DIR="$BUILD_DIR/improve2_corpus"

if [ ! -d "$LIBPNG_DIR" ] ; then
    git clone "$LIBPNG_REPO" "$LIBPNG_DIR" --branch "$BRANCH"
fi

if [ ! -d "$OSS_FUZZ_DIR" ] ; then
    git clone "$OSS_FUZZ" "$OSS_FUZZ_DIR" --branch "$BRANCH"
fi

# generate diff files (oss-fuzz and libpng as project)
mkdir -p "$REPORT_DIR"

pushd "$LIBPNG_DIR" >/dev/null
git diff origin/libpng16...HEAD > "$DIFF_DIR/project.diff"
echo "[+] Wrote libpng diff to $DIFF_DIR/project.diff"
popd >/dev/null

pushd "$OSS_FUZZ_DIR" >/dev/null
git diff origin/master...HEAD > "$DIFF_DIR/oss-fuzz.diff"
echo "[+] Wrote oss-fuzz diff to $DIFF_DIR/oss-fuzz.diff"
popd >/dev/null

# build the libpng fuzzers
cd "$OSS_FUZZ_DIR"
python3 infra/helper.py build_image "$PROJECT"
python3 infra/helper.py build_fuzzers "$PROJECT"

# 4h campaign run
echo "[+] Running $PROJECT_FUZZER with improved seed corpus for $TIMEOUT"
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
DESTDIR="$REPORT_DIR"
mkdir -p "$DESTDIR"
rm -rf "${DESTDIR:?}"/*

cp -r "$COVERAGE_DIR"/* "$DESTDIR"/

echo "[+] Coverage report with improved seeds at $DESTDIR/index.html"