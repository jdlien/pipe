package Pipe::Column;

use strict;
use warnings;
use utf8;
use Exporter 'import';
use Pipe::Core qw(:constants :keywords :functions);

=head1 NAME

Pipe::Column - Column operations and manipulation for pipe.pl

=head1 SYNOPSIS

    use Pipe::Column qw(:all);
    
    # Reorder columns
    order_line(\@line_data);
    
    # Merge columns 
    merge_line(\@line_data);
    
    # Parse qualified column specifications
    my @columns = read_requested_qualified_columns(\@column_specs, $prefix);
    
    # Get numeric value from column
    my $value = get_column_value($column_spec, $line_string);
    
    # Generate key from columns
    my $key = get_key($line_string, \@column_indices);
    
    # Parse whole number safely
    my $number = read_whole_number($input);
    
    # Merge reference file data
    merge_reference_file(\@line_data);

=head1 DESCRIPTION

Pipe::Column provides column manipulation operations for the pipe.pl text processing tool.
It handles column reordering, merging, parsing qualified column specifications with operators,
reference file merging, and utility functions for column-based operations.

=head1 FUNCTIONS

=head2 order_line($line_ref, $order_cols_ref)

Reorders columns in a line according to ORDER_COLUMNS specification.

Parameters:
- $line_ref: Array reference to line columns
- $order_cols_ref: Array reference to order columns (optional, defaults to @main::ORDER_COLUMNS)

Returns: None (modifies input array in-place)

Supports keywords: 'remaining', 'continue', 'last', 'reverse', 'exclude', 'num_cols'

=head2 merge_line($line_ref)

Merges columns based on MERGE_COLUMNS and MERGE_SRC_COLUMNS specifications.

Parameters:
- $line_ref: Array reference to line columns

Returns: None (modifies input array in-place)

=head2 read_requested_qualified_columns($column_specs_ref, $prefix)

Parses qualified column specifications with operators and qualifiers.

Parameters:
- $column_specs_ref: Array reference to column specifications (e.g., 'c0:add:5')
- $prefix: String prefix for generated variable names

Returns: Array of parsed column specifications

Supports operators: add, sub, mul, div, range, and other qualifiers

=head2 get_column_value($column_spec, $line_string)

Extracts numeric value from specified column in a pipe-delimited line.

Parameters:
- $column_spec: Column specification (e.g., 'c0', '0')
- $line_string: Pipe-delimited line string

Returns: Numeric value from column, or 0 if non-numeric/non-existent

=head2 get_key($line_string, $column_indices_ref)

Generates concatenated key from specified columns in a line.

Parameters:
- $line_string: Pipe-delimited line string
- $column_indices_ref: Array reference to column indices

Returns: String key created by concatenating trimmed column values

=head2 read_whole_number($input)

Safely parses a whole number from input with validation.

Parameters:
- $input: String input to parse

Returns: Numeric value if valid whole number, 0 if empty, exits on invalid input

=head2 merge_reference_file($line_ref)

Merges data from reference file based on key lookup.

Parameters:
- $line_ref: Array reference to line columns

Returns: None (modifies input array in-place)

Uses global variables: $main::REF_FILE_DATA_HREF, @main::MERGE_REF_COLUMNS

=head1 DEPENDENCIES

- Pipe::Core - For constants, keywords, and utility functions

=head1 GLOBAL VARIABLES

This module accesses global variables from the main:: package including:
- Column arrays (@ORDER_COLUMNS, @MERGE_COLUMNS, @MERGE_SRC_COLUMNS, etc.)
- Reference data structures ($REF_FILE_DATA_HREF, @REF_LITERALS_FALSE)  
- Options hash (%opt) for flags like -D (debug), -N (normalize)
- Other state variables ($RELAX_o_EXCLUDE, etc.)

=head1 SEE ALSO

L<Pipe::Core>, L<Pipe::Text>, L<Pipe::Math>

=cut

# Note: This module accesses global variables from the main:: package

our @EXPORT_OK = qw(
    order_line
    merge_line
    read_requested_qualified_columns
    get_column_value
    merge_reference_file
    get_key
    read_whole_number
);

our %EXPORT_TAGS = (
    operations => [qw(order_line merge_line)],
    parsing => [qw(read_requested_qualified_columns get_column_value get_key)],
    merging => [qw(merge_reference_file)],
    utilities => [qw(read_whole_number)],
    all => [qw(order_line merge_line read_requested_qualified_columns get_column_value merge_reference_file get_key read_whole_number)],
);

# Reorders columns in a line according to the ORDER_COLUMNS specification
# param: Array reference to line columns
# param: Array reference to order columns (optional, defaults to @main::ORDER_COLUMNS)
# return: None (modifies input array in-place)
sub order_line( $;$ )
{
    my $line          = shift;
    my $order_cols_ref = shift || \@main::ORDER_COLUMNS;
    my @newLine       = ();
    my @order_columns = ();
    my $count         = 0; # Keep track of the index of the your index in the line. Used for 'continue' keyword in -o.
    
    foreach my $c ( @$order_cols_ref )
    {
        # If the keyword any is used push all the missing columns of the line onto @order_columns.
        # Other lines might have different numbers of columns.
        # now add all the columns that aren't on the array already.
        if ( $c =~ m/($KEYWORD_REMAINING)/i )
        {
            foreach my $colIndex ( 0 .. scalar( @{ $line } ) -1 )
            {
                next if ( grep { $colIndex eq $_ } @order_columns );
                push @order_columns, $colIndex;
            }
            last;
        }
        # Add all the rest of the columns from the input line.
        elsif ( $c =~ m/($KEYWORD_CONTINUE)/i )
        {
            # Use the last saved array index to 
            foreach my $colIndex ( $count .. scalar( @{ $line } ) -1 )
            {
                push @order_columns, $colIndex;
            }
            last;
        }
        # Return the last column from the list.
        elsif ( $c =~ m/($KEYWORD_LAST)/i )
        {
            push @order_columns, -1;
            last;
        }
        elsif ( $c =~ m/($KEYWORD_REVERSE)/i )
        {
            foreach my $colIndex ( 0 .. scalar( @{ $line } ) -1 )
            {
                push @order_columns, $colIndex;
            }
            @order_columns = reverse @order_columns;
            last;
        }
        elsif ( $c =~ m/($KEYWORD_EXCLUDE)/i || $main::RELAX_o_EXCLUDE ) # 'exclude' is the first value.
        {
            # this value is set from the first time we encounter 'exclude'.
            if ( $main::RELAX_o_EXCLUDE )
            {
                foreach my $colIndex ( 0 .. scalar( @{ $line } ) -1 )
                {
                    push @order_columns, $colIndex if ( ! grep { $colIndex eq $_ } @main::ORDER_COLUMNS );
                }
                last;
            }
            else # This is the first time we encounter 'exclude' so set the variable, and the next
                 # iteration of the loop the set variable will cause the rest of the loop to 
            {
                $main::RELAX_o_EXCLUDE = 1;
            }
        }
        else # Standard column output ordering request, and all column ordering requests before 'remaining'.
        {
            push @order_columns, $c;
        }
        # To get here the value has to have been numeric, save it in case the continue keyword is used,
        # then use it to output all the columns from the last index to the end of the line.
        $count = $c +1 if ( ! $main::RELAX_o_EXCLUDE ); # The exclude keyword appears first, but ignore it.
    }
    if ( $main::opt{'D'} )
    {
        printf STDERR "order of columns: ";
        foreach my $c ( @order_columns )
        {
            printf STDERR "%d, ", $c;
        }
        printf STDERR "\n";
    }
    foreach my $colIndex ( @order_columns )
    {
        if ( defined @{ $line }[ $colIndex ] )
        {
            push @newLine, @{ $line }[ $colIndex ];
        }
    }
    @{ $line } = ();
    push @{ $line }, @newLine;
}

# Merges columns according to the MERGE_COLUMNS specification
# param: Array reference to line columns
# return: None (modifies input array in-place)
sub merge_line( $ )
{
    my $line = shift;
    my $i    = 0;
    if ( $main::MERGE_COLUMNS[ 0 ] =~ m/($KEYWORD_ANY)/i )
    {
        printf STDERR "merge: '%s' \n", $KEYWORD_ANY if ( $main::opt{'D'} );
        @{ $line }[ 0 ] = join '', @{ $line };
        return;
    }
    if ( ! defined $main::MERGE_COLUMNS[ 0 ] or ! defined @{ $line }[ $main::MERGE_COLUMNS[ 0 ] ] )
    {
        printf STDERR "** warning: merge target 'c%s' doesn't exist in line '%s...'.\n", $main::MERGE_COLUMNS[ 0 ], @{ $line }[0] if ( $main::opt{'D'} );
    }
    # The rest of the columns are to be appended to @{ $line }[ $main::MERGE_COLUMNS[ 0 ] ]
    for ( $i = 1; $i < scalar( @{ $line } ); $i++ )
    {
        if ( defined $main::MERGE_COLUMNS[ $i ] and defined @{ $line }[ $main::MERGE_COLUMNS[ $i ] ] )
        {
            printf STDERR "merge: '%s' \n", @{ $line }[ $main::MERGE_COLUMNS[ $i ] ] if ( $main::opt{'D'} );
            @{ $line }[ $main::MERGE_COLUMNS[ 0 ] ] .= @{ $line }[ $main::MERGE_COLUMNS[ $i ] ];
        }
    }
}

