#!/usr/bin/perl
#
# Unit tests for Pipe::Core module
#
use strict;
use warnings;
use Test::More;
use lib 'lib';

BEGIN { 
    use_ok('Pipe::Core') or BAIL_OUT("Can't load Pipe::Core");
}

# Test constants
is($Pipe::Core::TRUE, 0, 'TRUE constant is 0');
is($Pipe::Core::FALSE, 1, 'FALSE constant is 1');
is($Pipe::Core::DELIMITER, '|', 'Default delimiter is pipe');
is($Pipe::Core::MAX_LINE, 100000000, 'MAX_LINE constant is correct');

# Test keywords
is($Pipe::Core::KEYWORD_ANY, 'any', 'KEYWORD_ANY is correct');
is($Pipe::Core::KEYWORD_REMAINING, 'remaining', 'KEYWORD_REMAINING is correct');
is($Pipe::Core::KEYWORD_EXCLUDE, 'exclude', 'KEYWORD_EXCLUDE is correct');

# Test trim function - comprehensive branch testing
subtest 'trim function comprehensive tests' => sub {
    # Basic trimming
    is(Pipe::Core::trim('  hello  '), 'hello', 'trim removes spaces');
    is(Pipe::Core::trim('hello'), 'hello', 'trim handles no spaces');
    is(Pipe::Core::trim("\thello\n"), 'hello', 'trim removes tabs and newlines');
    is(Pipe::Core::trim("\r\n  hello  \t\r\n"), 'hello', 'trim removes all whitespace types');
    
    # Test the length parameter branch
    is(Pipe::Core::trim('  hello  ', 3), 'hel', 'trim with length limit');
    is(Pipe::Core::trim('  hello  ', 0), 'hello', 'trim with zero length (0 means no limit)');
    is(Pipe::Core::trim('  hello  ', 10), 'hello', 'trim with length longer than result');
    is(Pipe::Core::trim('  hello  ', 5), 'hello', 'trim with length equal to result');
    is(Pipe::Core::trim('hello world', 5), 'hello', 'trim multi-word with length');
    
    # Test edge cases
    is(Pipe::Core::trim(''), '', 'trim handles empty string');
    is(Pipe::Core::trim('   '), '', 'trim handles only whitespace');
    is(Pipe::Core::trim('   ', 1), '', 'trim whitespace-only with length');
    is(Pipe::Core::trim('a'), 'a', 'trim single character');
    is(Pipe::Core::trim('a', 1), 'a', 'trim single character with length 1');
    is(Pipe::Core::trim('a', 0), 'a', 'trim single character with length 0 (no limit)');
    
    # Test with no length parameter (exercises the @_ check)
    is(Pipe::Core::trim('  test  '), 'test', 'trim without length parameter');
    
    # Test with undef input (function may not handle undef well)
    my $undef_result = Pipe::Core::trim(undef);
    ok(!defined($undef_result) || $undef_result eq '', 'trim handles undef gracefully');
    $undef_result = Pipe::Core::trim(undef, 5);
    ok(!defined($undef_result) || $undef_result eq '', 'trim handles undef with length gracefully');
};


# Test get_number_format function - comprehensive branch testing
subtest 'get_number_format comprehensive tests' => sub {
    # Basic integer formatting
    is(Pipe::Core::get_number_format('123'), '123', 'Integer formatting');
    is(Pipe::Core::get_number_format('-42'), '-42', 'Negative integer');
    is(Pipe::Core::get_number_format('+42'), '42', 'Positive integer with sign');
    
    # Integer-only mode (number_type = true)
    is(Pipe::Core::get_number_format('123', 1), '123', 'Integer-only formatting');
    is(Pipe::Core::get_number_format('+456', 1), '456', 'Integer-only with positive sign');
    is(Pipe::Core::get_number_format('0', 1), '', 'Zero in integer-only mode (falsy value)');
    
    # Test the undef/false case for number_type when input is false/empty
    is(Pipe::Core::get_number_format('', 1), '', 'Empty string in integer-only mode returns empty');
    is(Pipe::Core::get_number_format(undef, 1), '', 'Undef in integer-only mode returns empty');
    is(Pipe::Core::get_number_format('000', 1), '0', 'Zero string in integer-only mode (evaluates to 0)');
    
    # Test missing condition branch: input is true but doesn't match regex when number_type is true
    is(Pipe::Core::get_number_format('abc', 1), '', 'Non-numeric in integer-only mode returns empty');
    is(Pipe::Core::get_number_format('12.34', 1), '', 'Decimal in integer-only mode returns empty');
    
    # Float formatting with precision
    is(Pipe::Core::get_number_format('123.45', 0, 2), '123.45', 'Float formatting with precision');
    is(Pipe::Core::get_number_format('123.456', 0, 1), '123.5', 'Float formatting with 1 decimal');
    is(Pipe::Core::get_number_format('123.456', 0, 0), '123', 'Float formatting with 0 decimals');
    is(Pipe::Core::get_number_format('-123.456', 0, 2), '-123.46', 'Negative float with precision');
    
    # Test various float patterns that should match the regex
    is(Pipe::Core::get_number_format('123.', 0, 2), '123.00', 'Number ending with decimal point');
    is(Pipe::Core::get_number_format('123', 0, 2), '123', 'Integer with precision (doesn\'t match precision regex)');
    is(Pipe::Core::get_number_format('.456', 0, 2), '0.46', 'Number starting with decimal point with precision');
    is(Pipe::Core::get_number_format('-0.5', 0, 1), '-0.5', 'Negative fraction');
    
    # Test scientific notation - NOW FIXED!
    # The regex now correctly uses | instead of & in the lookahead
    is(Pipe::Core::get_number_format('1.23E+10'), '1.23E+10', 'Scientific notation positive exponent');
    is(Pipe::Core::get_number_format('1.23e-5'), '1.23e-5', 'Scientific notation negative exponent');
    is(Pipe::Core::get_number_format('-1.23E+10'), '-1.23E+10', 'Negative scientific notation');
    is(Pipe::Core::get_number_format('1E10'), '1E10', 'Scientific notation without decimal');
    is(Pipe::Core::get_number_format('+3.14E-2'), '+3.14E-2', 'Positive scientific notation');
    is(Pipe::Core::get_number_format('.5E3'), '.5E3', 'Scientific notation starting with decimal');
    is(Pipe::Core::get_number_format('42e0'), '42e0', 'Scientific notation with zero exponent');
    
    # Test edge case that triggers the second part of the OR condition on line 122
    # Now test patterns that match the fixed regex
    is(Pipe::Core::get_number_format('.456', 0, 2), '0.46', 'Number starting with decimal with precision');
    is(Pipe::Core::get_number_format('-.789', 0, 1), '-0.8', 'Negative number starting with decimal');
    
    # Test invalid patterns with precision
    is(Pipe::Core::get_number_format('invalid', 0, 2), 'NaN', 'Invalid input with precision returns NaN');
    is(Pipe::Core::get_number_format('123.45', 0, undef), '123', 'Float without defined precision falls through to integer');
    
    # Test invalid inputs that should return NaN
    is(Pipe::Core::get_number_format('abc'), 'NaN', 'Non-numeric returns NaN');
    is(Pipe::Core::get_number_format('12.34.56'), 'NaN', 'Multiple decimal points return NaN');
    is(Pipe::Core::get_number_format('12abc'), 'NaN', 'Mixed alphanumeric returns NaN');
    is(Pipe::Core::get_number_format(''), 'NaN', 'Empty string returns NaN');
    is(Pipe::Core::get_number_format('  123  '), 'NaN', 'Number with spaces returns NaN');
    
    # Test edge cases with no arguments
    is(Pipe::Core::get_number_format('123', undef), '123', 'With explicit undef number_type');
    is(Pipe::Core::get_number_format('123.45', 0), '123', 'Without precision argument falls through to integer');
    
    # Test the case where precision is defined but input doesn't match first regex  
    is(Pipe::Core::get_number_format('1.5', 0, 1), '1.5', 'Simple decimal with precision');
};


