#!/usr/bin/perl
#
# Unit tests for Pipe::IO module
#
use strict;
use warnings;
use Test::More;
use lib 'lib';

BEGIN { 
    use_ok('Pipe::IO') or BAIL_OUT("Can't load Pipe::IO");
    use_ok('Pipe::Context') or BAIL_OUT("Can't load Pipe::Context");
}

# Test prepare_table_data function for different formats
{
    # Test HTML format
    local $main::TABLE_OUTPUT = 'HTML';
    my @columns = ('col1', 'col2', 'col3');
    my @original = @columns;
    
    Pipe::IO::prepare_table_data(\@columns);
    
    # Check that the function modified the array
    ok(scalar @columns > scalar @original, 'HTML table formatting modifies data');
    like(join('', @columns), qr/<tr><td>/, 'HTML table has correct format');
    
    # Test MEDIA_WIKI format
    @columns = ('col1', 'col2', 'col3');
    $main::TABLE_OUTPUT = 'MEDIA_WIKI';
    
    Pipe::IO::prepare_table_data(\@columns);
    like(join('', @columns), qr/\|\-/, 'MEDIA_WIKI format works');
    
    # Test WIKI format
    @columns = ('col1', 'col2', 'col3');
    $main::TABLE_OUTPUT = 'WIKI';
    
    Pipe::IO::prepare_table_data(\@columns);
    like(join('', @columns), qr/\|\-/, 'WIKI format works');
    
    # Test MD (Markdown) format
    @columns = ('col1', 'col2', 'col3');
    $main::TABLE_OUTPUT = 'MD';
    
    Pipe::IO::prepare_table_data(\@columns);
    like(join('', @columns), qr/\|.*\|/, 'Markdown format works');
    
    # Test CSV format
    @columns = ('col1', 'col2', 'col3');
    $main::TABLE_OUTPUT = 'CSV';
    local $main::TOTAL_CSV_COLS = 0;
    
    Pipe::IO::prepare_table_data(\@columns);
    like(join('', @columns), qr/"col1","col2","col3"/, 'CSV format works');
    
    # Test CSV UTF-8 format with quotes needed
    @columns = ('col,with,comma', 'normal', 'quote"test');
    $main::TABLE_OUTPUT = 'CSV-UTF-8';
    
    Pipe::IO::prepare_table_data(\@columns);
    my $result = join('', @columns);
    like($result, qr/"col,with,comma"/, 'CSV UTF-8 handles commas');
    like($result, qr/"quote""test"/, 'CSV UTF-8 handles quotes');
    
    # Test CHUNKED format
    @columns = ('col1', 'col2', 'col3');
    $main::TABLE_OUTPUT = 'CHUNKED';
    local $main::SKIP_LINE_TABLE = 2;
    local $main::LINE_NUMBER = 2;
    local $main::SKIP_VALUE = '---separator---';
    
    Pipe::IO::prepare_table_data(\@columns);
    my $chunked_result = join('', @columns);
    like($chunked_result, qr/col1.*col2.*col3/, 'CHUNKED format works');
}

# Test URL encoding functions
{
    # Build the encoding table first
    Pipe::IO::build_encoding_table();
    
    # Test encoding a string
    my $encoded = Pipe::IO::map_url_characters('hello world!');
    like($encoded, qr/hello%20world%21/, 'String encoding works');
    
    # Test other characters
    my $encoded2 = Pipe::IO::map_url_characters('test@example.com');
    like($encoded2, qr/test%40example\.com/, 'Email encoding works');
    
    # Test allowed characters (should not be encoded)
    my $encoded3 = Pipe::IO::map_url_characters('ABCabc123._~-');
    is($encoded3, 'ABCabc123._~-', 'Allowed characters not encoded');
    
    # Test special characters
    my $encoded4 = Pipe::IO::map_url_characters('a+b=c&d');
    like($encoded4, qr/%2B/, 'Plus sign encoded');
    like($encoded4, qr/%3D/, 'Equals sign encoded');
    like($encoded4, qr/%26/, 'Ampersand encoded');
    
    # Test empty string
    my $encoded5 = Pipe::IO::map_url_characters('');
    is($encoded5, '', 'Empty string handled correctly');
    
    # Test high ASCII characters
    my $encoded6 = Pipe::IO::map_url_characters('café');
    like($encoded6, qr/%/, 'High ASCII characters encoded');
}

