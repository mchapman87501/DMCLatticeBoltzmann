#!/bin/sh
set -e -u

swift test --enable-code-coverage
swift demangle --compact <$(swift test --show-codecov-path) >test_coverage.json
python3 ${GITHUB_WORKSPACE}/.github/workflows/print_coverage_report.py
