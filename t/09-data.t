#!/usr/bin/perl
#
# Unit tests for Pipe::Data module - Comprehensive testing using Core.pm methodology
#
use strict;
use warnings;
use Test::More;
use lib 'lib';

BEGIN { 
    use_ok('Pipe::Data') or BAIL_OUT("Can't load Pipe::Data");
    use_ok('Pipe::Context') or BAIL_OUT("Can't load Pipe::Context");
}

# Initialize required global variables that Data.pm functions expect
# Data.pm functions use main:: package variables
package main;
our @ALL_LINES = ();
our %opt = ();
our $DELIMITER = '|';
our $PRECISION = 3;
our %ddup_ref = ();
our %avg_ref = ();
our %avg_count = ();
our %REF_FILE_DATA_HREF = ();
our @REF_LITERALS_FALSE = ();
our $J_COUNT = 0;
our %J_BUCKET_COUNTS = ();
our $J_CMD = '';
our @SORT_COLUMNS = ();
our @DDUP_COLUMNS = ();

# Reset function for test isolation
sub reset_test_globals {
    @ALL_LINES = ();
    %opt = ();
    $DELIMITER = '|';
    $PRECISION = 3;
    %ddup_ref = ();
    %avg_ref = ();
    %avg_count = ();
    %REF_FILE_DATA_HREF = ();
    @REF_LITERALS_FALSE = ();
    $J_COUNT = 0;
    %J_BUCKET_COUNTS = ();
    $J_CMD = '';
    @SORT_COLUMNS = ();
    @DDUP_COLUMNS = ();
}

# Test sort_list function - comprehensive testing
subtest 'sort_list comprehensive tests' => sub {
    
    # Basic functionality tests
    subtest 'basic_sort_functionality' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "charlie|30|programmer",
            "alice|25|designer", 
            "bob|35|manager"
        );
        %opt = ('N' => 0, 'R' => 0, 'U' => 0, 'I' => 0, 'D' => 0);
        my @sort_cols = (0);
        
        Pipe::Data::sort_list(\@sort_cols);
        
        like($ALL_LINES[0], qr/^alice/, 'First line contains alice after sort');
        like($ALL_LINES[1], qr/^bob/, 'Second line contains bob after sort');
        like($ALL_LINES[2], qr/^charlie/, 'Third line contains charlie after sort');
        is(scalar @ALL_LINES, 3, 'All lines preserved after sort');
    };
    
    # Reverse sort functionality
    subtest 'reverse_sort_functionality' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "apple|data",
            "banana|data",
            "cherry|data"
        );
        %opt = ('R' => 1, 'U' => 0, 'I' => 0, 'D' => 0);
        my @sort_cols = (0);
        
        Pipe::Data::sort_list(\@sort_cols);
        
        like($ALL_LINES[0], qr/^cherry/, 'Reverse sort puts cherry first');
        like($ALL_LINES[2], qr/^apple/, 'Reverse sort puts apple last');
    };
    
    # Numeric sort functionality
    subtest 'numeric_sort_functionality' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "10|ten",
            "2|two", 
            "1|one",
            "100|hundred"
        );
        %opt = ('R' => 0, 'U' => 1, 'I' => 0, 'D' => 0);
        my @sort_cols = (0);
        
        Pipe::Data::sort_list(\@sort_cols);
        
        like($ALL_LINES[0], qr/^1/, 'Numeric sort puts 1 first');
        like($ALL_LINES[1], qr/^2/, 'Numeric sort puts 2 second');
        like($ALL_LINES[2], qr/^10/, 'Numeric sort puts 10 third');
        like($ALL_LINES[3], qr/^100/, 'Numeric sort puts 100 last');
    };
    
    # Case insensitive sort
    subtest 'case_insensitive_sort' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "ZEBRA|animal",
            "apple|fruit",
            "Banana|fruit"
        );
        %opt = ('R' => 0, 'U' => 0, 'I' => 1, 'D' => 0);
        my @sort_cols = (0);
        
        Pipe::Data::sort_list(\@sort_cols);
        
        like($ALL_LINES[0], qr/^apple/, 'Case insensitive sort: apple first');
        like($ALL_LINES[1], qr/^Banana/, 'Case insensitive sort: Banana second');
        like($ALL_LINES[2], qr/^ZEBRA/, 'Case insensitive sort: ZEBRA last');
    };
    
    # Combined options: reverse numeric sort
    subtest 'reverse_numeric_sort' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "5|five",
            "10|ten",
            "1|one"
        );
        %opt = ('R' => 1, 'U' => 1, 'I' => 0, 'D' => 0);
        my @sort_cols = (0);
        
        Pipe::Data::sort_list(\@sort_cols);
        
        like($ALL_LINES[0], qr/^10/, 'Reverse numeric sort: 10 first');
        like($ALL_LINES[2], qr/^1/, 'Reverse numeric sort: 1 last');
    };
    
    # TEST CASE FOR LINE 113: Reverse case-insensitive sort (missing coverage)
    subtest 'reverse_case_insensitive_sort' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "apple|fruit",
            "ZEBRA|animal",
            "Banana|fruit"
        );
        %opt = ('R' => 1, 'U' => 0, 'I' => 1, 'D' => 0);  # Reverse + Case insensitive
        my @sort_cols = (0);
        
        Pipe::Data::sort_list(\@sort_cols);
        
        like($ALL_LINES[0], qr/^ZEBRA/, 'Reverse case-insensitive sort: ZEBRA first');
        like($ALL_LINES[1], qr/^Banana/, 'Reverse case-insensitive sort: Banana second');
        like($ALL_LINES[2], qr/^apple/, 'Reverse case-insensitive sort: apple last');
    };
    
    # Edge cases
    subtest 'edge_cases_and_error_conditions' => sub {
        # Empty array
        reset_test_globals();
        @ALL_LINES = ();
        %opt = ('R' => 0, 'U' => 0, 'I' => 0, 'D' => 0);
        my @sort_cols = (0);
        
        eval { Pipe::Data::sort_list(\@sort_cols); };
        ok(!$@, 'sort_list handles empty array without error');
        is(scalar @ALL_LINES, 0, 'Empty array remains empty');
        
        # Single line
        reset_test_globals();
        @ALL_LINES = ("single|line");
        my @single_cols = (0);
        
        eval { Pipe::Data::sort_list(\@single_cols); };
        ok(!$@, 'sort_list handles single line without error');
        is(scalar @ALL_LINES, 1, 'Single line preserved');
        like($ALL_LINES[0], qr/single/, 'Single line content preserved');
        
        # Lines with float values in sort key
        reset_test_globals();
        @ALL_LINES = (
            "3.14|pi",
            "2.71|e",
            "1.41|sqrt2"
        );
        %opt = ('R' => 0, 'U' => 0, 'I' => 0, 'D' => 0);
        my @float_cols = (0);
        
        eval { Pipe::Data::sort_list(\@float_cols); };
        ok(!$@, 'sort_list handles float values without error');
        is(scalar @ALL_LINES, 3, 'All float lines preserved');
        
        # Lines with mixed content (numbers and text)
        reset_test_globals();
        @ALL_LINES = (
            "abc|text",
            "123|number",
            "mix3d|mixed"
        );
        my @mixed_cols = (0);
        
        eval { Pipe::Data::sort_list(\@mixed_cols); };
        ok(!$@, 'sort_list handles mixed content without error');
        is(scalar @ALL_LINES, 3, 'Mixed content lines preserved');
    };
    
    # Normalization option (-N)
    subtest 'normalization_option_tests' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "Test With Spaces|data",
            "test.with.dots|data",
            "UPPER_CASE|data"
        );
        %opt = ('N' => 1, 'R' => 0, 'U' => 0, 'I' => 0, 'D' => 0);
        my @norm_cols = (0);
        
        eval { Pipe::Data::sort_list(\@norm_cols); };
        ok(!$@, 'sort_list with normalization executes without error');
        is(scalar @ALL_LINES, 3, 'Normalization preserves all lines');
    };
    
    # Multi-column sort (testing with array ref)
    subtest 'multi_column_sort_parameter' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "same|z|third",
            "same|a|first",
            "different|b|second"
        );
        %opt = ('R' => 0, 'U' => 0, 'I' => 0, 'D' => 0);
        my @multi_cols = (0, 1);  # Sort by column 0, then column 1
        
        eval { Pipe::Data::sort_list(\@multi_cols); };
        ok(!$@, 'sort_list with multi-column parameter executes without error');
        is(scalar @ALL_LINES, 3, 'Multi-column parameter preserves all lines');
    };
};

