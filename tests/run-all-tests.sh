#!/bin/bash
# Comprehensive test runner for pipe.pl
# This runs all available tests and generates a report

PIPE="../pipe.pl"
LOG_FILE="pipe-tests.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
PASS=0
FAIL=0
TOTAL=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Start logging
echo "=== Pipe.pl Test Run - $TIMESTAMP ===" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check if pipe.pl exists and is executable
if [ ! -f "$PIPE" ]; then
    echo -e "${RED}ERROR: pipe.pl not found at $PIPE${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

if [ ! -x "$PIPE" ]; then
    echo -e "${YELLOW}WARNING: pipe.pl is not executable, trying with perl${NC}" | tee -a "$LOG_FILE"
    PIPE="perl $PIPE"
fi

# Run basic tests first
echo "Running basic tests..." | tee -a "$LOG_FILE"
./run-basic-tests.sh > basic-tests.out 2>&1
BASIC_RESULT=$?
cat basic-tests.out | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check for existing test-*.sh scripts (excluding special ones)
echo "Checking for generated test scripts..." | tee -a "$LOG_FILE"
TEST_SCRIPTS=$(ls test-*.sh 2>/dev/null | grep -v "run-\|performance-\|uncovered-branches")

if [ -z "$TEST_SCRIPTS" ]; then
    echo -e "${YELLOW}No generated test-*.sh scripts found.${NC}" | tee -a "$LOG_FILE"
    echo "Note: To generate tests from Readme.md, use:" | tee -a "$LOG_FILE"
    echo "  make clean && make build" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Check for spec files
    SPEC_FILES=$(ls spec-*.test 2>/dev/null)
    if [ -n "$SPEC_FILES" ]; then
        echo "Found spec files: $SPEC_FILES" | tee -a "$LOG_FILE"
        echo "You can generate test scripts manually with gen_test.sh" | tee -a "$LOG_FILE"
    fi
else
    echo "Found $(echo "$TEST_SCRIPTS" | wc -w) generated test scripts" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    # Run each test script
    for test_script in $TEST_SCRIPTS; do
        echo "Running $test_script..." | tee -a "$LOG_FILE"
        ./"$test_script" >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}PASS${NC}: $test_script" | tee -a "$LOG_FILE"
            PASS=$((PASS + 1))
        else
            echo -e "${RED}FAIL${NC}: $test_script" | tee -a "$LOG_FILE"
            FAIL=$((FAIL + 1))
        fi
        TOTAL=$((TOTAL + 1))
    done
fi

# Run uncovered branches tests if available
if [ -f "test-uncovered-branches.sh" ]; then
    echo "" | tee -a "$LOG_FILE"
    echo "Running uncovered branches tests..." | tee -a "$LOG_FILE"
    ./test-uncovered-branches.sh >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}: test-uncovered-branches.sh" | tee -a "$LOG_FILE"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}FAIL${NC}: test-uncovered-branches.sh" | tee -a "$LOG_FILE"
        FAIL=$((FAIL + 1))
    fi
    TOTAL=$((TOTAL + 1))
fi

# Create a simple spec-based test for common flags
echo "" | tee -a "$LOG_FILE"
echo "Running inline flag tests..." | tee -a "$LOG_FILE"

# Function to run inline tests
run_inline_test() {
    local flag="$1"
    local input="$2"
    local expected="$3"
    local description="$4"
    
    TOTAL=$((TOTAL + 1))
    actual=$(echo "$input" | $PIPE "$flag" 2>&1)
    
    if [ "$actual" = "$expected" ]; then
        echo -e "${GREEN}PASS${NC}: $description ($flag)" | tee -a "$LOG_FILE"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}FAIL${NC}: $description ($flag)" | tee -a "$LOG_FILE"
        echo "  Expected: $expected" | tee -a "$LOG_FILE"
        echo "  Actual:   $actual" | tee -a "$LOG_FILE"
        FAIL=$((FAIL + 1))
    fi
}

# Test various flags - use printf for newlines
run_inline_test "-oc1" "a|b|c" "b" "Extract single column"
run_inline_test "-oc2,c0,c1" "a|b|c" "c|a|b" "Reorder columns"
# Note: -d outputs the deduplicated list
run_inline_test "-h:" "a|b|c" "a:b:c" "Change delimiter"
run_inline_test "-tany" " a | b | c " "a|b|c" "Trim all"
run_inline_test "-nc0" "Hello-World|test" "HELLOWORLD|test" "Normalize"

# For multi-line tests, use a different approach
echo "" | tee -a "$LOG_FILE"
echo "Multi-line tests:" | tee -a "$LOG_FILE"

# Test deduplication
TOTAL=$((TOTAL + 1))
actual=$(printf "a|1\na|2\nb|3" | $PIPE -dc0 2>&1)
expected=$(printf "a|2\nb|3")
if [ "$actual" = "$expected" ]; then
    echo -e "${GREEN}PASS${NC}: Deduplicate (-dc0)" | tee -a "$LOG_FILE"
    PASS=$((PASS + 1))
else
    echo -e "${RED}FAIL${NC}: Deduplicate (-dc0)" | tee -a "$LOG_FILE"
    FAIL=$((FAIL + 1))
fi

# Test grep
TOTAL=$((TOTAL + 1))
actual=$(printf "apple|1\nbanana|2" | $PIPE -gc0:^a 2>&1)
expected="apple|1"
if [ "$actual" = "$expected" ]; then
    echo -e "${GREEN}PASS${NC}: Grep pattern (-gc0:^a)" | tee -a "$LOG_FILE"
    PASS=$((PASS + 1))
else
    echo -e "${RED}FAIL${NC}: Grep pattern (-gc0:^a)" | tee -a "$LOG_FILE"
    FAIL=$((FAIL + 1))
fi

# Test inverse grep
TOTAL=$((TOTAL + 1))
actual=$(printf "apple|1\nbanana|2" | $PIPE -Gc0:^a 2>&1)
expected="banana|2"
if [ "$actual" = "$expected" ]; then
    echo -e "${GREEN}PASS${NC}: Inverse grep (-Gc0:^a)" | tee -a "$LOG_FILE"
    PASS=$((PASS + 1))
else
    echo -e "${RED}FAIL${NC}: Inverse grep (-Gc0:^a)" | tee -a "$LOG_FILE"
    FAIL=$((FAIL + 1))
fi

# Summary
echo "" | tee -a "$LOG_FILE"
echo "=== Test Summary ===" | tee -a "$LOG_FILE"
echo "Total tests: $TOTAL" | tee -a "$LOG_FILE"
echo -e "${GREEN}Passed: $PASS${NC}" | tee -a "$LOG_FILE"
echo -e "${RED}Failed: $FAIL${NC}" | tee -a "$LOG_FILE"
echo "Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"

# Cleanup
rm -f basic-tests.out

# Exit with appropriate code
if [ $FAIL -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}$FAIL tests failed.${NC}"
    exit 1
fi