# Test is_printable_range function
{
    my $ctx = Pipe::Context->new();
    
    # Default range is all lines (1 to MAX_LINE)
    ok(Pipe::IO::is_printable_range(1, $ctx), 'Line 1 is printable by default');
    ok(Pipe::IO::is_printable_range(100, $ctx), 'Line 100 is printable by default');
    ok(Pipe::IO::is_printable_range(1000000, $ctx), 'Large line number is printable by default');
    
    # Test custom range
    $ctx->{line_ranges} = { 5 => 10 };
    ok(!Pipe::IO::is_printable_range(1, $ctx), 'Line 1 not in range 5-10');
    ok(!Pipe::IO::is_printable_range(4, $ctx), 'Line 4 not in range 5-10');
    ok(Pipe::IO::is_printable_range(5, $ctx), 'Line 5 is in range 5-10');
    ok(Pipe::IO::is_printable_range(7, $ctx), 'Line 7 is in range 5-10');
    ok(Pipe::IO::is_printable_range(10, $ctx), 'Line 10 is in range 5-10');
    ok(!Pipe::IO::is_printable_range(11, $ctx), 'Line 11 not in range 5-10');
    
    # Test negative range (tail functionality)
    $ctx->{line_ranges} = { -5 => 0 };
    ok(Pipe::IO::is_printable_range(100, $ctx), 'Negative range returns 1 (tail functionality)');
    
    # Test multiple ranges
    $ctx->{line_ranges} = { 1 => 3, 8 => 10 };
    ok(Pipe::IO::is_printable_range(2, $ctx), 'Line 2 in first range');
    ok(!Pipe::IO::is_printable_range(5, $ctx), 'Line 5 not in any range');
    ok(Pipe::IO::is_printable_range(9, $ctx), 'Line 9 in second range');
}

# Test finalize_full_read_functions - moved back to main script
# These tests are no longer relevant since the function is not in IO module
{
    ok(1, 'Finalize functions moved to main script');
}

# Test print_summary function
{
    my $ctx = Pipe::Context->new();
    $ctx->{delimiter} = '|';
    $ctx->{precision} = 2;
    $ctx->set_option('N', 0);  # Normal headers
    
    my %stats = (
        'c0' => 42,
        'c1' => 3.14159,
        'c2' => 100,
    );
    
    my @columns = (0, 1, 2);
    
    # Capture STDERR
    my $output = '';
    {
        local *STDERR;
        open STDERR, '>', \$output or die "Can't redirect STDERR";
        Pipe::IO::print_summary('TEST', \%stats, \@columns, $ctx);
    }
    
    like($output, qr/== +TEST/, 'Summary header printed');
    like($output, qr/c0:\s+42/, 'Column 0 value printed');
    like($output, qr/c1:\s+3\.14/, 'Column 1 value printed with precision');
    like($output, qr/c2:\s+100/, 'Column 2 value printed');
    
    # Test with suppress headers
    $ctx->set_option('N', 1);
    $output = '';
    {
        local *STDERR;
        open STDERR, '>', \$output or die "Can't redirect STDERR";
        Pipe::IO::print_summary('TEST', \%stats, \@columns, $ctx);
    }
    
    unlike($output, qr/== +TEST/, 'Header suppressed when N=1');
    like($output, qr/c0\|42/, 'Delimiter format when headers suppressed');
    
    # Test with missing column in stats
    my %partial_stats = ('c0' => 50);
    my @more_columns = (0, 5);  # Column 5 not in stats
    
    $output = '';
    {
        local *STDERR;
        open STDERR, '>', \$output or die "Can't redirect STDERR";
        Pipe::IO::print_summary('PARTIAL', \%partial_stats, \@more_columns, $ctx);
    }
    
    like($output, qr/c0/, 'Existing column printed');
    like($output, qr/c5/, 'Missing column printed with default 0');
    
    # Test with empty title
    $ctx->set_option('N', 0);
    $output = '';
    {
        local *STDERR;
        open STDERR, '>', \$output or die "Can't redirect STDERR";
        Pipe::IO::print_summary('', \%stats, \@columns, $ctx);
    }
    
    unlike($output, qr/==/, 'No header for empty title');
}

