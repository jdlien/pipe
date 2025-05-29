#!/usr/bin/perl
#
# Unit tests for Pipe::Column module
#
use strict;
use warnings;
use Test::More;
use lib 'lib';

BEGIN { 
    use_ok('Pipe::Column') or BAIL_OUT("Can't load Pipe::Column");
}

# Import required functions for testing
use Pipe::Column qw(:all);
use Pipe::Core qw(:constants :keywords :functions);

# Set up global variables that the module expects
our @ORDER_COLUMNS = ();
our @MERGE_COLUMNS = ();
our @MERGE_SRC_COLUMNS = ();
our @MERGE_REF_COLUMNS = ();
our $RELAX_o_EXCLUDE = 0;
our %opt = ();
our $REF_FILE_DATA_HREF = {};
our @REF_LITERALS_FALSE = ();

# Test get_column_value function
subtest 'get_column_value tests' => sub {
    my $test_line = "apple|banana|cherry|date|elderberry";
    
    is(get_column_value("c0", $test_line), 0, 'get_column_value with non-numeric column returns 0');
    is(get_column_value("0", $test_line), 0, 'get_column_value without c prefix works');
    
    my $numeric_line = "123|456.78|-789|0|abc";
    is(get_column_value("c0", $numeric_line), 123, 'get_column_value with integer');
    is(get_column_value("c1", $numeric_line), 456.78, 'get_column_value with float');
    is(get_column_value("c2", $numeric_line), -789, 'get_column_value with negative number');
    is(get_column_value("c3", $numeric_line), 0, 'get_column_value with zero');
    is(get_column_value("c4", $numeric_line), 0, 'get_column_value with non-numeric returns 0');
    is(get_column_value("c10", $numeric_line), 0, 'get_column_value with non-existent column returns 0');
};

# Test get_key function
subtest 'get_key tests' => sub {
    my $test_line = "  apple  |  banana  |  cherry  ";
    my @columns = (0, 1, 2);
    
    is(get_key($test_line, \@columns), 'applebananacherry', 'get_key concatenates trimmed columns');
    
    my @single_col = (1);
    is(get_key($test_line, \@single_col), 'banana', 'get_key with single column');
    
    my @partial_cols = (0, 2);
    is(get_key($test_line, \@partial_cols), 'applecherry', 'get_key with non-consecutive columns');
    
    my @empty_cols = ();
    is(get_key($test_line, \@empty_cols), '', 'get_key with empty column list');
};

# Test read_whole_number function
subtest 'read_whole_number tests' => sub {
    is(read_whole_number("123"), 123, 'read_whole_number with valid integer');
    is(read_whole_number("0"), 0, 'read_whole_number with zero');
    is(read_whole_number(""), 0, 'read_whole_number with empty string returns 0');
    
    # Note: Invalid inputs would cause exit(), so we can't easily test them in unit tests
    # Those would be better tested in integration tests
};

# Test order_line function
subtest 'order_line basic tests' => sub {
    my @test_line = ("apple", "banana", "cherry", "date");
    
    # Test with simple column order
    @ORDER_COLUMNS = (2, 0, 1, 3);
    order_line(\@test_line);
    is_deeply(\@test_line, ["cherry", "apple", "banana", "date"], 'order_line reorders columns correctly');
    
    # Reset for next test
    @test_line = ("apple", "banana", "cherry", "date");
    @ORDER_COLUMNS = (3, 2, 1, 0);
    order_line(\@test_line);
    is_deeply(\@test_line, ["date", "cherry", "banana", "apple"], 'order_line reverses columns');
};

# Test order_line with keywords
subtest 'order_line keyword tests' => sub {
    my @test_line = ("apple", "banana", "cherry", "date");
    
    # Test with 'remaining' keyword
    @ORDER_COLUMNS = (0, "remaining");
    order_line(\@test_line);
    is_deeply(\@test_line, ["apple", "banana", "cherry", "date"], 'order_line with remaining keyword');
    
    # Reset for next test
    @test_line = ("apple", "banana", "cherry", "date");
    @ORDER_COLUMNS = (2, "remaining");
    order_line(\@test_line);
    is_deeply(\@test_line, ["cherry", "apple", "banana", "date"], 'order_line with remaining after specific column');
    
    # Test with 'last' keyword
    @test_line = ("apple", "banana", "cherry", "date");
    @ORDER_COLUMNS = ("last");
    order_line(\@test_line);
    is_deeply(\@test_line, ["date"], 'order_line with last keyword');
    
    # Test with 'reverse' keyword
    @test_line = ("apple", "banana", "cherry", "date");
    @ORDER_COLUMNS = ("reverse");
    order_line(\@test_line);
    is_deeply(\@test_line, ["date", "cherry", "banana", "apple"], 'order_line with reverse keyword');
    
    # Test with 'continue' keyword
    @test_line = ("apple", "banana", "cherry", "date", "elderberry");
    @ORDER_COLUMNS = (1, "continue");
    order_line(\@test_line);
    is_deeply(\@test_line, ["banana", "cherry", "date", "elderberry"], 'order_line with continue keyword');
};

