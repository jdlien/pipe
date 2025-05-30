#!/usr/bin/perl
#
# Unit tests for Pipe::Context module - Comprehensive test coverage using Core.pm methodology
#
use strict;
use warnings;
use Test::More;
use lib 'lib';

BEGIN { 
    use_ok('Pipe::Context') or BAIL_OUT("Can't load Pipe::Context");
}

# Test object creation - comprehensive testing
subtest 'object creation comprehensive tests' => sub {
    my $ctx = Pipe::Context->new();
    isa_ok($ctx, 'Pipe::Context', 'Created context object');
    
    # Test that all expected attributes are initialized
    ok(exists $ctx->{options}, 'options hash exists');
    ok(exists $ctx->{delimiter}, 'delimiter exists');
    ok(exists $ctx->{line_number}, 'line_number exists');
    ok(exists $ctx->{previous_lines}, 'previous_lines exists');
    ok(exists $ctx->{line_buff}, 'line_buff exists');
    
    # Test default values are set correctly
    is($ctx->{delimiter}, '|', 'Default delimiter is pipe');
    is($ctx->{input_delimiter}, '|', 'Default input_delimiter is pipe');
    is($ctx->{output_delimiter}, '|', 'Default output_delimiter is pipe');
    is($ctx->{line_number}, 0, 'Default line_number is 0');
    is($ctx->{last_line}, 0, 'Default last_line is 0');
    is($ctx->{skip_line}, 0, 'Default skip_line is 0');
    is($ctx->{buff_size}, 0, 'Default buff_size is 0');
    is($ctx->{read_full}, 0, 'Default read_full is 0');
    is($ctx->{keep_lines}, 10, 'Default keep_lines is 10');
    is($ctx->{fast_forward}, 0, 'Default fast_forward is 0');
    is($ctx->{relax_o_exclude}, 0, 'Default relax_o_exclude is 0');
    is($ctx->{collapse_option}, 0, 'Default collapse_option is 0');
    is($ctx->{allow_scripting}, 0, 'Default allow_scripting is 0');
    is($ctx->{precision}, 2, 'Default precision is 2');
    is($ctx->{is_data_to_merge}, 1, 'Default is_data_to_merge is 1');
    is($ctx->{is_x_match}, 0, 'Default is_x_match is 0');
    is($ctx->{is_y_match}, 0, 'Default is_y_match is 0');
    is($ctx->{h_match}, -1, 'Default h_match is -1');
    is($ctx->{match_limit}, 1, 'Default match_limit is 1');
    is($ctx->{match_count}, 0, 'Default match_count is 0');
    is($ctx->{auto_incr_orig_value}, 0, 'Default auto_incr_orig_value is 0');
    
    # Test that array references are initialized
    is(ref($ctx->{previous_lines}), 'ARRAY', 'previous_lines is array ref');
    is(ref($ctx->{line_buff}), 'ARRAY', 'line_buff is array ref');
    is(ref($ctx->{all_lines}), 'ARRAY', 'all_lines is array ref');
    is(ref($ctx->{alt_lines}), 'ARRAY', 'alt_lines is array ref');
    is(ref($ctx->{frame_buffer}), 'ARRAY', 'frame_buffer is array ref');
    is(ref($ctx->{incr_columns}), 'ARRAY', 'incr_columns is array ref');
    is(ref($ctx->{sum_columns}), 'ARRAY', 'sum_columns is array ref');
    is(ref($ctx->{count_columns}), 'ARRAY', 'count_columns is array ref');
    is(ref($ctx->{avg_columns}), 'ARRAY', 'avg_columns is array ref');
    
    # Test that hash references are initialized
    is(ref($ctx->{options}), 'HASH', 'options is hash ref');
    is(ref($ctx->{line_ranges}), 'HASH', 'line_ranges is hash ref');
    is(ref($ctx->{increment_ref}), 'HASH', 'increment_ref is hash ref');
    is(ref($ctx->{sum_ref}), 'HASH', 'sum_ref is hash ref');
    is(ref($ctx->{avg_ref}), 'HASH', 'avg_ref is hash ref');
    is(ref($ctx->{count_ref}), 'HASH', 'count_ref is hash ref');
    is(ref($ctx->{auto_incr_seed}), 'HASH', 'auto_incr_seed is hash ref');
    is(ref($ctx->{auto_incr_reset}), 'HASH', 'auto_incr_reset is hash ref');
    
    # Test special initializations
    is(scalar(@{$ctx->{previous_lines}}), 1, 'previous_lines initialized with BOF');
    is($ctx->{previous_lines}->[0], 'BOF', 'BOF marker present');
    is($ctx->{line_ranges}->{'1'}, 100000000, 'Default line range set');
    
    # Test that we can create multiple contexts independently
    my $ctx2 = Pipe::Context->new();
    isnt($ctx, $ctx2, 'Multiple contexts are separate objects');
    is($ctx2->{line_number}, 0, 'Second context has independent state');
};

