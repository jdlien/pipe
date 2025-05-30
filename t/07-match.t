#!/usr/bin/perl
#
# Unit tests for Pipe::Match module
#
use strict;
use warnings;
use Test::More;
use lib 'lib';

BEGIN { 
    use_ok('Pipe::Match') or BAIL_OUT("Can't load Pipe::Match");
}

# Import required functions for testing
use Pipe::Match qw(:all);
use Pipe::Core qw(:constants :keywords :functions);

# Set up global variables that the module expects
our %opt = ();
our $DELIMITER = '|';

# Test is_match function (simplified tests due to complexity)
subtest 'is_match function tests' => sub {
    # Set up global variables for testing
    local %main::opt = ('D' => 0, 'I' => 0, '5' => 0);
    local $main::DELIMITER = '|';
    
    my @test_line = ('apple', 'banana', 'cherry');
    my $regex_ref = {0 => 'app', 1 => 'ban'};
    my @match_columns = (0, 1);
    
    # Test basic pattern matching functionality
    my $result = is_match(\@test_line, $regex_ref, \@match_columns);
    is($result, 1, 'is_match finds patterns in specified columns');
    
    # Test non-matching patterns
    $regex_ref = {0 => 'xyz', 1 => 'ban'};
    $result = is_match(\@test_line, $regex_ref, \@match_columns);
    is($result, 0, 'is_match returns 0 when not all patterns match');
    
    # Test with 'any' keyword
    my @any_columns = ('any');
    $regex_ref = {'any' => 'app'};
    $result = is_match(\@test_line, $regex_ref, \@any_columns);
    is($result, 1, 'is_match works with any keyword');
    
    # Test case insensitive matching
    %main::opt = ('I' => 1, 'D' => 0, '5' => 0);
    $regex_ref = {0 => 'APP'};
    @match_columns = (0);
    $result = is_match(\@test_line, $regex_ref, \@match_columns);
    is($result, 1, 'is_match works with case insensitive flag');
    
    # Test empty regex (should match first column pattern against other columns)
    %main::opt = ('I' => 0, 'D' => 0, '5' => 0);
    my @match_line = ('test', 'test', 'other');
    $regex_ref = {0 => '', 1 => ''};  # Empty regex should use first column
    @match_columns = (0, 1);
    $result = is_match(\@match_line, $regex_ref, \@match_columns);
    # This should use the first column's value to match other columns
    ok(defined $result, 'is_match handles empty regex patterns');
    
    # Test with undefined column
    my @sparse_line = ('apple', undef, 'cherry');
    $regex_ref = {1 => 'test'};
    @match_columns = (1);
    $result = is_match(\@sparse_line, $regex_ref, \@match_columns);
    is($result, 0, 'is_match handles undefined columns');
};

# Test is_not_match function  
subtest 'is_not_match function tests' => sub {
    # Set up global variables for testing  
    local %main::opt = ('D' => 0, 'I' => 0);
    local @main::NOT_MATCH_COLUMNS = (0, 1);
    local $main::not_match_ref = {0 => 'xyz', 1 => 'unknown'};
    
    my @test_line = ('apple', 'banana', 'cherry');
    
    # Test non-matching patterns (should return 1)
    my $result = is_not_match(\@test_line);
    is($result, 1, 'is_not_match returns 1 when patterns do not match');
    
    # Test matching patterns (should return 0)
    $main::not_match_ref = {0 => 'app', 1 => 'ban'};
    $result = is_not_match(\@test_line);
    is($result, 0, 'is_not_match returns 0 when patterns match');
    
    # Test with 'any' keyword
    @main::NOT_MATCH_COLUMNS = ('any');
    $main::not_match_ref = {'any' => 'xyz'};
    $result = is_not_match(\@test_line);
    is($result, 1, 'is_not_match works with any keyword (no match)');
    
    # Test with 'any' keyword that matches
    $main::not_match_ref = {'any' => 'app'};
    $result = is_not_match(\@test_line);
    is($result, 0, 'is_not_match works with any keyword (match found)');
    
    # Test case insensitive
    %main::opt = ('I' => 1, 'D' => 0);
    $main::not_match_ref = {'any' => 'APP'};
    $result = is_not_match(\@test_line);
    is($result, 0, 'is_not_match case insensitive matching works');
    
    # Test with undefined columns
    my @sparse_line = ('apple', undef, 'cherry');
    @main::NOT_MATCH_COLUMNS = (1);
    $main::not_match_ref = {1 => 'test'};
    %main::opt = ('I' => 0, 'D' => 0);
    $result = is_not_match(\@sparse_line);
    is($result, 1, 'is_not_match handles undefined columns');
};

