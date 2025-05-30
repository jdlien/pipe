package Pipe::Math;

use strict;
use warnings;
use utf8;

use Pipe::Core qw(get_number_format);
use Pipe::Column qw(read_whole_number);

=head1 NAME

Pipe::Math - Mathematical operations and aggregations for pipe.pl

=head1 SYNOPSIS

    use Pipe::Math qw(:all);
    
    # Count non-empty values
    count(\@line);
    
    # Sum numeric values
    sum(\@line);
    
    # Calculate column widths
    width(\@line, $line_number);
    
    # Compute averages
    average(\@line);
    
    # Increment values
    inc_line(\@line);
    inc_line_by_value(\@line);
    
    # Mathematical operations
    do_math(\@line);
    
    # Delta calculations
    delta_previous_line(\@line);
    
    # Auto-increment functionality
    add_auto_increment(\@line);
    
    # Histogram generation
    my $graph = histogram(\@line);

=head1 DESCRIPTION

Pipe::Math provides mathematical operations and statistical aggregations
for the pipe.pl text processing tool. It handles counting, summation,
averaging, width calculations, delta operations, and histogram generation.

=head1 FUNCTIONS

=head2 count($line_ref)

Counts non-empty values in specified columns.

Parameters:
- $line_ref: Array reference to line data

Returns: None (modifies global $main::count_ref)

=head2 sum($line_ref)

Sums numeric values in specified columns.

Parameters:
- $line_ref: Array reference to line data

Returns: None (modifies global $main::sum_ref)

=head2 width($line_ref, $line_number)

Calculates minimum and maximum width of column values.

Parameters:
- $line_ref: Array reference to line data
- $line_number: Current line number for tracking

Returns: None (modifies global width reference variables)

=head2 average($line_ref)

Computes running averages for specified columns.

Parameters:
- $line_ref: Array reference to line data

Returns: None (modifies global $main::avg_ref and $main::avg_count)

=head2 inc_line($line_ref)

Increments values in specified columns by 1.

Parameters:
- $line_ref: Array reference to line data

Returns: None (modifies line data in place)

=head2 inc_line_by_value($line_ref)

Increments values in specified columns by their current values.

Parameters:
- $line_ref: Array reference to line data

Returns: None (modifies line data in place)

=head2 do_math($line_ref)

Performs mathematical operations (add, subtract, multiply, divide) on columns.

Parameters:
- $line_ref: Array reference to line data

Returns: None (modifies line data in place)

=head2 delta_previous_line($line_ref)

Calculates differences between current and previous line values.

Parameters:
- $line_ref: Array reference to line data

Returns: None (modifies line data in place)

=head2 add_auto_increment($line_ref)

Adds auto-incrementing sequence numbers to lines.

Parameters:
- $line_ref: Array reference to line data

Returns: None (modifies line data in place)

=head2 histogram($line_ref)

Generates histogram characters for specified columns.

Parameters:
- $line_ref: Array reference to line data

Returns: String of histogram characters

=head2 do_op($key, $current_value, $new_value)

Helper function for performing aggregation operations (min, max, sum, avg).

Parameters:
- $key: Operation key identifier
- $current_value: Current accumulated value
- $new_value: New value to process

Returns: Updated accumulated value

=head1 DEPENDENCIES

- Pipe::Core - For numeric formatting and utilities
- Pipe::Column - For number reading operations

=head1 GLOBAL VARIABLES

This module accesses global variables from the main:: package including:
- Column arrays (@COUNT_COLUMNS, @SUM_COLUMNS, @WIDTH_COLUMNS, etc.)
- Reference hashes ($count_ref, $sum_ref, $width_*_ref, etc.)
- Auto-increment variables ($AUTO_INCR_COLUMN, $AUTO_INCR_SEED, etc.)
- Options hash (%opt) for flags like -D (debug), -R (reverse), -N (absolute)

=head1 SEE ALSO

L<Pipe::Core>, L<Pipe::Column>, L<Pipe::Data>

=cut

# Export functions to main package
use Exporter 'import';
our @EXPORT_OK = qw(
    count sum width average inc_line inc_line_by_value do_math 
    delta_previous_line histogram do_op add_auto_increment
);

