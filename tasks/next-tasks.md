# Next Tasks for Pipe.pl Project

## Current Focus: Pipe.pl Main Script Coverage Improvement

This document tracks the ongoing effort to improve test coverage for the main pipe.pl script, which currently has very low coverage metrics.

## Current Status

### Test Infrastructure
- **Status**: ✅ **EXCELLENT** - Fully functional and AI-friendly 
- **Test Command**: `./run-tests.pl -a` (AI-friendly mode)
- **Coverage Command**: `./run-coverage.pl` (generates HTML reports)
- **All Tests Passing**: 170+ tests (155+ Perl unit + 15 shell integration)

### Current Code Coverage Summary

| Module          | Statement | Branch | Condition | Subroutine | POD     | Total  | Status       |
| --------------- | --------- | ------ | --------- | ---------- | ------- | ------ | ------------ |
| `Pipe::Core`    | **100.0%** | **100.0%** | **100.0%** | **100.0%** | **100.0%** | **100.0%** | **✅ PERFECT** |
| `Pipe::Context` | **100.0%** | **100.0%** | **n/a**     | **100.0%** | **100.0%** | **100.0%** | **✅ PERFECT** |
| `Pipe::IO`      | **97.2%**  | **91.1%**  | **82.1%**   | **100.0%** | **100.0%** | **94.2%**  | **✅ EXCELLENT** |
| `Pipe::Data`    | **95.2%**  | **92.3%**  | **33.3%**   | **100.0%** | **100.0%** | **93.3%**  | **✅ EXCELLENT** |
| `Pipe::Text`    | **92.7%**  | **84.1%**  | **83.7%**   | **100.0%** | **100.0%** | **89.4%**  | **✅ EXCELLENT** |
| `Pipe::Math`    | **93.8%**  | **89.0%**  | **72.2%**   | **100.0%** | **100.0%** | **91.7%**  | **✅ EXCELLENT** |
| `Pipe::Utils`   | **86.5%**  | **85.0%**  | **66.6%**   | **100.0%** | **100.0%** | **84.4%**  | **✅ GOOD** |
| `Pipe::Column`  | **86.3%**  | **77.1%**  | **60.0%**   | **100.0%** | **100.0%** | **82.8%**  | **✅ GOOD** |
| `Pipe::Match`   | **89.1%**  | **83.3%**  | **65.2%**   | **100.0%** | **100.0%** | **84.6%**  | **✅ GOOD** |
| **pipe.pl**     | **58.0%**  | **31.9%**  | **14.7%**   | **95.4%**  | **n/a**     | **45.7%**  | **❌ POOR** |

**Overall Coverage**: 83.3% statement, 70.6% branch, 57.6% condition, 99.3% subroutine, 100.0% POD

## CRITICAL ISSUE: Pipe.pl Main Script Coverage

### Problem Analysis

The main `pipe.pl` script has **extremely poor coverage** compared to the modularized library code:

- **Statement Coverage**: Only 58.0% (335/577 statements covered)
- **Branch Coverage**: Only 31.9% (117/366 branches covered) 
- **Condition Coverage**: Only 14.7% (15/102 conditions covered)
- **Total Coverage**: Only 45.7% (488/1067 total coverage points)

### Root Cause Analysis

1. **Limited Test Approach**: Current `t/10-pipe-script.t` only tests basic functionality via command-line execution
2. **Integration vs Unit Testing**: pipe.pl contains ~577 statements that need comprehensive testing
3. **Complex Command-Line Interface**: Many flags and option combinations are not exercised
4. **Error Handling Paths**: Numerous error conditions and edge cases are untested
5. **Interactive Features**: Some functionality may require more sophisticated test setup

## IMMEDIATE PRIORITY: Comprehensive Pipe.pl Coverage Plan

### Phase 1: Coverage Gap Analysis (NEXT)

**Goal**: Identify specific uncovered code paths in pipe.pl

**Actions**:
1. **Generate Detailed Coverage Report**: 
   ```bash
   ./run-coverage.pl
   open cover_db/coverage.html
   # Focus on pipe-pl.html detailed report
   ```

2. **JSON Analysis for Specific Gaps**:
   ```bash
   # Extract pipe.pl specific coverage data
   grep -A50 -B5 '"pipe.pl"' cover_db/cover_detailed.json
   ```

3. **Categorize Uncovered Code**:
   - Command-line argument parsing logic
   - Error handling and validation paths  
   - Complex feature combinations
   - Edge cases and boundary conditions
   - Debug and verbose output paths

### Phase 2: Enhanced Integration Testing (PRIORITY)