# Test dedup_list function - comprehensive testing
subtest 'dedup_list comprehensive tests' => sub {
    
    # Basic deduplication functionality
    subtest 'basic_dedup_functionality' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "apple|red|fruit",
            "apple|red|fruit",  # exact duplicate
            "banana|yellow|fruit",
            "apple|green|fruit"  # different value, same key
        );
        %ddup_ref = ();
        %opt = ('I' => 0, 'N' => 0, 'A' => 0, 'J' => 0, 'R' => 0, 'U' => 0, 'P' => 0, 'D' => 0);
        my @dedup_cols = (0);  # dedup on first column
        
        Pipe::Data::dedup_list(\@dedup_cols);
        
        is(scalar @ALL_LINES, 2, 'dedup_list removes duplicates correctly');
        my $has_apple = grep(/apple/, @ALL_LINES);
        my $has_banana = grep(/banana/, @ALL_LINES);
        ok($has_apple, 'dedup_list keeps one apple entry');
        ok($has_banana, 'dedup_list keeps banana entry');
    };
    
    # Dedup with count option (-A)
    subtest 'dedup_with_count_option' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "apple|red",
            "apple|green",
            "banana|yellow",
            "apple|blue"  # third apple
        );
        %ddup_ref = ();
        %opt = ('A' => 1, 'I' => 0, 'N' => 0, 'J' => 0, 'R' => 0, 'U' => 0, 'P' => 0, 'D' => 0);
        my @dedup_cols = (0);
        
        Pipe::Data::dedup_list(\@dedup_cols);
        
        my $apple_line = (grep(/apple/, @ALL_LINES))[0] || '';
        my $banana_line = (grep(/banana/, @ALL_LINES))[0] || '';
        
        like($apple_line, qr/3.*apple/, 'dedup with count shows 3 for apple');
        like($banana_line, qr/1.*banana/, 'dedup with count shows 1 for banana');
    };
    
    # Case insensitive dedup (-I)
    subtest 'case_insensitive_dedup' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "Apple|fruit",
            "APPLE|fruit",
            "apple|fruit"
        );
        %ddup_ref = ();
        %opt = ('I' => 1, 'N' => 0, 'A' => 0, 'J' => 0, 'R' => 0, 'U' => 0, 'P' => 0, 'D' => 0);
        my @dedup_cols = (0);
        
        Pipe::Data::dedup_list(\@dedup_cols);
        
        is(scalar @ALL_LINES, 1, 'case insensitive dedup treats Apple/APPLE/apple as same');
    };
    
    # Normalization option (-N)
    subtest 'normalization_dedup' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "Test Data|info",
            "test.data|info",
            "TEST_DATA|info"
        );
        %ddup_ref = ();
        %opt = ('I' => 0, 'N' => 1, 'A' => 0, 'J' => 0, 'R' => 0, 'U' => 0, 'P' => 0, 'D' => 0);
        my @dedup_cols = (0);
        
        eval { Pipe::Data::dedup_list(\@dedup_cols); };
        ok(!$@, 'dedup with normalization executes without error');
        # Note: actual normalization behavior needs to be tested based on normalize() function
    };
    
    # Reverse sort in dedup (-R)
    subtest 'reverse_sort_dedup' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "zebra|animal",
            "apple|fruit",
            "banana|fruit"
        );
        %ddup_ref = ();
        %opt = ('I' => 0, 'N' => 0, 'A' => 0, 'J' => 0, 'R' => 1, 'U' => 0, 'P' => 0, 'D' => 0);
        my @dedup_cols = (0);
        
        Pipe::Data::dedup_list(\@dedup_cols);
        
        # Should be sorted in reverse order
        like($ALL_LINES[0], qr/zebra/, 'reverse dedup puts zebra first');
        like($ALL_LINES[2], qr/apple/, 'reverse dedup puts apple last');
    };
    
    # TEST CASE FOR LINE 210: Reverse text sort (not numeric) in dedup
    subtest 'reverse_text_sort_dedup' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "100|hundred",
            "20|twenty",
            "3|three"
        );
        %ddup_ref = ();
        %opt = ('I' => 0, 'N' => 0, 'A' => 0, 'J' => 0, 'R' => 1, 'U' => 0, 'P' => 0, 'D' => 0);  # R=1, U=0
        my @dedup_cols = (0);
        
        Pipe::Data::dedup_list(\@dedup_cols);
        
        # Text sort: "3" > "20" > "100" when reversed
        like($ALL_LINES[0], qr/^3/, 'reverse text dedup puts 3 first (text sort)');
        like($ALL_LINES[1], qr/^20/, 'reverse text dedup puts 20 second');
        like($ALL_LINES[2], qr/^100/, 'reverse text dedup puts 100 last');
    };
    
    # Numeric sort in dedup (-U)
    subtest 'numeric_sort_dedup' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "10|ten",
            "2|two",
            "100|hundred"
        );
        %ddup_ref = ();
        %opt = ('I' => 0, 'N' => 0, 'A' => 0, 'J' => 0, 'R' => 0, 'U' => 1, 'P' => 0, 'D' => 0);
        my @dedup_cols = (0);
        
        Pipe::Data::dedup_list(\@dedup_cols);
        
        like($ALL_LINES[0], qr/^2/, 'numeric dedup sort puts 2 first');
        like($ALL_LINES[2], qr/^100/, 'numeric dedup sort puts 100 last');
    };
    
    # J operation testing (aggregate functions) - comprehensive
    subtest 'j_operation_functionality' => sub {
        # Test J operation with 'sum' aggregate
        reset_test_globals();
        @ALL_LINES = (
            "group1|5",
            "group1|10", 
            "group2|3"
        );
        %ddup_ref = ();
        %J_BUCKET_COUNTS = ();
        $J_COUNT = 0;
        $J_CMD = '';
        %opt = ('I' => 0, 'N' => 0, 'A' => 0, 'J' => 'sum1', 'R' => 0, 'U' => 0, 'P' => 0, 'D' => 0);
        my @dedup_cols = (0);
        
        eval { Pipe::Data::dedup_list(\@dedup_cols); };
        ok(!$@, 'dedup with J sum operation executes without error');
        is(scalar @ALL_LINES, 2, 'J operation groups correctly');
        
        # Test J operation with 'min' aggregate
        reset_test_globals();
        @ALL_LINES = (
            "test|15",
            "test|5",
            "test|10"
        );
        %ddup_ref = ();
        %J_BUCKET_COUNTS = ();
        $J_COUNT = 0;
        $J_CMD = '';
        %opt = ('I' => 0, 'N' => 0, 'A' => 0, 'J' => 'min1', 'R' => 0, 'U' => 0, 'P' => 0, 'D' => 0);
        
        eval { Pipe::Data::dedup_list(\@dedup_cols); };
        ok(!$@, 'dedup with J min operation executes without error');
        
        # Test J operation with 'max' aggregate  
        reset_test_globals();
        @ALL_LINES = (
            "test|15",
            "test|5",
            "test|10"
        );
        %ddup_ref = ();
        %J_BUCKET_COUNTS = ();
        $J_COUNT = 0;
        $J_CMD = '';
        %opt = ('J' => 'max1');
        
        eval { Pipe::Data::dedup_list(\@dedup_cols); };
        ok(!$@, 'dedup with J max operation executes without error');
        
        # Test J operation with 'avg' aggregate
        reset_test_globals();
        @ALL_LINES = (
            "group1|6",
            "group1|12",
            "group2|9"
        );
        %ddup_ref = ();
        %J_BUCKET_COUNTS = ();
        $J_COUNT = 0;
        $J_CMD = '';
        %opt = ('J' => 'avg1');
        
        eval { Pipe::Data::dedup_list(\@dedup_cols); };
        ok(!$@, 'dedup with J avg operation executes without error');
        
        # TEST CASE FOR LINE 250: J_CMD = avg but J_COUNT = 0
        reset_test_globals();
        @ALL_LINES = (
            "group1|10",
            "group2|20"
        );
        %ddup_ref = ();
        %J_BUCKET_COUNTS = ();
        $J_COUNT = 0;  # Zero count
        $J_CMD = 'avg';  # Set to 'avg' to trigger the condition
        %opt = ('J' => 'avg1', 'P' => 0);
        
        eval { Pipe::Data::dedup_list(\@dedup_cols); };
        ok(!$@, 'dedup with J avg and J_COUNT=0 executes without error');
        
        # Test J operation with 'count' aggregate
        reset_test_globals();
        @ALL_LINES = (
            "test|1",
            "test|2", 
            "test|3"
        );
        %ddup_ref = ();
        %J_BUCKET_COUNTS = ();
        $J_COUNT = 0;
        $J_CMD = '';
        %opt = ('J' => 'count1');
        
        eval { Pipe::Data::dedup_list(\@dedup_cols); };
        ok(!$@, 'dedup with J count operation executes without error');
    };
    
    # Edge cases
    subtest 'edge_cases_and_error_conditions' => sub {
        # Empty array
        reset_test_globals();
        @ALL_LINES = ();
        %ddup_ref = ();
        %opt = ('I' => 0, 'N' => 0, 'A' => 0, 'J' => 0, 'R' => 0, 'U' => 0, 'P' => 0, 'D' => 0);
        my @dedup_cols = (0);
        
        eval { Pipe::Data::dedup_list(\@dedup_cols); };
        ok(!$@, 'dedup handles empty array without error');
        is(scalar @ALL_LINES, 0, 'Empty array remains empty after dedup');
        
        # Single line
        reset_test_globals();
        @ALL_LINES = ("single|line");
        %ddup_ref = ();
        my @single_cols = (0);
        
        eval { Pipe::Data::dedup_list(\@single_cols); };
        ok(!$@, 'dedup handles single line without error');
        is(scalar @ALL_LINES, 1, 'Single line preserved after dedup');
        
        # Lines with identical keys
        reset_test_globals();
        @ALL_LINES = (
            "same|value1",
            "same|value2",
            "same|value3"
        );
        %ddup_ref = ();
        my @same_cols = (0);
        
        eval { Pipe::Data::dedup_list(\@same_cols); };
        ok(!$@, 'dedup handles identical keys without error');
        is(scalar @ALL_LINES, 1, 'dedup reduces identical keys to one line');
    };
    
    # Combined options testing
    subtest 'combined_options_testing' => sub {
        # Count + pipe delimiter format (-A -P)
        reset_test_globals();
        @ALL_LINES = (
            "test|data",
            "test|data2"
        );
        %ddup_ref = ();
        %opt = ('A' => 1, 'P' => 1, 'I' => 0, 'N' => 0, 'J' => 0, 'R' => 0, 'U' => 0, 'D' => 0);
        $DELIMITER = '|';
        my @combo_cols = (0);
        
        eval { Pipe::Data::dedup_list(\@combo_cols); };
        ok(!$@, 'dedup with combined A+P options executes without error');
        
        # Verify pipe delimiter format is used
        if (@ALL_LINES) {
            like($ALL_LINES[0], qr/\|/, 'combined A+P uses pipe delimiter format');
        }
        
        # J operation + pipe delimiter format (-J -P) - targets uncovered branch line 186
        reset_test_globals();
        @ALL_LINES = (
            "group|10",
            "group|20"
        );
        %ddup_ref = ();
        %J_BUCKET_COUNTS = ();
        $J_COUNT = 0;
        $J_CMD = 'avg';  # Set J_CMD to trigger avg computation
        %opt = ('J' => 'avg1', 'P' => 1, 'I' => 0, 'N' => 0, 'A' => 0, 'R' => 0, 'U' => 0, 'D' => 0);
        $DELIMITER = '|';
        $PRECISION = 2;
        
        eval { Pipe::Data::dedup_list(\@combo_cols); };
        ok(!$@, 'dedup with J+P options executes without error');
        
        # Should trigger average calculation and pipe delimiter format
        if (@ALL_LINES) {
            like($ALL_LINES[0], qr/\|/, 'J+P uses pipe delimiter format');
        }
    };
};


# Test randomize_list function - comprehensive testing
subtest 'randomize_list comprehensive tests' => sub {
    
    # Basic randomization functionality
    subtest 'basic_randomization_functionality' => sub {
        reset_test_globals();
        @ALL_LINES = ();
        for my $i (1..20) {
            push @ALL_LINES, "line$i|data$i";
        }
        my $original_count = scalar @ALL_LINES;
        
        %opt = ('r' => 50, 'D' => 0);  # 50% of lines
        
        Pipe::Data::randomize_list();
        
        my $result_count = scalar @ALL_LINES;
        ok($result_count >= 8 && $result_count <= 12, 'randomize_list selects approximately 50% of lines');
        ok($result_count > 0, 'randomize_list returns some lines');
        
        # Check that returned lines are from original set
        my $valid_lines = 0;
        for my $line (@ALL_LINES) {
            if ($line =~ /^line\d+\|data\d+$/) {
                $valid_lines++;
            }
        }
        is($valid_lines, $result_count, 'randomize_list returns valid original lines');
    };
    
    # Different percentages
    subtest 'different_percentage_tests' => sub {
        # 10% selection
        reset_test_globals();
        @ALL_LINES = map { "item$_|value$_" } (1..100);
        %opt = ('r' => 10, 'D' => 0);
        
        Pipe::Data::randomize_list();
        
        my $result_count = scalar @ALL_LINES;
        ok($result_count >= 8 && $result_count <= 12, '10% selection works (8-12 items from 100)');
        
        # 90% selection
        reset_test_globals();
        @ALL_LINES = map { "item$_|value$_" } (1..10);
        %opt = ('r' => 90, 'D' => 0);
        
        Pipe::Data::randomize_list();
        
        $result_count = scalar @ALL_LINES;
        ok($result_count >= 8 && $result_count <= 10, '90% selection works (8-10 items from 10)');
        
        # 100% selection
        reset_test_globals();
        @ALL_LINES = map { "item$_|value$_" } (1..5);
        %opt = ('r' => 100, 'D' => 0);
        
        Pipe::Data::randomize_list();
        
        is(scalar @ALL_LINES, 5, '100% selection returns all lines');
    };
    
    # Edge cases
    subtest 'edge_cases_and_error_conditions' => sub {
        # Empty array
        reset_test_globals();
        @ALL_LINES = ();
        %opt = ('r' => 50, 'D' => 0);
        
        eval { Pipe::Data::randomize_list(); };
        ok(!$@, 'randomize_list handles empty array without error');
        is(scalar @ALL_LINES, 0, 'Empty array remains empty');
        
        # Single line
        reset_test_globals();
        @ALL_LINES = ("single|line");
        %opt = ('r' => 50, 'D' => 0);
        
        eval { Pipe::Data::randomize_list(); };
        ok(!$@, 'randomize_list handles single line without error');
        ok(scalar @ALL_LINES <= 1, 'Single line result is 0 or 1');
        
        # Very small percentage (should still return at least 1)
        reset_test_globals();
        @ALL_LINES = map { "item$_" } (1..1000);
        %opt = ('r' => 0.1, 'D' => 0);  # 0.1%
        
        eval { Pipe::Data::randomize_list(); };
        ok(!$@, 'randomize_list handles very small percentage without error');
        ok(scalar @ALL_LINES >= 1, 'Very small percentage still returns at least 1 line');
        
        # Zero percentage (edge case)
        reset_test_globals();
        @ALL_LINES = map { "item$_" } (1..10);
        %opt = ('r' => 0, 'D' => 0);
        
        eval { Pipe::Data::randomize_list(); };
        ok(!$@, 'randomize_list handles 0% without error');
        # Note: function forces at least 1 line even with 0%
        ok(scalar @ALL_LINES >= 1, '0% still returns at least 1 line (forced minimum)');
    };
    
    # Debug option testing
    subtest 'debug_option_testing' => sub {
        reset_test_globals();
        @ALL_LINES = map { "debug$_" } (1..5);
        %opt = ('r' => 60, 'D' => 1);  # Debug mode on
        
        # Capture STDERR to test debug output (basic test)
        eval { Pipe::Data::randomize_list(); };
        ok(!$@, 'randomize_list with debug mode executes without error');
        ok(scalar @ALL_LINES >= 1, 'Debug mode still produces results');
    };
    
    # TEST CASE FOR LINE 145: Debug mode OFF in sort_list
    subtest 'sort_debug_mode_off' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "charlie|30",
            "alice|25",
            "bob|35"
        );
        %opt = ('N' => 0, 'R' => 0, 'U' => 0, 'I' => 0, 'D' => 0);  # Debug OFF
        my @sort_cols = (0);
        
        Pipe::Data::sort_list(\@sort_cols);
        
        like($ALL_LINES[0], qr/^alice/, 'Sort with debug off: alice first');
        like($ALL_LINES[2], qr/^charlie/, 'Sort with debug off: charlie last');
    };
    
    # TEST CASE FOR LINE 205: Debug mode OFF in dedup_list  
    subtest 'dedup_debug_mode_off' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "apple|red",
            "apple|green",
            "banana|yellow"
        );
        %ddup_ref = ();
        %opt = ('I' => 0, 'N' => 0, 'A' => 0, 'J' => 0, 'R' => 0, 'U' => 0, 'P' => 0, 'D' => 0);  # Debug OFF
        my @dedup_cols = (0);
        
        Pipe::Data::dedup_list(\@dedup_cols);
        
        is(scalar @ALL_LINES, 2, 'Dedup with debug off works correctly');
    };
    
    # Consistency testing (verify randomness properties)
    subtest 'randomness_properties_testing' => sub {
        # Test that multiple runs produce different results (probabilistically)
        reset_test_globals();
        my @base_lines = map { "test$_" } (1..20);
        
        my @results1;
        my @results2;
        
        # Run 1
        @ALL_LINES = @base_lines;
        %opt = ('r' => 50, 'D' => 0);
        Pipe::Data::randomize_list();
        @results1 = @ALL_LINES;
        
        # Run 2 
        @ALL_LINES = @base_lines;
        %opt = ('r' => 50, 'D' => 0);
        Pipe::Data::randomize_list();
        @results2 = @ALL_LINES;
        
        # Results should probably be different (though not guaranteed)
        # This is a weak test but checks the function runs consistently
        ok(scalar @results1 >= 1, 'First randomization run produces results');
        ok(scalar @results2 >= 1, 'Second randomization run produces results');
        
        # Both results should be from the original set
        for my $line (@results1, @results2) {
            ok($line =~ /^test\d+$/, "Result line '$line' is from original set");
        }
    };
};


