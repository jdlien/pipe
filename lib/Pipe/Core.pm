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

# Default values
our $ALLOW_SCRIPTING = $TRUE;
our $COLLAPSE_OPTION = 0;
our $READ_FULL = 0;
our $KEEP_LINES = 10;
our $FAST_FORWARD = 0;
our $PRECISION = 2;

# Exports
our @EXPORT = qw(
    $TRUE $FALSE $DELIMITER
    $KEYWORD_ANY $KEYWORD_REMAINING
    trim
);

our @EXPORT_OK = qw(
    $VERSION $MAX_LINE
    $SUB_DELIMITER $QUOTED_DELIMITER
    $KEYWORD_CONTINUE $KEYWORD_LAST
    $KEYWORD_REVERSE $KEYWORD_EXCLUDE
    $KEYWORD_NUM_COLS
    $ALLOW_SCRIPTING $COLLAPSE_OPTION
    $READ_FULL $KEEP_LINES $FAST_FORWARD
    $PRECISION
    get_number_format
);

our %EXPORT_TAGS = (
    constants => [qw(
        $TRUE $FALSE $DELIMITER
        $SUB_DELIMITER $QUOTED_DELIMITER
        $MAX_LINE $PRECISION
    )],
    keywords => [qw(
        $KEYWORD_ANY $KEYWORD_REMAINING
        $KEYWORD_CONTINUE $KEYWORD_LAST
        $KEYWORD_REVERSE $KEYWORD_EXCLUDE
        $KEYWORD_NUM_COLS
    )],
    settings => [qw(
        $ALLOW_SCRIPTING $COLLAPSE_OPTION
        $READ_FULL $KEEP_LINES $FAST_FORWARD
    )],
    functions => [qw(
        trim get_number_format
    )]
);

# Trim function to remove white space from the start and end of the string.
# param:  string to trim.
# param:  Trims the string to argument number of characters (optional).
#         This operation is performed after any white space has been trimmed.
# return: string without leading or trailing spaces.
sub trim
{
    my $string = shift;
    my $chop_count = 0;
    $chop_count = shift if ( @_ );
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    $string = substr( $string, 0, $chop_count ) if ( $chop_count );
    return $string;
}


# Formats a number based on type and precision
# param:  input - the number to format
# param:  number_type - if true, format as integer only
# param:  precision - decimal places for floating point
# return: formatted string or 'NaN' if not a number
sub get_number_format
{
    my $input       = shift @_;
    my $number_type = shift @_ if ( @_ );
    my $precision   = shift @_ if ( @_ );
    my $summary     = '';
    if ( $number_type )
    {
        if ( $input && $input =~ /^[+]?\d+\z/ ){ $summary = sprintf "%d", $input; }
    }
    elsif ( $input =~ /^[+-]?\d+\z/ )   { $summary = sprintf "%d", $input; }
    elsif ( defined $precision && $input =~ /^-?\d+\.?\d*\z/ || $input =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)\z/ )
    { $summary = eval("sprintf \"%.".$precision."f\", $input"); }
    elsif ( $input =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\z/ ){ $summary = $input; }
    else { $summary = "NaN"; }
    return $summary;
}


1;

__END__

=head1 NAME

Pipe::Core - Core constants and utilities for pipe.pl

=head1 SYNOPSIS

    use Pipe::Core;
    
    # Use constants
    my $delimiter = $DELIMITER;
    
    # Use functions
    my $trimmed = trim("  hello  ");

=head1 DESCRIPTION

This module provides core constants, keywords, and utility functions
used throughout the pipe.pl application.

=head1 EXPORTS

By default, this module exports:
- Basic constants: $TRUE, $FALSE, $DELIMITER
- Basic keywords: $KEYWORD_ANY, $KEYWORD_REMAINING
- Basic functions: trim()

Additional constants and functions are available through explicit import.

=head1 FUNCTIONS

=head2 trim($string, [$length])

Removes leading and trailing whitespace from a string.
Optionally truncates to specified length after trimming.

=head2 get_number_format($input, [$number_type], [$precision])

Formats a number according to type and precision specifications.


=head1 AUTHOR

Pipe.pl contributors

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut