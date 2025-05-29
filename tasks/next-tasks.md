# Next Tasks - Pipe.pl Modularization Project

## 🎯 Current Status - MAJOR MILESTONE ACHIEVED! 
- **Phase 4 COMPLETED:** 727 lines removed (Text Processing)
- **Total Progress:** 1,448 lines removed (33.4% of original)
- **Current Size:** 2,884 lines (down from 4,332)
- **✅ TEST SUITE FIXED:** 99% of tests now passing (92/92 Perl + 14/15 Shell)
- **✅ ALL MAJOR MODULES WORKING:** Column, Text, IO, Core, Context fully functional

## 🚀 Immediate Next Tasks (Priority Order)

### 🎯 READY TO PROCEED: With test suite stable, we can confidently move to Phase 5!

### 1. Phase 5: Pattern Matching Module (HIGH PRIORITY) - READY TO START
**Estimated Impact:** 400+ line reduction
**Estimated Time:** 2-3 days

#### Key Functions to Modularize:
- `is_match()` - Core pattern matching logic
- `is_not_match()` - Inverse pattern matching  
- `is_empty()` / `is_not_empty()` - Empty field detection
- `contain_same_value()` - Cross-column comparison
- `test_condition()` / `test_condition_cmp()` - Conditional testing

#### Command Flags Affected:
- `-g` (pattern matching), `-G` (inverse matching)
- `-b` (equality), `-B` (inequality)  
- `-C` (conditions: gt, lt, eq, etc.)
- `-z` (suppress empty), `-Z` (show empty)

#### Steps:
1. [ ] Analyze pattern matching functions in pipe.pl
2. [ ] Create `lib/Pipe/Match.pm` module structure
3. [ ] Move functions systematically to module
4. [ ] Update function calls to use `Pipe::Match::` namespace
5. [ ] Remove duplicate functions from pipe.pl
6. [ ] Test all matching operations

#### Minor Issue to Address:
- [ ] Fix substring operation (-S flag) - 1 test still failing

### 2. Phase 6: Mathematical Operations (MEDIUM PRIORITY)
**Estimated Impact:** 300+ line reduction
**Estimated Time:** 2-3 days

#### Key Functions to Modularize:
- `count()`, `sum()`, `average()` - Basic math operations
- `width()`, `histogram()` - Analysis functions
- `do_math()`, `do_op()` - Math operation framework
- `delta_previous_line()` - Line comparison math
- `inc_line()`, `inc_line_by_value()` - Increment operations

#### Command Flags Affected:
- `-a` (sum), `-c` (count), `-v` (average)
- `-w` (width), `-6` (histogram)
- `-?` (math operations), `-1`, `-3`, `-4` (increments)

### 3. Phase 7: Data Management (MEDIUM PRIORITY)  
**Estimated Impact:** 200+ line reduction
**Estimated Time:** 2 days

#### Key Functions to Modularize:
- `dedup_list()` - Deduplication logic
- `sort_list()` - Sorting operations
- `randomize_list()` - Random ordering
- Data merging and join operations

#### Command Flags Affected:
- `-d` (dedup), `-s` (sort), `-r` (randomize)
- `-M` (merge files)

## 📋 Supporting Tasks

### Testing & Quality Assurance
- [ ] Create comprehensive test suite for each new module
- [ ] Performance benchmarking on large files (1GB+)
- [ ] Edge case testing for complex flag combinations
- [ ] Regression testing after each phase

### Documentation Updates
- [ ] Update main README.md with new module information
- [ ] Add module-specific documentation
- [ ] Update usage examples
- [ ] Create migration guide for developers

### Integration & Optimization (Future)
- [ ] Main script cleanup and optimization
- [ ] Memory usage analysis
- [ ] Function call optimization
- [ ] Import/export optimization

## 🎯 Success Targets

### Phase 5 Targets:
- [ ] 400+ lines removed from pipe.pl
- [ ] Pipe::Match module under 500 lines
- [ ] All pattern matching tests pass
- [ ] No performance degradation

### Overall Project Targets:
- [ ] Reach 50%+ reduction (2,166 lines or fewer)
- [ ] Complete 6 of 8 planned modules (75%)
- [ ] Maintain 100% backward compatibility
- [ ] Zero external dependencies

## ⚡ Quick Wins Available

### Low-Effort, High-Impact Tasks:
1. **Function Analysis Script:** Create automated tool to identify remaining large functions
2. **Module Size Report:** Track module sizes and ensure they stay under limits
3. **Test Coverage Report:** Identify untested functionality
4. **Performance Baseline:** Establish benchmarks before major changes

### Maintenance Tasks:
1. **Code Style Consistency:** Ensure all modules follow same formatting
2. **POD Documentation:** Complete documentation for all modules
3. **Export Tag Cleanup:** Organize function exports by category
4. **Error Message Consistency:** Standardize error reporting across modules

## 🚀 Recommended Next Steps (This Week)

### Day 1-2: Phase 5 Planning
- [ ] Analyze pattern matching functions in pipe.pl
- [ ] Create detailed function inventory with line counts
- [ ] Design Pipe::Match module structure
- [ ] Plan function signatures and interfaces

### Day 3-4: Phase 5 Implementation  
- [ ] Create Pipe::Match module skeleton
- [ ] Move core matching functions
- [ ] Update function calls in pipe.pl
- [ ] Basic testing and validation

### Day 5: Phase 5 Completion
- [ ] Remove duplicate functions from pipe.pl
- [ ] Comprehensive testing
- [ ] Documentation updates
- [ ] Measure line reduction achieved

---

**Priority:** Start with Phase 5 (Pattern Matching) for maximum impact
**Goal:** Achieve 50%+ total reduction within next 2 weeks
**Timeline:** On track to complete project 2-3 weeks ahead of original estimate