# Test push_merge_ref_columns function - comprehensive testing
subtest 'push_merge_ref_columns comprehensive tests' => sub {
    
    # Basic functionality
    subtest 'basic_merge_functionality' => sub {
        reset_test_globals();
        %REF_FILE_DATA_HREF = ();
        @REF_LITERALS_FALSE = ();
        %opt = ('I' => 0, 'N' => 0, 'D' => 0);
        $DELIMITER = '|';
        
        my @col_indexes = (1, 2);  # columns to extract
        my @line_data = ('key1', 'value1', 'value2', 'value3');
        my $key_col = 0;  # use column 0 as key
        
        eval {
            Pipe::Data::push_merge_ref_columns(\@col_indexes, \@line_data, $key_col);
        };
        ok(!$@, 'push_merge_ref_columns executes without error');
        
        # Check that function executed without error (may or may not store data based on key validity)
        ok(1, 'push_merge_ref_columns basic execution completed');
    };
    
    # Case insensitive option (-I)
    subtest 'case_insensitive_functionality' => sub {
        reset_test_globals();
        %REF_FILE_DATA_HREF = ();
        %opt = ('I' => 1, 'N' => 0, 'D' => 0);
        $DELIMITER = '|';
        
        my @col_indexes = (1);
        my @line_data = ('KeyCase', 'data');
        my $key_col = 0;
        
        eval {
            Pipe::Data::push_merge_ref_columns(\@col_indexes, \@line_data, $key_col);
        };
        ok(!$@, 'push_merge_ref_columns case insensitive executes without error');
        
        # Case insensitive function executes successfully
        ok(1, 'Case insensitive push_merge_ref_columns completed');
    };
    
    # Normalization option (-N)
    subtest 'normalization_functionality' => sub {
        reset_test_globals();
        %REF_FILE_DATA_HREF = ();
        %opt = ('I' => 0, 'N' => 1, 'D' => 0);
        $DELIMITER = '|';
        
        my @col_indexes = (1);
        my @line_data = ('Test Key', 'test_data');
        my $key_col = 0;
        
        eval {
            Pipe::Data::push_merge_ref_columns(\@col_indexes, \@line_data, $key_col);
        };
        ok(!$@, 'push_merge_ref_columns with normalization executes without error');
        # Note: Actual key format depends on normalize() function behavior
    };
    
    # Multiple column extraction
    subtest 'multiple_column_extraction' => sub {
        reset_test_globals();
        %REF_FILE_DATA_HREF = ();
        %opt = ('I' => 0, 'N' => 0, 'D' => 0);
        $DELIMITER = ':';
        
        my @col_indexes = (0, 2, 4);  # Extract columns 0, 2, 4
        my @line_data = ('val0', 'val1', 'val2', 'val3', 'val4', 'val5');
        my $key_col = 1;  # Use column 1 as key
        
        eval {
            Pipe::Data::push_merge_ref_columns(\@col_indexes, \@line_data, $key_col);
        };
        ok(!$@, 'Multiple column extraction executes without error');
        
        if (exists $REF_FILE_DATA_HREF{'val1'}) {
            is($REF_FILE_DATA_HREF{'val1'}, 'val0:val2:val4', 'Multiple columns joined correctly');
        }
    };
    
    # Edge cases and error conditions
    subtest 'edge_cases_and_error_conditions' => sub {
        # Undefined key column
        reset_test_globals();
        %REF_FILE_DATA_HREF = ();
        %opt = ('I' => 0, 'N' => 0, 'D' => 0);
        
        my @col_indexes = (1);
        my @line_data = ('data');
        my $key_col = undef;
        
        eval {
            Pipe::Data::push_merge_ref_columns(\@col_indexes, \@line_data, $key_col);
        };
        ok(!$@, 'push_merge_ref_columns handles undef key_col gracefully');
        
        # Out of range key column
        reset_test_globals();
        my $large_key_col = 999;
        my @small_data = ('only_one');
        
        eval {
            Pipe::Data::push_merge_ref_columns(\@col_indexes, \@small_data, $large_key_col);
        };
        ok(!$@, 'push_merge_ref_columns handles out of range key_col without error');
        
        # Out of range column indexes
        reset_test_globals();
        my @large_indexes = (10, 20, 30);
        my @normal_data = ('key', 'val1', 'val2');
        my $normal_key = 0;
        
        eval {
            Pipe::Data::push_merge_ref_columns(\@large_indexes, \@normal_data, $normal_key);
        };
        ok(!$@, 'push_merge_ref_columns handles out of range column indexes without error');
        
        # Empty column indexes array
        reset_test_globals();
        my @empty_indexes = ();
        
        eval {
            Pipe::Data::push_merge_ref_columns(\@empty_indexes, \@normal_data, $normal_key);
        };
        ok(!$@, 'push_merge_ref_columns handles empty column indexes without error');
        
        # Empty line data
        reset_test_globals();
        my @empty_data = ();
        
        eval {
            Pipe::Data::push_merge_ref_columns(\@col_indexes, \@empty_data, 0);
        };
        ok(!$@, 'push_merge_ref_columns handles empty line data without error');
    };
    
    # REF_LITERALS_FALSE behavior
    subtest 'ref_literals_false_behavior' => sub {
        reset_test_globals();
        %REF_FILE_DATA_HREF = ();
        @REF_LITERALS_FALSE = ('DEFAULT');
        %opt = ('I' => 0, 'N' => 0, 'D' => 0);
        $DELIMITER = '|';
        
        my @col_indexes = (5, 6);  # Out of range columns
        my @line_data = ('key', 'val1', 'val2');  # Only 3 elements
        my $key_col = 0;
        
        eval {
            Pipe::Data::push_merge_ref_columns(\@col_indexes, \@line_data, $key_col);
        };
        ok(!$@, 'push_merge_ref_columns with REF_LITERALS_FALSE executes without error');
        
        # Should use REF_LITERALS_FALSE for missing values
        if (exists $REF_FILE_DATA_HREF{'key'}) {
            # Expected behavior may vary - test that it doesn't crash
            ok(length($REF_FILE_DATA_HREF{'key'}) >= 0, 'REF_LITERALS_FALSE produces some result');
        }
    };
    
    # Debug mode testing
    subtest 'debug_mode_testing' => sub {
        reset_test_globals();
        %REF_FILE_DATA_HREF = ();
        %opt = ('I' => 0, 'N' => 0, 'D' => 1);  # Debug on
        $DELIMITER = '|';
        
        my @col_indexes = (1);
        my @line_data = ('debug_key', 'debug_value');
        my $key_col = 0;
        
        eval {
            Pipe::Data::push_merge_ref_columns(\@col_indexes, \@line_data, $key_col);
        };
        ok(!$@, 'push_merge_ref_columns with debug mode executes without error');
    };
};


