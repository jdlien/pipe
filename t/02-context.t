#!/usr/bin/perl
#
# Unit tests for Pipe::Context module
# Currently a template - will be activated when module is created
#
use strict;
use warnings;
use Test::More;
use lib 'lib';

BEGIN { 
    use_ok('Pipe::Context') or BAIL_OUT("Can't load Pipe::Context");
}

# Test object creation
my $ctx = Pipe::Context->new();
isa_ok($ctx, 'Pipe::Context', 'Created context object');

# Test initial state
is($ctx->get_line_number(), 0, 'Initial line number is 0');
is($ctx->get_delimiter(), '|', 'Default delimiter is pipe');
is($ctx->{precision}, 2, 'Default precision is 2');
is($ctx->{read_full}, 0, 'read_full defaults to 0');

# Test line number management
$ctx->set_line_number(5);
is($ctx->get_line_number(), 5, 'set_line_number works');
is($ctx->increment_line_number(), 6, 'increment_line_number returns new value');
is($ctx->get_line_number(), 6, 'line number was incremented');

# Test delimiter management
$ctx->set_delimiter(',');
is($ctx->get_delimiter(), ',', 'set_delimiter works');

# Test options management
$ctx->set_option('A', 1);
is($ctx->get_option('A'), 1, 'set_option and get_option work');

my %opts = (x => 1, y => 2, z => 3);
$ctx->set_options(\%opts);
is($ctx->get_option('y'), 2, 'set_options works');

# Test column arrays
is(ref($ctx->get_sum_columns()), 'ARRAY', 'get_sum_columns returns array ref');
is(ref($ctx->get_count_columns()), 'ARRAY', 'get_count_columns returns array ref');
is(ref($ctx->get_avg_columns()), 'ARRAY', 'get_avg_columns returns array ref');
is(ref($ctx->get_width_columns()), 'ARRAY', 'get_width_columns returns array ref');

# Test reference hashes
is(ref($ctx->get_sum_ref()), 'HASH', 'get_sum_ref returns hash ref');
is(ref($ctx->get_count_ref()), 'HASH', 'get_count_ref returns hash ref');
is(ref($ctx->get_avg_ref()), 'HASH', 'get_avg_ref returns hash ref');
is(ref($ctx->get_avg_count()), 'HASH', 'get_avg_count returns hash ref');

# Test accumulator reset
$ctx->{sum_ref}->{'c0'} = 100;
$ctx->{count_ref}->{'c1'} = 5;
$ctx->reset_accumulators();
is(scalar(keys %{$ctx->{sum_ref}}), 0, 'sum_ref reset');
is(scalar(keys %{$ctx->{count_ref}}), 0, 'count_ref reset');

# Test match frame state
ok(!$ctx->is_in_match_frame(), 'Initially not in match frame');
$ctx->start_match_frame();
ok($ctx->is_in_match_frame(), 'In match frame after start');
is($ctx->{is_x_match}, 1, 'is_x_match set');
my $buffer = $ctx->end_match_frame();
ok(!$ctx->is_in_match_frame(), 'Not in match frame after end');
is(ref($buffer), 'ARRAY', 'end_match_frame returns array ref');

# Test line buffer
$ctx->add_to_line_buffer("line1");
$ctx->add_to_line_buffer("line2");
my $buff = $ctx->get_line_buffer();
is(scalar(@$buff), 2, 'Line buffer has 2 lines');
is($buff->[0], 'line1', 'First line correct');

# Test line buffer overflow
for (1..20) {
    $ctx->add_to_line_buffer("line$_");
}
$buff = $ctx->get_line_buffer();
is(scalar(@$buff), 10, 'Line buffer limited to keep_lines');

# Test needs_full_read
ok(!$ctx->needs_full_read(), 'Does not need full read by default');
$ctx->{read_full} = 1;
ok($ctx->needs_full_read(), 'Needs full read when read_full set');
$ctx->{read_full} = 0;
push @{$ctx->{sort_columns}}, 0;
ok($ctx->needs_full_read(), 'Needs full read when sort columns exist');

# Test initial arrays and hashes
is(scalar(@{$ctx->{previous_lines}}), 1, 'previous_lines initialized with BOF');
is($ctx->{previous_lines}->[0], 'BOF', 'BOF marker present');
is($ctx->{line_ranges}->{'1'}, 100000000, 'Default line range set');

done_testing();