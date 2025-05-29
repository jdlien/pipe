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
    my @orig_columns = @columns;
    
    # Test HTML format
    Pipe::IO::prepare_table_data(\@columns, 1, 0, '|');
    like($columns[0], qr/<td.*>col1<\/td>/, 'HTML table formatting works');
    
    # Reset for next test
    @columns = @orig_columns;
    
    # Test Wiki format
    Pipe::IO::prepare_table_data(\@columns, 2, 0, '|');
    is(scalar(@columns), 1, 'Wiki format combines columns into one');
    like($columns[0], qr/\| col1 \| col2 \| col3 \|/, 'Wiki table formatting works');
    
    # Reset for next test
    @columns = @orig_columns;
    
    # Test Markdown format
    Pipe::IO::prepare_table_data(\@columns, 3, 0, '|');
    is(scalar(@columns), 1, 'Markdown format combines columns into one');
    like($columns[0], qr/\| col1 \| col2 \| col3 \|/, 'Markdown table formatting works');
    
    # Reset for next test
    @columns = ('field,with,commas', 'field"with"quotes', 'normal');
    
    # Test CSV format
    Pipe::IO::prepare_table_data(\@columns, 4, 0, '|');
    like($columns[0], qr/"field,with,commas"/, 'CSV escapes commas');
    like($columns[1], qr/"field""with""quotes"/, 'CSV escapes quotes');
    is($columns[2], 'normal', 'CSV leaves normal fields unchanged');
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

# Test finalize_full_read_functions - deduplication
{
    my $ctx = Pipe::Context->new();
    $ctx->{delimiter} = '|';
    $ctx->{ddup_columns} = [0];  # Deduplicate on first column
    
    my @lines = (
        'apple|red|sweet',
        'banana|yellow|sweet', 
        'apple|green|tart',  # Duplicate first column
        'cherry|red|tart',
    );
    
    Pipe::IO::finalize_full_read_functions($ctx, \@lines);
    
    is(scalar(@lines), 3, 'Deduplication removed one line');
    
    # Check that first occurrence is kept
    my $found_apple = 0;
    foreach my $line (@lines) {
        if ($line =~ /^apple\|/) {
            like($line, qr/apple\|red\|sweet/, 'First apple entry kept');
            $found_apple++;
        }
    }
    is($found_apple, 1, 'Only one apple entry remains');
}

# Test finalize_full_read_functions - sorting
{
    my $ctx = Pipe::Context->new();
    $ctx->{delimiter} = '|';
    $ctx->{sort_columns} = [0];  # Sort on first column
    $ctx->{ddup_columns} = [];   # No deduplication
    
    my @lines = (
        'zebra|black|stripes',
        'apple|red|sweet',
        'banana|yellow|curved',
    );
    
    Pipe::IO::finalize_full_read_functions($ctx, \@lines);
    
    is($lines[0], 'apple|red|sweet', 'First line after sort is apple');
    is($lines[1], 'banana|yellow|curved', 'Second line after sort is banana');
    is($lines[2], 'zebra|black|stripes', 'Third line after sort is zebra');
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
    like($output, qr/c0: 42/, 'Column 0 value printed');
    like($output, qr/c1: 3\.14/, 'Column 1 value printed with precision');
    like($output, qr/c2: 100/, 'Column 2 value printed');
}

# Test table_output function  
{
    my $ctx = Pipe::Context->new();
    $ctx->{table_output} = 1;  # HTML format
    $ctx->{table_attr} = 'class="test"';
    
    # Capture STDOUT
    my $output = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$output or die "Can't redirect STDOUT";
        Pipe::IO::table_output($ctx, 0);  # Start table
        Pipe::IO::table_output($ctx, 3);  # End table
    }
    
    like($output, qr/<table class="test">/, 'HTML table start tag');
    like($output, qr/<\/table>/, 'HTML table end tag');
}

done_testing();