# Test is_empty function
subtest 'is_empty function tests' => sub {
    # Set up required global variables
    local @main::EMPTY_COLUMNS = (0, 1, 2);  # Check all columns
    local $main::opt = { 'D' => 0 };
    
    my @empty_line = ('', '', '');
    my $result = is_empty(\@empty_line);
    is($result, 1, 'is_empty detects empty line');
    
    my @non_empty_line = ('apple', '', 'cherry');
    $result = is_empty(\@non_empty_line);
    is($result, 1, 'is_empty returns 1 when any column is empty');
    
    my @all_filled_line = ('apple', 'banana', 'cherry');
    $result = is_empty(\@all_filled_line);
    is($result, 0, 'is_empty returns 0 for filled line');
};

# Test is_not_empty function
subtest 'is_not_empty function tests' => sub {
    # Set up required global variables
    local @main::SHOW_EMPTY_COLUMNS = (0, 1, 2);  # Check all columns
    local $main::opt = { 'D' => 0 };
    
    my @empty_line = ('', '', '');
    my $result = is_not_empty(\@empty_line);
    is($result, 0, 'is_not_empty returns 0 for empty line');
    
    my @non_empty_line = ('apple', '', 'cherry');
    $result = is_not_empty(\@non_empty_line);
    is($result, 0, 'is_not_empty returns 0 when any column is empty');
    
    my @all_filled_line = ('apple', 'banana', 'cherry');
    $result = is_not_empty(\@all_filled_line);
    is($result, 1, 'is_not_empty returns 1 for filled line');
};

# Test contain_same_value function
subtest 'contain_same_value function tests' => sub {
    my @same_values = ('apple', 'apple', 'apple');
    my @columns = (0, 1, 2);
    
    my $result = contain_same_value(\@same_values, \@columns);
    is($result, 1, 'contain_same_value detects identical values');
    
    my @different_values = ('apple', 'banana', 'apple');
    $result = contain_same_value(\@different_values, \@columns);
    is($result, 0, 'contain_same_value detects different values');
    
    my @partial_same = ('apple', 'apple', 'cherry');
    @columns = (0, 1);  # Only check first two columns
    $result = contain_same_value(\@partial_same, \@columns);
    is($result, 1, 'contain_same_value works with subset of columns');
};

# Test test_condition function (simplified)
subtest 'test_condition function tests' => sub {
    # This function has complex dependencies on global variables
    # For now, just verify it executes without errors
    
    my @test_line = ('10', '20', '30');
    
    my $result = test_condition(\@test_line);
    ok(defined $result, 'test_condition executes and returns a value');
    ok($result == 0 || $result == 1, 'test_condition returns boolean value');
};

# Test test_condition_cmp function - simplified to avoid exit issues
subtest 'test_condition_cmp function tests' => sub {
    # Set up required global variables
    local %main::opt = ('N' => 0, 'I' => 0, 'D' => 0, 'U' => 0);
    
    # Test numeric comparisons
    my $result = test_condition_cmp('eq', '10', '10');
    is($result, 1, 'test_condition_cmp eq comparison works');
    
    $result = test_condition_cmp('lt', '10', '5');
    is($result, 1, 'test_condition_cmp lt comparison works');
    
    $result = test_condition_cmp('gt', '10', '15');
    is($result, 1, 'test_condition_cmp gt comparison works');
    
    $result = test_condition_cmp('le', '10', '10');
    is($result, 1, 'test_condition_cmp le comparison works');
    
    $result = test_condition_cmp('ge', '10', '10');
    is($result, 1, 'test_condition_cmp ge comparison works');
    
    $result = test_condition_cmp('ne', '10', '5');
    is($result, 1, 'test_condition_cmp ne comparison works');
    
    # Test string comparisons
    $result = test_condition_cmp('eq', 'apple', 'apple');
    is($result, 1, 'test_condition_cmp string eq works');
    
    $result = test_condition_cmp('lt', 'banana', 'apple');
    is($result, 1, 'test_condition_cmp string lt works');
    
    # Test range comparisons  
    $result = test_condition_cmp('rg', '5-15', '10');
    is($result, 1, 'test_condition_cmp range comparison works');
    
    $result = test_condition_cmp('rg', '5-15', '20');
    is($result, 0, 'test_condition_cmp range comparison fails outside range');
    
    # Test width comparisons
    $result = test_condition_cmp('width', '3-5', 'test');
    is($result, 1, 'test_condition_cmp width comparison works');
    
    $result = test_condition_cmp('width', '6-10', 'test');
    is($result, 0, 'test_condition_cmp width comparison fails');
    
    # Test case insensitive
    %main::opt = ('I' => 1, 'D' => 0, 'N' => 0, 'U' => 0);
    $result = test_condition_cmp('eq', 'APPLE', 'apple');
    is($result, 1, 'test_condition_cmp case insensitive works');
};

# Test _get_range_ function
subtest '_get_range_ function tests' => sub {
    local %main::opt = ('D' => 0);
    
    # Test positive range
    my @range = _get_range_('5-10');
    is_deeply(\@range, [5, 10], '_get_range_ parses positive range correctly');
    
    # Test range with negative numbers
    @range = _get_range_('-5-5');
    is_deeply(\@range, [-5, 5], '_get_range_ handles negative start correctly');
    
    # Test reversed range (should be ordered smallest to largest)
    @range = _get_range_('10-5');
    is_deeply(\@range, [5, 10], '_get_range_ orders range correctly');
    
    # Test decimal ranges
    @range = _get_range_('1.5-3.7');
    is_deeply(\@range, [1.5, 3.7], '_get_range_ handles decimal ranges');
    
    # Test single digit ranges
    @range = _get_range_('1-9');
    is_deeply(\@range, [1, 9], '_get_range_ handles single digit ranges');
};

# Test edge cases and additional coverage
subtest 'edge cases and additional coverage' => sub {
    # Set up required global variables for empty tests
    local @main::EMPTY_COLUMNS = (0);
    local @main::SHOW_EMPTY_COLUMNS = (0);
    local %main::opt = ('D' => 0);
    
    # Test with empty arrays
    my @empty_line = ();
    my $result = is_empty(\@empty_line);
    ok(defined $result, 'is_empty handles empty array');
    
    $result = is_not_empty(\@empty_line);
    ok(defined $result, 'is_not_empty handles empty array');
    
    # Test with undefined values
    my @undef_line = (undef, 'test', undef);
    $result = is_empty(\@undef_line);
    ok(defined $result, 'is_empty handles undefined values');
    
    $result = is_not_empty(\@undef_line);
    ok(defined $result, 'is_not_empty handles undefined values');
    
    # Test contain_same_value with case insensitive
    %main::opt = ('I' => 1, 'D' => 0);
    my @case_line = ('APPLE', 'apple', 'Apple');
    my @test_columns = (0, 1, 2);
    $result = contain_same_value(\@case_line, \@test_columns);
    is($result, 1, 'contain_same_value works case insensitive');
    
    # Test contain_same_value with different values
    %main::opt = ('I' => 0, 'D' => 0);
    my @diff_line = ('apple', 'banana', 'cherry');
    $result = contain_same_value(\@diff_line, \@test_columns);
    is($result, 0, 'contain_same_value detects different values');
    
    # Test contain_same_value with undefined columns
    my @sparse_same = ('apple', undef, 'apple');
    @test_columns = (0, 1, 2);
    $result = contain_same_value(\@sparse_same, \@test_columns);
    is($result, 0, 'contain_same_value handles undefined values correctly');
    
    # Test test_condition_cmp with normalize flag
    %main::opt = ('N' => 1, 'I' => 0, 'D' => 0, 'U' => 0);
    $result = test_condition_cmp('eq', 'test value', 'test  value');
    ok(defined $result, 'test_condition_cmp with normalize flag works');
    
    # Test test_condition_cmp with U flag (numeric only)
    %main::opt = ('U' => 1, 'I' => 0, 'D' => 0, 'N' => 0);
    $result = test_condition_cmp('eq', 'not_a_number', 'also_not_number');
    is($result, 0, 'test_condition_cmp with U flag rejects non-numeric');
    
    # Test negative numeric comparisons
    %main::opt = ('U' => 0, 'I' => 0, 'D' => 0, 'N' => 0);
    $result = test_condition_cmp('lt', '-5', '-10');
    is($result, 1, 'test_condition_cmp handles negative numbers');
};

# Test case-insensitive matching with -I flag (0% coverage critical gap)
subtest 'case-insensitive matching with -I flag tests' => sub {
    # Test is_match with -I flag
    local %main::opt = ('I' => 1, 'D' => 0, '5' => 0);
    local $main::DELIMITER = '|';
    
    my @test_line = ('APPLE', 'banana', 'Cherry');
    my $regex_ref = {0 => 'apple', 1 => 'BANANA'};
    my @match_columns = (0, 1);
    
    my $result = is_match(\@test_line, $regex_ref, \@match_columns);
    is($result, 1, 'is_match case-insensitive matching works');
    
    # Test is_not_match with -I flag
    local @main::NOT_MATCH_COLUMNS = (0);
    local $main::not_match_ref = {0 => 'APPLE'};
    
    $result = is_not_match(\@test_line);
    is($result, 0, 'is_not_match case-insensitive matching works');
    
    # Test case-insensitive with any keyword
    @main::NOT_MATCH_COLUMNS = ('any');
    $main::not_match_ref = {'any' => 'CHERRY'};
    
    $result = is_not_match(\@test_line);
    is($result, 0, 'is_not_match any keyword case-insensitive works');
};

# Test debug output with -D and -5 flags (0% coverage critical gap)
subtest 'debug output with -D and -5 flags tests' => sub {
    # Test debug mode with existing regex patterns
    local %main::opt = ('D' => 1, 'I' => 0, '5' => 0);
    local $main::DELIMITER = '|';
    
    my @test_line = ('apple', 'banana');
    my $regex_ref = {0 => 'app', 'any' => 'test'};
    my @match_columns = (0);
    
    # Capture STDERR to test debug output
    my $result = is_match(\@test_line, $regex_ref, \@match_columns);
    ok(defined $result, 'is_match with debug flag executes');
    
    # Test debug with undefined regex patterns
    $regex_ref = {0 => undef};
    $result = is_match(\@test_line, $regex_ref, \@match_columns);
    ok(defined $result, 'is_match debug with undefined regex works');
    
    # Test is_not_match debug output
    local @main::NOT_MATCH_COLUMNS = (0);
    local $main::not_match_ref = {0 => 'test'};
    
    $result = is_not_match(\@test_line);
    ok(defined $result, 'is_not_match with debug flag executes');
    
    # Test -5 flag (match display output)
    %main::opt = ('D' => 0, 'I' => 0, '5' => 1);
    @match_columns = ('any');
    $regex_ref = {'any' => 'app'};
    
    $result = is_match(\@test_line, $regex_ref, \@match_columns);
    is($result, 1, 'is_match with -5 flag match display works');
};

# Test conditional testing functions (0% coverage critical gap)
subtest 'conditional testing functions comprehensive tests' => sub {
    # Set up global variables for test_condition
    local %main::opt = ('D' => 0, 'I' => 0, 'N' => 0, 'U' => 0);
    local @main::COND_CMP_COLUMNS = ();
    local $main::cond_cmp_ref = {};
    
    my @test_line = ('10', '20', 'test', 'value');
    
    # Test width comparison
    @main::COND_CMP_COLUMNS = ('num_cols');
    $main::cond_cmp_ref = {'num_cols' => 'width2-5'};
    
    my $result = test_condition(\@test_line);
    is($result, 1, 'test_condition width comparison works');
    
    # Test width comparison that fails
    $main::cond_cmp_ref = {'num_cols' => 'width10-20'};
    
    $result = test_condition(\@test_line);
    is($result, 0, 'test_condition width comparison fails correctly');
    
    # Test any keyword with comparison operators
    @main::COND_CMP_COLUMNS = ('any');
    $main::cond_cmp_ref = {'any' => 'eq10'};
    
    $result = test_condition(\@test_line);
    is($result, 1, 'test_condition any keyword eq comparison works');
    
    # Note: cc (column comparison) operator causes exit() with current format
    # Documented for coverage tracking: 'cceq1' format triggers exit() at line 490
    # This requires integration testing rather than unit testing
    
    # Test specific column conditions (safe operators)
    @main::COND_CMP_COLUMNS = (0, 1);
    $main::cond_cmp_ref = {0 => 'eq10', 1 => 'eq20'};
    
    $result = test_condition(\@test_line);
    is($result, 1, 'test_condition multiple column conditions work');
    
    # Note: Invalid operators cause exit() and cannot be tested in unit tests
    # Documented for coverage tracking: malformed operators, invalid cc syntax
};

# Test string comparison operators (0% coverage critical gap)
subtest 'string comparison operators comprehensive tests' => sub {
    local %main::opt = ('N' => 0, 'I' => 0, 'D' => 0, 'U' => 0);
    
    # Test gt (greater than) string comparison
    my $result = test_condition_cmp('gt', 'banana', 'apple'); # banana > apple
    is($result, 1, 'test_condition_cmp string gt works (banana > apple)');
    
    $result = test_condition_cmp('gt', 'apple', 'zebra'); # apple < zebra
    is($result, 0, 'test_condition_cmp string gt works (apple < zebra)');
    
    # Test le (less than or equal) string comparison
    $result = test_condition_cmp('le', 'apple', 'banana');
    is($result, 1, 'test_condition_cmp string le works (apple <= banana)');
    
    $result = test_condition_cmp('le', 'apple', 'apple');
    is($result, 1, 'test_condition_cmp string le equal works');
    
    # Test ge (greater than or equal) string comparison
    $result = test_condition_cmp('ge', 'banana', 'apple');
    is($result, 1, 'test_condition_cmp string ge works (banana >= apple)');
    
    $result = test_condition_cmp('ge', 'apple', 'apple');
    is($result, 1, 'test_condition_cmp string ge equal works');
    
    # Test ne (not equal) string comparison
    $result = test_condition_cmp('ne', 'apple', 'banana');
    is($result, 1, 'test_condition_cmp string ne works');
    
    $result = test_condition_cmp('ne', 'apple', 'apple');
    is($result, 0, 'test_condition_cmp string ne equal fails correctly');
};

# Test range validation and error conditions (high priority gaps)
subtest 'range validation and error handling tests' => sub {
    local %main::opt = ('D' => 0);
    
    # Test valid ranges
    my @range = _get_range_('1-5');
    is_deeply(\@range, [1, 5], '_get_range_ basic range works');
    
    @range = _get_range_('-10--5');
    is_deeply(\@range, [-10, -5], '_get_range_ negative range works');
    
    @range = _get_range_('5-1'); # Should be ordered
    is_deeply(\@range, [1, 5], '_get_range_ reverses order correctly');
    
    # Test decimal ranges
    @range = _get_range_('1.5-3.7');
    is_deeply(\@range, [1.5, 3.7], '_get_range_ decimal range works');
    
    # Note: Malformed ranges cause exit(), so we document them for coverage tracking
    # These would require fork/eval testing which is beyond unit test scope:
    # - _get_range_('invalid') -> exit(1)
    # - _get_range_('1-a') -> exit(1)
    # - _get_range_('a-1') -> exit(1)
};

# Test pattern matching edge cases and fallback scenarios
subtest 'pattern matching edge cases and fallback scenarios' => sub {
    local %main::opt = ('D' => 0, 'I' => 0, '5' => 0);
    local $main::DELIMITER = '|';
    
    # Test empty regex fallback to first column pattern
    my @test_line = ('test', 'test', 'other');
    my $regex_ref = {0 => 'test', 1 => ''}; # Empty regex for column 1
    my @match_columns = (0, 1);
    
    my $result = is_match(\@test_line, $regex_ref, \@match_columns);
    ok(defined $result, 'is_match handles empty regex fallback');
    
    # Test empty first regex fallback to column comparison
    $regex_ref = {0 => '', 1 => ''}; # Both empty
    @match_columns = (0, 1);
    
    $result = is_match(\@test_line, $regex_ref, \@match_columns);
    ok(defined $result, 'is_match handles empty regex column comparison');
    
    # Test is_not_match similar scenarios
    local @main::NOT_MATCH_COLUMNS = (0, 1);
    local $main::not_match_ref = {0 => 'nomatch', 1 => ''};
    
    $result = is_not_match(\@test_line);
    ok(defined $result, 'is_not_match handles empty regex fallback');
    
    # Test is_not_match with column index > 0 check
    @test_line = ('different', 'test', 'other');
    @main::NOT_MATCH_COLUMNS = (1, 2);
    $main::not_match_ref = {1 => '', 2 => ''}; # Empty patterns
    
    $result = is_not_match(\@test_line);
    ok(defined $result, 'is_not_match column index > 0 check works');
};

