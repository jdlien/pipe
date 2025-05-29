# Phase 1: Core Infrastructure

**Note: This is historical documentation from the completed modularization project (May 2025).**

--- Tasks

## Objective
Create the foundational modules that all other modules will depend on.

## Module: Pipe::Core

### Tasks

1. **Create Module Structure**
   ```bash
   mkdir -p lib/Pipe
   touch lib/Pipe/Core.pm
   ```

2. **Move Constants**
   - [x] Extract all global constants from pipe.pl:
     - `$VERSION`
     - `$TRUE` / `$FALSE`
     - `$DELIMITER` / `$SUB_DELIMITER` / `$QUOTED_DELIMITER`
     - All `$KEYWORD_*` constants
     - `$MAX_LINE`
     - Default values (buffer sizes, precision, etc.)

3. **Move Basic Utilities**
   - [x] `trim()` - Remove whitespace
   - [x] `normalize()` - Text normalization
   - [x] `get_number_format()` - Number formatting
   - [ ] `parse_line_ranges()` - Line range parsing (moved to Pipe::Utils)
   - [x] Error handling utilities

4. **Create Export Lists**
   ```perl
   our @EXPORT = qw(
       $TRUE $FALSE $DELIMITER
       trim normalize
   );
   
   our @EXPORT_OK = qw(
       $VERSION $MAX_LINE
       get_number_format parse_line_ranges
   );
   ```

## Module: Pipe::Context

### Tasks

1. **Design Context Object**
   - [x] Identify all global state variables
   - [x] Group related state variables
   - [x] Design accessor methods

2. **Create Context Structure**
   ```perl
   package Pipe::Context;
   
   sub new {
       my $class = shift;
       my $self = {
           # I/O State
           delimiter => '|',
           input_delimiter => '|',
           output_delimiter => '|',
           
           # Column Operations
           count_columns => [],
           sum_columns => [],
           avg_columns => [],
           width_columns => [],
           
           # Accumulators
           count_ref => {},
           sum_ref => {},
           avg_ref => {},
           avg_count => {},
           
           # Processing State
           line_number => 0,
           is_header => 0,
           
           # Options
           options => {},
       };
       return bless $self, $class;
   }
   ```

3. **Implement State Management Methods**
   - [x] Getters/setters for all state
   - [x] Reset methods for accumulators
   - [x] State validation methods

## Integration Tasks

1. **Update pipe.pl**
   - [x] Add `use lib 'lib';`
   - [x] Add `use Pipe::Core;`
   - [x] Add `use Pipe::Context;`
   - [x] Replace constants with imported versions
   - [x] Replace utility functions with module calls

2. **Testing**
   - [x] Create t/01-core.t
   - [x] Create t/02-context.t
   - [x] Test all moved functions
   - [x] Verify constants are accessible

3. **Documentation**
   - [x] Add POD documentation to modules
   - [x] Update CLAUDE.md with module information
   - [x] Document any API changes

## Example Implementation

### lib/Pipe/Core.pm
```perl
package Pipe::Core;

use strict;
use warnings;
use utf8;
use Exporter 'import';

our $VERSION = '2.03.02';

# Constants
our $TRUE = 0;
our $FALSE = 1;
our $DELIMITER = '|';
our $SUB_DELIMITER = '___PIPE___';
our $QUOTED_DELIMITER = '___QUOTED_DELIMITER___';
our $MAX_LINE = 100000000;

# Keywords
our $KEYWORD_ANY = 'any';
our $KEYWORD_REMAINING = 'remaining';
our $KEYWORD_CONTINUE = 'continue';
our $KEYWORD_LAST = 'last';
our $KEYWORD_REVERSE = 'reverse';
our $KEYWORD_EXCLUDE = 'exclude';
our $KEYWORD_NUM_COLS = 'num_cols';

# Exports
our @EXPORT = qw(
    $TRUE $FALSE $DELIMITER
    $KEYWORD_ANY $KEYWORD_REMAINING
    trim normalize
);

our @EXPORT_OK = qw(
    $VERSION $MAX_LINE
    $SUB_DELIMITER $QUOTED_DELIMITER
    $KEYWORD_CONTINUE $KEYWORD_LAST
    $KEYWORD_REVERSE $KEYWORD_EXCLUDE
    $KEYWORD_NUM_COLS
    get_number_format parse_line_ranges
);

# Trim function to remove white space
sub trim {
    my $string = shift;
    my $chop_count = 0;
    $chop_count = shift if (@_);
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    $string = substr($string, 0, $chop_count) if ($chop_count);
    return $string;
}

# Normalize text
sub normalize {
    my $line = shift;
    $line =~ s/\W+//g;
    # Note: Case handling depends on -I flag
    # This will need to be handled via context
    return uc $line;
}

1;
```

## Validation Checklist

- [x] All constants are accessible
- [x] Basic utilities work correctly
- [x] No performance regression
- [x] All existing tests pass
- [x] New tests provide good coverage
- [x] Documentation is complete