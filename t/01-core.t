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

# Test trim function
is(Pipe::Core::trim('  hello  '), 'hello', 'trim removes spaces');
is(Pipe::Core::trim('hello'), 'hello', 'trim handles no spaces');
is(Pipe::Core::trim('  hello  ', 3), 'hel', 'trim with length limit');
is(Pipe::Core::trim("\thello\n"), 'hello', 'trim removes tabs and newlines');

# Test normalize function
is(Pipe::Core::normalize('Hello World!'), 'HELLOWORLD', 'normalize removes non-word chars and uppercases');
is(Pipe::Core::normalize('test-123_ABC'), 'TEST123_ABC', 'normalize handles various characters');

# Test get_number_format function
is(Pipe::Core::get_number_format('123'), '123', 'Integer formatting');
is(Pipe::Core::get_number_format('123.45', 0, 2), '123.45', 'Float formatting with precision');
is(Pipe::Core::get_number_format('abc'), 'NaN', 'Non-numeric returns NaN');
is(Pipe::Core::get_number_format('123.456', 0, 1), '123.5', 'Float formatting with 1 decimal');
is(Pipe::Core::get_number_format('-42'), '-42', 'Negative integer');
is(Pipe::Core::get_number_format('123', 1), '123', 'Integer-only formatting');

# Edge cases
is(Pipe::Core::trim(''), '', 'trim handles empty string');
is(Pipe::Core::normalize(''), '', 'normalize handles empty string');

# Test with very long strings
my $long_string = 'x' x 10000;
is(length(Pipe::Core::trim("  $long_string  ")), 10000, 'trim handles long strings');

done_testing();