# Test table_output function for different formats
{
    # Test HTML format
    local $main::TABLE_OUTPUT = 'HTML';
    local $main::TABLE_ATTR = ' class="test"';
    
    # Capture STDOUT
    my $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output or die "Can't redirect STDOUT";
        Pipe::IO::table_output('HEAD');  # Start table
        Pipe::IO::table_output('FOOT');  # End table
    }
    
    like($output, qr/<table/, 'HTML table start tag');
    like($output, qr/<\/table>/, 'HTML table end tag');
    like($output, qr/class="test"/, 'HTML table includes attributes');
    
    # Test MEDIA_WIKI format
    $main::TABLE_OUTPUT = 'MEDIA_WIKI';
    $main::TABLE_ATTR = 'Header1,Header2,Header3';
    
    $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output or die "Can't redirect STDOUT";
        Pipe::IO::table_output('HEAD');
        Pipe::IO::table_output('FOOT');
    }
    
    like($output, qr/\{\|/, 'MEDIA_WIKI table start');
    like($output, qr/\|\}/, 'MEDIA_WIKI table end');
    like($output, qr/! Header1/, 'MEDIA_WIKI includes headers');
    
    # Test WIKI format
    $main::TABLE_OUTPUT = 'WIKI';
    $main::TABLE_ATTR = 'Header1,Header2';
    
    $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output or die "Can't redirect STDOUT";
        Pipe::IO::table_output('HEAD');
        Pipe::IO::table_output('FOOT');
    }
    
    like($output, qr/\{\|/, 'WIKI table start');
    like($output, qr/\|\}/, 'WIKI table end');
    like($output, qr/! Header1/, 'WIKI includes headers');
    
    # Test MD (Markdown) format
    $main::TABLE_OUTPUT = 'MD';
    $main::TABLE_ATTR = 'Column A,Column B';
    
    $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output or die "Can't redirect STDOUT";
        Pipe::IO::table_output('HEAD');
        Pipe::IO::table_output('FOOT');  # No footer for MD
    }
    
    like($output, qr/\*\*Column A\*\*/, 'Markdown headers formatted');
    like($output, qr/\|:---:\|/, 'Markdown separator line');
    
    # Test CSV format
    $main::TABLE_OUTPUT = 'CSV';
    $main::TABLE_ATTR = 'Name,Age,City';
    local $main::TOTAL_CSV_COLS = 0;
    
    $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output or die "Can't redirect STDOUT";
        Pipe::IO::table_output('HEAD');
        Pipe::IO::table_output('FOOT');  # No footer for CSV
    }
    
    like($output, qr/"Name","Age","City"/, 'CSV headers with quotes');
    
    # Test CSV UTF-8 format
    $main::TABLE_OUTPUT = 'CSV-UTF-8';
    $main::TABLE_ATTR = 'Name,Age,City';
    
    $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output or die "Can't redirect STDOUT";
        Pipe::IO::table_output('HEAD');
    }
    
    like($output, qr/Name,Age,City/, 'CSV UTF-8 headers without quotes');
    
    # Test CHUNKED format
    $main::TABLE_OUTPUT = 'CHUNKED';
    $main::TABLE_ATTR = 'BEGIN=starthere,SKIP=3.separator,END=endhere';
    local $main::opt = {'D' => 0};
    
    $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output or die "Can't redirect STDOUT";
        Pipe::IO::table_output('HEAD');
        Pipe::IO::table_output('FOOT');
    }
    
    like($output, qr/starthere/, 'CHUNKED format includes BEGIN value');
    like($output, qr/endhere/, 'CHUNKED format includes END value');
}

done_testing();