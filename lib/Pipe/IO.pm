package Pipe::IO;

use strict;
use warnings;
use utf8;
use Exporter 'import';
use Pipe::Core qw(:constants :keywords trim get_number_format);

# Note: This module accesses global variables from the main:: package

our @EXPORT_OK = qw(
    prepare_table_data
    table_output
    print_summary
    is_printable_range
    build_encoding_table
    map_url_characters
);

our %EXPORT_TAGS = (
    output => [qw(prepare_table_data table_output print_summary)],
    input => [qw(is_printable_range)],
    encoding => [qw(build_encoding_table map_url_characters)],
);

# Outputs data from argument line as a table of one type or another.
# param:  String of line data - pipe-delimited.
# return: <none>.
sub prepare_table_data( $ )
{
    my $line = shift;
    my @newLine = ();
    if ( $main::TABLE_OUTPUT =~ m/HTML/i )
    {
        push @newLine, "  <tr><td>";
        foreach my $value ( @{ $line } )
        {
            push @newLine, $value;
            push @newLine, '</td><td>';
        }
        # remove the last '</td><td>'.
        pop @newLine;
        push @newLine, "</td></tr>";
    }
    elsif ( $main::TABLE_OUTPUT =~ m/MEDIA_WIKI/i )
    {
        push @newLine, "|-\n";
        foreach my $value ( @{ $line } )
        {
            push @newLine, "| ";
            push @newLine, $value;
            push @newLine, "\n";
        }
    }
    elsif ( $main::TABLE_OUTPUT =~ m/WIKI/i )
    {
        push @newLine, "\n|-\n| ";
        foreach my $value ( @{ $line } )
        {
            push @newLine, $value;
            push @newLine, ' || ';
        }
        # remove the last ' || '.
        pop @newLine;
        # push @newLine, "\n|-";
    }
    elsif ( $main::TABLE_OUTPUT =~ m/MD/i )
    {
        # Markdown tables start with a '|'
        push @newLine, '| ';
        foreach my $value ( @{ $line } )
        {
            push @newLine, $value;
            push @newLine, ' | ';
        }
        push @newLine, "\n";
    }
    elsif ( $main::TABLE_OUTPUT =~ m/CSV/i )
    {
        foreach my $value ( @{ $line } )
        {
            if ( $main::TABLE_OUTPUT =~ m/UTF-8/ )
            {
                # remove repeated white space
                $value =~ s/\s+/ /g;
                # Only quote values that contain ','
                if ( $value =~ m/,/ || $value =~ m/[\"|\']/)
                {
                    $value =~ s/\"/\"\"/g;
                    push @newLine, "\"".$value."\"";
                }
                else
                {
                    push @newLine, $value;
                }
            }
            else
            {
                if ( $value =~ m/^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ )
                {
                    push @newLine, $value;
                }
                else
                {
                    push @newLine, "\"".$value."\"";
                }
            }
            push @newLine, ',';
        }
        # The number of titles indicate the expected width of each row.
        if ( $main::TOTAL_CSV_COLS )
        {
            # Add trailing delimiters to match expected columns if the row is ragged and short.
            for ( my $i = scalar(@{ $line }); $i < $main::TOTAL_CSV_COLS; $i++ )
            {
                push @newLine, ',';
            }
        }
        # remove the last ','.
        pop @newLine;
        push @newLine, "\n";
    }
    elsif ( $main::TABLE_OUTPUT =~ m/CHUNKED/i )
    {
        foreach my $value ( @{ $line } )
        {
            push @newLine, $value;
            push @newLine, $DELIMITER;
        }
        # remove the last delimiter.
        pop @newLine;
        push @newLine, "\n";
        # Place the requested literal AFTER the requisite number of skip rows are output.
        if ( defined $main::SKIP_LINE_TABLE && $main::SKIP_LINE_TABLE > 0 )
        {
            if ( $main::LINE_NUMBER % $main::SKIP_LINE_TABLE == 0 )
            {
                  push @newLine, $main::SKIP_VALUE;
                  push @newLine, "\n";
            }
        }
    }
    else # Huh, unknown table type.
    {
        printf STDERR "** error, unsupported table type '%s'\n", $main::TABLE_OUTPUT;
        exit( 1 );
    }
    @{ $line } = ();
    foreach my $v ( @newLine )
    {
        push @{ $line }, $v;
    }
}

# Outputs table headers and footers for various formats
# param: String - placement ("HEAD" or "FOOT")
# return: None (prints directly)
sub table_output( $ )
{
    my $placement = shift;
    if ( $main::TABLE_OUTPUT =~ m/HTML/i )
    {
        if ( $placement =~ m/HEAD/ )
        {
            printf "<table%s>\n  <tbody>\n", $main::TABLE_ATTR;
        }
        else
        {
            printf "  </tbody>\n</table>\n";
        }
    }
    elsif ( $main::TABLE_OUTPUT =~ m/MEDIA_WIKI/i )
    {
        if ( $placement =~ m/HEAD/ )
        {
            # {| class="wikitable" 
            # |- style="font-weight:bold;"
            # ! A
            # ! B
            # |-
            # printf "{| class='wikitable'%s", $main::TABLE_ATTR;
            my @headers = split(/,/, $main::TABLE_ATTR);
            printf "{| class=\"wikitable\"\n";
            if ( scalar( @headers ) > 0)
            {
                printf "|- style=\"font-weight:bold;\"\n";
                foreach my $my_header ( @headers )
                {
                    printf "! %s\n", trim($my_header);
                }
            }
            # printf "|-";
        }
        else 
        {
            printf "|}\n";
        }
    }
    elsif ( $main::TABLE_OUTPUT =~ m/WIKI/i )
    {
        if ( $placement =~ m/HEAD/ )
        {
            # printf "{| class='wikitable'%s", $main::TABLE_ATTR;
            # {| class="wikitable" 
            # |- style="font-weight:bold;"
            # ! A
            # ! B
            # |-
            my @headers = split(/,/, $main::TABLE_ATTR);
            printf "{| class=\"wikitable\"";
            if ( scalar( @headers ) > 0)
            {
                printf "\n|- style=\"font-weight:bold;\"";
                foreach my $my_header ( @headers )
                {
                    printf "\n! %s", trim($my_header);
                }
            }
        }
        else
        {
            printf "\n|}\n";
        }
    }
    elsif ( $main::TABLE_OUTPUT =~ m/MD/i )
    {
        if ( $placement =~ m/HEAD/ )
        {
            # | **A** | **B** |
            # |---|---|
            my @headers = split(/,/, $main::TABLE_ATTR);
            if ( scalar( @headers ) > 0)
            {
                printf "|";
                foreach my $my_header ( @headers )
                {
                    printf " **%s** |", trim($my_header);
                }
                printf "\n";
                # Print the header separation bar
                printf "|:";
                foreach my $my_header ( @headers )
                {
                    printf "---:|";
                }
                printf "\n";
            }
        }
        # No footer for MarkDown.
    }
    elsif ( $main::TABLE_OUTPUT =~ m/^CSV/i )
    {
        if ( $placement =~ m/HEAD/ )
        {
            my @titles = split ',', $main::TABLE_ATTR;
            my $out_string = "";
            # The number of titles dictates the number of columns which we try to ensure.
            $main::TOTAL_CSV_COLS = scalar( @titles );
            for my $title ( @titles )
            {
                if ( $main::TABLE_OUTPUT =~ m/UTF-8/ )
                {
                    $out_string .= sprintf "%s,", trim( $title );
                }
                else
                {
                    $out_string .= sprintf "\"%s\",", trim( $title );
                }
            }
            chop( $out_string ); # Take the last ',' off the end of the string.
            printf "%s\n", $out_string if ( $out_string );
        }
        # No footer for CSV.
    }
    elsif ( $main::TABLE_OUTPUT =~ m/CHUNKED/i )
    {
        if ( $placement =~ m/HEAD/ )
        {
            # [BEGIN={literal}][,SKIP={integer}.{literal}][,END={literal}
            my @keywords = split ',', $main::TABLE_ATTR;
            foreach my $keyword_assignment ( @keywords )
            {
                my ( $keyword, @params ) = split /=/, $keyword_assignment;
                my $param = join '=', @params;
                if ( defined $keyword )
                {
                    if ( $keyword =~ m/BEGIN/ )
                    {
                        $main::BEGIN_VALUE = $param;
                    }
                    elsif ( $keyword =~ m/END/ )
                    {
                        $main::END_VALUE = $param;
                    }
                    elsif ( $keyword =~ m/SKIP/ )
                    {
                        # parse out the number of lines to skip and the literal.
                        ( $main::SKIP_LINE_TABLE, my @skip_values ) = split '\.', $param;
                        if ( $main::SKIP_LINE_TABLE !~ m/^\d+$/ || ( $main::SKIP_LINE_TABLE + 0 ) < 1 )
                        {
                            printf STDERR "**error: invalid skip value '%s' requested in chunked table output.\n", $main::SKIP_LINE_TABLE;
                            exit 0;
                        }
                        # Preserver literals that contain '.'
                        $main::SKIP_VALUE = join '.', @skip_values;
                    }
                }
            }
            printf STDERR "BEGIN='%s' SKIP='%s'.'%s', END='%s'\n", $main::BEGIN_VALUE, $main::SKIP_LINE_TABLE, $main::SKIP_VALUE, $main::END_VALUE if ( $main::opt{'D'} );
            printf "%s\n", $main::BEGIN_VALUE if ( defined $main::BEGIN_VALUE && $main::BEGIN_VALUE !~ m/^$/ );
        }
        else # Footer for chunked table types.
        {
            printf "%s\n", $main::END_VALUE if ( defined $main::END_VALUE && $main::END_VALUE !~ m/^$/ );
        }
    }
}

# Prints summary statistics to STDERR
# param: Title of the summary section
# param: Hash reference containing the statistics
# param: Array reference of columns to report
# param: Context object
# return: None (prints to STDERR)
sub print_summary {
    my $title = shift;
    my $hash_ref = shift;
    my $columns = shift;
    my $context = shift;
    my $delimiter = $context->{delimiter} || $DELIMITER;
    my $precision = $context->{precision} || 2;
    my $suppress_headers = $context->get_option('N') || 0;
    
    printf STDERR "== %9s\n", $title if ($title && !$suppress_headers);
    
    foreach my $column (sort @{$columns}) {
        my $value = 0;
        $value = $hash_ref->{'c'.$column} if (defined $hash_ref->{'c'.$column});
        
        if ($suppress_headers) {
            printf STDERR "%s%s%s\n", 'c'.$column, $delimiter, get_number_format($value, 0, $precision);
        }
        else {
            printf STDERR " c%s: %7s\n", $column, get_number_format($value, 0, $precision);
        }
    }
}

# Check if line number is within printable range
# param: Line number to check
# param: Context object
# return: 1 if printable, 0 if not
sub is_printable_range {
    my $line_number = shift;
    my $context = shift;
    my $line_ranges = $context->{line_ranges};
    
    # Check if any range includes this line number
    foreach my $start (keys %{$line_ranges}) {
        my $end = $line_ranges->{$start};
        
        # Handle negative ranges (tail functionality)
        if ($start < 0) {
            # This requires knowing total line count, which is handled elsewhere
            return 1;
        }
        
        # Normal range check
        if ($line_number >= $start && $line_number <= $end) {
            return 1;
        }
    }
    
    return 0;
}


# Module-level URL character encoding table
my $url_characters = {};

# Builds URL encoding character table
# return: None (populates module-level $url_characters)
sub build_encoding_table() {
    # Build encoding table for URL characters
    for my $i (0..255) {
        my $char = chr($i);
        if ($char =~ /[A-Za-z0-9._~-]/) {
            $url_characters->{$i} = $char;
        }
        else {
            $url_characters->{$i} = sprintf("%%%02X", $i);
        }
    }
}

# Maps characters to their URL-encoded equivalents
# param: String to encode
# return: URL-encoded string
sub map_url_characters {
    my $input = shift;
    
    my @characters = split '', $input;
    my @newString = ();
    while (@characters) {
        my $c = shift @characters;
        next if (!defined $c);
        if (exists $url_characters->{ord $c}) {
            push @newString, $url_characters->{ord $c};
            next;
        }
        push @newString, $c;
    }
    return join '', @newString;
}

1;

__END__

=head1 NAME

Pipe::IO - Input/Output operations for pipe.pl

=head1 SYNOPSIS

    use Pipe::IO qw(:output :processing);
    
    # Format table data
    prepare_table_data(\@columns, $table_format, $total_cols, $delimiter);
    
    # Output table headers/footers
    table_output($context, $table_type);
    
    # Print summary statistics
    print_summary($title, \%stats, \@columns, $context);
    
    # Process full file operations
    finalize_full_read_functions($context, \@all_lines);

=head1 DESCRIPTION

This module handles all input/output operations for pipe.pl, including:
- Table formatting for HTML, Wiki, Markdown, CSV, and chunked output
- Summary statistics output
- Full-file processing operations (dedup, sort, averages)
- URL encoding utilities
- Line range filtering

=head1 EXPORTS

=head2 :output

Functions for formatting and outputting data:
- prepare_table_data() - Format line data for table output
- table_output() - Output table headers and footers
- print_summary() - Print summary statistics

=head2 :input

Functions for input processing:
- is_printable_range() - Check if line is in output range

=head2 :processing

Functions for full-file processing:
- finalize_full_read_functions() - Perform operations requiring full file

=head2 :encoding

Functions for URL encoding:
- build_encoding_table() - Create encoding character map
- map_url_characters() - Encode string for URLs

=head1 FUNCTIONS

=head2 prepare_table_data($columns_ref, $table_format, $total_cols, $delimiter)

Formats column data for different table output formats.

=head2 table_output($context, $table_type)

Outputs appropriate table headers and footers based on format.

=head2 print_summary($title, $stats_ref, $columns_ref, $context)

Prints summary statistics to STDERR in the appropriate format.

=head2 is_printable_range($line_number, $context)

Checks if a given line number falls within the printable range specified in the context.
Returns 1 if the line should be printed, 0 otherwise.

=head2 build_encoding_table()

Builds a hash table of URL encoding mappings for characters that need to be encoded.
Populates the global %url_characters hash with character codes and their encoded equivalents.

=head2 map_url_characters($string)

Encodes a string for URL transmission by replacing special characters with percent-encoded equivalents.
Returns the encoded string.

=head2 finalize_full_read_functions($context, $all_lines_ref)

Performs operations that require the entire file to be loaded first.

=head1 AUTHOR

Pipe.pl contributors

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut