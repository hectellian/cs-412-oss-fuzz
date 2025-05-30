# Submission Repo for Libpng OSS-Fuzz Project

## Part 1

### 1.1. Using the scripts

#### Running the scripts

The scripts are located in the `part1/report` directory. To run the scripts, you need to have Python 3 and Docker installed on your system. You can run the scripts by executing the following command in your terminal:

```bash
part1/report/run.w_corpus.sh
part1/report/run.w_o_corpus.py
```

The only action you need to do is accept if you want to pull the latest version of the images and then wait for the scripts to finish. 

#### Modifying the scripts

You can actually modify the scripts to change some directories and the execution time.

```bash
OSS_FUZZ_DIR="oss-fuzz-repo"
LIBPNG_REPO="libpng-repo"
PROJECT="name_of_the_project"
PROJECT_FUZZER="name_of_the_fuzzer"
BRANCH="no-seed-branch-name"
TIMEOUT="14400" # nb of seconds
WORKDIR="$(pwd)"
OSS_FUZZ_DIR="$WORKDIR/oss-fuzz-dir-name"
LIBPNG_DIR="$WORKDIR/libpng-dir-name"
REPORT_DIR="$WORKDIR/report-dir-name"
BUILD_DIR="$OSS_FUZZ_DIR/build-out-dir-name"
COVERAGE_DIR="$BUILD_DIR/coverage-out-dir-name"
CORPUS_DIR="$BUILD_DIR/corpus-dir-name"
```

### 1.2. Generating the reports

The reports are automatically generated by the scripts at the end of the execution. They are saved in the `part1/report/w*corpus` directory.
