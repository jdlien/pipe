package Pipe::Utils;

use strict;
use warnings;
use utf8;

use Exporter qw(import);
use Pipe::Core qw(trim);

our @EXPORT_OK = qw(
    parse_single_column_single_argument
    parse_line_ranges
    read_requested_columns
    get_col_num_or_literal_command
    parse_M_line
    is_between_zero_and_hundred
    validate
    convert_format
    format_radix
);

our %EXPORT_TAGS = (
    'parsing'    => [qw(parse_single_column_single_argument parse_line_ranges read_requested_columns get_col_num_or_literal_command parse_M_line)],
    'validation' => [qw(is_between_zero_and_hundred validate)],
    'formatting' => [qw(convert_format format_radix)],
    'all'        => \@EXPORT_OK,
);

# Takes a single argument from the command line in pipe.pl style input and returns a list of the column index and the value supplied.
# Looks like this: -2c1:1000, where '-2' is the flag, c1 is the column requested, and 1000 the additional input for the column. A reset value is also allowed as in -2c1:1000,1200, which resets the increment to 1000 after 1200 is reached.
# param:  string argument from the command line.
# return: List of 2 values, the column index and the requested value. In the example above the return values are (1, 1000).
sub parse_single_column_single_argument( $ )
{
    my $input = shift;
    if ( $input =~ m/^c\d{1,}/i )
    {
        my ( $colNum, $value ) = split ':', $input;
        my $reset = '';    # might not be used if user doesn't specify a reset value.
        $colNum =~ s/c//i; # get rid of the 'c' because it causes problems later.
        # There may be an additional value after the column specifier (or not).
        if ( $input =~ m/:/ )
        {
            $value = $';
            if ( $input =~ m/,/ )
            {
                ( $value, $reset ) = split '\s?,\s?', $value;
                $value = trim( $value );
                $reset = trim( $reset );
            }
            printf STDERR "increment start='%s', end='%s'\n", $value, $reset if ( $main::opt{'D'} );
        }
        if ( ! $value )
        {
            $value = 0;
        }
        return ( $colNum, $value, $reset );
    }
    printf STDERR "** error parsing column specification in '%s'\n", $input;
    exit( 0 );
}

# Parses the ranges of lines requested by the user.
# parse the user's instructions and print out the lines selected.
# n = exactly the 'n'th line.
# n- = print from line 'n' on.
# +n = print the first 'n' lines.
# -n = print the last 'n' lines.
# n-m = exactly the range of lines from n to m.
# n,m-p = print n and range n-p (optional).
# param:  String that lists all of the ranges.
# return: <none>.
sub parse_line_ranges( $ )
{
    my $range_str = shift;
    if ( $range_str =~ m/^skip/ )
    {
        my $skip = $' + 0;
        if ( ! $skip or $skip !~ m/\d+/ )
        {
            printf STDERR "** error '-L' skip option takes an integer value greater than 0, supplied '%s'\n", $main::opt{'L'};
            exit;
        }
        $main::SKIP_LINE = $skip; # The integer value stored here will be used to modulus the line numbers in process_line().
        return;
    }
    $range_str    =~ s/\s+//g;
    my @r         = split ',', $range_str;
    my $ranges    = \@r;
    while ( @{ $ranges } )
    {
        my $range = shift @{ $ranges };
        # Clear the default of all lines, or else all lines will be considered.
        # Parse the ranges from the input strings.
        # Set the start (key) and end (value) to a specific value.
        if ( $range =~ m/^\-\d+$/ ) # parses from line 'n' to the end of the file.
        {
            $main::READ_FULL = 1; # Set true to read the entire file before output as with -L'-n'.
            # get rid of the previous rule that outputs all lines.
            delete $main::LINE_RANGES->{ '1' } if ( exists $main::LINE_RANGES->{ '1' } and $main::LINE_RANGES->{ '1' } == $main::MAX_LINE );
            my $num = substr $range, 1;
            $main::LINE_RANGES->{ (0 -$num) } = $main::MAX_LINE;
            $main::KEEP_LINES  = $num; # Number of lines to keep in buffer if -L'-n' is used.
        }
        elsif ( $range =~ m/^\+\d+$/ ) # parses from beginning of file upto the given range.
        {
            # The rule for line 1 is automatically over written.
            my $num = substr $range, 1;
            $main::LINE_RANGES->{ '1' } = $num;
        }
        elsif ( $range =~ m/^\d+\-\d+$/ ) # User has selected a range of lines from n-m.
        {
            # Remove the default rule for the entire range.
            delete $main::LINE_RANGES->{ '1' } if ( exists $main::LINE_RANGES->{ '1' } and $main::LINE_RANGES->{ '1' } == $main::MAX_LINE );
            my @v = split '-', $range;
            $main::LINE_RANGES->{ $v[ 0 ] } = $v[ 1 ];
        }
        elsif ( $range =~ m/^\d+\-$/ ) # Select all lines from 'n' on.
        {
            # Remove the default rule for the entire range.
            delete $main::LINE_RANGES->{ '1' } if ( exists $main::LINE_RANGES->{ '1' } and $main::LINE_RANGES->{ '1' } == $main::MAX_LINE );
            my $num = substr $range, 0, length( $range ) -1;
            $main::LINE_RANGES->{ $num } = $main::MAX_LINE;
        }
        elsif ( $range =~ m/^\d+$/ ) # Select a specific line number.
        {
            # Remove the default rule for the entire range.
            delete $main::LINE_RANGES->{ '1' } if ( exists $main::LINE_RANGES->{ '1' } and $main::LINE_RANGES->{ '1' } == $main::MAX_LINE );
            $main::LINE_RANGES->{ $range } = $range;
        }
        else
        {
            printf STDERR "** pipe syntax error in line number range definition: '%s'\n", $range_str;
            exit 1;
        }
    }
}