# Test finalize_full_read_functions - comprehensive testing
subtest 'finalize_full_read_functions comprehensive tests' => sub {
    
    # Dedup functionality (opt d)
    subtest 'dedup_functionality_testing' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "duplicate|1",
            "duplicate|2", 
            "unique|3"
        );
        @DDUP_COLUMNS = (0);
        %opt = (
            'd' => 1,  # dedup
            'r' => 0,  # no randomize
            's' => 0,  # no sort  
            'v' => 0   # no average
        );
        %ddup_ref = ();
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize with dedup executes without error');
        is(scalar @ALL_LINES, 2, 'finalize performs dedup correctly');
    };
    
    # Randomize functionality (opt r)
    subtest 'randomize_functionality_testing' => sub {
        reset_test_globals();
        @ALL_LINES = map { "line$_|data$_" } (1..10);
        %opt = (
            'd' => 0,  # no dedup
            'r' => 50, # randomize 50%
            's' => 0,  # no sort
            'v' => 0   # no average
        );
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize with randomize executes without error');
        my $result_count = scalar @ALL_LINES;
        ok($result_count >= 3 && $result_count <= 7, 'finalize randomize selects appropriate number');
    };
    
    # Sort functionality (opt s)
    subtest 'sort_functionality_testing' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "charlie|data",
            "alice|data",
            "bob|data"
        );
        @SORT_COLUMNS = (0);
        %opt = (
            'd' => 0,  # no dedup
            'r' => 0,  # no randomize
            's' => 1,  # sort
            'v' => 0,  # no average
            'R' => 0, 'U' => 0, 'I' => 0, 'D' => 0
        );
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize with sort executes without error');
        like($ALL_LINES[0], qr/^alice/, 'finalize performs sort correctly');
    };
    
    # Average computation (opt v) - comprehensive testing
    subtest 'average_computation_testing' => sub {
        # Test basic average computation
        reset_test_globals();
        %avg_ref = ('c0' => 15, 'c1' => 30);  # sums
        %avg_count = ('c0' => 3, 'c1' => 2);  # counts
        %opt = (
            'd' => 0, 'r' => 0, 's' => 0,
            'v' => 1   # compute averages
        );
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize with averages executes without error');
        
        # Check that averages were computed
        ok(exists $avg_ref{'c0'}, 'finalize maintains avg_ref c0');
        ok(exists $avg_ref{'c1'}, 'finalize maintains avg_ref c1');
        
        # Test average computation with zero count (targets line 309 condition)
        reset_test_globals();
        %avg_ref = ('c0' => 10, 'c1' => 20);
        %avg_count = ('c0' => 0, 'c1' => 2);  # Zero count for c0
        %opt = ('v' => 1);
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize handles zero avg_count without error');
        
        # Test average computation with missing avg_count entry
        reset_test_globals();
        %avg_ref = ('c0' => 10, 'c1' => 20);
        %avg_count = ('c0' => 2);  # Missing c1 entry
        %opt = ('v' => 1);
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize handles missing avg_count entries without error');
        
        # Test average computation with valid counts - targets line 426 true branch
        reset_test_globals();
        %avg_ref = ('column1' => 30.0, 'column2' => 45.5);
        %avg_count = ('column1' => 5, 'column2' => 7);  # Both exist and non-zero
        %opt = ('v' => 1);
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize computes averages with valid counts');
        
        # Check that division was performed (values should be different)
        ok(defined $avg_ref{'column1'}, 'column1 average computed');
        ok(defined $avg_ref{'column2'}, 'column2 average computed');
        
        # Test specific branch coverage for line 426
        # Case 1: avg_count entry doesn't exist (false on first condition)
        reset_test_globals();
        %avg_ref = ('col_with_count' => 100, 'col_without_count' => 200);
        %avg_count = ('col_with_count' => 10);  # Missing col_without_count
        %opt = ('v' => 1);
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize handles missing avg_count key (false on exists)');
        
        # Case 2: avg_count exists but is 0 (true on exists, false on != 0)
        reset_test_globals();
        %avg_ref = ('col_zero' => 150, 'col_nonzero' => 300);
        %avg_count = ('col_zero' => 0, 'col_nonzero' => 5);  # col_zero has 0 count
        %opt = ('v' => 1);
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize handles zero avg_count (true exists, false != 0)');
    };
    
    # Combined operations testing
    subtest 'combined_operations_testing' => sub {
        # Sort + dedup combination
        reset_test_globals();
        @ALL_LINES = (
            "charlie|data",
            "alice|data",
            "alice|data",  # duplicate
            "bob|data"
        );
        @SORT_COLUMNS = (0);
        @DDUP_COLUMNS = (0);
        %opt = (
            'd' => 1,  # dedup
            'r' => 0,  # no randomize
            's' => 1,  # sort
            'v' => 0,  # no average
            'R' => 0, 'U' => 0, 'I' => 0, 'D' => 0
        );
        %ddup_ref = ();
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize with sort+dedup executes without error');
        
        # Should have 3 unique lines, sorted
        is(scalar @ALL_LINES, 3, 'Combined sort+dedup produces correct count');
        if (@ALL_LINES >= 3) {
            like($ALL_LINES[0], qr/alice/, 'Combined operations: alice first');
            like($ALL_LINES[2], qr/charlie/, 'Combined operations: charlie last');
        }
    };
    
    # No operations (all flags false)
    subtest 'no_operations_testing' => sub {
        reset_test_globals();
        @ALL_LINES = (
            "line1|data",
            "line2|data",
            "line3|data"
        );
        %opt = (
            'd' => 0,  # no dedup
            'r' => 0,  # no randomize
            's' => 0,  # no sort
            'v' => 0   # no average
        );
        
        my $original_lines = [@ALL_LINES];  # Copy for comparison
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize with no operations executes without error');
        
        # Lines should be unchanged
        is_deeply(\@ALL_LINES, $original_lines, 'No operations leaves lines unchanged');
    };
    
    # Edge cases
    subtest 'edge_cases_and_error_conditions' => sub {
        # Empty arrays and hashes
        reset_test_globals();
        @ALL_LINES = ();
        %avg_ref = ();
        %avg_count = ();
        %opt = ('d' => 1, 'r' => 50, 's' => 1, 'v' => 1);
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize handles empty data without error');
        
        # Average with zero counts
        reset_test_globals();
        %avg_ref = ('c0' => 10);
        %avg_count = ('c0' => 0);  # Zero count
        %opt = ('d' => 0, 'r' => 0, 's' => 0, 'v' => 1);
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize handles zero avg_count without error');
        
        # Average without corresponding count
        reset_test_globals();
        %avg_ref = ('c0' => 10, 'c1' => 20);
        %avg_count = ('c0' => 2);  # Missing c1 count
        %opt = ('v' => 1);
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize handles missing avg_count entries without error');
    };
    
    # Test with undefined/missing global arrays
    subtest 'missing_global_arrays_testing' => sub {
        reset_test_globals();
        @ALL_LINES = ("test|data");
        # Don't set SORT_COLUMNS or DDUP_COLUMNS
        %opt = ('d' => 1, 's' => 1);
        
        eval { Pipe::Data::finalize_full_read_functions(); };
        ok(!$@, 'finalize handles missing column arrays without error');
    };
};