# Test order_line with exclude keyword
subtest 'order_line exclude tests' => sub {
    # Reset the global variable
    $RELAX_o_EXCLUDE = 0;
    
    my @test_line = ("apple", "banana", "cherry", "date");
    @ORDER_COLUMNS = ("exclude", 1, 2);
    order_line(\@test_line);
    is_deeply(\@test_line, ["apple", "date"], 'order_line with exclude keyword removes specified columns');
};

# Test merge_line function
subtest 'merge_line tests' => sub {
    my @test_line = ("apple", "banana", "cherry", "date");
    
    # Test basic merge
    @MERGE_COLUMNS = (0, 1, 2);
    merge_line(\@test_line);
    is($test_line[0], "applebananacherry", 'merge_line concatenates specified columns');
    
    # Test merge with 'any' keyword
    @test_line = ("apple", "banana", "cherry", "date");
    @MERGE_COLUMNS = ("any");
    merge_line(\@test_line);
    is($test_line[0], "applebananacherrydate", 'merge_line with any keyword concatenates all columns');
};

# Test read_requested_qualified_columns function
subtest 'read_requested_qualified_columns tests' => sub {
    my %qualifiers = ();
    
    # Test basic column specification
    my @cols = read_requested_qualified_columns("c0:pattern,c1:value", \%qualifiers, $KEYWORD_ANY);
    is_deeply(\@cols, [0, 1], 'read_requested_qualified_columns parses basic columns');
    is($qualifiers{0}, 'pattern', 'read_requested_qualified_columns stores first qualifier');
    is($qualifiers{1}, 'value', 'read_requested_qualified_columns stores second qualifier');
    
    # Test with 'any' keyword
    %qualifiers = ();
    @cols = read_requested_qualified_columns("any:pattern", \%qualifiers, $KEYWORD_ANY);
    is_deeply(\@cols, ['any'], 'read_requested_qualified_columns handles any keyword');
    is($qualifiers{$KEYWORD_ANY}, 'pattern', 'read_requested_qualified_columns stores any qualifier');
    
    # Test with escaped commas
    %qualifiers = ();
    @cols = read_requested_qualified_columns("c0:pat\\,tern", \%qualifiers, $KEYWORD_ANY);
    is($qualifiers{0}, 'pat,tern', 'read_requested_qualified_columns handles escaped commas');
    
    # Test with arithmetic operators
    %qualifiers = ();
    @cols = read_requested_qualified_columns("add:c0,c1,c2", \%qualifiers);
    is_deeply(\@cols, ["c0", "c1", "c2"], 'read_requested_qualified_columns handles arithmetic operators');
    is($qualifiers{'add'}, 1, 'read_requested_qualified_columns sets arithmetic operator flag');
};

# Test merge_reference_file function
subtest 'merge_reference_file tests' => sub {
    my @test_line = ("key1", "value1");
    
    # Set up reference data
    $REF_FILE_DATA_HREF = {
        'key1' => 'ref_value1,ref_value2',
        'key2' => 'ref_value3,ref_value4'
    };
    @MERGE_SRC_COLUMNS = (0);  # Use first column as key
    @REF_LITERALS_FALSE = ('false1', 'false2');
    
    # Test successful merge
    merge_reference_file(\@test_line);
    is_deeply(\@test_line, ["key1", "value1", "ref_value1", "ref_value2"], 
             'merge_reference_file adds reference data for matching key');
    
    # Test with non-matching key
    @test_line = ("key3", "value3");
    merge_reference_file(\@test_line);
    is_deeply(\@test_line, ["key3", "value3", "false1", "false2"], 
             'merge_reference_file adds false literals for non-matching key');
    
    # Test with case insensitive matching
    $opt{'I'} = 1;
    $REF_FILE_DATA_HREF = {
        'KEY1' => 'ref_value1,ref_value2'
    };
    @test_line = ("key1", "value1");
    merge_reference_file(\@test_line);
    is_deeply(\@test_line, ["key1", "value1", "ref_value1", "ref_value2"], 
             'merge_reference_file handles case insensitive matching');
    
    # Clean up
    $opt{'I'} = 0;
};

# Test edge cases
subtest 'edge cases' => sub {
    # Test with empty arrays
    my @empty_line = ();
    @ORDER_COLUMNS = ();
    order_line(\@empty_line);
    is_deeply(\@empty_line, [], 'order_line handles empty line');
    
    # Test merge with empty line
    @empty_line = ();
    @MERGE_COLUMNS = ();
    merge_line(\@empty_line);
    is_deeply(\@empty_line, [], 'merge_line handles empty line');
    
    # Test get_key with non-existent columns
    my $test_line = "a|b|c";
    my @out_of_range = (10, 20);
    is(get_key($test_line, \@out_of_range), '', 'get_key handles non-existent columns gracefully');
};

done_testing();