# Reads the values supplied on the command line and parses them out into the argument list.
# param:  command line string of requested columns.
# param:  command "any" if the caller is allowed to operate on any column without restriction.
# return: New array.
sub read_requested_columns
{
    my $line             = shift;
    my @allowed_keywords = @_;
    # printf STDERR "-->%s<--\n", @allowed_keywords;
    my @list = ();
    # Since we can't split if there is no delimiter character, let's introduce one if there isn't one.
    $line .= "," if ( $line !~ m/,/ );
    my @cols = split( '\s?,\s?', $line );
    # my @cols = split( ',', $line );
    foreach my $colNum ( @cols )
    {
        # Columns are designated with 'c' prefix to get over the problem of perl not recognizing
        # '0' as a legitimate column number.
        if ( $colNum =~ m/[C|c]\d{1,}/ )
        {
            $colNum =~ s/c//i; # get rid of the 'c' because it causes problems later.
            push( @list, (trim( $colNum ) + 0) );
        }
        elsif ( $colNum =~ m/^any$/i && grep /($main::KEYWORD_ANY)/, @allowed_keywords )
        {
            # Clear any other column selections the user may have already requested.
            @list = ();
            push( @list, $main::KEYWORD_ANY );
            last; # don't allow user to add more.
        }
        elsif ( $colNum =~ m/^remaining$/i && grep /($main::KEYWORD_REMAINING)/, @allowed_keywords )
        {
            # Keep all the columns collected so far, but tack on the keyword as a marker
            # that the remaining fields (if any) should be appended in order.
            push( @list, $main::KEYWORD_REMAINING );
            last; # don't allow user to add more.
        }
        elsif ( $colNum =~ m/^continue$/i && grep /($main::KEYWORD_CONTINUE)/, @allowed_keywords )
        {
            # Keep all the columns collected so far, but tack on the keyword as a marker
            # that the remaining fields (if any) should be appended in order.
            push( @list, $main::KEYWORD_CONTINUE );
            last; # don't allow user to add more.
        }
        # $, $KEYWORD_REVERSE
        elsif ( $colNum =~ m/^last$/i && grep /($main::KEYWORD_LAST)/, @allowed_keywords )
        {
            # use the last column.
            push( @list, $main::KEYWORD_LAST );
            last; # don't allow user to add more.
        }
        elsif ( $colNum =~ m/^reverse$/i && grep /($main::KEYWORD_REVERSE)/, @allowed_keywords )
        {
            # use the last column.
            push( @list, $main::KEYWORD_REVERSE );
            last; # don't allow user to add more.
        }
        elsif ( $colNum =~ m/^exclude$/i && grep /($main::KEYWORD_EXCLUDE)/, @allowed_keywords )
        {
            # use the inverted set of columns.
            # Add the keyword as the FIRST element, then order_line() will exclude the rest of the listed columns
            unshift( @list, $main::KEYWORD_EXCLUDE );
        }
        else
        {
            print STDERR "** Warning: illegal column designation '$colNum', ignoring.\n";
        }
    }
    if ( scalar(@list) == 0 )
    {
        print STDERR "*** Error no valid columns selected. ***\n";
        exit;
    }
    print STDERR "columns requested: '@list'\n" if ( $main::opt{'D'} );
    return @list;
}

