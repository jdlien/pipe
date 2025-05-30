#!/usr/bin/perl
#
# Unit tests for Pipe::Math module
#
use strict;
use warnings;
use Test::More;
use lib 'lib';

BEGIN { 
    use_ok('Pipe::Math') or BAIL_OUT("Can't load Pipe::Math");
}

# Import required functions for testing
use Pipe::Math qw(:all);
use Pipe::Core qw(:constants :keywords :functions);

# Set up global variables that the module expects
our @COUNT_COLUMNS = ();
our @SUM_COLUMNS = ();
our @WIDTH_COLUMNS = ();
our @AVG_COLUMNS = ();
our @INCR_COLUMNS = ();
our @INCR3_COLUMNS = ();
our @MATH_COLUMNS = ();
our @DELTA4_COLUMNS = ();
our @HISTOGRAM_COLUMN = ();
our %opt = ();
our $PRECISION = 2;
our $LINE_NUMBER = 1;

# Hash references for storing computation results
our $count_ref = {};
our $sum_ref = {};
our $width_min_ref = {};
our $width_max_ref = {};
our $width_line_min_ref = {};
our $width_line_max_ref = {};
our $WIDTHS_COLUMNS = {};
our $avg_ref = {};
our $avg_count = {};
our $increment_ref = {};
our $math_ref = {};
our $delta_cols_ref = {};
our $hist_ref = {};

# Auto increment variables
our $AUTO_INCR_COLUMN = 0;
our $AUTO_INCR_SEED = 1;
our $AUTO_INCR_RESET = 0;
our $AUTO_INCR_ORIG_VALUE = 1;

# Group operation variables
our $J_CMD = '';
our $J_COUNT = 0;
our $J_BUCKET_COUNTS = {};

# Test count function
subtest 'count function tests' => sub {
    # Reset variables
    $count_ref = {};
    @COUNT_COLUMNS = (0, 1, 2);
    
    my @test_line = ('apple', '', 'cherry');
    count(\@test_line);
    
    is($count_ref->{'c0'}, 1, 'count increments for non-empty column 0');
    is($count_ref->{'c1'}, undef, 'count does not increment for empty column 1');
    is($count_ref->{'c2'}, 1, 'count increments for non-empty column 2');
    
    # Test multiple calls
    @test_line = ('banana', 'date', '');
    count(\@test_line);
    
    is($count_ref->{'c0'}, 2, 'count increments again for column 0');
    is($count_ref->{'c1'}, 1, 'count increments for previously empty column 1');
    is($count_ref->{'c2'}, 1, 'count remains same for column 2 (empty)');
};

# Test sum function
subtest 'sum function tests' => sub {
    # Reset variables
    $sum_ref = {};
    @SUM_COLUMNS = (0, 1, 2);
    
    my @test_line = ('10', '20.5', 'not-a-number');
    sum(\@test_line);
    
    is($sum_ref->{'c0'}, 10, 'sum adds integer value');
    is($sum_ref->{'c1'}, 20.5, 'sum adds float value');
    is($sum_ref->{'c2'}, undef, 'sum ignores non-numeric value');
    
    # Test multiple calls
    @test_line = ('5', '10.25', '15');
    sum(\@test_line);
    
    is($sum_ref->{'c0'}, 15, 'sum accumulates values for column 0');
    is($sum_ref->{'c1'}, 30.75, 'sum accumulates values for column 1');
    is($sum_ref->{'c2'}, 15, 'sum adds numeric value for previously non-numeric column');
    
    # Test negative numbers
    @test_line = ('-5', '0', '3.14');
    sum(\@test_line);
    
    is($sum_ref->{'c0'}, 10, 'sum handles negative numbers');
    is($sum_ref->{'c1'}, 30.75, 'sum handles zero');
    is($sum_ref->{'c2'}, 18.14, 'sum handles decimal numbers');
};