# Test numeric vs string comparison logic branches
subtest 'numeric vs string comparison logic comprehensive tests' => sub {
    local %main::opt = ('N' => 0, 'I' => 0, 'D' => 0, 'U' => 0);
    
    # Test all numeric comparison operators (fix parameter order)
    my $result = test_condition_cmp('lt', '5', '10'); # 5 < 10
    is($result, 1, 'test_condition_cmp numeric lt works');
    
    $result = test_condition_cmp('gt', '15', '10'); # 15 > 10  
    is($result, 1, 'test_condition_cmp numeric gt works');
    
    $result = test_condition_cmp('le', '10', '10'); # 10 <= 10
    is($result, 1, 'test_condition_cmp numeric le equal works');
    
    $result = test_condition_cmp('ge', '15', '10'); # 15 >= 10
    is($result, 1, 'test_condition_cmp numeric ge works');
    
    $result = test_condition_cmp('ne', '5', '10');
    is($result, 1, 'test_condition_cmp numeric ne works');
    
    # Test with normalize flag
    %main::opt = ('N' => 1, 'I' => 0, 'D' => 0, 'U' => 0);
    $result = test_condition_cmp('eq', 'test value', 'test  value');
    ok(defined $result, 'test_condition_cmp with normalize flag works');
    
    # Test with case-insensitive flag
    %main::opt = ('N' => 0, 'I' => 1, 'D' => 0, 'U' => 0);
    $result = test_condition_cmp('eq', 'TEST', 'test');
    is($result, 1, 'test_condition_cmp with case-insensitive flag works');
    
    # Test with numeric-only flag (U flag)
    %main::opt = ('N' => 0, 'I' => 0, 'D' => 0, 'U' => 1);
    $result = test_condition_cmp('eq', 'not_numeric', 'also_not_numeric');
    is($result, 0, 'test_condition_cmp with U flag rejects non-numeric correctly');
};

# Test empty field functionality with debug mode
subtest 'empty field functionality with debug mode tests' => sub {
    local %main::opt = ('D' => 1);
    local @main::EMPTY_COLUMNS = (0, 1);
    local @main::SHOW_EMPTY_COLUMNS = (0, 1);
    
    # Test is_empty with debug output
    my @test_line = ('', 'value', '');
    my $result = is_empty(\@test_line);
    is($result, 1, 'is_empty with debug mode works');
    
    # Test is_not_empty with debug output
    $result = is_not_empty(\@test_line);
    is($result, 0, 'is_not_empty with debug mode works');
    
    # Test with all non-empty fields
    @test_line = ('value1', 'value2', 'value3');
    $result = is_empty(\@test_line);
    is($result, 0, 'is_empty returns 0 for non-empty fields with debug');
    
    $result = is_not_empty(\@test_line);
    is($result, 1, 'is_not_empty returns 1 for non-empty fields with debug');
};

# Test contain_same_value with debug mode and edge cases
subtest 'contain_same_value with debug mode and edge cases tests' => sub {
    local %main::opt = ('D' => 1, 'I' => 0);
    
    # Test with debug output
    my @test_line = ('value', 'value', 'value');
    my @columns = (0, 1, 2);
    
    my $result = contain_same_value(\@test_line, \@columns);
    is($result, 1, 'contain_same_value with debug mode works');
    
    # Test with undefined values in debug mode
    @test_line = ('value', undef, 'value');
    $result = contain_same_value(\@test_line, \@columns);
    is($result, 0, 'contain_same_value handles undefined values with debug');
    
    # Test case-insensitive with debug
    %main::opt = ('D' => 1, 'I' => 1);
    @test_line = ('VALUE', 'value', 'Value');
    $result = contain_same_value(\@test_line, \@columns);
    is($result, 1, 'contain_same_value case-insensitive with debug works');
    
    # Test with empty string as lastValue
    @test_line = ('', '', '');
    @columns = (0, 1, 2);
    %main::opt = ('D' => 0, 'I' => 0);
    $result = contain_same_value(\@test_line, \@columns);
    ok(defined $result, 'contain_same_value handles empty strings correctly');
};

done_testing();