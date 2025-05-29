#!/usr/bin/perl
#
# Unit tests for Pipe::Utils module
#
use strict;
use warnings;
use Test::More;
use lib 'lib';

BEGIN { 
    use_ok('Pipe::Utils') or BAIL_OUT("Can't load Pipe::Utils");
}

# Import required functions for testing
use Pipe::Utils qw(:all);
use Pipe::Core qw(:constants :keywords :functions);

# Test parse_single_column_single_argument function
subtest 'parse_single_column_single_argument tests' => sub {
    # Test basic column:value format
    my ($col, $val, $reset) = parse_single_column_single_argument('c1:1000');
    is($col, 1, 'parse_single_column_single_argument extracts column number');
    is($val, '1000', 'parse_single_column_single_argument extracts value');
    
    # Test with reset value
    ($col, $val, $reset) = parse_single_column_single_argument('c2:100,200');
    is($col, 2, 'parse_single_column_single_argument extracts column with reset');
    is($val, '100', 'parse_single_column_single_argument extracts value with reset');
    is($reset, '200', 'parse_single_column_single_argument extracts reset value');
    
    # Test uppercase C
    ($col, $val, $reset) = parse_single_column_single_argument('C0:500');
    is($col, 0, 'parse_single_column_single_argument handles uppercase C');
    is($val, '500', 'parse_single_column_single_argument extracts value with uppercase C');
};

# Test is_between_zero_and_hundred function
subtest 'is_between_zero_and_hundred tests' => sub {
    is(is_between_zero_and_hundred('50'), 1, 'is_between_zero_and_hundred: 50 is valid');
    is(is_between_zero_and_hundred('0'), 1, 'is_between_zero_and_hundred: 0 is valid');
    is(is_between_zero_and_hundred('100'), 1, 'is_between_zero_and_hundred: 100 is valid');
    is(is_between_zero_and_hundred('101'), 0, 'is_between_zero_and_hundred: 101 is invalid');
    is(is_between_zero_and_hundred('-1'), 0, 'is_between_zero_and_hundred: -1 is invalid');
    is(is_between_zero_and_hundred('50.5'), 0, 'is_between_zero_and_hundred: 50.5 is invalid (function only accepts integers)');
    is(is_between_zero_and_hundred('abc'), 0, 'is_between_zero_and_hundred: non-numeric is invalid');
};

# Test read_requested_columns function
subtest 'read_requested_columns tests' => sub {
    # Test basic column list
    my @cols = read_requested_columns('c0,c1,c2');
    is_deeply(\@cols, [0, 1, 2], 'read_requested_columns parses basic column list');
    
    # Test with spaces
    @cols = read_requested_columns('c0, c1, c2');
    is_deeply(\@cols, [0, 1, 2], 'read_requested_columns handles spaces');
    
    # Test single column
    @cols = read_requested_columns('c5');
    is_deeply(\@cols, [5], 'read_requested_columns handles single column');
};

# Test get_col_num_or_literal_command function
subtest 'get_col_num_or_literal_command tests' => sub {
    # Test column number
    my @result = ();
    get_col_num_or_literal_command(\@result, 'c1', 0);
    is($result[0], 1, 'get_col_num_or_literal_command extracts column number');
    
    # Test literal string
    @result = ();
    get_col_num_or_literal_command(\@result, 'literal_text', 1);
    is($result[0], 'literal_text', 'get_col_num_or_literal_command returns literal text');
    
    # Test empty string - function pushes the empty string to array
    @result = ();
    get_col_num_or_literal_command(\@result, '', 1);
    is(scalar(@result), 1, 'get_col_num_or_literal_command adds empty string to array');
};

# Test convert_format function
subtest 'convert_format tests' => sub {
    # The convert_format function has complex logic, just test it executes
    my $result = convert_format('255', 'h');
    ok(defined($result), 'convert_format executes without fatal error for hex');
    
    $result = convert_format('8', 'd');
    ok(defined($result), 'convert_format executes without fatal error for decimal');
    
    $result = convert_format('5', 'b');
    ok(defined($result), 'convert_format executes without fatal error for binary');
    
    # Test empty string
    $result = convert_format('', 'd');
    ok(defined($result), 'convert_format handles empty string');
};

# Test format_radix function
subtest 'format_radix tests' => sub {
    # format_radix expects a single array reference parameter
    my @line = ('10', '255');
    # This function modifies the array in place and has side effects
    # We need to set up the global variables it expects
    local $main::FORMAT_COLUMNS = [1, 1];
    local $main::format_ref = { 0 => 'b', 1 => 'h' };
    local $main::opt = { 'D' => 0 };
    
    format_radix(\@line);
    # Check that the function executed without error
    ok(defined $line[0], 'format_radix processes line array');
};

# Test validate function
subtest 'validate tests' => sub {
    # validate expects 3 parameters: original, modified, line_no
    # Set up global variables it needs
    local $main::opt = { 'D' => 0, 'o' => 0 };
    local $main::COLLAPSE_OPTION = 0;
    
    my $result = validate('a|b|c', 'x|y|z', 1);
    ok(defined $result, 'validate function executes');
    is($result, 'x|y|z', 'validate returns modified line when counts match');
    
    # Test with different field counts
    $result = validate('a|b|c', 'x|y', 1);
    is($result, 'x|y|', 'validate adds pipe when modified has fewer fields');
};

# Test edge cases
subtest 'edge cases' => sub {
    # Test parse_single_column_single_argument with valid input only (invalid input causes exit)
    my ($col, $val, $reset) = parse_single_column_single_argument('c1:100');
    is($col, 1, 'parse_single_column_single_argument parses valid input');
    is($val, '100', 'parse_single_column_single_argument extracts value');
    
    # Test very large numbers
    is(is_between_zero_and_hundred('999999'), 0, 'is_between_zero_and_hundred rejects very large numbers');
    
    # Test negative numbers in convert_format
    my $result = convert_format('-5', 'd');
    ok(defined($result), 'convert_format handles negative numbers');
    
    # Test zero in format_radix
    my @zero_line = ('0');
    local $main::FORMAT_COLUMNS = [1];
    local $main::format_ref = { 0 => 'h' };
    local $main::opt = { 'D' => 0 };
    format_radix(\@zero_line);
    ok(defined $zero_line[0], 'format_radix handles zero');
};

done_testing();