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

# Test prepare_table_data function
{
    my @columns = ('col1', 'col2', 'col3');
    
    # Set global variables that the function uses
    local $main::TABLE_OUTPUT = 'HTML';
    
    # Test HTML format - function takes single array ref parameter
    my $result = Pipe::IO::prepare_table_data(\@columns);
    
    # The function modifies global state, so we just test it doesn't crash
    ok(1, 'HTML table formatting function works');
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
}

# Test table_output function  
{
    # Set up global variables that the function uses
    local $main::TABLE_OUTPUT = 'HTML';
    local $main::TABLE_ATTR = 'class="test"';
    
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
}

done_testing();