our %EXPORT_TAGS = (
    'aggregation' => [qw(count sum average width)],
    'increments'  => [qw(inc_line inc_line_by_value add_auto_increment)],
    'operations'  => [qw(do_math do_op delta_previous_line)],
    'display'     => [qw(histogram)],
    'all'         => \@EXPORT_OK,
);

# Access to pipe.pl global variables and constants
our $TRUE = 0;
our $FALSE = 1;

# Counts the non-empty values of specified columns.
# param:  line to pull out columns from.
# return: string line with requested columns removed.
sub count( $ )
{
    my $line = shift;
    foreach my $colIndex ( @main::COUNT_COLUMNS )
    {
        if ( defined @{ $line }[ $colIndex ] and @{ $line }[ $colIndex ] =~ m/\S/ )
        {
            $main::count_ref->{ "c$colIndex" }++;
        }
    }
}

# Sums the non-empty values of specified columns.
# param:  line to pull out columns from.
# return: string line with requested columns removed.
sub sum( $ )
{
    my $line = shift;
    foreach my $colIndex ( @main::SUM_COLUMNS )
    {
        if ( defined @{ $line }[ $colIndex ] and Pipe::Core::trim( @{ $line }[ $colIndex ] ) =~ m/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ )
        {
            $main::sum_ref->{ "c$colIndex" } += Pipe::Core::trim( @{ $line }[ $colIndex ] );
        }
    }
}

# Computes the maximum and minimum width of all the data in the column.
# param:  line to pull out columns from.
# param:  line number.
# return: string line with requested columns removed.
sub width( $$ )
{
    my $line = shift;
    my $line_no = shift;
    foreach my $colIndex ( @main::WIDTH_COLUMNS )
    {
        if ( defined @{ $line }[ $colIndex ] )
        {
            my $length = length @{ $line }[ $colIndex ];
            printf STDERR "COL: '%s'::LEN '%d'\n", @{ $line }[ $colIndex ], $length if ( $main::opt{'D'} );
            if ( ! exists $main::width_min_ref->{ "c$colIndex" } )
            {
                $main::width_line_min_ref->{ "c$colIndex" } = $line_no;
                $main::width_min_ref->{ "c$colIndex" } = $length;
            }
            if ( ! exists $main::width_max_ref->{ "c$colIndex" } )
            {
                $main::width_line_max_ref->{ "c$colIndex" } = $line_no;
                $main::width_max_ref->{ "c$colIndex" } = $length;
            }
            $main::width_line_min_ref->{ "c$colIndex" } = $line_no if ( $length < $main::width_min_ref->{ "c$colIndex" } );
            $main::width_line_max_ref->{ "c$colIndex" } = $line_no if ( $length >= $main::width_max_ref->{ "c$colIndex" } );
            $main::width_min_ref->{ "c$colIndex" } = $length if ( $length < $main::width_min_ref->{ "c$colIndex" } );
            $main::width_max_ref->{ "c$colIndex" } = $length if ( $length >= $main::width_max_ref->{ "c$colIndex" } );
        }
        else
        {
            # Update the min width to '0' since other lines might have added a value - regardless this is the shortest.
            $main::width_line_min_ref->{ "c$colIndex" } = $line_no; # And this is the last shortest (so far).
            $main::width_min_ref->{ "c$colIndex" } = 0;
            if ( ! exists $main::width_max_ref->{ "c$colIndex" } )
            {
                $main::width_line_max_ref->{ "c$colIndex" } = $line_no;
                $main::width_max_ref->{ "c$colIndex" } = 0;
            }
        }
    }
    $main::WIDTHS_COLUMNS->{ @{ $line } } = $main::LINE_NUMBER;
}

# Average the non-empty values of specified columns.
# param:  line to pull out columns from.
# return: string line with requested columns removed.
sub average( $ )
{
    my $line = shift;
    foreach my $colIndex ( @main::AVG_COLUMNS )
    {
        if ( defined @{ $line }[ $colIndex ] and Pipe::Core::trim( @{ $line }[ $colIndex ] ) =~ m/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ )
        {
            $main::avg_ref->{ "c$colIndex" } += Pipe::Core::trim( @{ $line }[ $colIndex ] );
            $main::avg_count->{ "c$colIndex" } = 0 if ( ! exists $main::avg_count->{ "c$colIndex" } );
            $main::avg_count->{ "c$colIndex" }++;
        }
    }
}

