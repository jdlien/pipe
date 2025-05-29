# Pipe.pl Baseline Test Results

This document captures the baseline behavior of pipe.pl before modularization.
Generated: 2025-05-29

## Test Environment
- pipe.pl version: 2.03.02
- Perl version: (system default)
- Platform: macOS

## Core Functionality Tests

### 1. Basic I/O
```bash
echo "a|b|c" | pipe.pl
# Output: a|b|c
```

### 2. Column Operations (-o)
```bash
echo "a|b|c" | pipe.pl -oc2,c0
# Output: c|a
```

### 3. Text Trimming (-t)
```bash
echo "  a  |  b  |  c  " | pipe.pl -tany
# Output: a|b|c
```

### 4. Pattern Matching (-g)
```bash
echo "a|b|c" | pipe.pl -gc1:b
# Output: a|b|c

echo "a|b|c" | pipe.pl -gc1:x
# Output: (empty)
```

### 5. Mathematical Operations (-a, -c)
```bash
echo -e "1|apple\n2|banana\n3|cherry" | pipe.pl -ac0
# Output includes both data and summary:
==       sum
 c0:       6
1|apple
2|banana
3|cherry
```

### 6. Deduplication (-d)
```bash
echo -e "a|1\na|2\nb|3" | pipe.pl -dc0
# Output: 
a|2
b|3
# Note: Keeps the last occurrence
```

### 7. Case Conversion (-e)
```bash
echo "hello|world" | pipe.pl -eany:uc
# Output: HELLO|WORLD
```

### 8. Delimiter Change (-h)
```bash
echo "a|b|c" | pipe.pl -h:
# Output: a:b:c
```

### 9. Normalization (-n)
```bash
echo "Hello World!|test" | pipe.pl -nc0
# Output: HELLOWORLD|test
```

### 10. Substring Operations (-S)
```bash
echo "12345|abcde" | pipe.pl -Sc0:0-2
# Output: 12|abcde
# Note: 0-2 means positions 0 and 1
```

### 11. Line Numbers (-A)
```bash
echo -e "a|b\nc|d" | pipe.pl -A
# Output:
  1 a|b
  2 c|d
```

## Summary Statistics Behavior

When using summary flags (-a, -c, -v, -w), pipe.pl outputs:
1. Summary header and statistics to STDERR
2. Original data to STDOUT
3. Both are displayed together in normal usage

## Important Behaviors

1. **Deduplication Order**: When using -d, the last occurrence of a duplicate is kept
2. **Column Indexing**: Columns are 0-based (c0 is first column)
3. **Line Numbers**: Start at 1 with -A flag
4. **Substring Ranges**: In -S, ranges like "0-2" include positions 0 and 1
5. **Summary Output**: Mathematical operations output both summary and data

## Performance Baseline

(To be measured before modularization)
- Time to process 1MB file: TBD
- Time to process 100MB file: TBD
- Memory usage baseline: TBD

## Error Handling

1. Invalid column references are ignored
2. Non-numeric data in math operations is skipped
3. Missing columns are treated as empty strings