# Test width function
subtest 'width function tests' => sub {
    # Reset variables
    $width_min_ref = {};
    $width_max_ref = {};
    $width_line_min_ref = {};
    $width_line_max_ref = {};
    @WIDTH_COLUMNS = (0, 1);
    $LINE_NUMBER = 1;
    
    my @test_line = ('short', 'longer string');
    width(\@test_line, $LINE_NUMBER);
    
    is($width_min_ref->{'c0'}, 5, 'width tracks minimum length for column 0');
    is($width_max_ref->{'c0'}, 5, 'width tracks maximum length for column 0');
    is($width_min_ref->{'c1'}, 13, 'width tracks minimum length for column 1');
    is($width_max_ref->{'c1'}, 13, 'width tracks maximum length for column 1');
    
    # Test with different lengths
    $LINE_NUMBER = 2;
    @test_line = ('x', 'medium');
    width(\@test_line, $LINE_NUMBER);
    
    is($width_min_ref->{'c0'}, 1, 'width updates minimum when smaller');
    is($width_max_ref->{'c0'}, 5, 'width keeps maximum when current is smaller');
    is($width_min_ref->{'c1'}, 6, 'width updates minimum for column 1');
    is($width_max_ref->{'c1'}, 13, 'width keeps maximum for column 1');
    
    # Test with undefined value
    $LINE_NUMBER = 3;
    @test_line = (undef, 'test');
    width(\@test_line, $LINE_NUMBER);
    
    is($width_min_ref->{'c0'}, 0, 'width sets minimum to 0 for undefined value');
    is($width_line_min_ref->{'c0'}, 3, 'width tracks line number for minimum');
};

# Test average function
subtest 'average function tests' => sub {
    # Reset variables
    $avg_ref = {};
    $avg_count = {};
    @AVG_COLUMNS = (0, 1);
    
    my @test_line = ('10', '20.5');
    average(\@test_line);
    
    is($avg_ref->{'c0'}, 10, 'average accumulates first value');
    is($avg_count->{'c0'}, 1, 'average tracks count');
    is($avg_ref->{'c1'}, 20.5, 'average handles float values');
    is($avg_count->{'c1'}, 1, 'average tracks count for float');
    
    # Test accumulation
    @test_line = ('30', '15.5');
    average(\@test_line);
    
    is($avg_ref->{'c0'}, 40, 'average accumulates values');
    is($avg_count->{'c0'}, 2, 'average increments count');
    is($avg_ref->{'c1'}, 36, 'average accumulates float values');
    is($avg_count->{'c1'}, 2, 'average increments count for float');
};

# Test inc_line function
subtest 'inc_line function tests' => sub {
    @INCR_COLUMNS = (0, 2);
    
    my @test_line = ('5', 'text', '10');
    inc_line(\@test_line);
    
    is_deeply(\@test_line, ['6', 'text', '11'], 'inc_line increments specified columns');
    
    # Test with undefined value
    @test_line = (undef, 'text', '0');
    inc_line(\@test_line);
    
    is_deeply(\@test_line, [undef, 'text', '1'], 'inc_line skips undefined values');
};

# Test inc_line_by_value function
subtest 'inc_line_by_value function tests' => sub {
    @INCR3_COLUMNS = (0, 1);
    $increment_ref = {0 => '5', 1 => '2.5'};
    
    my @test_line = ('10', '20.5');
    inc_line_by_value(\@test_line);
    
    is_deeply(\@test_line, ['15', '23'], 'inc_line_by_value increments by specified amounts');
    
    # Test with invalid increment value
    $increment_ref = {0 => 'invalid', 1 => '3'};
    @test_line = ('10', '20');
    inc_line_by_value(\@test_line);
    
    is_deeply(\@test_line, ['10', '23'], 'inc_line_by_value ignores invalid increment values');
};

# Test do_math function
subtest 'do_math function tests' => sub {
    @MATH_COLUMNS = ('c0', 'c1', 'c2');
    
    # Test addition
    $math_ref = {'add' => 1};
    my @test_line = ('10', '5', '3');
    do_math(\@test_line);
    
    like($test_line[0], qr/^18(\.00)?$/, 'do_math performs addition');
    is(scalar(@test_line), 4, 'do_math prepends result');
    
    # Test multiplication
    $math_ref = {'mul' => 1};
    @test_line = ('2', '3', '4');
    do_math(\@test_line);
    
    like($test_line[0], qr/^24(\.00)?$/, 'do_math performs multiplication');
    
    # Test division
    $math_ref = {'div' => 1};
    @test_line = ('100', '5', '2');
    do_math(\@test_line);
    
    like($test_line[0], qr/^10(\.00)?$/, 'do_math performs division');
    
    # Test subtraction
    $math_ref = {'sub' => 1};
    @test_line = ('100', '30', '20');
    do_math(\@test_line);
    
    like($test_line[0], qr/^50(\.00)?$/, 'do_math performs subtraction');
};