# Increments values in column data.
# param:  Array reference of line's columns.
# return: string with table formatting.
sub inc_line( $ )
{
    my $line = shift;
    foreach my $colIndex ( @main::INCR_COLUMNS )
    {
        if ( defined @{ $line }[ $colIndex ] )
        {
            @{ $line }[ $colIndex ]++;
        }
    }
}

# Increments values in column data by a given step.
# param:  Array reference of line's columns.
# return: <none>
sub inc_line_by_value( $ )
{
    my $line    = shift;
    foreach my $colIndex ( @main::INCR3_COLUMNS )
    {
        if ( defined @{ $line }[ $colIndex ] )
        {
            if ( $main::increment_ref->{ $colIndex } =~ m/^(\-)?\d+(\.\d+)?$/ )
            {
                @{ $line }[ $colIndex ] += $main::increment_ref->{ $colIndex };
            }
            else
            {
                printf STDERR "* warning invalid increment value: '%s'\n", $main::increment_ref->{ $colIndex } if ( $main::opt{'D'} );
            }
        }
    }
}

# Performs math operations on columns.
sub do_math( $ )
{
    my $line    = shift;
    my $count_numeric_columns = 0;
    my $result  = 0.0;
    foreach my $colIndex ( @main::MATH_COLUMNS )
    {
        $colIndex =~ s/c//i;
        if ( defined @{ $line }[ $colIndex ] )
        {
            # Guard against values that can't be operated on mathematically.
            if ( @{ $line }[ $colIndex ] !~ m/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ )
            {
                printf STDERR "* warning can't use '%s' for computation.\n", @{ $line }[ $colIndex ] if ( $main::opt{'D'} );
                next;
            }
            # You have to store the first value @line[0] if it exists and is numeric to pre populate the result for mul, div, sub.
            if ( $count_numeric_columns == 0 )
            {
                $result = @{ $line }[ $colIndex ];
                $count_numeric_columns++;
                next;
            }
            if ( exists $main::math_ref->{'add'} )
            {
                $result += @{ $line }[ $colIndex ];
            }
            elsif ( exists $main::math_ref->{'sub'} )
            {
                $result -= @{ $line }[ $colIndex ];
            }
            elsif ( exists $main::math_ref->{'mul'} )
            {
                $result *= @{ $line }[ $colIndex ];
            }
            elsif ( exists $main::math_ref->{'div'} )
            {   
                if ( @{ $line }[ $colIndex ] == 0 )
                {
                    printf STDERR "*** error divide by 0 error.\n" if ( $main::opt{'D'} );
                    $result = "NaN";
                } 
                else
                {
                    $result /= @{ $line }[ $colIndex ];
                }
            }
            else
            {
                printf STDERR "*** error unsupported operation '%s'.\n", keys %{$main::math_ref};
                exit();
            }
        }
        $count_numeric_columns++;
    }
    # Place the result in the '0'th field.
    unshift @{ $line }, get_number_format( $result, 0, $main::PRECISION );
}

# Computes the difference between this line and the previous and outputs that difference.
# param:  Array reference of line's columns.
# return: <none>
sub delta_previous_line( $ )
{
    # my @DELTA4_COLUMNS    = (); my $delta_cols_ref= {};
    my $line    = shift;
    foreach my $colIndex ( @main::DELTA4_COLUMNS )
    {
        if ( defined @{ $line }[ $colIndex ] )
        {
            # Guard against values that can't be subtracted.
            if ( @{ $line }[ $colIndex ] !~ m/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ )
            {
                printf STDERR "* warning can't use '%s' for computation.\n", @{ $line }[ $colIndex ] if ( $main::opt{'D'} );
                next;
            }
            # Save the first value
            if ( ! exists $main::delta_cols_ref->{ $colIndex } )
            {
                $main::delta_cols_ref->{ $colIndex } = @{ $line }[ $colIndex ];
                next;
            }
            # But if the '-R' reverse switch is used subtract this value from the previous line.
            if ( $main::opt{'R'} )
            {
                # Save this rows orginial value in this row for the next row's calculation.
                my $tmp = @{ $line }[ $colIndex ];
                # Compute the new value for this row.
                if ( $main::opt{'N'} )
                {
                    @{ $line }[ $colIndex ] = abs $main::delta_cols_ref->{ $colIndex } - @{ $line }[ $colIndex ];
                }
                else
                {
                    @{ $line }[ $colIndex ] = $main::delta_cols_ref->{ $colIndex } - @{ $line }[ $colIndex ];
                }
                $main::delta_cols_ref->{ $colIndex } = $tmp;
            }
            else
            {
                # Save this rows orginial value in this row for the next row's calculation.
                my $tmp = @{ $line }[ $colIndex ];
                # Compute the new value for this row.
                if ( $main::opt{'N'} )
                {
                    @{ $line }[ $colIndex ] = abs @{ $line }[ $colIndex ] - $main::delta_cols_ref->{ $colIndex };
                }
                else
                {
                    @{ $line }[ $colIndex ] = @{ $line }[ $colIndex ] - $main::delta_cols_ref->{ $colIndex };
                }
                $main::delta_cols_ref->{ $colIndex } = $tmp;
            }
        }
    }
}

# Adds an auto-incremented field to the output line in the column position specified.
# param:  Array reference of line's columns.
# return: string with table formatting.
sub add_auto_increment( $ )
{
    my $line = shift;
    my $size = scalar( @{ $line } );
    if ( $main::AUTO_INCR_COLUMN >= $size )
    {
        push @{ $line }, $main::AUTO_INCR_SEED++;
    }
    else
    {
        splice @{ $line }, $main::AUTO_INCR_COLUMN, 0, $main::AUTO_INCR_SEED++;
    }
    # The start and end range are inclusive, so we have to increment the AUTO_INCR_RESET by 1 with the post increment
    # code above.
    if ( $main::AUTO_INCR_RESET =~ m/^\d+$/ && $main::AUTO_INCR_SEED =~ m/^\d+$/ )
    {
        $main::AUTO_INCR_SEED = $main::AUTO_INCR_ORIG_VALUE if ( $main::AUTO_INCR_RESET && $main::AUTO_INCR_SEED >= $main::AUTO_INCR_RESET + 1 );
    }
    else
    {
        $main::AUTO_INCR_SEED = $main::AUTO_INCR_ORIG_VALUE if ( $main::AUTO_INCR_RESET && $main::AUTO_INCR_SEED gt $main::AUTO_INCR_RESET );
    }
}

# Shows histogram of columns value.
# param:  Array reference of line's columns.
# return: character(s) to be used for graphing.
sub histogram( $ )
{
    my $line = shift;
    foreach my $colIndex ( @main::HISTOGRAM_COLUMN )
    {
        if ( defined @{ $line }[ $colIndex ] )
        {
            printf STDERR "stored column:%s\n", @{ $line }[ $colIndex ] if ( $main::opt{'D'} );
            my $range_whole_number = read_whole_number( @{ $line }[ $colIndex ] );
            my @new_string = ();
            foreach my $i ( 1..$range_whole_number )
            {
                push @new_string, $main::hist_ref->{ $colIndex };
            }
            @{ $line }[ $colIndex ] = join '', @new_string;
        }
    }
}

# Does an extended math operation on a group.
# param: The operation string (min,max,avg,sum).
# param: The variable where the computed value is placed.
# param: The value from the selected field.
# return: none
sub do_op( $$$ )
{
    my $key = shift;
    my $cur = shift;
    my $val = shift;
    if ( $val !~ /^[+|-]?\d{1,}(\.\d{1,})?$/ )
    {
        printf STDERR "skipping non-numeric value on $main::LINE_NUMBER\n" if ( $main::opt{'D'} );
        return $cur;
    }
    $main::J_COUNT++;
    $main::J_BUCKET_COUNTS->{ $key }++;
    return $val if ( $cur eq "init" );
    if ( $main::J_CMD =~ m/min/ )
    {
        if ( $val < $cur ) 
        {
            return $val;
        }
        else
        {
            return $cur;
        }
    }
    elsif ( $main::J_CMD =~ m/max/ )
    {
        if ( $val > $cur ) 
        {
            return $val;
        }
        else
        {
            return $cur;
        }
    }
    elsif ( $main::J_CMD =~ m/avg/ )
    {
        return ( $cur += $val );
    }
    elsif ( $main::J_CMD =~ m/sum/ )
    {
        # Same as default action.
        return ( $cur += $val );
    }
    elsif ( $main::J_CMD =~ m/count/ )
    {
        return $main::J_COUNT;
    }
    else
    {
        return ( $cur += $val );
    }
}

1;