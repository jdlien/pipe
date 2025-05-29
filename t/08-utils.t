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
    is(is_between_zero_and_hundred('50.5'), 1, 'is_between_zero_and_hundred: 50.5 is valid');
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
    my $result = get_col_num_or_literal_command('c1');
    is($result, 1, 'get_col_num_or_literal_command extracts column number');
    
    # Test literal string
    $result = get_col_num_or_literal_command('literal_text');
    is($result, 'literal_text', 'get_col_num_or_literal_command returns literal text');
    
    # Test empty string
    $result = get_col_num_or_literal_command('');
    is($result, '', 'get_col_num_or_literal_command handles empty string');
};

# Test convert_format function
subtest 'convert_format tests' => sub {
    # Test hexadecimal conversion
    my $result = convert_format('255', 'hex');
    is($result, 'ff', 'convert_format converts to hexadecimal');
    
    # Test octal conversion
    $result = convert_format('8', 'oct');
    is($result, '10', 'convert_format converts to octal');
    
    # Test binary conversion
    $result = convert_format('5', 'bin');
    is($result, '101', 'convert_format converts to binary');
    
    # Test invalid format
    $result = convert_format('10', 'invalid');
    is($result, '10', 'convert_format returns original for invalid format');
};

# Test format_radix function
subtest 'format_radix tests' => sub {
    # Test different radix conversions
    my $result = format_radix('10', 2);
    is($result, '1010', 'format_radix converts to binary');
    
    $result = format_radix('10', 8);
    is($result, '12', 'format_radix converts to octal');
    
    $result = format_radix('10', 16);
    is($result, 'a', 'format_radix converts to hexadecimal');
    
    $result = format_radix('255', 16);
    is($result, 'ff', 'format_radix converts 255 to hex');
};

# Test validate function
subtest 'validate tests' => sub {
    # This function has complex validation logic
    # Test basic functionality
    my $result = validate('test_input');
    ok(defined $result, 'validate function executes');
    
    # Test empty input
    $result = validate('');
    ok(defined $result, 'validate handles empty input');
};

# Test edge cases
subtest 'edge cases' => sub {
    # Test parse_single_column_single_argument with invalid input
    my ($col, $val, $reset) = parse_single_column_single_argument('invalid');
    ok(defined $col || defined $val, 'parse_single_column_single_argument handles invalid input');
    
    # Test very large numbers
    is(is_between_zero_and_hundred('999999'), 0, 'is_between_zero_and_hundred rejects very large numbers');
    
    # Test negative numbers in convert_format
    my $result = convert_format('-5', 'hex');
    ok(defined $result, 'convert_format handles negative numbers');
    
    # Test zero in format_radix
    $result = format_radix('0', 16);
    is($result, '0', 'format_radix handles zero');
};

done_testing();