# The returned string may also include literal strings. Use '\+' if you wish to include 
# a '+' in the literal string.
# param:  array reference of column indexes. This is where you intend to store the columns that
#         the consuming function will operate on.
# param:  The input string. Example: 'c100+"dog eat dog"+c 2'
# param:  1 if literal terms (used to fill in false values optionally), or 0, specifies columns
#         all of which will be expected to be in the form of '[c|C]n' where n is a positive integer.
# return: None. Side effect: argument array reference will contain integers, and strings.
sub get_col_num_or_literal_command( $$$ )
{
    my $array_ref = shift;
    my $line_string = shift;
    my $is_literal_string = shift;
    # Split on column identifiers, making sure we don't pick up any empty or blank column identifiers.
    my @tmp = ();
    if ( $is_literal_string )
    {
        @tmp = split( /\+/, $line_string ) if ( $line_string );
        push(@tmp, $line_string) if ( ! @tmp );
    }
    else
    {
        @tmp = grep { /\S/ } split( /\+?\s?c/i, $line_string ) if ( $line_string );
    }
    foreach my $i ( @tmp )
    {
        push @{$array_ref}, $i if ( defined $i );
    }
}

# Take the line input. Its the columns from the alternate file with the key of the comparison field.
# Later we will add it to the line(s) from the data coming in (from STDIN).
# return: nothing, but a hash reference is built of compare column keys, with merge columns as values.
sub parse_M_line()
{
    # parse the expression that describes which columns of the ref file we want.
    # -Mc1:c2?c3.c4 but more generally -Mcn:"[cm,...|'literal']?[cp,...|'literal'].[cq,...|'literal']"
    foreach my $key ( keys %{$main::merge_expression_ref} )
    {
        printf STDERR "key : '%s' \n", $main::merge_expression_ref->{ $key } if ( $main::opt{'D'} );
        # EXPRESSION [col_input]:[col_ref]?[true column index or literal].[false literal]
        # Example: [col_input]:'c2?c3', OR: 'c4'
        # Split on the '.'. The LHS is the test operator and true expression, the RHS is the false expression.
        my ( $token, $ref_false_literals ) = split( m/(?<!\\)\./, $main::merge_expression_ref->{ $key } );
        # Split the LHS on the '?'. The LHS of this operation is the column to compare to the column of the input file. The RHS is the true expression.
        my ( $ref_file_columns, $ref_true_cols ) = split( m/(?<!\\)\?/, $token );
        printf STDERR "ref_file_columns : '%s', ref_true_cols : '%s', ref_false_literals: '%s'\n", $ref_file_columns, $ref_true_cols, $ref_false_literals if ( $main::opt{'D'} );
        get_col_num_or_literal_command( \@main::MERGE_REF_COLUMNS, $ref_file_columns, 0 ); # Parse out the column(s) for matching.
        get_col_num_or_literal_command( \@main::REF_COLUMN_INDEX_TRUE, $ref_true_cols, 0 ); # Parse out the column(s) used if match true.
        get_col_num_or_literal_command( \@main::REF_LITERALS_FALSE, $ref_false_literals, 1 ); # Parse out the literals used if match false.
    }
}

# Test if argument is a number between 0-100.
# param:  number to test.
# return: 1 if the argument is a number between 0-100, and 0 otherwise.
sub is_between_zero_and_hundred( $ )
{
    my $testValue = shift;
    chomp $testValue;
    if ( $testValue =~ m/^\d{1,3}$/)
    {
        if ( 0 <= $testValue and $testValue <= 100 )
        {
            return 1;
        }
    }
    return 0;
}

