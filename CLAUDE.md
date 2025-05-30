# Pipe.pl Project Notes

## Overview

Pipe.pl is a Swiss Army knife tool for text processing, particularly for pipe-delimited files. It's written in Perl and designed for system administrators who need to manipulate data on the command line without advanced knowledge of awk, Bash, or Pandas.

Readme.md is the documentation for this project and serves as a detailed specification for the project.

## Project Structure

```
pipe/
├── pipe.pl          # Main application (~5000+ lines, partially modularized)
├── lib/Pipe/        # Module library (NEW - modularized code)
│   ├── Core.pm      # Core utilities (trim, normalize, formatting)
│   ├── Context.pm   # State management and configuration
│   ├── IO.pm        # Input/output operations
│   ├── Column.pm    # Column operations (order, merge, etc.)
│   ├── Text.pm      # Text processing (case, masks, padding)
│   ├── Math.pm      # Mathematical operations
│   ├── Match.pm     # Pattern matching and conditions
│   ├── Utils.pm     # Utility functions
│   └── Data.pm      # Data processing (sort, dedup)
├── t/               # Perl unit tests (NEW - Test::More)
├── tests/           # Shell integration tests
├── cpanfile         # Development dependencies (NEW)
├── local/           # Carton dependency cache (ignored by git)
└── run-*.pl         # Test runners (NEW - AI-friendly)
```

## Key Programming Practices

### Task Management

- Tasks are managed as .md files in the `tasks/` directory.
- As tasks are completed, update the relevant document to note the task status (complete, in progress, etc).
- Note any issues or blockers in the task document.
- Update the next-tasks.md file to reflect the current status of the tasks. This is important for when context gets cleared to instruct Claude and LLMs to continue working on the tasks.

### Version Control

- Before making significant changes, make atomic commits explaining what has changed.
- After making significant changes, make commits with descriptions of the changes.

### Important Considerations

- **No Dependencies**: This project is written in Perl and does not make use of additional libraries or dependencies for production. If at all possible, avoid adding dependencies to this project. Only development dependencies are allowed.
- **Perl v5 Compatibility**: This project must maintain compatibility with Perl v5.
- **Test-Driven Development**: This project is written in a test-driven development style. Ensure that, for significant feature changes, a test is written first. Iterate on tests until the feature is implemented.
- **Documentation**: This project is documented in Readme.md. Ensure that any changes to the code are reflected in the documentation. Avoid removing existing documentation unless it is DEFINITELY no longer relevant.
- **Preserve Existing API**: This project is a mature tool with a large user base. Any changes to the API must be backwards compatible. All command-line flags and options must be preserved.

### Testing

**Status**: ✅ Comprehensive test suite with 100% pass rate (170+ tests total)

#### Test Structure
- **Perl unit tests**: `t/` directory - 155+ Test::More tests for all 9 modules
- **Shell integration**: `tests/` directory - 15 core functionality tests  
- **Extended tests**: `tests/run-extended-tests.sh` - 59 tests from Readme examples

#### Key Commands
- `./run-tests.pl -a` - All tests (AI-friendly, single process)
- `./run-coverage.pl` - Code coverage analysis (requires carton)
- `carton exec -- perlcritic lib/` - Static code analysis

#### Development Dependencies (NEW)
- **Setup**: `brew install carton && carton install`
- **Zero production deps**: All dev tools in `local/` (git-ignored)
- **Tools**: Devel::Cover, Perl::Critic, Test::Pod, Perl::Tidy

#### Test Coverage Best Practices

##### Analyzing Coverage
1. **Run coverage**: `./run-coverage.pl -q` generates HTML reports in `cover_db/`
2. **View results**: `open cover_db/coverage.html` for overview
3. **Check specific files**: `cover_db/lib-Pipe-ModuleName-pm.html` shows line-by-line coverage
4. **Coverage types**:
   - **Green (c3)**: Covered code
   - **Red (c0)**: Uncovered code
   - **Yellow (c1/c2)**: Partial coverage

##### Finding Missing Coverage
1. **Branch coverage**: Check `lib-Pipe-ModuleName-pm--branch.html` for untested conditions
2. **Condition coverage**: Check `lib-Pipe-ModuleName-pm--condition.html` for complex boolean logic
3. **Common gaps**:
   - Error handling paths
   - Edge cases in conditionals
   - Regex patterns that never match (check for typos like `&` vs `|`)

