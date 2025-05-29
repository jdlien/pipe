package Pipe::Match;

use strict;
use warnings;
use utf8;
use Exporter 'import';
use Pipe::Core qw($TRUE $FALSE $KEYWORD_ANY $KEYWORD_NUM_COLS trim);
use Pipe::Text qw(normalize);

# Note: This module accesses global variables from the main:: package

our @EXPORT_OK = qw(
    is_match
    is_not_match
    is_empty
    is_not_empty
    contain_same_value
    test_condition
    test_condition_cmp
    _get_range_
);

our %EXPORT_TAGS = (
    patterns => [qw(is_match is_not_match)],
    empty => [qw(is_empty is_not_empty)],
    comparison => [qw(contain_same_value test_condition test_condition_cmp)],
    utilities => [qw(_get_range_)],
    all => [qw(is_match is_not_match is_empty is_not_empty contain_same_value test_condition test_condition_cmp _get_range_)],
);

# Core pattern matching function using Perl regex
# param: Array reference to line columns
# param: Hash reference to regex patterns
# param: Array reference to match columns
# return: 1 if pattern matches, 0 otherwise
sub is_match( $$$ )
{
    my $line           = shift;
    my $regex_hash_ref = shift;  # Can be -X or -Y reference of regular expressions.
    my $match_columns  = shift;
    my $matchCount     = 0;
    if ( @{ $match_columns }[0] =~ m/($KEYWORD_ANY)/i )
    {
        if ( $main::opt{'D'} )
        {
            if ( exists $regex_hash_ref->{ $KEYWORD_ANY } && $regex_hash_ref->{ $KEYWORD_ANY } )
            {
                printf STDERR "regex: '%s' \n", $regex_hash_ref->{ $KEYWORD_ANY };
            }
            else
            {
                printf STDERR "regex: '[unset]' \n";
            }
        }
        my $return_value = 0;
        foreach my $colIndex ( 0 .. scalar( @{ $line } ) -1 )
        {
            if ( $main::opt{'I'} ) # Ignore case on search
            {
                if ( @{ $line }[ $colIndex ] =~ m/($regex_hash_ref->{ $KEYWORD_ANY })/i )
                {
                    if ( $return_value > 0 and $main::opt{'5'} )
                    {
                        printf STDERR "%s%s", $main::DELIMITER, @{ $line }[ $colIndex ];
                    }
                    elsif ( $main::opt{'5'} )
                    {
                        printf STDERR "%s", @{ $line }[ $colIndex ];
                    }
                    $return_value = 1;
                }
            }
            else
            {
                if ( @{ $line }[ $colIndex ] =~ m/($regex_hash_ref->{ $KEYWORD_ANY })/ )
                {
                    if ( $return_value > 0 and $main::opt{'5'} ) # Add a pipe to the output if matched.
                    {
                        printf STDERR "%s%s", $main::DELIMITER, @{ $line }[ $colIndex ];
                    }
                    elsif ( $main::opt{'5'} )
                    {
                        printf STDERR "%s", @{ $line }[ $colIndex ];
                    }
                    $return_value = 1;
                }
            }
            # Quick exit if -g match and -5 not selected.
            last if ( $return_value and ! $main::opt{'5'} );
        }
        printf STDERR "\n" if ( $return_value > 0 and $main::opt{'5'} ); # print return because we found at least 1 match on this line.
        return $return_value;
    }
    foreach my $colIndex ( @{ $match_columns } )
    {
        if ( defined @{ $line }[ $colIndex ] )
        {
            if ( $main::opt{'D'} )
            {
                if ( exists $regex_hash_ref->{ $colIndex } && $regex_hash_ref->{ $colIndex } )
                {
                    printf STDERR "regex: '%s' \n", $regex_hash_ref->{ $colIndex };
                }
                else
                {
                    printf STDERR "regex: '[unset]' \n";
                }
            }
            if ( $regex_hash_ref->{ $colIndex } )
            {
                if ( $main::opt{'I'} ) # Ignore case on search
                {
                    $matchCount++ if ( @{ $line }[ $colIndex ] =~ m/($regex_hash_ref->{ $colIndex })/i );
                }
                else
                {
                    $matchCount++ if ( @{ $line }[ $colIndex ] =~ m/($regex_hash_ref->{ $colIndex })/ );
                }
            }
            else ### If the regex is empty imply the first specified column regex should be tested on
                 ### this column's data.
            {
                if ( $regex_hash_ref->{ @{ $match_columns }[0] } )
                {
                    if ( $main::opt{'I'} ) # Ignore case on search
                    {
                        $matchCount++ if ( @{ $line }[ $colIndex ] =~ m/($regex_hash_ref->{ @{ $match_columns }[0] })/i );
                    }
                    else
                    {
                        $matchCount++ if ( @{ $line }[ $colIndex ] =~ m/($regex_hash_ref->{ @{ $match_columns }[0] })/ );
                    }
                }
                else ### If the first regex is empty then compare the defined columns value to the other columns.
                {
                    if ( $main::opt{'I'} ) # Ignore case on search
                    {
                        $matchCount++ if ( @{ $line }[ $colIndex ] =~ m/(@{$line}[0])/i );
                    }
                    else
                    {
                        $matchCount++ if ( @{ $line }[ $colIndex ] =~ m/(@{$line}[0])/ );
                    }
                }
            }
        }
    }
    # This ensures an AND type operation, that all the requested columns matched. Remove test for count if you want OR.
    return 1 if ( $matchCount == scalar @{ $match_columns } and $matchCount > 0 ); # Count of matches should match count of column match requests.
    return 0;
}

