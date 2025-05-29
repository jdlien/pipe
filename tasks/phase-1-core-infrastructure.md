# Phase 1: Core Infrastructure Tasks

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
   - [ ] Extract all global constants from pipe.pl:
     - `$VERSION`
     - `$TRUE` / `$FALSE`
     - `$DELIMITER` / `$SUB_DELIMITER` / `$QUOTED_DELIMITER`
     - All `$KEYWORD_*` constants
     - `$MAX_LINE`
     - Default values (buffer sizes, precision, etc.)

3. **Move Basic Utilities**
   - [ ] `trim()` - Remove whitespace
   - [ ] `normalize()` - Text normalization
   - [ ] `get_number_format()` - Number formatting
   - [ ] `parse_line_ranges()` - Line range parsing
   - [ ] Error handling utilities

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
   - [ ] Identify all global state variables
   - [ ] Group related state variables
   - [ ] Design accessor methods

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
   - [ ] Getters/setters for all state
   - [ ] Reset methods for accumulators
   - [ ] State validation methods

## Integration Tasks

1. **Update pipe.pl**
   - [ ] Add `use lib 'lib';`
   - [ ] Add `use Pipe::Core;`
   - [ ] Add `use Pipe::Context;`
   - [ ] Replace constants with imported versions
   - [ ] Replace utility functions with module calls

2. **Testing**
   - [ ] Create t/01-core.t
   - [ ] Create t/02-context.t
   - [ ] Test all moved functions
   - [ ] Verify constants are accessible

3. **Documentation**
   - [ ] Add POD documentation to modules
   - [ ] Update CLAUDE.md with module information
   - [ ] Document any API changes

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

- [ ] All constants are accessible
- [ ] Basic utilities work correctly
- [ ] No performance regression
- [ ] All existing tests pass
- [ ] New tests provide good coverage
- [ ] Documentation is complete