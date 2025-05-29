#!/bin/bash
# Basic test runner for pipe.pl
# This script runs fundamental tests to ensure pipe.pl is working correctly

PIPE="../pipe.pl"
PASS=0
FAIL=0
TOTAL=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test function
run_test() {
    local test_name="$1"
    local input="$2"
    local expected="$3"
    local flags="$4"
    
    TOTAL=$((TOTAL + 1))
    
    # Run the test
    actual=$(echo "$input" | $PIPE $flags 2>&1)
    
    if [ "$actual" = "$expected" ]; then
        echo -e "${GREEN}PASS${NC}: $test_name"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}FAIL${NC}: $test_name"
        echo "  Input:    $input"
        echo "  Flags:    $flags"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        FAIL=$((FAIL + 1))
    fi
}

echo "Running basic tests for pipe.pl..."
echo "================================="

# Test 1: Basic pipe handling
run_test "Basic pipe handling" "a|b|c" "a|b|c" ""

# Test 2: Column ordering (-o)
run_test "Column ordering" "a|b|c" "c|a" "-oc2,c0"

# Test 3: Trim whitespace (-t)
run_test "Trim whitespace" "  a  |  b  |  c  " "a|b|c" "-tany"

# Test 4: Grep column (-g)
run_test "Grep column match" "a|b|c" "a|b|c" "-gc1:b"

# Test 5: Grep column no match
run_test "Grep column no match" "a|b|c" "" "-gc1:x"

# Test 6: Sum column (-a) - Note: -a outputs data AND summary
input="1|apple
2|banana
3|cherry"
expected="==       sum
 c0:       6
1|apple
2|banana
3|cherry"
run_test "Sum numeric column" "$input" "$expected" "-ac0"

# Test 7: Count non-empty (-c) - Note: -c outputs data AND summary
input="1|apple
|banana
3|"
expected="==     count
 c0:       2
 c1:       2
1|apple
|banana
3|"
run_test "Count non-empty" "$input" "$expected" "-cc0,c1"

# Test 8: Uppercase (-e)
run_test "Uppercase conversion" "hello|world" "HELLO|WORLD" "-eany:uc"

# Test 9: Deduplication (-d) - Note: order may vary
input="a|1
b|2
a|3"
# The last occurrence of 'a' is kept
run_test "Deduplication" "$input" "a|3
b|2" "-dc0"

# Test 10: Change delimiter (-h)
run_test "Change delimiter" "a|b|c" "a:b:c" "-h:"

# Test 11: Multiple columns operation
run_test "Multiple column trim" "  a  |  b  |  c  " "a|  b  |c" "-tc0,c2"

# Test 12: Normalize (-n)
run_test "Normalize column" "Hello World!|test" "HELLOWORLD|test" "-nc0"

# Test 13: Substring (-S) - Note: 0-2 means positions 0 and 1
run_test "Substring operation" "12345|abcde" "12|abcde" "-Sc0:0-2"

# Test 14: Line numbers (-A) - Note: format is different
input="a|b
c|d"
expected="  1 a|b
  2 c|d"
run_test "Line numbers" "$input" "$expected" "-A"

# Test 15: Usage/help check (-x shows usage)
# Note: The usage might go to STDERR, so we need to capture it properly
if $PIPE -x 2>&1 | grep -q "usage:" ; then
    echo -e "${GREEN}PASS${NC}: Usage/help accessible (-x)"
    PASS=$((PASS + 1))
else
    echo -e "${RED}FAIL${NC}: Usage/help not accessible (-x)"
    FAIL=$((FAIL + 1))
fi
TOTAL=$((TOTAL + 1))

echo "================================="
echo "Test Summary:"
echo "  Total: $TOTAL"
echo -e "  ${GREEN}Pass: $PASS${NC}"
echo -e "  ${RED}Fail: $FAIL${NC}"

if [ $FAIL -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed.${NC}"
    exit 1
fi