# Test line number management - comprehensive testing
subtest 'line number management comprehensive tests' => sub {
    my $ctx = Pipe::Context->new();
    
    # Test initial state
    is($ctx->get_line_number(), 0, 'Initial line number is 0');
    
    # Test setting various values
    $ctx->set_line_number(5);
    is($ctx->get_line_number(), 5, 'set_line_number works with positive integer');
    
    $ctx->set_line_number(0);
    is($ctx->get_line_number(), 0, 'set_line_number works with zero');
    
    $ctx->set_line_number(-5);
    is($ctx->get_line_number(), -5, 'set_line_number works with negative integer');
    
    $ctx->set_line_number(999999);
    is($ctx->get_line_number(), 999999, 'set_line_number works with large number');
    
    # Test increment functionality
    $ctx->set_line_number(10);
    is($ctx->increment_line_number(), 11, 'increment_line_number returns new value');
    is($ctx->get_line_number(), 11, 'line number was incremented correctly');
    
    # Test multiple increments
    for my $expected (12..15) {
        is($ctx->increment_line_number(), $expected, "increment works for line $expected");
    }
    
    # Test increment from zero
    $ctx->set_line_number(0);
    is($ctx->increment_line_number(), 1, 'increment from zero works');
    
    # Test increment from negative
    $ctx->set_line_number(-1);
    is($ctx->increment_line_number(), 0, 'increment from negative works');
    
    # Test with undef/empty values (edge cases)
    $ctx->set_line_number(undef);
    ok(!defined($ctx->get_line_number()) || $ctx->get_line_number() eq '', 'handles undef gracefully');
    
    $ctx->set_line_number('');
    is($ctx->get_line_number(), '', 'handles empty string');
};

# Test delimiter management - comprehensive testing
subtest 'delimiter management comprehensive tests' => sub {
    my $ctx = Pipe::Context->new();
    
    # Test initial state
    is($ctx->get_delimiter(), '|', 'Default delimiter is pipe');
    
    # Test setting various delimiters
    $ctx->set_delimiter(',');
    is($ctx->get_delimiter(), ',', 'set_delimiter works with comma');
    
    $ctx->set_delimiter('\t');
    is($ctx->get_delimiter(), '\t', 'set_delimiter works with tab');
    
    $ctx->set_delimiter(' ');
    is($ctx->get_delimiter(), ' ', 'set_delimiter works with space');
    
    $ctx->set_delimiter(':');
    is($ctx->get_delimiter(), ':', 'set_delimiter works with colon');
    
    $ctx->set_delimiter(';');
    is($ctx->get_delimiter(), ';', 'set_delimiter works with semicolon');
    
    # Test edge cases
    $ctx->set_delimiter('');
    is($ctx->get_delimiter(), '', 'set_delimiter works with empty string');
    
    $ctx->set_delimiter('||');
    is($ctx->get_delimiter(), '||', 'set_delimiter works with multi-character delimiter');
    
    $ctx->set_delimiter('ABC');
    is($ctx->get_delimiter(), 'ABC', 'set_delimiter works with alphabetic delimiter');
    
    $ctx->set_delimiter('123');
    is($ctx->get_delimiter(), '123', 'set_delimiter works with numeric delimiter');
    
    # Test special characters
    $ctx->set_delimiter('\\');
    is($ctx->get_delimiter(), '\\', 'set_delimiter works with backslash');
    
    $ctx->set_delimiter('\"');
    is($ctx->get_delimiter(), '\"', 'set_delimiter works with quote');
    
    # Test with undef
    $ctx->set_delimiter(undef);
    ok(!defined($ctx->get_delimiter()) || $ctx->get_delimiter() eq '', 'handles undef delimiter gracefully');
};

# Test options management - comprehensive testing
subtest 'options management comprehensive tests' => sub {
    my $ctx = Pipe::Context->new();
    
    # Test initial state
    is(ref($ctx->{options}), 'HASH', 'options is initialized as hash ref');
    is(scalar(keys %{$ctx->{options}}), 0, 'options starts empty');
    
    # Test setting individual options
    $ctx->set_option('A', 1);
    is($ctx->get_option('A'), 1, 'set_option and get_option work with simple value');
    
    $ctx->set_option('B', 'string_value');
    is($ctx->get_option('B'), 'string_value', 'set_option works with string value');
    
    $ctx->set_option('C', 0);
    is($ctx->get_option('C'), 0, 'set_option works with zero value');
    
    $ctx->set_option('D', undef);
    ok(!defined($ctx->get_option('D')), 'set_option works with undef value');
    
    $ctx->set_option('E', '');
    is($ctx->get_option('E'), '', 'set_option works with empty string');
    
    # Test getting non-existent option
    is($ctx->get_option('NONEXISTENT'), undef, 'get_option returns undef for non-existent key');
    
    # Test overwriting options
    $ctx->set_option('A', 'new_value');
    is($ctx->get_option('A'), 'new_value', 'set_option overwrites existing value');
    
    # Test setting multiple options via hash
    my %opts = (x => 1, y => 2, z => 3, w => 'test');
    $ctx->set_options(\%opts);
    is($ctx->get_option('x'), 1, 'set_options works for x');
    is($ctx->get_option('y'), 2, 'set_options works for y');
    is($ctx->get_option('z'), 3, 'set_options works for z');
    is($ctx->get_option('w'), 'test', 'set_options works for w');
    
    # Test that set_options replaces entire hash
    is($ctx->get_option('A'), undef, 'set_options replaces previous options');
    
    # Test setting options with complex values
    my %complex_opts = (
        array_ref => [1, 2, 3],
        hash_ref => {a => 1, b => 2},
        code_ref => sub { return 42; }
    );
    $ctx->set_options(\%complex_opts);
    is(ref($ctx->get_option('array_ref')), 'ARRAY', 'set_options works with array ref');
    is(ref($ctx->get_option('hash_ref')), 'HASH', 'set_options works with hash ref');
    is(ref($ctx->get_option('code_ref')), 'CODE', 'set_options works with code ref');
    
    # Test with empty hash
    my %empty_opts = ();
    $ctx->set_options(\%empty_opts);
    is(scalar(keys %{$ctx->{options}}), 0, 'set_options works with empty hash');
    
    # Test edge cases with option keys
    $ctx->set_option('', 'empty_key');
    is($ctx->get_option(''), 'empty_key', 'set_option works with empty key');
    
    $ctx->set_option(123, 'numeric_key');
    is($ctx->get_option(123), 'numeric_key', 'set_option works with numeric key');
    
    $ctx->set_option(undef, 'undef_key');
    is($ctx->get_option(undef), 'undef_key', 'set_option works with undef key');
};

# Test column array getters - comprehensive testing
subtest 'column array getters comprehensive tests' => sub {
    my $ctx = Pipe::Context->new();
    
    # Test that all getters return array references
    is(ref($ctx->get_sum_columns()), 'ARRAY', 'get_sum_columns returns array ref');
    is(ref($ctx->get_count_columns()), 'ARRAY', 'get_count_columns returns array ref');
    is(ref($ctx->get_avg_columns()), 'ARRAY', 'get_avg_columns returns array ref');
    is(ref($ctx->get_width_columns()), 'ARRAY', 'get_width_columns returns array ref');
    
    # Test that arrays start empty
    is(scalar(@{$ctx->get_sum_columns()}), 0, 'sum_columns starts empty');
    is(scalar(@{$ctx->get_count_columns()}), 0, 'count_columns starts empty');
    is(scalar(@{$ctx->get_avg_columns()}), 0, 'avg_columns starts empty');
    is(scalar(@{$ctx->get_width_columns()}), 0, 'width_columns starts empty');
    
    # Test that we can modify the arrays through the references
    my $sum_cols = $ctx->get_sum_columns();
    push @$sum_cols, 0, 1, 2;
    is(scalar(@{$ctx->get_sum_columns()}), 3, 'sum_columns can be modified via reference');
    is($ctx->get_sum_columns()->[0], 0, 'sum_columns first element correct');
    is($ctx->get_sum_columns()->[1], 1, 'sum_columns second element correct');
    is($ctx->get_sum_columns()->[2], 2, 'sum_columns third element correct');
    
    # Test that arrays are independent
    my $count_cols = $ctx->get_count_columns();
    push @$count_cols, 5, 6;
    is(scalar(@{$ctx->get_sum_columns()}), 3, 'sum_columns unchanged when count_columns modified');
    is(scalar(@{$ctx->get_count_columns()}), 2, 'count_columns has correct size');
    
    # Test that the same reference is returned on multiple calls
    my $ref1 = $ctx->get_sum_columns();
    my $ref2 = $ctx->get_sum_columns();
    is($ref1, $ref2, 'get_sum_columns returns same reference on multiple calls');
    
    # Test with different data types in arrays
    my $avg_cols = $ctx->get_avg_columns();
    push @$avg_cols, 0, 'string', undef, -1, 3.14;
    is(scalar(@{$ctx->get_avg_columns()}), 5, 'avg_columns accepts mixed data types');
    is($ctx->get_avg_columns()->[1], 'string', 'avg_columns handles string values');
    ok(!defined($ctx->get_avg_columns()->[2]), 'avg_columns handles undef values');
    is($ctx->get_avg_columns()->[3], -1, 'avg_columns handles negative values');
    is($ctx->get_avg_columns()->[4], 3.14, 'avg_columns handles float values');
};