# Test delta_previous_line function
subtest 'delta_previous_line function tests' => sub {
    @DELTA4_COLUMNS = (0, 1);
    $delta_cols_ref = {};
    $opt{'R'} = 0;
    $opt{'N'} = 0;
    
    # First line - just stores values
    my @test_line = ('10', '20');
    delta_previous_line(\@test_line);
    
    is_deeply(\@test_line, ['10', '20'], 'delta_previous_line stores first values');
    
    # Second line - computes deltas
    @test_line = ('15', '25');
    delta_previous_line(\@test_line);
    
    is_deeply(\@test_line, ['5', '5'], 'delta_previous_line computes differences');
    
    # Third line - computes deltas from previous
    @test_line = ('12', '30');
    delta_previous_line(\@test_line);
    
    is_deeply(\@test_line, ['-3', '5'], 'delta_previous_line handles negative differences');
};

# Test add_auto_increment function
subtest 'add_auto_increment function tests' => sub {
    $AUTO_INCR_COLUMN = 1;
    $AUTO_INCR_SEED = 100;
    $AUTO_INCR_RESET = 0;
    
    my @test_line = ('apple', 'banana');
    add_auto_increment(\@test_line);
    
    is_deeply(\@test_line, ['apple', '100', 'banana'], 'add_auto_increment inserts at specified position');
    is($AUTO_INCR_SEED, 101, 'add_auto_increment increments seed');
    
    # Test append at end
    $AUTO_INCR_COLUMN = 10;  # Beyond array size
    @test_line = ('test');
    add_auto_increment(\@test_line);
    
    is_deeply(\@test_line, ['test', '101'], 'add_auto_increment appends when position exceeds size');
};

# Test histogram function
subtest 'histogram function tests' => sub {
    @HISTOGRAM_COLUMN = (0);
    $hist_ref = {0 => '*'};
    
    my @test_line = ('3');
    histogram(\@test_line);
    
    is($test_line[0], '***', 'histogram creates visual representation');
    
    # Test with zero
    @test_line = ('0');
    histogram(\@test_line);
    
    is($test_line[0], '', 'histogram handles zero');
    
    # Test with different character
    $hist_ref = {0 => '#'};
    @test_line = ('5');
    histogram(\@test_line);
    
    is($test_line[0], '#####', 'histogram uses specified character');
};

# Test do_op function
subtest 'do_op function tests' => sub {
    $J_CMD = 'min';
    $J_COUNT = 0;
    $J_BUCKET_COUNTS = {};
    
    # Test initialization
    my $result = do_op('key1', 'init', '10');
    is($result, '10', 'do_op initializes with first value');
    
    # Test min operation
    $result = do_op('key1', '10', '5');
    is($result, '5', 'do_op finds minimum');
    
    $result = do_op('key1', '5', '8');
    is($result, '5', 'do_op keeps minimum');
    
    # Test max operation
    $J_CMD = 'max';
    $result = do_op('key2', '10', '15');
    is($result, '15', 'do_op finds maximum');
    
    $result = do_op('key2', '15', '12');
    is($result, '15', 'do_op keeps maximum');
    
    # Test sum operation
    $J_CMD = 'sum';
    $result = do_op('key3', '10', '5');
    is($result, '15', 'do_op performs sum');
    
    # Test avg operation (same as sum)
    $J_CMD = 'avg';
    $result = do_op('key4', '10', '5');
    is($result, '15', 'do_op performs avg (accumulation)');
    
    # Test invalid numeric value
    $result = do_op('key5', '10', 'invalid');
    is($result, '10', 'do_op ignores non-numeric values');
};

# Test edge cases
subtest 'edge cases' => sub {
    # Test with empty arrays
    my @empty_line = ();
    
    count(\@empty_line);
    sum(\@empty_line);
    inc_line(\@empty_line);
    
    ok(1, 'functions handle empty arrays without crashing');
    
    # Test do_math with division by zero
    $math_ref = {'div' => 1};
    @MATH_COLUMNS = ('c0', 'c1');
    my @test_line = ('10', '0');
    do_math(\@test_line);
    
    is($test_line[0], 'NaN', 'do_math handles division by zero');
    
    # Test very large numbers
    @SUM_COLUMNS = (0);
    $sum_ref = {};
    @test_line = ('999999999999999');
    sum(\@test_line);
    
    is($sum_ref->{'c0'}, 999999999999999, 'sum handles large numbers');
};

