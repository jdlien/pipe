package Pipe::Data;

use strict;
use warnings;
use utf8;

use Pipe::Core qw(get_number_format trim);
use Pipe::Column qw(get_key get_column_value);
use Pipe::Text qw(normalize);
use Pipe::Math qw(do_op);

# Export functions to main package
use Exporter 'import';
our @EXPORT_OK = qw(
    sort_list dedup_list randomize_list push_merge_ref_columns
    finalize_full_read_functions
);

our %EXPORT_TAGS = (
    'sorting'   => [qw(sort_list)],
    'dedup'     => [qw(dedup_list)],
    'random'    => [qw(randomize_list)],
    'merge'     => [qw(push_merge_ref_columns)],
    'finalize'  => [qw(finalize_full_read_functions)],
    'all'       => \@EXPORT_OK,
);

# Access to pipe.pl global variables and constants
our $TRUE = 0;
our $FALSE = 1;

=head1 NAME

Pipe::Data - Data processing functions for pipe.pl (sorting, deduplication, randomization)

=head1 SYNOPSIS

    use Pipe::Data qw(:all);
    
    # Sort lines by specified columns
    sort_list(\@sort_columns);
    
    # Remove duplicates with optional aggregation
    dedup_list(\@dedup_columns);
    
    # Select random percentage of lines
    randomize_list();
    
    # Merge reference file data
    push_merge_ref_columns(\@col_indexes, \@line_data, $key_col);
    
    # Finalize operations after reading entire input
    finalize_full_read_functions();

=head1 DESCRIPTION

This module provides data processing functions for the pipe.pl tool, focusing on
operations that require processing the entire dataset: sorting, deduplication,
randomization, and reference file merging.

=head1 FUNCTIONS

=cut

=head2 sort_list()

Sorts the @main::ALL_LINES array in-place based on specified columns.

Parameters:
  $wantedColumns - Array reference containing column indices to sort on

Returns: None (modifies @main::ALL_LINES in-place)

The function supports various sorting options through global flags:
- -R: Reverse sort order  
- -U: Numeric sort (uses <=> operator)
- -I: Case-insensitive sort
- -N: Normalize keys before sorting

Uses O(1) space by building a hash of keys mapped to original lines.

=cut

sub sort_list( $ )
{
    my $all_list_ref  = {};
    my $wantedColumns = shift;
    my $count         = 1;
    while( @main::ALL_LINES )
    {
        my $line = shift @main::ALL_LINES;
        chomp $line;
        my $key = get_key( $line, $wantedColumns );
        $key = normalize( $key ) if ( $main::opt{'N'} );
        # Make the value.00000001 to make each key unique. If value is a number, sort numeric works.
        # Where this breaks is if the values you want to sort are floats. In that case we should just
        # add more least significant digits.
        if ( trim( $key ) =~ m/^\d+\.\d+$/ )
        {
            $all_list_ref->{ $key . sprintf( "%.8d", $count ) } = $line;
        }
        else
        {
            $all_list_ref->{ $key . '.' . sprintf( "%.8d", $count ) } = $line;
        }
        $count++;
    }
    my @sortedKeysArray = ();
    my @tempKeys        = ( keys %$all_list_ref );
    # reverse sort?
    if ( $main::opt{'R'} )
    {
        if ( $main::opt{'U'} )
        {
            @sortedKeysArray = sort { $b <=> $a } @tempKeys;
        }
        elsif ( $main::opt{'I'})
        {
            @sortedKeysArray = sort { lc($b) cmp lc($a) } @tempKeys;
        }
        else
        {
            @sortedKeysArray = sort { $b cmp $a } @tempKeys;
        }
    }
    else # Sort descending.
    {
        if ( $main::opt{'U'} )
        {
            @sortedKeysArray = sort { $a <=> $b } @tempKeys;
        }
        elsif ( $main::opt{'I'})
        {
            @sortedKeysArray = sort { lc($a) cmp lc($b) } @tempKeys;
        }
        else
        {
            @sortedKeysArray = sort { $a cmp $b } @tempKeys;
        }
    }
    # now remove the key from the start of the entry for each line in the array.
    while ( @sortedKeysArray )
    {
        my $key = shift @sortedKeysArray;
        print STDERR "\$key=$key\n" if ( $main::opt{'D'} );
        push @main::ALL_LINES, $all_list_ref->{ $key };
    }
}

=head2 dedup_list()

Removes duplicate lines from @main::ALL_LINES based on specified columns.

Parameters:
  $wantedColumns - Array reference containing column indices to use for deduplication

Returns: None (modifies @main::ALL_LINES in-place)

The function supports various deduplication options:
- -A: Include count of duplicates in output
- -J: Perform aggregation operations (min, max, avg, sum, count)
- -I: Case-insensitive key comparison
- -N: Normalize keys before comparison
- -R/-U: Sort output (reverse/numeric)
- -P: Use pipe delimiter format for counts