# Test reference hash getters - comprehensive testing
subtest 'reference hash getters comprehensive tests' => sub {
    my $ctx = Pipe::Context->new();
    
    # Test that all getters return hash references
    is(ref($ctx->get_sum_ref()), 'HASH', 'get_sum_ref returns hash ref');
    is(ref($ctx->get_count_ref()), 'HASH', 'get_count_ref returns hash ref');
    is(ref($ctx->get_avg_ref()), 'HASH', 'get_avg_ref returns hash ref');
    is(ref($ctx->get_avg_count()), 'HASH', 'get_avg_count returns hash ref');
    
    # Test that hashes start empty
    is(scalar(keys %{$ctx->get_sum_ref()}), 0, 'sum_ref starts empty');
    is(scalar(keys %{$ctx->get_count_ref()}), 0, 'count_ref starts empty');
    is(scalar(keys %{$ctx->get_avg_ref()}), 0, 'avg_ref starts empty');
    is(scalar(keys %{$ctx->get_avg_count()}), 0, 'avg_count starts empty');
    
    # Test that we can modify the hashes through the references
    my $sum_ref = $ctx->get_sum_ref();
    $sum_ref->{'c0'} = 100;
    $sum_ref->{'c1'} = 200;
    is(scalar(keys %{$ctx->get_sum_ref()}), 2, 'sum_ref can be modified via reference');
    is($ctx->get_sum_ref()->{'c0'}, 100, 'sum_ref c0 value correct');
    is($ctx->get_sum_ref()->{'c1'}, 200, 'sum_ref c1 value correct');
    
    # Test that hashes are independent
    my $count_ref = $ctx->get_count_ref();
    $count_ref->{'c0'} = 5;
    is(scalar(keys %{$ctx->get_sum_ref()}), 2, 'sum_ref unchanged when count_ref modified');
    is(scalar(keys %{$ctx->get_count_ref()}), 1, 'count_ref has correct size');
    is($ctx->get_count_ref()->{'c0'}, 5, 'count_ref value correct');
    
    # Test that the same reference is returned on multiple calls
    my $ref1 = $ctx->get_sum_ref();
    my $ref2 = $ctx->get_sum_ref();
    is($ref1, $ref2, 'get_sum_ref returns same reference on multiple calls');
    
    # Test with different data types as keys and values
    my $avg_ref = $ctx->get_avg_ref();
    $avg_ref->{'string_key'} = 'string_value';
    $avg_ref->{123} = 'numeric_key';
    $avg_ref->{''} = 'empty_key';
    $avg_ref->{'key'} = undef;
    $avg_ref->{'negative'} = -42;
    $avg_ref->{'float'} = 3.14159;
    
    is(scalar(keys %{$ctx->get_avg_ref()}), 6, 'avg_ref accepts mixed key/value types');
    is($ctx->get_avg_ref()->{'string_key'}, 'string_value', 'avg_ref handles string values');
    is($ctx->get_avg_ref()->{123}, 'numeric_key', 'avg_ref handles numeric keys');
    is($ctx->get_avg_ref()->{''}, 'empty_key', 'avg_ref handles empty keys');
    ok(!defined($ctx->get_avg_ref()->{'key'}), 'avg_ref handles undef values');
    is($ctx->get_avg_ref()->{'negative'}, -42, 'avg_ref handles negative values');
    is($ctx->get_avg_ref()->{'float'}, 3.14159, 'avg_ref handles float values');
};

# Test reset_accumulators - comprehensive testing
subtest 'reset_accumulators comprehensive tests' => sub {
    my $ctx = Pipe::Context->new();
    
    # Set up some data in the accumulators
    $ctx->{sum_ref}->{'c0'} = 100;
    $ctx->{sum_ref}->{'c1'} = 200;
    $ctx->{count_ref}->{'c0'} = 5;
    $ctx->{count_ref}->{'c2'} = 10;
    $ctx->{avg_ref}->{'c1'} = 25.5;
    $ctx->{avg_count}->{'c1'} = 3;
    $ctx->{width_min_ref}->{'c0'} = 5;
    $ctx->{width_max_ref}->{'c0'} = 15;
    $ctx->{ddup_ref}->{'key1'} = 1;
    $ctx->{hist_ref}->{'value1'} = 10;
    
    # Verify data is set
    is(scalar(keys %{$ctx->{sum_ref}}), 2, 'sum_ref has data before reset');
    is(scalar(keys %{$ctx->{count_ref}}), 2, 'count_ref has data before reset');
    is(scalar(keys %{$ctx->{avg_ref}}), 1, 'avg_ref has data before reset');
    is(scalar(keys %{$ctx->{avg_count}}), 1, 'avg_count has data before reset');
    is(scalar(keys %{$ctx->{width_min_ref}}), 1, 'width_min_ref has data before reset');
    is(scalar(keys %{$ctx->{width_max_ref}}), 1, 'width_max_ref has data before reset');
    is(scalar(keys %{$ctx->{ddup_ref}}), 1, 'ddup_ref has data before reset');
    is(scalar(keys %{$ctx->{hist_ref}}), 1, 'hist_ref has data before reset');
    
    # Reset accumulators
    $ctx->reset_accumulators();
    
    # Verify all accumulators are reset
    is(scalar(keys %{$ctx->{sum_ref}}), 0, 'sum_ref reset to empty');
    is(scalar(keys %{$ctx->{count_ref}}), 0, 'count_ref reset to empty');
    is(scalar(keys %{$ctx->{avg_ref}}), 0, 'avg_ref reset to empty');
    is(scalar(keys %{$ctx->{avg_count}}), 0, 'avg_count reset to empty');
    is(scalar(keys %{$ctx->{width_min_ref}}), 0, 'width_min_ref reset to empty');
    is(scalar(keys %{$ctx->{width_max_ref}}), 0, 'width_max_ref reset to empty');
    is(scalar(keys %{$ctx->{ddup_ref}}), 0, 'ddup_ref reset to empty');
    is(scalar(keys %{$ctx->{hist_ref}}), 0, 'hist_ref reset to empty');
    
    # Test that reset doesn't affect other attributes
    is($ctx->{line_number}, 0, 'line_number unchanged by reset');
    is($ctx->{delimiter}, '|', 'delimiter unchanged by reset');
    is(scalar(@{$ctx->{previous_lines}}), 1, 'previous_lines unchanged by reset');
    
    # Test reset when accumulators are already empty
    $ctx->reset_accumulators();
    is(scalar(keys %{$ctx->{sum_ref}}), 0, 'reset works when already empty');
    
    # Test reset multiple times
    for (1..5) {
        $ctx->reset_accumulators();
        is(scalar(keys %{$ctx->{sum_ref}}), 0, "reset works on iteration $_");
    }
    
    # Test that we can use accumulators after reset
    $ctx->{sum_ref}->{'c0'} = 50;
    is($ctx->{sum_ref}->{'c0'}, 50, 'accumulators work normally after reset');
};

# Test match frame state management - comprehensive testing
subtest 'match frame state management comprehensive tests' => sub {
    my $ctx = Pipe::Context->new();
    
    # Test initial state
    ok(!$ctx->is_in_match_frame(), 'Initially not in match frame');
    is($ctx->{is_x_match}, 0, 'is_x_match initially 0');
    is($ctx->{is_y_match}, 0, 'is_y_match initially 0');
    is(ref($ctx->{frame_buffer}), 'ARRAY', 'frame_buffer is array ref');
    is(scalar(@{$ctx->{frame_buffer}}), 0, 'frame_buffer initially empty');
    
    # Test starting match frame
    $ctx->start_match_frame();
    ok($ctx->is_in_match_frame(), 'In match frame after start');
    is($ctx->{is_x_match}, 1, 'is_x_match set to 1 after start');
    is($ctx->{is_y_match}, 0, 'is_y_match still 0 after start');
    is(scalar(@{$ctx->{frame_buffer}}), 0, 'frame_buffer reset to empty on start');
    
    # Test that is_in_match_frame checks both x and y match
    $ctx->{is_x_match} = 0;
    $ctx->{is_y_match} = 1;
    ok($ctx->is_in_match_frame(), 'In match frame when y_match is set');
    
    $ctx->{is_x_match} = 1;
    $ctx->{is_y_match} = 1;
    ok($ctx->is_in_match_frame(), 'In match frame when both x and y match are set');
    
    $ctx->{is_x_match} = 0;
    $ctx->{is_y_match} = 0;
    ok(!$ctx->is_in_match_frame(), 'Not in match frame when both are 0');
    
    # Test ending match frame
    $ctx->{is_x_match} = 1;
    $ctx->{is_y_match} = 1;
    push @{$ctx->{frame_buffer}}, 'line1', 'line2', 'line3';
    
    my $buffer = $ctx->end_match_frame();
    ok(!$ctx->is_in_match_frame(), 'Not in match frame after end');
    is($ctx->{is_x_match}, 0, 'is_x_match reset to 0 after end');
    is($ctx->{is_y_match}, 0, 'is_y_match reset to 0 after end');
    is(ref($buffer), 'ARRAY', 'end_match_frame returns array ref');
    is(scalar(@$buffer), 3, 'returned buffer has correct size');
    is($buffer->[0], 'line1', 'returned buffer has correct first element');
    is($buffer->[2], 'line3', 'returned buffer has correct last element');
    
    # Test multiple start/end cycles
    for my $cycle (1..3) {
        $ctx->start_match_frame();
        ok($ctx->is_in_match_frame(), "In match frame after start cycle $cycle");
        
        push @{$ctx->{frame_buffer}}, "cycle$cycle";
        
        my $buf = $ctx->end_match_frame();
        ok(!$ctx->is_in_match_frame(), "Not in match frame after end cycle $cycle");
        is(scalar(@$buf), 1, "Buffer size correct for cycle $cycle");
        is($buf->[0], "cycle$cycle", "Buffer content correct for cycle $cycle");
    }
    
    # Test starting when already in frame
    $ctx->start_match_frame();
    push @{$ctx->{frame_buffer}}, 'data1';
    $ctx->start_match_frame();  # Start again
    is(scalar(@{$ctx->{frame_buffer}}), 0, 'frame_buffer reset on second start');
    ok($ctx->is_in_match_frame(), 'Still in match frame after second start');
    
    # Test ending when not in frame
    $ctx->{is_x_match} = 0;
    $ctx->{is_y_match} = 0;
    my $empty_buffer = $ctx->end_match_frame();
    is(ref($empty_buffer), 'ARRAY', 'end_match_frame returns array even when not in frame');
    ok(!$ctx->is_in_match_frame(), 'Still not in match frame after end when not started');
};

# Test line buffer management - comprehensive testing
subtest 'line buffer management comprehensive tests' => sub {
    my $ctx = Pipe::Context->new();
    
    # Test initial state
    is(ref($ctx->get_line_buffer()), 'ARRAY', 'get_line_buffer returns array ref');
    is(scalar(@{$ctx->get_line_buffer()}), 0, 'line buffer initially empty');
    is($ctx->{keep_lines}, 10, 'keep_lines default is 10');
    
    # Test adding single lines
    $ctx->add_to_line_buffer("line1");
    my $buffer = $ctx->get_line_buffer();
    is(scalar(@$buffer), 1, 'line buffer has 1 line after first add');
    is($buffer->[0], 'line1', 'first line content correct');
    
    $ctx->add_to_line_buffer("line2");
    $buffer = $ctx->get_line_buffer();
    is(scalar(@$buffer), 2, 'line buffer has 2 lines after second add');
    is($buffer->[0], 'line1', 'first line still correct');
    is($buffer->[1], 'line2', 'second line content correct');
    
    # Test adding up to keep_lines limit
    for my $i (3..10) {
        $ctx->add_to_line_buffer("line$i");
    }
    $buffer = $ctx->get_line_buffer();
    is(scalar(@$buffer), 10, 'line buffer at keep_lines limit');
    is($buffer->[0], 'line1', 'first line still present at limit');
    is($buffer->[9], 'line10', 'last line correct at limit');
    
    # Test overflow behavior
    $ctx->add_to_line_buffer("line11");
    $buffer = $ctx->get_line_buffer();
    is(scalar(@$buffer), 10, 'line buffer size maintained after overflow');
    is($buffer->[0], 'line2', 'oldest line removed after overflow');
    is($buffer->[9], 'line11', 'newest line at end after overflow');
    
    # Test continued overflow
    for my $i (12..20) {
        $ctx->add_to_line_buffer("line$i");
    }
    $buffer = $ctx->get_line_buffer();
    is(scalar(@$buffer), 10, 'line buffer size still maintained after many overflows');
    is($buffer->[0], 'line11', 'correct oldest line after many overflows');
    is($buffer->[9], 'line20', 'correct newest line after many overflows');
    
    # Test with different keep_lines values
    $ctx->{keep_lines} = 3;
    my $ctx2 = Pipe::Context->new();
    $ctx2->{keep_lines} = 3;
    
    for my $i (1..5) {
        $ctx2->add_to_line_buffer("line$i");
    }
    my $buffer2 = $ctx2->get_line_buffer();
    is(scalar(@$buffer2), 3, 'line buffer respects different keep_lines value');
    is($buffer2->[0], 'line3', 'correct oldest line with keep_lines=3');
    is($buffer2->[2], 'line5', 'correct newest line with keep_lines=3');
    
    # Test with keep_lines = 0
    my $ctx3 = Pipe::Context->new();
    $ctx3->{keep_lines} = 0;
    $ctx3->add_to_line_buffer("line1");
    $ctx3->add_to_line_buffer("line2");
    my $buffer3 = $ctx3->get_line_buffer();
    is(scalar(@$buffer3), 0, 'line buffer remains empty with keep_lines=0');
    
    # Test with keep_lines = 1
    my $ctx4 = Pipe::Context->new();
    $ctx4->{keep_lines} = 1;
    $ctx4->add_to_line_buffer("line1");
    $ctx4->add_to_line_buffer("line2");
    my $buffer4 = $ctx4->get_line_buffer();
    is(scalar(@$buffer4), 1, 'line buffer keeps only 1 line with keep_lines=1');
    is($buffer4->[0], 'line2', 'most recent line kept with keep_lines=1');
    
    # Test edge cases with line content
    my $ctx5 = Pipe::Context->new();
    $ctx5->add_to_line_buffer("");  # Empty string
    $ctx5->add_to_line_buffer(undef);  # Undef
    $ctx5->add_to_line_buffer(0);  # Zero
    $ctx5->add_to_line_buffer("  ");  # Whitespace
    $ctx5->add_to_line_buffer("line with\ttabs\nand\nnewlines");  # Special chars
    
    my $buffer5 = $ctx5->get_line_buffer();
    is(scalar(@$buffer5), 5, 'line buffer accepts various line types');
    is($buffer5->[0], '', 'empty string line stored correctly');
    ok(!defined($buffer5->[1]), 'undef line stored correctly');
    is($buffer5->[2], 0, 'zero line stored correctly');
    is($buffer5->[3], '  ', 'whitespace line stored correctly');
    is($buffer5->[4], "line with\ttabs\nand\nnewlines", 'special chars line stored correctly');
    
    # Test that the same reference is returned
    my $ref1 = $ctx->get_line_buffer();
    my $ref2 = $ctx->get_line_buffer();
    is($ref1, $ref2, 'get_line_buffer returns same reference on multiple calls');
};

