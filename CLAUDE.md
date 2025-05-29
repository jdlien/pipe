# Pipe.pl Project Notes

## Overview

Pipe.pl is a Swiss Army knife tool for text processing, particularly for pipe-delimited files. It's written in Perl and designed for system administrators who need to manipulate data on the command line without advanced knowledge of awk, Bash, or Pandas.

Readme.md is the documentation for this project and serves as a detailed specification for the project.

## Project Structure

```
pipe/
├── pipe.pl          # Main application (single Perl script, ~5000+ lines)
├── LICENSE
├── Makefile         # Build and test orchestration
├── Readme.md        # Comprehensive documentation
└── tests/           # Test framework
    ├── Makefile
    ├── gen_spec.sh  # Generate test specifications
    ├── gen_test.sh  # Generate test scripts from specs
    ├── pipeline.sh
    ├── spec.awk     # AWK script for spec processing
    └── template.sh  # Template for test scripts
```

## Key Programming Practices

### Task Management

- Tasks are managed as .md files in the `tasks/` directory.
- As tasks are completed, update the relevant document to note the task status (complete, in progress, etc).
- Note any issues or blockers in the task document.
- Update the next-tasks.md file to reflect the current status of the tasks. This is important for when context gets cleared to instruct Claude and LLMs to continue working on the tasks.

### Version Control

- Before making significant changes, make atomic commits explaining what has changed.
- After making significant changes, make commits with thorough descriptions of the changes.

### Important Considerations

- **No Dependencies**: This project is written in Perl and does not make use of additional libraries or dependencies for production. If at all possible, avoid adding dependencies to this project. Only development dependencies are allowed.
- **Perl v5 Compatibility**: This project must maintain compatibility with Perl v5.
- **Test-Driven Development**: This project is written in a test-driven development style. Ensure that, for significant feature changes, a test is written first. Iterate on tests until the feature is implemented.
- **Documentation**: This project is documented in Readme.md. Ensure that any changes to the code are reflected in the documentation. Avoid removing existing documentation unless it is DEFINITELY no longer relevant.
- **Preserve Existing API**: This project is a mature tool with a large user base. Any changes to the API must be backwards compatible. All command-line flags and options must be preserved.

### Testing

#### Shell-based tests (original)

- Located in `tests/` directory
- Makefile is used to generate tests from the Readme.md file:
  - `make build` will generate the test files
  - After that, `make test` will run the tests
- Custom test runners:
  - `tests/run-basic-tests.sh` - Core functionality tests
  - `tests/run-all-tests.sh` - Comprehensive test suite
  - `tests/performance-baseline.sh` - Performance benchmarks

#### Perl unit tests (Test::More)

- Located in `t/` directory
- Run with `prove -v t/` or individual test files
- Test files:
  - `00-load.t` - Basic infrastructure test
  - `01-core.t` - Template for Pipe::Core tests
  - `02-context.t` - Template for Pipe::Context tests
  - `99-integration.t` - Integration tests for pipe.pl
- Follows Perl testing best practices

#### Master test runner

- `run-tests.pl` - Runs both Perl and shell tests
- Provides unified test results

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

## Build and Test

```bash
# Run all tests
cd tests && make all

# Generate new test
./gen_test.sh --spec-file=spec-x.test --force

# Build/install
chmod +x pipe.pl
# Add to PATH as needed
```
