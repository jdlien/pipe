#!/usr/bin/perl
#
# Basic test to ensure our test infrastructure works
# This will be updated once we have actual modules to test
#
use strict;
use warnings;
use Test::More tests => 3;

# Test that Test::More is working
ok(1, 'Test::More is loaded and working');

# Test basic Perl functionality
is(2 + 2, 4, 'Basic math works');

# Test that we can access the lib directory
use lib 'lib';
ok(1, 'Can use lib directory');

# Once we have modules, we'll test loading them here:
# BEGIN { use_ok('Pipe::Core') }

diag("Testing Perl $], Test::More $Test::More::VERSION");