# Test additional constants and exports
subtest 'additional constants and exports' => sub {
    # Test more constants that might not be tested
    is($Pipe::Core::SUB_DELIMITER, '___PIPE___', 'SUB_DELIMITER constant');
    is($Pipe::Core::QUOTED_DELIMITER, '___QUOTED_DELIMITER___', 'QUOTED_DELIMITER constant');
    is($Pipe::Core::KEYWORD_CONTINUE, 'continue', 'KEYWORD_CONTINUE constant');
    is($Pipe::Core::KEYWORD_LAST, 'last', 'KEYWORD_LAST constant');
    is($Pipe::Core::KEYWORD_REVERSE, 'reverse', 'KEYWORD_REVERSE constant');
    is($Pipe::Core::KEYWORD_NUM_COLS, 'num_cols', 'KEYWORD_NUM_COLS constant');
    
    # Test numeric constants
    is($Pipe::Core::ALLOW_SCRIPTING, 0, 'ALLOW_SCRIPTING constant');
    is($Pipe::Core::COLLAPSE_OPTION, 0, 'COLLAPSE_OPTION constant');
    is($Pipe::Core::READ_FULL, 0, 'READ_FULL constant');
    is($Pipe::Core::KEEP_LINES, 10, 'KEEP_LINES constant');
    is($Pipe::Core::FAST_FORWARD, 0, 'FAST_FORWARD constant');
    is($Pipe::Core::PRECISION, 2, 'PRECISION constant');
    
    # Test version
    ok(defined $Pipe::Core::VERSION, 'VERSION is defined');
    like($Pipe::Core::VERSION, qr/^\d+\.\d+\.\d+$/, 'VERSION has correct format');
};

# Test export functionality
subtest 'export functionality tests' => sub {
    # Test that basic exports are available
    ok(defined &trim, 'trim function is exported by default');
    ok(defined $TRUE, 'TRUE constant is exported by default');
    ok(defined $FALSE, 'FALSE constant is exported by default');
    ok(defined $DELIMITER, 'DELIMITER constant is exported by default');
    ok(defined $KEYWORD_ANY, 'KEYWORD_ANY is exported by default');
    ok(defined $KEYWORD_REMAINING, 'KEYWORD_REMAINING is exported by default');
    
    # Test exported constants have correct values
    is($TRUE, 0, 'Exported TRUE equals 0');
    is($FALSE, 1, 'Exported FALSE equals 1');
    is($DELIMITER, '|', 'Exported DELIMITER equals pipe');
};

# Test edge cases and error conditions
subtest 'edge cases and error conditions' => sub {
    # Test with very long strings
    my $long_string = 'x' x 10000;
    is(length(Pipe::Core::trim("  $long_string  ")), 10000, 'trim handles long strings');
    
    # Test with special numeric formats for get_number_format
    is(Pipe::Core::get_number_format('0'), '0', 'get_number_format handles zero');
    is(Pipe::Core::get_number_format('00123'), '123', 'get_number_format handles leading zeros');
    is(Pipe::Core::get_number_format('-0'), '0', 'get_number_format handles negative zero');
    
    # Test boundary conditions for trim length
    is(Pipe::Core::trim('hello', 1000), 'hello', 'trim with very large length');
    is(Pipe::Core::trim('hello', -1), 'hell', 'trim with negative length (substr handles it)');
};

done_testing();