# Parses column specifications with qualifiers (e.g., "c1:pattern,c2:value")
# param: String of column specifications
# param: Hash reference to store qualifiers
# param: Array of allowed keywords
# return: Array of parsed column numbers
sub read_requested_qualified_columns
{
    my $line             = shift;
    my @list             = ();
    my $hash_ref         = shift;
    my @allowed_keywords = @_;
    # Since we can't split if there is no delimiter character, let's introduce one if there isn't one.
    $line .= "," if ( $line !~ m/,/ );
    # To accommodate expressions that include a ',' as part of the mask split on non-escaped ','s
    # we use a negative look behind.
    my @cols = split( m/(?<!\\),/, $line );
    foreach my $colNum ( @cols )
    {
        # Columns are designated with 'c' prefix to get over the problem of perl not recognizing
        # '0' as a legitimate column number.
        if ( $colNum =~ m/^c\d{1,}/i )
        {
            $colNum =~ s/[C|c]//; # get rid of the 'c' because it causes problems later.
            # We now allow other characters, and possibly ':' so split the line on the first one only.
            my @nameQualifier = ();
            if ( $colNum =~ m/:/ )
            {
                push @nameQualifier, $`;
                push @nameQualifier, $';
            }
            if ( scalar @nameQualifier != 2 )
            {
                print STDERR "*** Error missing qualifier '$colNum'. ***\n";
                exit;
            }
            push( @list, trim( $nameQualifier[0] ) );
            # Add the qualifier to the hash reference too for reference later.
            # The ',' char is a field delimiter and has to be escaped, but in regex it has a different meaning and has to be un-escaped.
            $nameQualifier[1] =~ s/\\,/,/g;
            $hash_ref->{$nameQualifier[0]} = trim( $nameQualifier[1] );
        }
        elsif ( $colNum =~ m/any/ && grep /($KEYWORD_ANY)/, @allowed_keywords )
        {
            my @nameQualifier = ();
            if ( $colNum =~ m/:/ )
            {
                push @nameQualifier, $`;
                push @nameQualifier, $';
            }
            if ( scalar @nameQualifier != 2 )
            {
                print STDERR "*** Error missing qualifier '$colNum'. ***\n";
                exit;
            }
            @list = ();
            push( @list, trim( $nameQualifier[0] ) );
            ## Add the qualifier to the hash reference too for reference later.
            ## The ',' char is a field delimiter and has to be escaped, but in regex it has a different meaning and has to be un-escaped.
            $nameQualifier[1] =~ s/\\,/,/g;
            $hash_ref->{$KEYWORD_ANY} = trim( $nameQualifier[1] );
            last;
        }
        elsif ( $colNum =~ m/num_cols/i && grep /($KEYWORD_NUM_COLS)/, @allowed_keywords )
        {
            my @nameQualifier = ();
            if ( $colNum =~ m/:/ )
            {
                push @nameQualifier, $`;
                push @nameQualifier, $';
            }
            if ( scalar @nameQualifier != 2 )
            {
                print STDERR "*** Error missing qualifier '$colNum'. ***\n";
                exit;
            }
            @list = ();
            push( @list, trim( $nameQualifier[0] ) );
            ## Add the qualifier to the hash reference too for reference later.
            ## The ',' char is a field delimiter and has to be escaped, but in regex it has a different meaning and has to be un-escaped.
            $nameQualifier[1] =~ s/\\,/,/g;
            $hash_ref->{$KEYWORD_NUM_COLS} = trim( $nameQualifier[1] );
            last;
        }
        elsif ( $colNum =~ m/(add|sub|mul|div)/i )
        {
            my ( $operator, $column_string ) = '';
            if ( $colNum =~ m/:/ )
            {
                $operator      = $`;
                $column_string = $';
            }
            # printf STDERR "--> '%s' and '%s' <--\n", $operator, $column_string;
            if ( not $operator || not $column_string )
            {
                print STDERR "*** Syntax error at '$colNum'. ***\n";
                exit();
            }
            @list = ();
            push( @list, trim( $column_string ) );
            push( @list, @cols[1 .. @cols -1] );
            $hash_ref->{$operator} = 1;
            last;
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

# Gets a numeric value from a specific column in a line
# param: Column specification (e.g., "c1" or "1")
# param: Line string (pipe-delimited)
# return: Numeric value from the column, or 0 if not numeric
sub get_column_value( $$ )
{
    my $wantedColumn  = shift;
    my $line          = shift;
    $wantedColumn     =~ s/c//i;
    # Make sure the user entered a '[c|C]n'
    if ( $wantedColumn !~ m/^\d{1,}$/ )
    {
        printf STDERR "** invalid column selection for summation over groups: '%s'.\n", $wantedColumn;
        exit;
    }
    my @columns = split( '\|', $line );
    if ( defined $columns[ $wantedColumn ] )
    {
        # The user may have requested -W so there may be SUB_DELIMITERs in string.
        $columns[ $wantedColumn ] =~ s/($SUB_DELIMITER)/\|/g;
        my $trimmed_column = trim( $columns[ $wantedColumn ] );
        if ( $trimmed_column =~ m/^[+|-]?\d{1,}(\.\d{1,})?$/ )
        {
            return $trimmed_column;
        }
        else
        {
            printf STDERR "* warning value in column not numeric: '%s'.\n", $columns[ $wantedColumn ] if ( $main::opt{'D'} );
        }
    }

    return 0;
}

# Returns the key composed of the selected fields
# param: String line of values from the input
# param: List of desired fields, or columns
# return: String composed of each string selected as column pasted together without trailing spaces
sub get_key( $$ )
{
    my $line          = shift;
    my $wantedColumns = shift;
    my $key           = "";
    my @columns = split( /\|/, $line );
    foreach my $column ( @{$wantedColumns} )
    {
        if ( defined $columns[ $column ] )
        {
            $key .= trim( $columns[ $column ] );
        }
    }
    return $key;
}

# Tests if argument is a whole number and returns it if is, and exits if not
# param: String value of a numeric value
# param: Do not exit if defined (optional)
# return: Number, or exits with warning if the value isn't a whole number
sub read_whole_number( $ )
{
    my $input = shift;
    my $value = get_number_format( $input, 1 );
    printf STDERR "argument to read_whole_number()='%s' \n", $value if ( $main::opt{'D'} );
    return 0 if ( $value eq '' );
    return $value if ( $value );
    printf STDERR "*** error: invalid argument, expected a whole number, but got '%s' \n", $input;
    exit( -1 );
}

# If there is data selected for extraction from the file argument (to '-0') 
# merge that data with the input line as required
# param: Input line read from STDIN
# return: None. Side effect; appends the true or false column data from the
#         the file argument specified with '-0'
sub merge_reference_file( $ )
{
    my $line = shift;
    # Compare columns from STDIN and look up the values in the reference file
    # by comparing columns in @main::MERGE_SRC_COLUMNS and @main::MERGE_REF_COLUMNS,
    # allowing for '-I', and '-N' operators.
    my $key = '';
    return if ( ! defined $main::MERGE_SRC_COLUMNS[0] );
    my $src_col = $main::MERGE_SRC_COLUMNS[0];
    # There may not even be such a column so test.
    return if ( ! defined @{$line}[$src_col] );
    # Normalize, and make case insensitive if required here.
    $key = @{$line}[$src_col];
    $key = uc $key if ( $main::opt{'I'} ); # Compare key in upper case if '-I'.
    $key = normalize( $key ) if ( $main::opt{'N'} );
    # Okay there is a column in the STDIN doc, but is there one in the reference doc?
    if ( exists $main::REF_FILE_DATA_HREF->{ $key } )
    {
        push @{$line}, split ',', $main::REF_FILE_DATA_HREF->{ $key };
    }
    else
    {
        push @{$line}, @main::REF_LITERALS_FALSE;  # which may be empty.
    }
    printf STDERR "KEY: '%s'\n", $key if ( $main::opt{'D'} );
}

1;

__END__

=head1 NAME

Pipe::Column - Column operations for pipe.pl

=head1 SYNOPSIS

    use Pipe::Column qw(:operations :parsing :merging);
    
    # Reorder columns
    order_line(\@columns);
    
    # Merge columns
    merge_line(\@columns);
    
    # Parse column specifications
    my @cols = read_requested_qualified_columns($spec, \%qualifiers, @keywords);
    
    # Get numeric value from column
    my $value = get_column_value("c1", $line);
    
    # Merge reference file data
    merge_reference_file(\@columns);

=head1 DESCRIPTION

This module handles all column-related operations for pipe.pl, including:
- Column reordering with keywords (remaining, continue, exclude, reverse)
- Column merging operations
- Column specification parsing with qualifiers
- Column value extraction and validation
- Reference file merging

=head1 EXPORTS

=head2 :operations

Functions for column manipulation:
- order_line() - Reorder columns according to specification
- merge_line() - Merge columns together

=head2 :parsing

Functions for column specification parsing:
- read_requested_qualified_columns() - Parse column specs with qualifiers
- get_column_value() - Extract numeric values from columns
- get_key() - Build keys from selected columns

=head2 :merging

Functions for file merging:
- merge_reference_file() - Merge data from reference files

=head2 :utilities

Utility functions:
- read_whole_number() - Parse and validate whole numbers

=head1 FUNCTIONS

=head2 order_line($columns_ref)

Reorders columns in a line according to the ORDER_COLUMNS specification.
Supports keywords: remaining, continue, exclude, reverse, last.

=head2 merge_line($columns_ref)

Merges columns according to the MERGE_COLUMNS specification.

=head2 read_requested_qualified_columns($spec, $qualifiers_ref, @keywords)

Parses column specifications with qualifiers (e.g., "c1:pattern,c2:value").

=head2 get_column_value($column_spec, $line)

Gets a numeric value from a specific column in a pipe-delimited line.

=head2 merge_reference_file($line_ref)

Merges data from reference files into the current line based on key matching.

=head1 AUTHOR

Pipe.pl contributors

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut