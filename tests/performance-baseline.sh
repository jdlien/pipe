#!/bin/bash
# Performance baseline for pipe.pl
# Run this before and after modularization to ensure no regression

PIPE="../pipe.pl"
RESULTS_FILE="performance-baseline.txt"
TEMP_FILE="/tmp/pipe-test-data.txt"

echo "=== Pipe.pl Performance Baseline ===" | tee "$RESULTS_FILE"
echo "Date: $(date)" | tee -a "$RESULTS_FILE"
echo "" | tee -a "$RESULTS_FILE"

# Function to measure time
measure_time() {
    local description="$1"
    local command="$2"
    
    echo "Test: $description" | tee -a "$RESULTS_FILE"
    
    # Run 3 times and average
    total_time=0
    for i in 1 2 3; do
        start_time=$(perl -MTime::HiRes=time -e 'print time')
        eval "$command" > /dev/null 2>&1
        end_time=$(perl -MTime::HiRes=time -e 'print time')
        elapsed=$(perl -e "print $end_time - $start_time")
        total_time=$(perl -e "print $total_time + $elapsed")
        echo "  Run $i: ${elapsed}s" | tee -a "$RESULTS_FILE"
    done
    
    avg_time=$(perl -e "print $total_time / 3")
    echo "  Average: ${avg_time}s" | tee -a "$RESULTS_FILE"
    echo "" | tee -a "$RESULTS_FILE"
}

# Generate test data
echo "Generating test data..." | tee -a "$RESULTS_FILE"

# Small file (1000 lines)
perl -e 'for (1..1000) { print join("|", $_, "name$_", rand(100), "data$_", localtime($_)), "\n" }' > "${TEMP_FILE}.small"

# Medium file (100,000 lines)
perl -e 'for (1..100000) { print join("|", $_, "name$_", rand(100), "data$_", localtime($_)), "\n" }' > "${TEMP_FILE}.medium"

# Large file (1,000,000 lines)
perl -e 'for (1..1000000) { print join("|", $_, "name$_", rand(100), "data$_", localtime($_)), "\n" }' > "${TEMP_FILE}.large"

echo "" | tee -a "$RESULTS_FILE"

# Test 1: Simple pass-through
measure_time "Simple pass-through (1K lines)" "cat ${TEMP_FILE}.small | $PIPE"
measure_time "Simple pass-through (100K lines)" "cat ${TEMP_FILE}.medium | $PIPE"
measure_time "Simple pass-through (1M lines)" "cat ${TEMP_FILE}.large | $PIPE"

# Test 2: Column operations
measure_time "Column reorder (100K lines)" "cat ${TEMP_FILE}.medium | $PIPE -oc2,c0,c1"
measure_time "Column reorder (1M lines)" "cat ${TEMP_FILE}.large | $PIPE -oc2,c0,c1"

# Test 3: Pattern matching
measure_time "Grep operation (100K lines)" "cat ${TEMP_FILE}.medium | $PIPE -gc1:name"
measure_time "Grep operation (1M lines)" "cat ${TEMP_FILE}.large | $PIPE -gc1:name"

# Test 4: Mathematical operations
measure_time "Sum operation (100K lines)" "cat ${TEMP_FILE}.medium | $PIPE -ac2"
measure_time "Sum operation (1M lines)" "cat ${TEMP_FILE}.large | $PIPE -ac2"

# Test 5: Deduplication
measure_time "Dedup operation (10K lines)" "head -10000 ${TEMP_FILE}.medium | $PIPE -dc1"

# Test 6: Sorting
measure_time "Sort operation (10K lines)" "head -10000 ${TEMP_FILE}.medium | $PIPE -sc0"

# Test 7: Complex operation (multiple flags)
measure_time "Complex operation (100K lines)" "cat ${TEMP_FILE}.medium | $PIPE -gc1:name -oc2,c0 -tany"

# Memory usage test
echo "Memory Usage Test:" | tee -a "$RESULTS_FILE"
if command -v /usr/bin/time >/dev/null 2>&1; then
    echo "  Processing 1M lines:" | tee -a "$RESULTS_FILE"
    /usr/bin/time -l sh -c "cat ${TEMP_FILE}.large | $PIPE -ac2 > /dev/null 2>&1" 2>&1 | grep -E "(maximum resident|elapsed)" | tee -a "$RESULTS_FILE"
else
    echo "  Memory measurement not available on this system" | tee -a "$RESULTS_FILE"
fi

# Cleanup
rm -f ${TEMP_FILE}*

echo "" | tee -a "$RESULTS_FILE"
echo "Performance baseline saved to: $RESULTS_FILE" | tee -a "$RESULTS_FILE"