# This function fixes lines that have trailing empty pipe columns. If it is not used
# lines are truncated after the last content-filled column.
# param:  original line sent to the calling function.
# param:  line after any modification.
# param:  line number for reporting.
# return: modified line with additional pipes if required.
sub validate( $$$ )
{
    my ( $original, $modified, $line_no ) = @_;
    my $count       = ( $original =~ tr/\|// );
    my $final_count = ( $modified =~ tr/\|// );
    printf STDERR "original: %d, modified: %d fields at line number %s.\n", $count, $final_count, $line_no if ( $main::opt{'D'} );
    # if ( $opt{'V'} ) # Original
    if ( $main::opt{'o'} ) # If you select -o this doesn't get done or extra fields are added even if you select 'V'
    {
        # But pad to the width of the columns selected -1, because pipe doesn't add a terminal pipe by default.
        if ( $main::RELAX_o_EXCLUDE )
        {
            my @original_cols = split( /\|/, $original );
            $count = ( scalar( @original_cols ) -1 ) - ( scalar(@main::ORDER_COLUMNS) -1 );
        }
        else
        {
            $count = scalar @main::ORDER_COLUMNS -1 if ( $count > scalar @main::ORDER_COLUMNS -1 );
        }
    }
    # Normally this ensures the total number of columns in == out, but collapse
    # can be set in the '-e' flag (modify_case_line() function).
    if ( $final_count < $count && $main::COLLAPSE_OPTION == 0 )
    {
        my $iterations = $count - $final_count;
        my $i = 0;
        for ( $i = 0; $i < $iterations; $i++ )
        {
            $modified .= '|';
        }
    }
    return $modified;
}

# Applies format to requested string.
# param:  String for conversion.
# param:  Conversion type 'c', 'b', 'h', 'd'.
# return: String with the specified modifications.
sub convert_format( $$ )
{
    my ( $field, $format ) = @_;
    my @format_parts       = split /\./, $format;
    @format_parts          = grep /\S/, @format_parts;
    # @format_parts can have 1 or 2 radix defined. If there is 1 the radix is
    # the destination radix. If there are 2 the second is the destination radix
    # and the source radix is the first value. If the user defines a from radix
    # no matter what the data is, convert it to decimal, ready for the next step
    # which will take the decimal number and convert it to the appropriate
    # destination radix.
    # To accomadate strings use an array.
    my @in_array = ();
    if ( $format_parts[1] )
    {
        if ( $format_parts[0] =~ /b/i )
        {
            push @in_array, oct( "0b" . $field );
        }
        elsif ( $format_parts[0] =~ /h/i )
        {
            push @in_array, oct( "0x" . $field );
        }
        elsif ( $format_parts[0] =~ /c/i )
        {
            @in_array = unpack( "C*", $field ); # Converts all values into ints.
        }
        else # Decimal
        {
            push @in_array, $field;
        }
        # Set the destination radix for the remainder of the calculation 
        $format_parts[0] = $format_parts[1];
    }
    if ( $format_parts[0] =~ /c/i )
    {
        return pack( "C*", @in_array);
    }
    # So not a string so the value in $in_array[0] should be all there is to convert.
    $field = join '', @in_array;
    if ( $format_parts[0] =~ /b/i )
    {
        return sprintf( "%b", $field );
    }
    elsif ( $format_parts[0] =~ /h/i )
    {
        return sprintf( "%x", $field );
    }
    elsif ( $format_parts[0] =~ /d/i )
    {
        return sprintf( "%d", $field );
    }
    else
    {
        printf STDERR "** error unsupported option: '%s' \n", $format_parts[0];
        exit(1);
    }
}

# Formats the specified column to the desired base type.
# param:  Original line input.
# return: <none>.
sub format_radix( $ )
{
    my $line = shift;
    my $i    = 0;
    for ( $i = 0; $i < scalar( @{ $line } ); $i++ )
    {
        if ( defined $main::FORMAT_COLUMNS[ $i ] and exists $main::format_ref->{ $i } )
        {
            printf STDERR "format expression: '%s' \n", $main::format_ref->{$i} if ( $main::opt{'D'} );
            @{ $line }[ $i ] = convert_format( @{ $line }[ $i ], lc ( $main::format_ref->{ $i } ) );
        }
    }
}

1;

__END__

=head1 NAME

Pipe::Utils - Utility functions for parsing, validation, and formatting

=head1 DESCRIPTION

This module contains utility functions for the pipe.pl tool, including:
- Column and range parsing functions
- Data validation functions  
- Format conversion functions
- Merge line parsing utilities

=head1 FUNCTIONS

=head2 Parsing Functions

=over 4

=item parse_single_column_single_argument($input)

Parse a single column specification with argument.

=item parse_line_ranges($range_str)

Parse line range specifications like "skip10" or "1-100".

=item read_requested_columns(@allowed_keywords)

Read and parse requested column specifications.

=item get_col_num_or_literal_command($array_ref, $line_string, $is_literal_string)

Extract column numbers or literal commands from input.

=item parse_M_line()

Parse merge line expressions for the -M flag.

=back

=head2 Validation Functions

=over 4

=item is_between_zero_and_hundred($testValue)

Validate that a value is between 0 and 100.

=item validate($original, $modified, $line_no)

Validate that field counts match between original and modified lines.

=back

=head2 Formatting Functions

=over 4

=item convert_format($field, $format)

Convert field values according to format specifications.

=item format_radix($line)

Apply radix formatting to line fields.

=back

=head1 AUTHOR

Pipe.pl project

=cut