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
);

our %EXPORT_TAGS = (
    'sorting'   => [qw(sort_list)],
    'dedup'     => [qw(dedup_list)],
    'random'    => [qw(randomize_list)],
    'merge'     => [qw(push_merge_ref_columns)],
    'all'       => \@EXPORT_OK,
);

# Access to pipe.pl global variables and constants
our $TRUE = 0;
our $FALSE = 1;

# Sorts the ALL_LINES array using (O)1 space.
# param:  list of columns to sort on.
# return: <none> - reorders the ALL_LINES list.
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

# Dedups the ALL_LINES array using (O)1 space.
# param:  list of columns to sort on.
# return: <none> - removes duplicate values from the ALL_LINES list.
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

# Randomizes the entire list of input lines.
# param:  <none>
# return: <none>
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

# param:  line from the file. Also an array of columns. We take the values from here and save them.
# param:  Key of the column to store from the ref file.
# return: none.
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

1;