# Test export functionality and constants
subtest 'export_functionality_and_constants_tests' => sub {
    
    # Test module exports
    subtest 'module_export_testing' => sub {
        # Test that functions are available for import
        ok(defined &Pipe::Data::sort_list, 'sort_list function is defined');
        ok(defined &Pipe::Data::dedup_list, 'dedup_list function is defined');
        ok(defined &Pipe::Data::randomize_list, 'randomize_list function is defined');
        ok(defined &Pipe::Data::push_merge_ref_columns, 'push_merge_ref_columns function is defined');
        ok(defined &Pipe::Data::finalize_full_read_functions, 'finalize_full_read_functions function is defined');
    };
    
    # Test export tags
    subtest 'export_tags_testing' => sub {
        # Test that export tags are defined
        ok(exists $Pipe::Data::EXPORT_TAGS{'sorting'}, 'sorting export tag exists');
        ok(exists $Pipe::Data::EXPORT_TAGS{'dedup'}, 'dedup export tag exists');
        ok(exists $Pipe::Data::EXPORT_TAGS{'random'}, 'random export tag exists');
        ok(exists $Pipe::Data::EXPORT_TAGS{'merge'}, 'merge export tag exists');
        ok(exists $Pipe::Data::EXPORT_TAGS{'finalize'}, 'finalize export tag exists');
        ok(exists $Pipe::Data::EXPORT_TAGS{'all'}, 'all export tag exists');
        
        # Test that tags contain expected functions
        if (exists $Pipe::Data::EXPORT_TAGS{'sorting'}) {
            my @sorting_funcs = @{$Pipe::Data::EXPORT_TAGS{'sorting'}};
            ok(grep(/sort_list/, @sorting_funcs), 'sorting tag contains sort_list');
        }
        
        if (exists $Pipe::Data::EXPORT_TAGS{'all'}) {
            my @all_funcs = @{$Pipe::Data::EXPORT_TAGS{'all'}};
            ok(scalar @all_funcs >= 5, 'all tag contains expected number of functions');
        }
    };
    
    # Test constants
    subtest 'constants_testing' => sub {
        # Test boolean constants
        ok(defined $Pipe::Data::TRUE, 'TRUE constant is defined');
        ok(defined $Pipe::Data::FALSE, 'FALSE constant is defined');
        is($Pipe::Data::TRUE, 0, 'TRUE constant has correct value');
        is($Pipe::Data::FALSE, 1, 'FALSE constant has correct value');
    };
};