# Test needs_full_read functionality - comprehensive testing
subtest 'needs_full_read functionality comprehensive tests' => sub {
    my $ctx = Pipe::Context->new();
    
    # Test initial state
    ok(!$ctx->needs_full_read(), 'does not need full read by default');
    is($ctx->{read_full}, 0, 'read_full initially 0');
    is(scalar(@{$ctx->{sort_columns}}), 0, 'sort_columns initially empty');
    is($ctx->{tail_output}, 0, 'tail_output initially 0');
    
    # Test read_full flag
    $ctx->{read_full} = 1;
    ok($ctx->needs_full_read(), 'needs full read when read_full set to 1');
    
    $ctx->{read_full} = 0;
    ok(!$ctx->needs_full_read(), 'does not need full read when read_full reset to 0');
    
    # Test sort_columns array
    push @{$ctx->{sort_columns}}, 0;
    ok($ctx->needs_full_read(), 'needs full read when sort_columns has elements');
    
    push @{$ctx->{sort_columns}}, 1, 2;
    ok($ctx->needs_full_read(), 'needs full read when sort_columns has multiple elements');
    
    @{$ctx->{sort_columns}} = ();  # Clear array
    ok(!$ctx->needs_full_read(), 'does not need full read when sort_columns cleared');
    
    # Test tail_output flag
    $ctx->{tail_output} = 1;
    ok($ctx->needs_full_read(), 'needs full read when tail_output set to 1');
    
    $ctx->{tail_output} = 0;
    ok(!$ctx->needs_full_read(), 'does not need full read when tail_output reset to 0');
    
    # Test combinations
    $ctx->{read_full} = 1;
    $ctx->{tail_output} = 1;
    push @{$ctx->{sort_columns}}, 0;
    ok($ctx->needs_full_read(), 'needs full read when all conditions true');
    
    $ctx->{read_full} = 0;
    ok($ctx->needs_full_read(), 'needs full read when any condition true (sort_columns + tail_output)');
    
    $ctx->{tail_output} = 0;
    ok($ctx->needs_full_read(), 'needs full read when any condition true (sort_columns only)');
    
    @{$ctx->{sort_columns}} = ();
    ok(!$ctx->needs_full_read(), 'does not need full read when all conditions false');
    
    # Test with different types of values in sort_columns
    push @{$ctx->{sort_columns}}, 'string';
    ok($ctx->needs_full_read(), 'needs full read with string in sort_columns');
    
    @{$ctx->{sort_columns}} = (undef);
    ok($ctx->needs_full_read(), 'needs full read with undef in sort_columns');
    
    @{$ctx->{sort_columns}} = (0, '', 'test', -1);
    ok($ctx->needs_full_read(), 'needs full read with mixed types in sort_columns');
    
    # Test with different values for flags
    $ctx->{sort_columns} = [];
    $ctx->{read_full} = 'string';
    ok($ctx->needs_full_read(), 'needs full read with truthy string in read_full');
    
    $ctx->{read_full} = '';
    ok(!$ctx->needs_full_read(), 'does not need full read with empty string in read_full');
    
    $ctx->{read_full} = undef;
    ok(!$ctx->needs_full_read(), 'does not need full read with undef in read_full');
    
    $ctx->{tail_output} = 'yes';
    ok($ctx->needs_full_read(), 'needs full read with truthy string in tail_output');
    
    $ctx->{tail_output} = '';
    ok(!$ctx->needs_full_read(), 'does not need full read with empty string in tail_output');
};