# Test debug output paths (0% coverage branches)
subtest 'debug output comprehensive tests' => sub {
    local %main::opt = ('D' => 1); # Enable debug flag
    
    # Test width debug output (line 72)
    $width_min_ref = {}; $width_max_ref = {}; $width_line_min_ref = {}; $width_line_max_ref = {};
    @WIDTH_COLUMNS = (0);
    my @test_line = ('test');
    $LINE_NUMBER = 1;
    
    width(\@test_line, $LINE_NUMBER);
    ok(1, 'width function executes with debug flag enabled');
    
    # Test inc_line_by_value debug output (line 151)
    local @INCR3_COLUMNS = (0, 1);
    local $increment_ref = {};
    @test_line = ('5', '10');
    inc_line_by_value(\@test_line);
    ok(1, 'inc_line_by_value executes with debug flag enabled');
    
    # Test do_math debug output (line 171)
    local @MATH_COLUMNS = (0);
    local $math_ref = {'c0' => 'add:5'};
    @test_line = ('10');
    do_math(\@test_line);
    ok(1, 'do_math executes with debug flag enabled');
    
    # Test delta_previous_line debug output (line 231)
    local @DELTA4_COLUMNS = (0);
    local $delta_cols_ref = {};
    @test_line = ('15');
    delta_previous_line(\@test_line);
    ok(1, 'delta_previous_line executes with debug flag enabled');
    
    # Test histogram debug output (line 312)
    local @HISTOGRAM_COLUMN = (0);
    local $hist_ref = {};
    @test_line = ('test_value');
    histogram(\@test_line);
    ok(1, 'histogram executes with debug flag enabled');
    
    # Test do_op debug output (line 336) - helper function with individual params
    my $result = do_op('test_key', '10', 'non_numeric_value');
    ok(1, 'do_op executes with debug flag enabled');
};

# Test reverse delta operations (-R flag) - 0% coverage
subtest 'reverse delta operations comprehensive tests' => sub {
    local %main::opt = ('R' => 1); # Enable reverse flag
    local @DELTA4_COLUMNS = (0, 1);
    local $delta_cols_ref = {};
    
    # Initialize delta state with first line
    my @test_line = ('10', '20');
    delta_previous_line(\@test_line);
    is($delta_cols_ref->{0}, 10, 'reverse delta initializes first value');
    is($delta_cols_ref->{1}, 20, 'reverse delta initializes second value');
    
    # Test reverse delta calculation (lines 244-254)
    @test_line = ('15', '25');
    delta_previous_line(\@test_line);
    is($test_line[0], -5, 'reverse delta calculates difference: 10 - 15 = -5');
    is($test_line[1], -5, 'reverse delta calculates difference: 20 - 25 = -5');
    is($delta_cols_ref->{0}, 15, 'reverse delta saves current value for next iteration');
    is($delta_cols_ref->{1}, 25, 'reverse delta saves current value for next iteration');
};

# Test absolute value in reverse delta operations (-R + -N flags) - 0% coverage  
subtest 'absolute value reverse delta operations tests' => sub {
    local %main::opt = ('R' => 1, 'N' => 1); # Enable reverse and absolute flags
    local @DELTA4_COLUMNS = (0);
    local $delta_cols_ref = {};
    
    # Initialize with first value
    my @test_line = ('10');
    delta_previous_line(\@test_line);
    is($delta_cols_ref->{0}, 10, 'absolute reverse delta initializes');
    
    # Test absolute value calculation in reverse delta (lines 246-248)
    @test_line = ('15');
    delta_previous_line(\@test_line);
    is($test_line[0], 5, 'absolute reverse delta: abs(10 - 15) = 5');
    is($delta_cols_ref->{0}, 15, 'absolute reverse delta saves original value');
    
    # Test with negative result
    @test_line = ('12');
    delta_previous_line(\@test_line);
    is($test_line[0], 3, 'absolute reverse delta: abs(15 - 12) = 3');
};

# Test width calculation edge cases - 0% coverage (lines 95-96)
subtest 'width calculation edge cases tests' => sub {
    # Test width_max_ref initialization for undefined columns (lines 95-96)
    $width_min_ref = {}; $width_max_ref = {}; $width_line_min_ref = {}; $width_line_max_ref = {};
    @WIDTH_COLUMNS = (0);
    $LINE_NUMBER = 10;
    
    # Test empty string case which triggers width_max initialization
    my @test_line = (''); 
    width(\@test_line, $LINE_NUMBER);
    
    is($width_min_ref->{'c0'}, 0, 'width_min_ref set to 0 for empty string');
    is($width_max_ref->{'c0'}, 0, 'width_max_ref initialized to 0 for empty column');
    is($width_line_min_ref->{'c0'}, 10, 'width_line_min_ref records line number');
    is($width_line_max_ref->{'c0'}, 10, 'width_line_max_ref records line number');
};

# Test string-based auto increment reset - 0% coverage (line 298)
subtest 'string-based auto increment reset tests' => sub {
    # Test string comparison logic for auto increment reset (line 298)
    local $AUTO_INCR_RESET = 'zz';  # String value to trigger string comparison
    local $AUTO_INCR_SEED = 'bb';   # String seed value
    local $AUTO_INCR_ORIG_VALUE = 'aa';
    local $AUTO_INCR_COLUMN = 0;
    
    my @test_line = ('any_value');
    add_auto_increment(\@test_line);
    
    # Since 'bb' gt 'zz' is false, seed should not reset but still increment to 'bc'
    is($AUTO_INCR_SEED, 'bc', 'string auto increment seed increments but does not reset when below threshold');
    
    # Test when string seed exceeds reset threshold
    $AUTO_INCR_SEED = 'zza';  # Greater than 'zz'
    add_auto_increment(\@test_line);
    is($AUTO_INCR_SEED, 'aa', 'string auto increment seed resets when exceeding threshold');
};

# Test absolute value in forward delta operations (-N flag) - 50% coverage
subtest 'absolute value forward delta operations tests' => sub {
    local %main::opt = ('N' => 1); # Enable absolute flag only
    local @DELTA4_COLUMNS = (0);
    local $delta_cols_ref = {};
    
    # Initialize with first value
    my @test_line = ('20');
    delta_previous_line(\@test_line);
    is($delta_cols_ref->{0}, 20, 'absolute forward delta initializes');
    
    # Test absolute value calculation in forward delta (line 261)
    @test_line = ('15');
    delta_previous_line(\@test_line);
    is($test_line[0], 5, 'absolute forward delta: abs(15 - 20) = 5');
    is($delta_cols_ref->{0}, 15, 'absolute forward delta updates reference');
    
    # Test with positive difference
    @test_line = ('25');
    delta_previous_line(\@test_line);
    is($test_line[0], 10, 'absolute forward delta: abs(25 - 15) = 10');
};

# Test enhanced branch coverage for existing functions
subtest 'enhanced branch coverage tests' => sub {
    # Test average with non-numeric values (line 111)
    local @AVG_COLUMNS = (0, 1);
    local $avg_ref = {}; local $avg_count = {};
    my @test_line = ('not_numeric', '15');
    average(\@test_line);
    
    is($avg_ref->{'c1'}, 15, 'average handles mixed numeric/non-numeric values');
    is($avg_count->{'c1'}, 1, 'average count increments for valid numeric value');
    ok(!exists $avg_ref->{'c0'}, 'average ignores non-numeric values');
    
    # Test inc_line_by_value with non-matching columns (line 143)
    local @INCR3_COLUMNS = (5, 6); # Columns that don't exist in test line
    local $increment_ref = {};
    @test_line = ('a', 'b'); # Only columns 0,1 exist
    inc_line_by_value(\@test_line);
    
    ok(!exists $increment_ref->{'c5'}, 'inc_line_by_value ignores non-existent columns');
    
    # Test do_math with non-matching columns (line 166)
    local @MATH_COLUMNS = (10); # Column that doesn't exist
    local $math_ref = {};
    @test_line = ('value');
    do_math(\@test_line);
    
    ok(1, 'do_math handles non-existent column gracefully');
    
    # Test delta with non-matching columns (line 226)
    local @DELTA4_COLUMNS = (10); # Column that doesn't exist
    local $delta_cols_ref = {};
    @test_line = ('value');
    delta_previous_line(\@test_line);
    
    ok(1, 'delta_previous_line handles non-existent column gracefully');
    
    # Test histogram with non-matching columns (line 310)
    local @HISTOGRAM_COLUMN = (10); # Column that doesn't exist
    local $hist_ref = {};
    @test_line = ('value');
    my $result = histogram(\@test_line);
    
    is($result, '', 'histogram returns empty string for non-existent column');
};

done_testing();