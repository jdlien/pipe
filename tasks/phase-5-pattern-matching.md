# Phase 5: Pattern Matching Module

## Objective
Create Pipe::Match module to handle all pattern matching and filtering operations, continuing the modularization of pipe.pl.

## Current Status: PLANNING
- **Start Date:** TBD
- **Target Completion:** TBD
- **Estimated Line Reduction:** 400+ lines

## Background
Following successful completion of Phase 4 (Text Processing), pipe.pl has been reduced from 4,332 lines to 2,884 lines (33.4% reduction). Phase 5 targets pattern matching and filtering functions.

## Phase 5 Goals
1. Create comprehensive Pipe::Match module for pattern matching operations
2. Target 400+ line reduction from pipe.pl
3. Maintain 100% backward compatibility
4. Improve code organization for filtering logic
5. Enable easier testing of pattern matching operations

## Functions to Modularize

### Core Pattern Matching Functions
1. `is_match()` - Primary pattern matching logic
2. `is_not_match()` - Inverse pattern matching
3. `is_empty()` - Empty field detection
4. `is_not_empty()` - Non-empty field detection
5. `contain_same_value()` - Value comparison across columns
6. `test_condition()` - Conditional testing framework
7. `test_condition_cmp()` - Comparison-based conditions

### Supporting Functions
- Regex compilation and caching
- Pattern validation utilities
- Match result processing
- Filter combination logic

## Implementation Plan

### Step 1: Analysis
- [ ] Identify all pattern matching functions in pipe.pl
- [ ] Document function signatures and dependencies
- [ ] Estimate line counts for each function
- [ ] Plan module organization

### Step 2: Module Creation
- [ ] Create lib/Pipe/Match.pm
- [ ] Implement module structure with proper exports
- [ ] Add comprehensive POD documentation
- [ ] Move functions maintaining exact behavior

### Step 3: Integration
- [ ] Update pipe.pl to use Pipe::Match functions
- [ ] Replace function calls with module calls
- [ ] Remove duplicate functions from pipe.pl
- [ ] Update global variable access patterns

### Step 4: Testing
- [ ] Test matching operations (-g, -G, -b, -B, -C, -z, -Z)
- [ ] Verify regex patterns work correctly
- [ ] Test complex filter combinations
- [ ] Validate case-sensitive/insensitive matching

## Command-Line Flags Affected
- `-g` - Pattern matching with regex
- `-G` - Inverse pattern matching
- `-b` - Field equality comparison
- `-B` - Field inequality comparison
- `-C` - Conditional comparisons (gt, lt, eq, etc.)
- `-z` - Suppress lines with empty columns
- `-Z` - Show lines with empty columns
- `-I` - Case-insensitive matching modifier

## Technical Approach
- Use `main::` package prefix for global variable access
- Maintain original function signatures
- Export all functions using Exporter
- Add comprehensive error handling
- Include detailed POD documentation
- Optimize regex compilation for performance

## Success Criteria
- [ ] All pattern matching operations function correctly
- [ ] 300+ lines removed from pipe.pl
- [ ] Module under 500 lines
- [ ] No performance degradation
- [ ] 100% backward compatibility maintained

## Risks and Mitigation
1. **Regex compilation performance** - Cache compiled patterns
2. **Complex condition logic** - Test thoroughly with edge cases
3. **Global variable dependencies** - Use main:: prefix consistently
4. **Pattern escaping issues** - Handle special characters correctly

## Current Progress
- [ ] Phase 5 planning
- [ ] Function analysis
- [ ] Module implementation
- [ ] Integration and testing

## Next Steps
1. Analyze pattern matching functions in current pipe.pl
2. Create Pipe::Match module structure
3. Move functions systematically
4. Test and validate all matching operations

## Dependencies
- Requires completion of Phases 1-4 ✅
- Uses Pipe::Core for constants and utilities
- May interact with Pipe::Text for text normalization
- May interact with Pipe::Column for column access

---
**Phase 5 Status:** PLANNING READY TO START