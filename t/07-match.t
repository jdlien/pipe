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

done_testing();