**Goal**: Create comprehensive tests that exercise pipe.pl functionality systematically

**Strategy**:
1. **Expand t/10-pipe-script.t** with systematic coverage:
   - Test all command-line flags individually
   - Test flag combinations and interactions
   - Test error conditions and invalid inputs
   - Test edge cases and boundary conditions

2. **Create Test Data Scenarios**:
   - Empty files, single line files, large files
   - Various delimiters and formats
   - Edge case data (unicode, special characters)
   - Invalid/malformed input data

3. **Flag Coverage Matrix**:
   ```bash
   # Systematically test every documented flag
   -A, -B, -C, -D, -F, -G, -H, -I, -J, -L, -M, -N, -O, -P, -Q, -R, -S, -T, -U, -V, -W, -X, -Y, -Z
   -a, -b, -c, -d, -e, -f, -g, -h, -i, -j, -k, -l, -m, -n, -o, -p, -q, -r, -s, -t, -u, -v, -w, -x, -y, -z
   ```

### Phase 3: Error Path and Edge Case Testing

**Goal**: Exercise error handling, validation, and edge case logic

**Test Categories**:
1. **Invalid Arguments**: Test malformed flag combinations
2. **File I/O Errors**: Test with missing files, permission issues
3. **Data Validation**: Test with invalid column specifications
4. **Memory/Performance**: Test with large datasets
5. **Feature Interactions**: Test complex flag combinations

### Phase 4: Advanced Testing Techniques

**Goal**: Reach remaining uncovered code paths using advanced testing methods

**Techniques**:
1. **Direct Function Testing**: Test pipe.pl functions directly (if possible)
2. **Mocked Input/Output**: Control STDIN/STDOUT/STDERR for comprehensive testing
3. **Environment Variable Testing**: Test various environment configurations
4. **Subprocess Testing**: Test pipe.pl as subprocess with controlled inputs

## Implementation Plan

### Week 1: Coverage Analysis and Basic Enhancement
- [ ] Generate and analyze detailed coverage report for pipe.pl
- [ ] Identify top 20 uncovered code paths
- [ ] Enhance t/10-pipe-script.t with systematic flag testing
- [ ] Target goal: **65%+ statement coverage**

### Week 2: Comprehensive Integration Testing  
- [ ] Create comprehensive test data scenarios
- [ ] Test all major feature combinations
- [ ] Add error condition and edge case testing
- [ ] Target goal: **75%+ statement coverage**

### Week 3: Advanced Testing and Optimization
- [ ] Implement advanced testing techniques for remaining gaps
- [ ] Focus on branch and condition coverage improvement
- [ ] Optimize test execution and maintainability
- [ ] Target goal: **85%+ statement coverage**

## Success Metrics

**Minimum Acceptable Goals**:
- **Statement Coverage**: 75%+ (currently 58.0%)
- **Branch Coverage**: 50%+ (currently 31.9%) 
- **Condition Coverage**: 25%+ (currently 14.7%)
- **Total Coverage**: 65%+ (currently 45.7%)

**Stretch Goals**:
- **Statement Coverage**: 85%+
- **Branch Coverage**: 65%+
- **Condition Coverage**: 40%+
- **Total Coverage**: 75%+

## Development Workflow

### Quick Commands
```bash
./run-tests.pl -a        # Run all tests (AI-friendly)
./run-coverage.pl        # Generate coverage report
perl t/10-pipe-script.t  # Test specific pipe.pl coverage

# Focus on pipe.pl coverage during development
./run-coverage.pl -q
grep "pipe.pl" cover_db/coverage.html -A5 -B5
```

### Testing Strategy for pipe.pl
1. **Command-line Testing**: Test via subprocess execution (current approach)
2. **Function-level Testing**: Import and test individual functions where possible
3. **Integration Testing**: Test complete workflows and feature interactions
4. **Error Testing**: Test error conditions and edge cases systematically

## Critical Success Factors

1. **Systematic Approach**: Test every command-line flag and combination methodically
2. **Real-world Scenarios**: Use realistic test data and common usage patterns  
3. **Error Coverage**: Don't neglect error handling and validation paths
4. **Maintainable Tests**: Write clear, documented tests that future developers can understand
5. **Performance Consideration**: Ensure tests run efficiently as part of the CI/CD pipeline

## Next Immediate Actions

1. **Run detailed coverage analysis** on pipe.pl
2. **Create comprehensive flag testing matrix** 
3. **Enhance t/10-pipe-script.t** with systematic coverage
4. **Set up coverage monitoring** to track improvement progress

**Priority**: **CRITICAL** - pipe.pl is the main user interface and needs comprehensive testing coverage.