##### Writing Comprehensive Tests
1. **Test all branches**: Ensure both true/false paths are tested
2. **Test edge cases**: Empty strings, undef, zero, negative numbers
3. **Test error conditions**: Invalid inputs, missing parameters
4. **Use subtest blocks**: Group related tests for better organization
5. **Coverage goals**: Aim for 90%+ but focus on meaningful coverage

##### Coverage Pitfalls
- **Low coverage numbers**: Check if coverage script is collecting data properly
- **Unreachable code**: Look for regex bugs or impossible conditions
- **Constants/declarations**: Don't need coverage, but Perl counts them

### Perl Conventions

- **Perl version**: Uses `#!/usr/bin/perl -w` with warnings enabled
- **Strict mode**: Always uses `use strict; use warnings;`
- **UTF-8 support**: Uses `use utf8` and sets binmode on STDIN/STDOUT/STDERR
- **Version tracking**: Maintains VERSION variable (`2.03.02`)

### Code Organization

- **Global variables**: Defined at the top with descriptive names in ALL_CAPS
- **Constants**: Uses `$TRUE = 0` and `$FALSE = 1` (Perl convention)
- **Data structures**: Extensive use of hash references for column operations
- **Arrays**: Parallel arrays for column indices and their corresponding hash refs

### Variable Naming

- **Arrays**: Prefixed with @ and named descriptively (e.g., `@COUNT_COLUMNS`, `@SUM_COLUMNS`)
- **Hash refs**: Suffixed with `_ref` (e.g., `$count_ref`, `$sum_ref`)
- **Keywords**: Defined as constants (e.g., `$KEYWORD_ANY`, `$KEYWORD_REMAINING`)

### Function Design

- **Documentation**: Each function has a comment block describing params and return
- **Parameter style**: Uses prototypes (e.g., `sub trim($)`)
- **Return values**: Functions clearly document what they return
- **Error handling**: Uses `print STDERR` for errors and `exit` for fatal errors

### Column Handling

- **Zero-indexed**: Columns are 0-based internally
- **Column syntax**: Uses 'c' prefix in command-line args (e.g., `-gc0:pattern`)
- **Line numbers**: Start at 1 (not 0)

### Testing Approach

- **Test generation**: Uses shell scripts to generate test cases
- **Spec files**: Test specifications drive test generation
- **Makefile integration**: Tests are run through make system
- **Template-based**: Tests are generated from templates

### Command-Line Interface

- **Getopt::Std**: Uses standard Perl getopt for argument parsing
- **Flag style**: Single-letter flags with optional arguments
- **Complex syntax**: Supports sophisticated column specifications with qualifiers

### Error Messages

- **Consistent format**: Uses `** error` or `*** Error` prefixes
- **STDERR output**: All errors go to STDERR
- **Debug mode**: `-D` flag enables debug output

### Performance Considerations

- **Line buffering**: Manages memory with configurable buffer sizes
- **Streaming**: Processes input line-by-line when possible
- **Full-file operations**: Only reads entire file when necessary (sort, tail, etc.)

## Development Guidelines

1. **Maintain backward compatibility** - This is a mature tool with existing users
2. **Follow existing patterns** - Match the established code style
3. **Test thoroughly** - Use the test framework for any changes
4. **Document flags** - Update usage() function and README for new features
5. **Consider performance** - Tool is used on large files
6. **Preserve precision** - Maintain numeric precision in calculations

## Common Operations

- Text manipulation (case conversion, trimming, normalization)
- Column operations (reordering, merging, splitting)
- Data validation and filtering
- Mathematical operations (sum, average, increment)
- Pattern matching with regex
- Deduplication and sorting
- Format conversion (CSV, HTML tables, etc.)

## Current Status (Updated)

**Modularization**: ✅ 9 modules extracted from main script, 100% test coverage
**Testing**: ✅ 170+ tests passing (Perl unit + shell integration + extended)
**Development**: ✅ Modern toolchain with carton, coverage, linting

## Quick Commands

```bash
./run-tests.pl -a        # All tests (AI-friendly)
./run-coverage.pl        # Code coverage  
carton exec -- perlcritic lib/  # Linting
```
