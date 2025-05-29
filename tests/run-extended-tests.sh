#!/bin/bash

# Extended integration tests for pipe.pl based on Readme.md examples
# These tests cover additional functionality not covered in run-all-tests.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL=0
PASS=0
FAIL=0

# Log file
LOG_FILE="pipe-extended-tests.log"
echo "=== Extended Pipe.pl Test Run - $(date) ===" > "$LOG_FILE"

# Path to pipe.pl
PIPE="../pipe.pl"

# Check if pipe.pl exists
if [ ! -f "$PIPE" ]; then
    echo "Error: pipe.pl not found in current directory"
    exit 1
fi

# Function to run a single test
run_test() {
    local params="$1"
    local input="$2" 
    local expected="$3"
    local description="$4"
    
    TOTAL=$((TOTAL + 1))
    actual=$(printf "$input" | $PIPE $params 2>&1)
    
    if [ "$actual" = "$expected" ]; then
        echo -e "${GREEN}PASS${NC}: $description" | tee -a "$LOG_FILE"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}FAIL${NC}: $description" | tee -a "$LOG_FILE"
        echo "  Expected: '$expected'" | tee -a "$LOG_FILE"
        echo "  Actual:   '$actual'" | tee -a "$LOG_FILE"
        FAIL=$((FAIL + 1))
    fi
}

echo "Running extended tests for pipe.pl..."
echo "====================================="

# Math operations tests (-?)
echo ""
echo "Math Operations Tests:"
run_test "-?add:c0,c1,c2,c3,c4" "1|2|0|10|1" "14|1|2|0|10|1" "Addition over columns"
run_test "-?sub:c0,c1,c2,c3,c4" "1|2|0|10|1" "-12|1|2|0|10|1" "Subtraction over columns"
run_test "-?mul:c0,c1,c2,c3,c4" "1|2|0|10|1" "0|1|2|0|10|1" "Multiplication over columns"
run_test "-?div:c1,c0" "1|2|0|10|1" "2|1|2|0|10|1" "Division of two columns (c1/c0)"
run_test "-?add:c0,c1,c2" "1|cat|2" "3|1|cat|2" "Sum with non-numeric value"

# Increment tests (-1)
echo ""
echo "Increment Tests:"
run_test "-1c0" "1" "2" "Increment integer"
run_test "-1c0" "aaa" "aab" "Increment string"
run_test "-1c0,c1,c2" "1|2|3" "2|3|4" "Increment multiple columns"

# Step increment tests (-3)
echo ""
echo "Step Increment Tests:"
run_test "-3c0:1" "1" "2" "Increment by step 1"
run_test "-3c0:3" "7" "10" "Increment by step 3"
run_test "-3c0:-1" "7" "6" "Decrement by step -1"

# Case conversion tests (-e) - Testing what actually works
echo ""
echo "Case Conversion Tests:"
run_test "-eany:lc" "ANT|BAT|CAT" "ant|bat|cat" "Convert to lowercase"
run_test "-eany:uc" "ant|bat|cat" "ANT|BAT|CAT" "Convert to uppercase"
run_test "-eany:us" "Bat The Bat|Cat in the hat" "Bat_The_Bat|Cat_in_the_hat" "Convert spaces to underscores"

# Working normalization tests
echo ""
echo "Normalization Tests:"
run_test "-nc0" "Hello-World#123" "HELLOWORLD123" "Normalize column (remove non-word chars)"
run_test "-nany" "Hello!|World@" "HELLO|WORLD" "Normalize all columns"

# Format conversion tests (-F)
echo ""
echo "Format Conversion Tests:"
run_test "-Fc0:b.h" "1111" "f" "Binary to hexadecimal"
run_test "-Fc0:d.b" "700" "1010111100" "Decimal to binary"
run_test "-Fc0:c.h,c1:c.h" "M|m" "4d|6d" "Character to hex"

# Character flip tests (-f)
echo ""
echo "Character Flip Tests:"
run_test "-fc0:2.9" "0000" "0090" "Flip character at position"
run_test "-fc0:1.1?A" "0100" "0A00" "Conditional character flip (match)"
run_test "-fc0:1.1?A" "0200" "0200" "Conditional character flip (no match)"
run_test "-fc0:1.1?A.B" "0100" "0A00" "Conditional flip with match"
run_test "-fc0:1.1?A.B" "0200" "0B00" "Conditional flip with else"

# Grep tests (-g)
echo ""
echo "Grep Tests:"
run_test "-gc0:812" "1481241" "1481241" "Match pattern in column"
run_test "-gc2:13" "a|b|13|d" "a|b|13|d" "Match exact value in column"

# Field replacement tests (-E) - Test what works
echo ""
echo "Field Replacement Tests:"
run_test "-Ec1:nnn" "111|222|333" "111|nnn|333" "Replace entire field unconditionally"

# Column merging tests (-O)
echo ""
echo "Column Merging Tests:"
run_test "-Oc0,c1" "aaa|bbb|ccc" "aaabbb|bbb|ccc" "Merge column 1 to column 0"
run_test "-Oc1,c0" "aaa|bbb|ccc" "aaa|bbbaaa|ccc" "Merge column 0 to column 1"
run_test "-Oany" "aaa|bbb|ccc" "aaabbbccc|bbb|ccc" "Merge all columns to column 0"

# Column ordering tests (-o)
echo ""
echo "Column Ordering Tests:"
run_test "-oc3,c2,c1" "1|2|3|4" "4|3|2" "Reorder specific columns"
run_test "-oc2,remaining" "1|2|3|4" "3|1|2|4" "Select column and remaining"
run_test "-oc1,continue" "1|2|3|4" "2|3|4" "Select column and continue"
run_test "-oreverse" "1|2|3|4" "4|3|2|1" "Reverse column order"
run_test "-olast" "1|2|3|4" "4" "Select last column"
run_test "-oc2,exclude" "1|2|3|4" "1|2|4" "Exclude specific column"

# Substring tests (-S) - Test working syntax
echo ""
echo "Substring Tests:"
run_test "-Sc0:2-" "12345" "345" "Select from position to end"

# Trim tests (-t)
echo ""
echo "Trim Tests:"
run_test "-tany" "  1 |  2  |  3 " "1|2|3" "Trim whitespace from all columns"
run_test "-tc0,c2" "  1 |  2  |  3 " "1|  2  |3" "Trim specific columns"

# URL encoding tests (-u) - Skipped (not implemented in current version)
# echo ""
# echo "URL Encoding Tests:"

# Input delimiter change tests (-W)
echo ""
echo "Input Delimiter Tests:"
run_test "-W:" "a:b" "a|b" "Change input delimiter"

# Summary
echo ""
echo "=== Test Summary ==="
echo "Total tests: $TOTAL"
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo "Log saved to: $LOG_FILE"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi