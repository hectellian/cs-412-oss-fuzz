#!/bin/bash -eu

# CONFIG
OSS_FUZZ="https://github.com/hectellian/oss-fuzz.git"
LIBPNG_REPO="https://github.com/hectellian/libpng.git"
PROJECT="libpng"
PROJECT_FUZZER="libpng_read_fuzzer"
BRANCH="improve1"
TIMEOUT="14400" # 4h
WORKDIR="$(pwd)"
OSS_FUZZ_DIR="$WORKDIR/oss-fuzz-improve1"
LIBPNG_DIR="$WORKDIR/libpng-improve1"
REPORT_DIR="$WORKDIR/part3/improve1"
BUILD_DIR="$OSS_FUZZ_DIR/build/out"
COVERAGE_DIR="$BUILD_DIR/libpng/report_target/libpng_read_fuzzer/linux"
CORPUS_DIR="$BUILD_DIR/improve1_corpus"

# number of parallel fuzz runs and their tmp locations
NUM_RUNS=3
declare -a TMP_CORPORA
for i in $(seq 1 $NUM_RUNS); do
  TMP_CORPORA[$i]="$BUILD_DIR/tmp_corpus${i}"
done

# clone repos (only on first run)
if [ ! -d "$LIBPNG_DIR" ] ; then
    git clone "$LIBPNG_REPO" "$LIBPNG_DIR" --branch "$BRANCH"
fi

if [ ! -d "$OSS_FUZZ_DIR" ] ; then
    git clone "$OSS_FUZZ" "$OSS_FUZZ_DIR" --branch "$BRANCH"
fi

# diffs
mkdir -p "$REPORT_DIR"
pushd "$LIBPNG_DIR" >/dev/null
git diff origin/libpng16...HEAD > "$REPORT_DIR/project.diff"
echo "[+] Wrote libpng diff to $REPORT_DIR/project.diff"
popd >/dev/null

pushd "$OSS_FUZZ_DIR" >/dev/null
git diff origin/master...HEAD > "$REPORT_DIR/oss-fuzz.diff"
echo "[+] Wrote oss-fuzz diff to $REPORT_DIR/oss-fuzz.diff"
popd >/dev/null

# build the libpng fuzzers
cd "$OSS_FUZZ_DIR"
python3 infra/helper.py build_image "$PROJECT"
python3 infra/helper.py build_fuzzers "$PROJECT"

# prepare corpus dir
mkdir -p "$CORPUS_DIR"

# 4h campaign run, 3 times in parallel tmp corpora
echo "[+] Running $PROJECT_FUZZER with improved seed corpus for $TIMEOUT (x$NUM_RUNS)"
for i in $(seq 1 $NUM_RUNS); do
    echo "[+] Run #$i: fuzzing into ${TMP_CORPORA[$i]} for $TIMEOUT"
    docker run --rm --privileged \
      -v "${TMP_CORPORA[$i]}":/corpus \
      -v "$BUILD_DIR/$PROJECT":/out \
      gcr.io/oss-fuzz/"$PROJECT" \
      /out/"$PROJECT_FUZZER" \
        -artifact_prefix=/corpus/ \
        -max_total_time="$TIMEOUT" \
        /corpus
    echo "[+] Finished run #$i"
done

# merge the 3 tmp corpora into one
echo "[+] Merging corpora into: $CORPUS_DIR"
for i in $(seq 1 $NUM_RUNS); do
  cp -r "${TMP_CORPORA[$i]}"/* "$CORPUS_DIR"/ || true
done

# rebuild with coverage report html
echo "[+] Rebuilding with coverage report html"
python3 infra/helper.py build_fuzzers --sanitizer coverage "$PROJECT"
python3 infra/helper.py coverage "$PROJECT" \
  --corpus-dir "$CORPUS_DIR" \
  --fuzz-target "$PROJECT_FUZZER" \
  --no-serve

# copy the coverage report to the submission folder
DESTDIR="$REPORT_DIR/coverage_improve1"
mkdir -p "$DESTDIR"
rm -rf "${DESTDIR:?}"/*

cp -r "$COVERAGE_DIR"/* "$DESTDIR"/

echo "[+] Coverage report with improved seeds at $DESTDIR/index.html"