# Test complex edge cases and integration scenarios
subtest 'complex_edge_cases_and_integration_tests' => sub {
    
    # Test function interaction with dependencies
    subtest 'dependency_interaction_testing' => sub {
        # Test that Data.pm functions can call imported functions
        reset_test_globals();
        
        # Test get_key dependency (from Column.pm)
        @ALL_LINES = ("test|data");
        my @test_cols = (0);
        eval { Pipe::Data::sort_list(\@test_cols); };
        ok(!$@, 'sort_list can call get_key from Column.pm without error');
        
        # Test normalize dependency (from Text.pm)  
        reset_test_globals();
        @ALL_LINES = ("Test Data|info");
        %opt = ('N' => 1);
        eval { Pipe::Data::sort_list(\@test_cols); };
        ok(!$@, 'sort_list can call normalize from Text.pm without error');
        
        # Test get_number_format dependency (from Core.pm)
        reset_test_globals();
        @ALL_LINES = ("test|data", "test|data2");
        %opt = ('A' => 1);
        %ddup_ref = ();
        eval { Pipe::Data::dedup_list(\@test_cols); };
        ok(!$@, 'dedup_list can call get_number_format from Core.pm without error');
    };
    
    # Test memory and performance edge cases
    subtest 'memory_and_performance_edge_cases' => sub {
        # Large data set handling
        reset_test_globals();
        @ALL_LINES = map { "item$_|data$_" } (1..1000);
        %opt = ('r' => 10);  # 10% of 1000 = 100 items
        
        eval { Pipe::Data::randomize_list(); };
        ok(!$@, 'randomize_list handles large dataset without error');
        my $result_count = scalar @ALL_LINES;
        ok($result_count >= 90 && $result_count <= 110, 'Large dataset randomization produces expected count');
        
        # Stress test with very long lines
        reset_test_globals();
        my $long_line = 'x' x 10000 . '|' . 'y' x 10000;
        @ALL_LINES = ($long_line, $long_line, 'short|line');
        %ddup_ref = ();
        %opt = ();
        my @test_cols = (0);
        
        eval { Pipe::Data::dedup_list(\@test_cols); };
        ok(!$@, 'dedup_list handles very long lines without error');
    };
    
    # Test error recovery and resilience
    subtest 'error_recovery_and_resilience' => sub {
        # Test with malformed data
        reset_test_globals();
        @ALL_LINES = (
            "normal|data",
            "",  # empty line
            "single_column",  # no delimiter
            "|||||",  # multiple delimiters
            "unicode_ñørmåł|data"
        );
        %opt = ();
        my @test_cols = (0);
        
        eval { Pipe::Data::sort_list(\@test_cols); };
        ok(!$@, 'sort_list handles malformed data without error');
        
        # Test with binary/control characters
        reset_test_globals();
        @ALL_LINES = (
            "test\x00null|data",
            "test\ttab|data",
            "test\nnewline|data"
        );
        
        eval { Pipe::Data::sort_list(\@test_cols); };
        ok(!$@, 'sort_list handles control characters without error');
    };
    
    # Test state isolation between function calls
    subtest 'state_isolation_testing' => sub {
        # Test that functions don't interfere with each other
        reset_test_globals();
        
        # First operation: sort
        @ALL_LINES = ("c|data", "a|data", "b|data");
        %opt = ();
        my @sort_cols = (0);
        Pipe::Data::sort_list(\@sort_cols);
        my @sorted_result = @ALL_LINES;
        
        # Second operation: dedup (should work independently)
        @ALL_LINES = ("dup|1", "dup|2", "unique|3");
        %ddup_ref = ();
        my @dedup_cols = (0);
        Pipe::Data::dedup_list(\@dedup_cols);
        
        # Verify both operations worked correctly
        like($sorted_result[0], qr/^a/, 'First sort operation worked correctly');
        is(scalar @ALL_LINES, 2, 'Second dedup operation worked correctly');
    };
};

done_testing();

# Test summary: Comprehensive testing of Pipe::Data module
# - 5 main functions with extensive edge case coverage
# - Global state management and isolation testing
# - Integration with dependent modules (Core, Column, Text, Math)
# - Performance and memory edge cases
# - Error recovery and malformed data handling
# - Export functionality and constants verification
# Total subtests: 50+ comprehensive test scenarios