# Test edge cases and error conditions - comprehensive testing
subtest 'edge cases and error conditions comprehensive tests' => sub {
    my $ctx = Pipe::Context->new();
    
    # Test with very large line numbers
    $ctx->set_line_number(999999999);
    is($ctx->get_line_number(), 999999999, 'handles very large line numbers');
    is($ctx->increment_line_number(), 1000000000, 'increment works with large numbers');
    
    # Test with negative line numbers
    $ctx->set_line_number(-999);
    is($ctx->get_line_number(), -999, 'handles negative line numbers');
    is($ctx->increment_line_number(), -998, 'increment works with negative numbers');
    
    # Test line buffer with very large keep_lines
    $ctx->{keep_lines} = 100000;
    for my $i (1..50) {
        $ctx->add_to_line_buffer("line$i");
    }
    my $buffer = $ctx->get_line_buffer();
    is(scalar(@$buffer), 50, 'line buffer works with large keep_lines value');
    
    # Test line buffer with very long lines
    my $long_line = 'x' x 10000;
    $ctx->add_to_line_buffer($long_line);
    $buffer = $ctx->get_line_buffer();
    is(length($buffer->[-1]), 10000, 'line buffer handles very long lines');
    
    # Test with very long delimiter
    my $long_delimiter = 'DELIMITER' x 100;
    $ctx->set_delimiter($long_delimiter);
    is($ctx->get_delimiter(), $long_delimiter, 'handles very long delimiter');
    
    # Test options with very large hash
    my %large_opts = ();
    for my $i (1..1000) {
        $large_opts{"key$i"} = "value$i";
    }
    $ctx->set_options(\%large_opts);
    is(scalar(keys %{$ctx->{options}}), 1000, 'handles large options hash');
    is($ctx->get_option('key500'), 'value500', 'can retrieve from large options hash');
    
    # Test accumulators with large amounts of data
    for my $i (1..1000) {
        $ctx->{sum_ref}->{"c$i"} = $i * 100;
    }
    is(scalar(keys %{$ctx->{sum_ref}}), 1000, 'sum_ref handles large amounts of data');
    $ctx->reset_accumulators();
    is(scalar(keys %{$ctx->{sum_ref}}), 0, 'reset works with large amount of data');
    
    # Test frame buffer with large amounts of data
    $ctx->start_match_frame();
    for my $i (1..1000) {
        push @{$ctx->{frame_buffer}}, "line$i";
    }
    my $frame_buf = $ctx->end_match_frame();
    is(scalar(@$frame_buf), 1000, 'frame buffer handles large amounts of data');
    
    # Test previous_lines array access
    is(scalar(@{$ctx->{previous_lines}}), 1, 'previous_lines has BOF marker');
    push @{$ctx->{previous_lines}}, 'line1', 'line2';
    is(scalar(@{$ctx->{previous_lines}}), 3, 'previous_lines can be extended');
    is($ctx->{previous_lines}->[0], 'BOF', 'BOF marker preserved');
    
    # Test line_ranges hash access
    is($ctx->{line_ranges}->{'1'}, 100000000, 'default line range accessible');
    $ctx->{line_ranges}->{'2'} = 50;
    is($ctx->{line_ranges}->{'2'}, 50, 'can add new line ranges');
    
    # Test creating multiple contexts and ensuring independence
    my $ctx2 = Pipe::Context->new();
    $ctx2->set_line_number(100);
    $ctx2->set_delimiter(':');
    
    isnt($ctx->get_line_number(), $ctx2->get_line_number(), 'multiple contexts have independent line numbers');
    isnt($ctx->get_delimiter(), $ctx2->get_delimiter(), 'multiple contexts have independent delimiters');
    
    # Test that modifying one context doesn't affect another
    push @{$ctx->get_sum_columns()}, 1, 2, 3;
    is(scalar(@{$ctx2->get_sum_columns()}), 0, 'multiple contexts have independent arrays');
    
    $ctx->{sum_ref}->{'test'} = 100;
    is(scalar(keys %{$ctx2->{sum_ref}}), 0, 'multiple contexts have independent hashes');
};

done_testing();