#!/bin/bash -eu

# CONFG
OSS_FUZZ="https://github.com/hectellian/oss-fuzz.git"
LIBPNG_REPO="https://github.com/hectellian/libpng.git"
PROJECT="libpng"
PROJECT_FUZZER="libpng_read_fuzzer"
BRANCH="no-seed-corpus"
TIMEOUT="14400" # 4h
WORKDIR="$(pwd)"
OSS_FUZZ_DIR="$WORKDIR/oss-fuzz-noseed"
LIBPNG_DIR="$WORKDIR/libpng"
REPORT_DIR="$WORKDIR/part1/report"
BUILD_DIR="$OSS_FUZZ_DIR/build/out"
COVERAGE_DIR="$BUILD_DIR/libpng/report_target/libpng_read_fuzzer/linux"
CORPUS_DIR="$BUILD_DIR/noseed_corpus"


if [ ! -d "$LIBPNG_DIR" ] ; then
    git clone "$LIBPNG_REPO" "$LIBPNG_DIR" --branch "$BRANCH"
fi

if [ ! -d "$OSS_FUZZ_DIR" ] ; then
    git clone "$OSS_FUZZ" "$OSS_FUZZ_DIR" --branch "$BRANCH"
fi

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
DESTDIR="$WORKDIR/part1/report/w_o_corpus"
mkdir -p "$DESTDIR"
rm -rf "${DESTDIR:?}"/*

cp -r "$COVERAGE_DIR"/* "$DESTDIR"/

echo "[+] Coverage report without seeds at $DESTDIR/index.html"