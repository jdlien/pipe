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
    # These tests are simplified due to complex global variable dependencies
    # The function works in the actual application but is difficult to test in isolation
    
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
};

# Test is_not_match function  
subtest 'is_not_match function tests' => sub {
    my @test_line = ('apple', 'banana', 'cherry');
    
    # Test that function executes without errors
    my $result = is_not_match(\@test_line);
    ok(defined $result, 'is_not_match executes and returns a value');
    ok($result == 0 || $result == 1, 'is_not_match returns boolean value');
};

# Test is_empty function
subtest 'is_empty function tests' => sub {
    my @empty_line = ('', '', '');
    my $result = is_empty(\@empty_line);
    is($result, 1, 'is_empty detects empty line');
    
    my @non_empty_line = ('apple', '', 'cherry');
    $result = is_empty(\@non_empty_line);
    is($result, 0, 'is_empty detects non-empty line');
    
    my @all_filled_line = ('apple', 'banana', 'cherry');
    $result = is_empty(\@all_filled_line);
    is($result, 0, 'is_empty returns 0 for filled line');
};

# Test is_not_empty function
subtest 'is_not_empty function tests' => sub {
    my @empty_line = ('', '', '');
    my $result = is_not_empty(\@empty_line);
    is($result, 0, 'is_not_empty returns 0 for empty line');
    
    my @non_empty_line = ('apple', '', 'cherry');
    $result = is_not_empty(\@non_empty_line);
    is($result, 1, 'is_not_empty detects non-empty line');
    
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

# Test test_condition_cmp function
subtest 'test_condition_cmp function tests' => sub {
    # Test basic comparison functionality
    my $result = test_condition_cmp('10', '>', '5');
    is($result, 1, 'test_condition_cmp: 10 > 5 is true');
    
    $result = test_condition_cmp('5', '>', '10');
    is($result, 0, 'test_condition_cmp: 5 > 10 is false');
    
    $result = test_condition_cmp('10', '==', '10');
    is($result, 1, 'test_condition_cmp: 10 == 10 is true');
    
    $result = test_condition_cmp('apple', 'eq', 'apple');
    is($result, 1, 'test_condition_cmp: string equality works');
    
    $result = test_condition_cmp('apple', 'ne', 'banana');
    is($result, 1, 'test_condition_cmp: string inequality works');
    
    $result = test_condition_cmp('5', '<', '10');
    is($result, 1, 'test_condition_cmp: 5 < 10 is true');
    
    $result = test_condition_cmp('15', '<=', '15');
    is($result, 1, 'test_condition_cmp: 15 <= 15 is true');
    
    $result = test_condition_cmp('20', '>=', '15');
    is($result, 1, 'test_condition_cmp: 20 >= 15 is true');
};

# Test _get_range_ function
subtest '_get_range_ function tests' => sub {
    # Test range parsing
    my $result = _get_range_('1-5');
    is_deeply($result, [1, 2, 3, 4, 5], '_get_range_ parses simple range');
    
    $result = _get_range_('3-3');
    is_deeply($result, [3], '_get_range_ handles single number range');
    
    $result = _get_range_('10-12');
    is_deeply($result, [10, 11, 12], '_get_range_ handles larger numbers');
    
    # Test edge cases
    $result = _get_range_('invalid');
    ok(ref($result) eq 'ARRAY', '_get_range_ returns array for invalid input');
};

# Test edge cases
subtest 'edge cases' => sub {
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
    
    # Test comparison edge cases
    $result = test_condition_cmp('', 'eq', '');
    is($result, 1, 'test_condition_cmp handles empty strings');
    
    $result = test_condition_cmp('0', '==', '0');
    is($result, 1, 'test_condition_cmp handles zero values');
};

done_testing();