For -J operations, the function parses aggregation commands and applies
mathematical operations using the do_op() function from Pipe::Math.

=cut

sub dedup_list( $ )
{
    my $wantedColumns = shift;
    my $count         = {};
    while( @main::ALL_LINES )
    {
        my $line = shift @main::ALL_LINES;
        chomp $line;
        my $key = get_key( $line, $wantedColumns );
        $key = lc( $key ) if ( $main::opt{'I'} );
        $key = normalize( $key ) if ( $main::opt{'N'} );
        $main::ddup_ref->{ $key } = $line;
        if ( $main::opt{'A'} )
        {
            $count->{ $key } = 0 if ( ! exists $count->{ $key } );
            $count->{ $key }++;
        }
        elsif ( $main::opt{'J'} )
        {
            if ( ! exists $count->{ $key } )
            {
                $count->{ $key } = "init";
                $main::J_COUNT = 0;
                $main::J_BUCKET_COUNTS->{ $key } = 0;
            }
            if ($main::opt{'J'} =~ m/^(min|max|avg|sum|count)/i )
            {
                $main::J_CMD = lc($&);
                $main::opt{'J'} = $';
            }
            my $val = get_column_value( $main::opt{'J'}, $line );
            $count->{ $key } = do_op( $key, $count->{ $key }, $val );
        }
        print STDERR "\$key=$key, \$value=$line\n" if ( $main::opt{'D'} );
    }
    my @tmp = ();
    if ( $main::opt{'R'} )
    {
        if ( $main::opt{'U'} )
        {
            @tmp = sort { $b <=> $a } keys %{$main::ddup_ref};
        }
        else
        {
            @tmp = sort { $b cmp $a } keys %{$main::ddup_ref};
        }
    }
    else
    {
        if ( $main::opt{'U'} )
        {
            @tmp = sort { $a <=> $b } keys %{$main::ddup_ref};
        }
        else
        {
            @tmp = sort { $a cmp $b } keys %{$main::ddup_ref};
        }
    }
    while ( @tmp )
    {
        my $key = shift @tmp;
        if ( $main::opt{'A'} )
        {
            my $summary = '';
            if ( $main::opt{'P'} )
            {
                # Changed for consistency. Previously '|' would have been replaced before output.
                $summary = sprintf "%s%s", get_number_format( $count->{ $key } ), $main::DELIMITER;
            }
            else
            {
                $summary = sprintf " %3s ", get_number_format( $count->{ $key } );
            }
            push @main::ALL_LINES, $summary . $main::ddup_ref->{ $key };
        }
        elsif ( $main::opt{'J'} )
        {
            my $summary = '';
            if ( $main::J_CMD eq "avg" && $main::J_COUNT != 0 )
            {
                $count->{ $key } = ( $count->{ $key } / $main::J_BUCKET_COUNTS->{ $key } );
            }
            if ( $main::opt{'P'} )
            {
                $summary = sprintf "%s%s", get_number_format( $count->{ $key }, 0, $main::PRECISION ), $main::DELIMITER;
            }
            else
            {
                $summary = sprintf " %3s ", get_number_format( $count->{ $key }, 0, $main::PRECISION );
            }
            push @main::ALL_LINES, $summary . $main::ddup_ref->{ $key };
        }
        else
        {
            push @main::ALL_LINES, $main::ddup_ref->{ $key };
        }
        delete $main::ddup_ref->{ $key };
    }
}

=head2 randomize_list()

Randomly selects a percentage of lines from @main::ALL_LINES.

Parameters: None (uses global options)

Returns: None (modifies @main::ALL_LINES in-place)

The function uses the -r option value as a percentage (0-100) to determine
how many lines to select. Uses a hash-based approach to ensure unique
random indices are selected. Always returns at least 1 line even for
very small percentages.

Supports -D debug flag to output selected random indices to STDERR.

=cut

sub randomize_list()
{
    # Convert the user requested number to a percent lines of the file.
    my $count = int( ( $main::opt{ 'r' } / 100.0 ) * scalar @main::ALL_LINES ); # is already tested for valid percent in init().
    $count = 1 if ( $count < 1 );
    my $randomHash = {};
    my $i = 0;
    # Generate all the random numbers needed as indexes.
    while ( $i != $count )
    {
        my $r = int( rand( scalar @main::ALL_LINES ) );
        print "\$r=$r\n" if ( $main::opt{'D'} );
        $randomHash->{ $r } = 1;
        $i = scalar keys %$randomHash;
    }
    my @row_selection = keys %$randomHash;
    my @new_array = ();
    # Grab the values stored on the ALL_LINES array, but don't splice because
    # that will change the size and indexes will miss.
    while ( @row_selection )
    {
        my $index = shift @row_selection;
        if ( defined $main::ALL_LINES[ $index ] )
        {
            chomp $main::ALL_LINES[ $index ];
            push @new_array, $main::ALL_LINES[ $index ];
        }
    }
    # Empty original list.
    while ( @main::ALL_LINES )
    {
        shift @main::ALL_LINES;
    }
    # Place the randomized values back onto the @ALL_LINES array.
    while ( @new_array )
    {
        my $value = shift @new_array;
        push @main::ALL_LINES, $value;
    }
}

=head2 push_merge_ref_columns()

Extracts and stores column values from reference file data for later merging.

Parameters:
  $col_index - Array reference of column indices to extract
  $line      - Array reference representing one line of data  
  $key_col   - Column index to use as the lookup key

Returns: None (stores data in %main::REF_FILE_DATA_HREF)

The function extracts specified columns from a line and stores them in a global
hash using the key column value as the hash key. Supports case-insensitive (-I)
and normalization (-N) options for key processing.

Uses @main::REF_LITERALS_FALSE for missing column values when defined.
Joins extracted values with $main::DELIMITER for storage.

=cut

sub push_merge_ref_columns( $$$ )
{
    my $col_index = shift;
    my $line      = shift;
    my $key_col   = shift;
    return if ( ! defined $key_col );
    # The indexes of the target columns we want are stored in order. Like: (3, 0, 1, ...).
    $key_col = sprintf( "%d", $key_col );
    my $key = @{$line}[ $key_col ];
    $key = uc $key if ( $main::opt{'I'} ); # Compare key in upper case if '-I'.
    $key = normalize( $key ) if ( $main::opt{'N'} );
    # Return is the key is blank, like if the index is out of range, or the files have different delimiters.
    return if ( ! defined $key );
    my @string_values = ();
    foreach my $i ( @{$col_index} )
    {
        if ( defined @{$line}[ $i ] )
        {
            push @string_values, @{$line}[ $i ];
        }
        elsif ( @main::REF_LITERALS_FALSE ) 
        {
            push @string_values, @main::REF_LITERALS_FALSE;
        }
        else
        {
            # Ensure a value if there aren't literals and no value or '0' stored in array.
            push @string_values, "";
        }
    }
    my $values = join $main::DELIMITER, @string_values;
    $main::REF_FILE_DATA_HREF->{ $key } = $values;
    print STDERR "$key => $values\n" if ( $main::opt{'D'} );
}

=head2 finalize_full_read_functions()

Executes final processing operations after reading all input data.

Parameters: None (uses global options and data)

Returns: None (modifies global data structures)

This function performs end-of-file operations based on command-line flags:

- -d: Calls dedup_list() to remove duplicates
- -r: Calls randomize_list() to select random percentage  
- -s: Calls sort_list() to sort the data
- -v: Computes final averages from %main::avg_ref and %main::avg_count

For average computation (-v), divides accumulated sums by their counts
and formats results to 3 decimal places. Only processes columns where
both avg_ref and avg_count exist and count is non-zero.

=cut

sub finalize_full_read_functions()
{
    if ( $main::opt{'d'} )
    {
        dedup_list( \@main::DDUP_COLUMNS );
    }
    if ( $main::opt{'r'} ) # select 'n'% of file at random for output.
    {
        randomize_list();
    }
    if ( $main::opt{'s'} )# Sort the items from STDIN.
    {
        # We have a list of lines. We will split them creating a key that we append to the start with a delimiter of ''
        # When it comes time to sort use the default sort in perl and then remove the prefix.
        sort_list( \@main::SORT_COLUMNS );
    }
    if ( $main::opt{'v'} ) # Compute averages now we have read the entire input.
    {
        foreach my $column ( keys %{$main::avg_ref} )
        {
            if ( exists $main::avg_count->{ $column } and $main::avg_count->{ $column } != 0 )
            {
                my $result = sprintf "%.3f", ( $main::avg_ref->{ $column } / $main::avg_count->{ $column } );
                # replace the previous column sum with the average.
                $main::avg_ref->{ $column } = $result;
            }
        }
    }
}

=head1 DEPENDENCIES

This module requires:

=over 4

=item * Pipe::Core - For get_number_format() and trim() functions

=item * Pipe::Column - For get_key() and get_column_value() functions  

=item * Pipe::Text - For normalize() function

=item * Pipe::Math - For do_op() aggregation operations

=back

=head1 GLOBAL VARIABLES

This module operates on several global variables from the main:: namespace:

=over 4

=item * @main::ALL_LINES - Primary data array for processing

=item * %main::opt - Command-line options hash

=item * %main::ddup_ref - Deduplication data storage

=item * %main::avg_ref, %main::avg_count - Average computation data

=item * %main::REF_FILE_DATA_HREF - Reference file merge data

=item * $main::DELIMITER, $main::PRECISION - Formatting options

=back

=head1 AUTHOR

Generated for pipe.pl project

=head1 SEE ALSO

L<Pipe::Core>, L<Pipe::Column>, L<Pipe::Text>, L<Pipe::Math>

=cut

1;