# Inverse pattern matching function
# param: Array reference to line columns
# return: 1 if pattern does NOT match, 0 if it matches
sub is_not_match( $ )
{
    my $line = shift;
    if ( $main::NOT_MATCH_COLUMNS[0] =~ m/($KEYWORD_ANY)/i )
    {
        if ( $main::opt{'D'} )
        {
            if ( exists $main::not_match_ref->{ $KEYWORD_ANY } && $main::not_match_ref->{ $KEYWORD_ANY } )
            {
                printf STDERR "regex: '%s' \n", $main::not_match_ref->{ $KEYWORD_ANY };
            }
            else
            {
                printf STDERR "regex: '[unset]' \n";
            }
        }
        foreach my $colIndex ( 0 .. scalar( @{ $line } ) -1 )
        {
            if ( $main::opt{'I'} ) # Ignore case on search
            {
                return 0 if ( @{ $line }[ $colIndex ] =~ m/($main::not_match_ref->{ $KEYWORD_ANY })/i );
            }
            else
            {
                return 0 if ( @{ $line }[ $colIndex ] =~ m/($main::not_match_ref->{ $KEYWORD_ANY })/ );
            }
        }
        return 1;
    }
    foreach my $colIndex ( @main::NOT_MATCH_COLUMNS )
    {
        if ( defined @{ $line }[ $colIndex ] )
        {
            if ( $main::opt{'D'} )
            {
                if ( exists $main::not_match_ref->{ $colIndex } && $main::not_match_ref->{ $colIndex } )
                {
                    printf STDERR "regex: '%s' \n", $main::not_match_ref->{ $colIndex };
                }
                else
                {
                    printf STDERR "regex: '[unset]' \n";
                }
            }
            if ( $main::not_match_ref->{ $colIndex } )
            {
                if ( $main::opt{'I'} ) # Ignore case on search
                {
                    return 0 if ( @{ $line }[ $colIndex ] =~ m/($main::not_match_ref->{ $colIndex })/i );
                }
                else
                {
                    return 0 if ( @{ $line }[ $colIndex ] =~ m/($main::not_match_ref->{ $colIndex })/ );
                }
            }
            else ### If the regex is empty imply the first specified column regex should be tested on
                 ### this column's data.
            {
                if ( $main::not_match_ref->{ $main::NOT_MATCH_COLUMNS[0] } )
                {
                    if ( $main::opt{'I'} ) # Ignore case on search
                    {
                        return 0 if ( @{ $line }[ $colIndex ] =~ m/($main::not_match_ref->{ $main::NOT_MATCH_COLUMNS[0] })/i );
                    }
                    else
                    {
                        return 0 if ( @{ $line }[ $colIndex ] =~ m/($main::not_match_ref->{ $main::NOT_MATCH_COLUMNS[0] })/ );
                    }
                }
                elsif ( $colIndex > 0 ) ### If the first regex is empty then compare the defined columns value to the other columns. But don't compare the first column with the first column because that always succeeds!
                {
                    if ( $main::opt{'I'} ) # Ignore case on search
                    {
                        return 0 if ( @{ $line }[ $colIndex ] =~ m/(@{$line}[0])/i );
                    }
                    else
                    {
                        printf STDERR "-G '%s' CMP '%s'\n", @{ $line }[ $colIndex ], @{$line}[0]  if ( $main::opt{'D'} );
                        return 0 if ( @{ $line }[ $colIndex ] =~ m/(@{$line}[0])/ );
                    }
                }
            }
        }
    }
    return 1;
}

# Tests if specified columns are empty or undefined
# param: Array reference to line columns
# return: 1 if any specified column is empty, 0 otherwise
sub is_empty( $ )
{
    my $line = shift;
    printf STDERR "EMPTY_LINE: " if ( $main::opt{'D'} );
    foreach my $colIndex ( @main::EMPTY_COLUMNS )
    {
        return 1 if ( ! defined @{ $line }[ $colIndex ] );
        printf STDERR "'%s', ", @{ $line }[ $colIndex ] if ( $main::opt{'D'} );
        return 1 if ( trim( @{ $line }[ $colIndex ] ) =~ m/^$/ );
    }
    printf STDERR "\n" if ( $main::opt{'D'} );
    return 0;
}

# Tests if specified columns are NOT empty
# param: Array reference to line columns  
# return: 1 if all specified columns are not empty, 0 if any is empty
sub is_not_empty( $ )
{
    my $line = shift;
    printf STDERR "SHOW_EMPTY_LINE: " if ( $main::opt{'D'} );
    foreach my $colIndex ( @main::SHOW_EMPTY_COLUMNS )
    {
        return 0 if ( ! defined @{ $line }[ $colIndex ] );
        printf STDERR "'%s', ", @{ $line }[ $colIndex ] if ( $main::opt{'D'} );
        return 0 if ( trim( @{ $line }[ $colIndex ] ) =~ m/^$/ );
    }
    printf STDERR "\n" if ( $main::opt{'D'} );
    return 1;
}

# Compares values across multiple columns for equality
# param: Array reference to line columns
# param: Array reference to columns to compare
# return: 1 if all specified columns contain the same value, 0 otherwise
sub contain_same_value( $$ )
{
    my $line = shift;
    my $wantedColumns = shift;
    printf STDERR "CMP_LINE: " if ( $main::opt{'D'} );
    my $lastValue = '';
    my $matchCount = 0;
    foreach my $colIndex ( @{$wantedColumns} )
    {
        if ( ! $lastValue )
        {
            $lastValue = @{ $line }[ $colIndex ] if ( defined @{ $line }[ $colIndex ] && @{ $line }[ $colIndex ] );
            next;
        }
        printf STDERR "IS_MATCHED: '%s' cmp '%s' \n", $lastValue, "UNDEFINED" if ( ! defined @{ $line }[ $colIndex ] &&  $main::opt{'D'} );
        printf STDERR "IS_MATCHED: '%s' cmp '%s' \n", $lastValue, @{ $line }[ $colIndex ] if ( defined @{ $line }[ $colIndex ] && $main::opt{'D'} );
        if ( $main::opt{'I'} )
        {
            return 0 if ( ! defined @{ $line }[ $colIndex ] || @{ $line }[ $colIndex ] !~ /^($lastValue)$/i );
        }
        else
        {
            return 0 if ( ! defined @{ $line }[ $colIndex ] || @{ $line }[ $colIndex ] !~ /^($lastValue)$/ );
        }
    }
    printf STDERR "IS_MATCHED: '%d'\n", $matchCount if ( $main::opt{'D'} );
    return 1;
}

# Main conditional testing function for complex comparisons
# param: Array reference to line columns
# return: 1 if condition tests pass, 0 otherwise
sub test_condition( $ )
{
    my $line = shift;
    my $result = 0;
    if ( $main::COND_CMP_COLUMNS[0] =~ m/($KEYWORD_NUM_COLS)/i )
    {
        # The next keyword allowed is stored on the conditional compare ref, in
        # bucket $KEYWORD_NUM_COLS. It should start with 'width...' but can be
        # extended.
        my $exp = $main::cond_cmp_ref->{$KEYWORD_NUM_COLS};
        if ( $exp =~ m/^width/i )
        {
            my $cmpValue = $';
            my @range = _get_range_( $cmpValue );
            if ( scalar( @{ $line } ) >= $range[0] && scalar( @{ $line } ) <= $range[1] )
            {
                $result = 1;
            }
        }
        else
        {
            printf STDERR "*** error invalid comparison '%s'\n", $main::cond_cmp_ref->{$KEYWORD_NUM_COLS};
        }
        return $result;
    }
    if ( $main::COND_CMP_COLUMNS[0] =~ m/($KEYWORD_ANY)/i )
    {
        my $exp = $main::cond_cmp_ref->{$KEYWORD_ANY};
        # The first 2 characters determine the type of comparison.
        $exp =~ m/(cc)?(lt|gt|eq|ge|le|ne|rg|width)/i;
        if ( ! $& )
        {
            printf STDERR "*** error invalid comparison '%s'\n", $main::cond_cmp_ref->{$KEYWORD_ANY};
            exit;
        }
        my $cmpValue    = $'; # in the case of 'rg' there could be a comma seperated value '0+197'
        my $cmpOperator = $&;
        # Change compare value to the value in a different column (if exists) and requested.
        if ( $exp =~ m/^cc/i )
        {
            # we are expecting a col definition like (c|C)\d+, so get that column number
            # strip it if supplied, but the 'c' is optional, but good form.
            $cmpValue =~ s/^c//i;
            if ( defined $cmpValue && $cmpValue =~ m/^\d+$/ )
            {
                if ( defined @{ $line }[ $cmpValue ] )
                {
                    $cmpValue = @{ $line }[ $cmpValue ];
                }
                else
                {
                    printf STDERR "* warn requested column in '%s' doesn't exist.\n", $cmpValue if ( $main::opt{'D'} );
                    return $result;
                }
            }
            else
            {
                printf STDERR "*** error malformed column requested '%s'.\n", $cmpValue;
                exit;
            }
        }
        foreach my $colIndex ( 0 .. scalar( @{ $line } ) -1 )
        {
            return 1 if( test_condition_cmp( $cmpOperator, $cmpValue, @{ $line }[ $colIndex ] ) );
        }
        return $result;
    }
    foreach my $colIndex ( @main::COND_CMP_COLUMNS )
    {
        if ( defined @{ $line }[ $colIndex ] and exists $main::cond_cmp_ref->{ $colIndex } )
        {
            my $exp = $main::cond_cmp_ref->{$colIndex};
            # The first 2 characters determine the type of comparison.
            $exp =~ m/(lt|gt|eq|ge|le|ne|rg|width|num_cols)/i;
            if ( ! $& )
            {
                printf STDERR "*** error invalid comparison '%s'\n", $main::cond_cmp_ref->{$colIndex};
                exit;
            }
            my $cmpValue    = $';
            my $cmpOperator = $&;
            # since the m// compares on 'lt' etc, only the exact match is kept in '$&'.
            # This allows us to prefix the operation with almost any keyword combination.
            if ( $exp =~ m/^cc/i )
            {
                # we are expecting a col definition like (c|C)\d+, so get that column number
                # strip it if supplied, but the 'c' is optional, but good form.
                $cmpValue =~ s/^c//i;
                if ( defined $cmpValue && $cmpValue =~ m/^\d+$/ )
                {
                    if ( defined @{ $line }[ $cmpValue ] )
                    {
                        $cmpValue = @{ $line }[ $cmpValue ];
                    }
                    else
                    {
                        printf STDERR "* warn requested column in '%s' doesn't exist.\n", $cmpValue if ( $main::opt{'D'} );
                        return $result;
                    }
                }
                else
                {
                    printf STDERR "*** error malformed column requested '%s'.\n", $cmpValue;
                    exit;
                }
            }
            $result += test_condition_cmp( $cmpOperator, $cmpValue, @{ $line }[ $colIndex ] );
        }
    }
    # All requested tests succeeded if the result count matches the number of test requests.
    return 1 if ( scalar( @main::COND_CMP_COLUMNS ) == $result );
    return 0;
}

# Helper function for individual value comparisons
# param: comparison operator (lt|gt|eq|ge|le|ne|rg|width)
# param: comparison value
# param: data value from column
# return: 1 on success, 0 otherwise
sub test_condition_cmp( $$$ )
{
    my $cmpOperator = shift;
    my $cmpValue    = shift ;
    my $value       = shift;
    my $result      = 0;
    if ( $main::opt{'N'} )  # Normalize, which preserves case.
    {
        $value = normalize( $value );
        $cmpValue = normalize( $cmpValue );
    }
    if ( $main::opt{'I'} )  # Normalize, which preserves case.
    {
        $value = uc $value;
        $cmpValue = uc $cmpValue;
    }
    printf STDERR "'%s' '%s' '%s'.\n", $cmpValue, $cmpOperator, $value if ( $main::opt{'D'} );
    if ( $cmpOperator =~ m/^rg$/i || $cmpOperator =~ m/^width$/i )
    {
        my @range = _get_range_( $cmpValue );
        if ( $cmpOperator =~ m/^rg$/i )
        {
            $result = 1 if ( $value >= $range[0] && $value <= $range[1] );
        }
        elsif ( $cmpOperator =~ m/^width$/i )
        {
            $result = 1 if ( length($value) >= $range[0] && length($value) <= $range[1] );
        }
    }
    elsif ( $value =~ m/^[+|-]?\d{1,}(\.\d{1,})?$/ && $cmpValue =~ m/^[+|-]?\d{1,}(\.\d{1,})?$/ )
    {
        if ( $cmpOperator eq 'eq' )
        {
            $result = 1 if ( $value == $cmpValue );
        }
        elsif ( $cmpOperator eq 'lt' )
        {
            $result = 1 if ( $value < $cmpValue );
        }
        elsif ( $cmpOperator eq 'gt' )
        {
            $result = 1 if ( $value > $cmpValue );
        }
        elsif ( $cmpOperator eq 'le' )
        {
            $result = 1 if ( $value <= $cmpValue );
        }
        elsif ( $cmpOperator eq 'ge' )
        {
            $result = 1 if ( $value >= $cmpValue );
        }
        elsif ( $cmpOperator eq 'ne' )
        {
            $result = 1 if ( $value != $cmpValue );
        }
        else
        {
            printf STDERR "*** error invalid operation '%s'.\n", $cmpOperator if ( $main::opt{'D'} );
            exit;
        }
    }
    else
    {
        if ( $main::opt{'U'} ) # request comparison on numbers 'U' only so ignore this one.
        {
            printf STDERR "* comparison fails on non-numeric value: '%s' and '%s' \n", $value, $cmpValue if ( $main::opt{'D'} );
            return 0;
        }
        if ( $cmpOperator eq 'eq' )
        {
            $result = 1 if ( $value eq $cmpValue );
        }
        elsif ( $cmpOperator eq 'lt' )
        {
            $result = 1 if ( $value lt $cmpValue );
        }
        elsif ( $cmpOperator eq 'gt' )
        {
            $result = 1 if ( $value gt $cmpValue );
        }
        elsif ( $cmpOperator eq 'le' )
        {
            $result = 1 if ( $value le $cmpValue );
        }
        elsif ( $cmpOperator eq 'ge' )
        {
            $result = 1 if ( $value ge $cmpValue );
        }
        elsif ( $cmpOperator eq 'ne' )
        {
            $result = 1 if ( $value ne $cmpValue );
        }
        else
        {
            printf STDERR "*** error invalid operation '%s'.\n", $cmpOperator if ( $main::opt{'D'} );
            exit;
        }
    }
    return $result;
}

# Helper function to parse range specifications
# param: range string (e.g., "1-10", "-5-5")
# return: array with start and end values, ordered smallest to largest
sub _get_range_( $ )
{
    my $rangeString = shift;
    # Search for the first '-' after character 1 in case the number is negative.
    my $rg_pos = index($rangeString, '-', 1);
    my @range = ();
    $range[0] = substr($rangeString, 0, $rg_pos);
    $range[1] = substr($rangeString, $rg_pos + 1);
    printf STDERR "range arg='%s' len(range)=%d '%d' and '%d'\n", $rangeString, scalar(@range), $range[0], $range[1] if ( $main::opt{'D'} );
    if ( scalar @range != 2 )
    {
        printf STDERR "**error, malformed range operator '%s'.\n", $rangeString;
        exit(1);
    }
    # Confirm range values are real numbers.
    if ( $range[0] !~ m/^[+|-]?\d{1,}(\.\d{1,})?$/ || $range[1] !~ m/^[+|-]?\d{1,}(\.\d{1,})?$/ )
    {
        printf STDERR "**error, range requires both start and end to be integers, but got '%s'.\n", $rangeString;
        exit(1);
    }
    # Order the range from smallest to end with largest.
    if ( $range[0] > $range[1] )
    {
        my $swp = $range[0];
        $range[0] = $range[1];
        $range[1] = $swp;
    }
    $range[0] += 0; # Turn them into numbers.
    $range[1] += 0;
    return @range;
}

1;

__END__

=head1 NAME

Pipe::Match - Pattern matching and conditional testing for pipe.pl

=head1 SYNOPSIS

    use Pipe::Match qw(:all);
    
    # Pattern matching
    if (is_match($line)) { ... }
    if (is_not_match($line)) { ... }
    
    # Empty field testing
    if (is_empty($line)) { ... }
    if (is_not_empty($line)) { ... }
    
    # Value comparison
    if (contain_same_value($line)) { ... }
    
    # Conditional testing
    if (test_condition($line)) { ... }

=head1 DESCRIPTION

This module provides pattern matching and conditional testing functionality for pipe.pl.
It handles:

- Regular expression pattern matching (grep operations)
- Empty field detection
- Cross-column value comparison
- Complex conditional testing with operators

=head1 FUNCTIONS

=head2 Pattern Matching Functions

=over 4

=item is_match($line)

Tests if the line matches the specified pattern(s) based on -g flag settings.
Supports column-specific and 'any' keyword matching.

=item is_not_match($line)

Inverse pattern matching - tests if the line does NOT match the specified pattern(s).
Used by -G flag for inverse grep operations.

=back

=head2 Empty Field Testing

=over 4

=item is_empty($line)

Tests if specified columns are empty or undefined.
Used by -z flag to suppress lines with empty fields.

=item is_not_empty($line)

Tests if specified columns are NOT empty.
Used by -Z flag to show only lines with empty fields.

=back

=head2 Value Comparison

=over 4

=item contain_same_value($line)

Compares values across multiple columns for equality.
Supports case-insensitive comparison with -I flag.
Used by -b flag.

=back

=head2 Conditional Testing

=over 4

=item test_condition($line)

Main conditional testing function for complex comparisons.
Supports 'any', 'num_cols', and specific column testing.
Used by -C flag.

=item test_condition_cmp($value, $operator, $condition)

Helper function for individual value comparisons.
Supports operators: lt, gt, eq, le, ge, ne, rg (range), width.

=back

=head2 Utility Functions

=over 4

=item _get_range_($range)

Helper function to parse range specifications for range operations.
Handles negative numbers and validates numeric ranges.

=back

=head1 DEPENDENCIES

- Pipe::Core - For constants, keywords, and trim function
- Pipe::Text - For normalize function

=head1 GLOBAL VARIABLES

This module accesses global variables from the main:: package including:
- %opt - Command line options
- Pattern matching arrays (@MATCH_COLUMNS, @NOT_MATCH_COLUMNS, etc.)
- State variables ($IS_X_MATCH, $IS_Y_MATCH, etc.)

=head1 SEE ALSO

L<Pipe::Core>, L<Pipe::Text>, L<Pipe::Column>

=cut