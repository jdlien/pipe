# Testing Strategy for Pipe.pl Modularization

**Note: This is historical documentation from the completed modularization project (May 2025).**  
**All tests are now passing with 100% backward compatibility maintained.**

---

## Overview
This document outlines the comprehensive testing approach for the pipe.pl modularization project.

## Testing Principles

1. **No Regression** - Every feature must work exactly as before
2. **Performance Parity** - No significant performance degradation
3. **Test First** - Write tests before modifying code
4. **Automated Testing** - All tests must be automated
5. **Coverage** - Aim for 100% feature coverage

## Test Categories

### 1. Unit Tests (Per Module)
Location: `t/` directory

#### Structure
```
t/
├── 01-core.t           # Pipe::Core tests
├── 02-context.t        # Pipe::Context tests  
├── 03-io.t             # Pipe::IO tests
├── 04-column.t         # Pipe::Column tests
├── 05-text.t           # Pipe::Text tests
├── 06-match.t          # Pipe::Match tests
├── 07-math.t           # Pipe::Math tests
├── 08-data.t           # Pipe::Data tests
├── 09-special.t        # Pipe::Special tests
└── 99-integration.t    # Integration tests
```

#### Example Unit Test
```perl
#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib 'lib';

# Test Pipe::Core
use_ok('Pipe::Core');

# Test constants
is($Pipe::Core::TRUE, 0, 'TRUE constant is 0');
is($Pipe::Core::FALSE, 1, 'FALSE constant is 1');
is($Pipe::Core::DELIMITER, '|', 'Default delimiter is pipe');

# Test trim function
is(Pipe::Core::trim('  hello  '), 'hello', 'trim removes spaces');
is(Pipe::Core::trim('hello'), 'hello', 'trim handles no spaces');
is(Pipe::Core::trim('  hello  ', 3), 'hel', 'trim with length limit');

# Test normalize function
is(Pipe::Core::normalize('Hello World!'), 'HELLOWORLD', 'normalize removes non-word chars and uppercases');

done_testing();
```

### 2. Integration Tests

#### Flag Combination Tests
Test common flag combinations:
```bash
# Test -g with -o
echo "a|b|c" | ./pipe.pl -gc1:b -oc2,c0

# Test -d with -s
echo -e "3|a\n1|b\n2|c" | ./pipe.pl -dc1 -sc0

# Test -C with -i
echo -e "1|2\n3|4\n5|6" | ./pipe.pl -Cc0:gt2 -i -oc1,c0
```

#### Edge Case Tests
- Empty input
- Single column
- Very large number of columns (1000+)
- Unicode/UTF-8 data
- Binary data handling
- Very long lines (1MB+)

### 3. Regression Tests

#### Capture Current Behavior
```bash
#!/bin/bash
# generate-regression-baseline.sh

# Create test data
cat > test_data.txt << 'EOF'
1|apple|red
2|banana|yellow
3|cherry|red
4|date|brown
5|elderberry|purple
EOF

# Run all flags and capture output
for flag in a b c d e f g h i j k l m n o p q r s t u v w x y z; do
    echo "Testing -$flag" > baseline/flag_$flag.out
    timeout 5 ./pipe.pl -$flag < test_data.txt >> baseline/flag_$flag.out 2>&1
done
```

#### Verify Against Baseline
```bash
#!/bin/bash
# verify-regression.sh

for baseline in baseline/*.out; do
    flag=$(basename $baseline .out)
    ./pipe.pl -${flag#flag_} < test_data.txt > current.out 2>&1
    if ! diff -q $baseline current.out; then
        echo "FAIL: $flag differs from baseline"
        diff $baseline current.out
    fi
done
```

### 4. Performance Tests

#### Benchmark Suite
```perl
#!/usr/bin/perl
# benchmark.pl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use File::Temp qw(tempfile);

# Generate test file
my ($fh, $filename) = tempfile();
for (1..1_000_000) {
    print $fh join('|', $_, "data$_", rand(1000), "text$_"), "\n";
}
close $fh;

# Benchmark operations
cmpthese(-3, {
    'original' => sub {
        system("./pipe.pl.original -a c2 < $filename > /dev/null");
    },
    'modular' => sub {
        system("./pipe.pl -a c2 < $filename > /dev/null");
    },
});

unlink $filename;
```

#### Performance Criteria
- No more than 5% slowdown for basic operations
- No more than 10% slowdown for complex operations
- Memory usage should not increase significantly

### 5. Compatibility Tests

#### Shell Script Compatibility
Test that existing scripts continue to work:
```bash
# Test in various shells
for shell in bash sh zsh ksh; do
    $shell -c 'echo "1|2|3" | ./pipe.pl -oc2,c0'
done

# Test with different Perl versions
for perl in perl5.16 perl5.20 perl5.30; do
    $perl pipe.pl -x
done
```

## Test Data Sets

### Standard Test Files
```
tests/data/
├── empty.txt              # Empty file
├── single_line.txt        # One line
├── single_column.txt      # No delimiters
├── standard.txt           # Normal pipe-delimited
├── unicode.txt            # UTF-8 characters
├── large_columns.txt      # 1000+ columns
├── large_rows.txt         # 1M+ rows
└── special_chars.txt      # Special characters
```

### Test Data Generator
```perl
#!/usr/bin/perl
# generate-test-data.pl

# Generate standard test file
open my $fh, '>', 'tests/data/standard.txt';
for my $i (1..1000) {
    print $fh join('|', $i, "name$i", rand(100), localtime($i)), "\n";
}
close $fh;

# Generate unicode test file
open $fh, '>:utf8', 'tests/data/unicode.txt';
print $fh "1|café|10\n";
print $fh "2|naïve|20\n";
print $fh "3|日本語|30\n";
print $fh "4|🎉|40\n";
close $fh;
```

## Continuous Integration

### GitHub Actions Workflow
```yaml
name: Test Pipeline

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        perl: ['5.16', '5.20', '5.30', '5.36']
    
    steps:
    - uses: actions/checkout@v2
    - uses: shogo82148/actions-setup-perl@v1
      with:
        perl-version: ${{ matrix.perl }}
    
    - name: Run tests
      run: |
        cd tests
        make all
        
    - name: Run unit tests
      run: |
        prove -v t/*.t
        
    - name: Check performance
      run: |
        perl benchmark.pl
```

## Test Execution Plan

### Before Each Phase
1. Run full test suite on original
2. Capture baseline metrics
3. Document any known issues

### During Each Phase
1. Write unit tests for module
2. Run tests after each function move
3. Check performance impact
4. Verify integration

### After Each Phase
1. Full regression test
2. Performance comparison
3. Memory usage check
4. Update documentation

## Success Metrics

1. **All existing tests pass** - 100% compatibility
2. **Performance within 5%** - Acceptable overhead
3. **No memory leaks** - Stable memory usage
4. **Cross-platform** - Works on Linux/Mac/BSD
5. **Perl version compatible** - 5.16+