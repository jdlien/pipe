#!/usr/bin/perl
#
# Integration tests - testing actual pipe.pl functionality
# These tests will ensure our modules work correctly together
#
use strict;
use warnings;
use Test::More tests => 9;
use File::Temp qw(tempfile);
use IPC::Open3;
use Symbol 'gensym';

# Path to pipe.pl
my $PIPE = './pipe.pl';

# Check that pipe.pl exists
ok(-f $PIPE, 'pipe.pl exists') or BAIL_OUT("Can't find pipe.pl");
ok(-x $PIPE, 'pipe.pl is executable') or BAIL_OUT("pipe.pl is not executable");

# Helper function to run pipe.pl
sub run_pipe {
    my ($input, $args) = @_;
    $args ||= '';
    
    my ($in, $out, $err);
    $err = gensym;
    
    my $pid = open3($in, $out, $err, "$PIPE $args");
    print $in $input if defined $input;
    close $in;
    
    my $output = do { local $/; <$out> };
    my $error = do { local $/; <$err> };
    
    waitpid($pid, 0);
    my $exit_code = $? >> 8;
    
    return ($output || '', $error || '', $exit_code);
}

# Test 1: Basic pass-through
{
    my ($out, $err, $exit) = run_pipe("a|b|c\n", '');
    is($out, "a|b|c\n", 'Basic pass-through works');
    is($exit, 0, 'Exit code is 0');
}

# Test 2: Column ordering
{
    my ($out, $err, $exit) = run_pipe("a|b|c\n", '-oc2,c0');
    is($out, "c|a\n", 'Column ordering works');
}

# Test 3: Trim operation
{
    my ($out, $err, $exit) = run_pipe("  a  |  b  |  c  \n", '-tany');
    is($out, "a|b|c\n", 'Trim all columns works');
}

# Test 4: Grep operation
{
    my ($out, $err, $exit) = run_pipe("apple|1\nbanana|2\n", '-gc0:^a');
    is($out, "apple|1\n", 'Grep operation works');
}

# Test 5: Delimiter change
{
    my ($out, $err, $exit) = run_pipe("a|b|c\n", '-h:');
    is($out, "a:b:c\n", 'Delimiter change works');
}

# Test 6: Multiple operations
{
    my ($out, $err, $exit) = run_pipe("  hello  |  world  \n", '-tany -eany:uc');
    is($out, "HELLO|WORLD\n", 'Multiple operations work together');
}

done_testing();