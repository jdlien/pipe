#!/usr/bin/perl
#
# Master test runner for pipe.pl project
# Runs both Perl unit tests and shell integration tests
#
use strict;
use warnings;
use Term::ANSIColor qw(colored);
use File::Spec;
use Cwd qw(abs_path);

# Change to script directory
my $script_dir = (File::Spec->splitpath(abs_path($0)))[1];
chdir $script_dir or die "Can't cd to $script_dir: $!";

print colored(['bold blue'], "=== Pipe.pl Test Suite ===\n\n");

# Run Perl unit tests
print colored(['bold'], "Running Perl Unit Tests:\n");
print "-" x 50, "\n";
my $prove_result = system('prove -v t/');
my $perl_tests_ok = ($prove_result == 0);

print "\n";

# Run shell integration tests
print colored(['bold'], "Running Shell Integration Tests:\n");
print "-" x 50, "\n";
chdir 'tests' or die "Can't cd to tests: $!";
my $shell_result = system('./run-all-tests.sh');
my $shell_tests_ok = ($shell_result == 0);

# Summary
print "\n";
print colored(['bold blue'], "=== Test Summary ===\n");

if ($perl_tests_ok) {
    print colored(['green'], "✓ Perl tests: PASSED\n");
} else {
    print colored(['red'], "✗ Perl tests: FAILED\n");
}

if ($shell_tests_ok) {
    print colored(['green'], "✓ Shell tests: PASSED\n");
} else {
    print colored(['red'], "✗ Shell tests: FAILED\n");
}

# Exit with appropriate code
exit(($perl_tests_ok && $shell_tests_ok) ? 0 : 1);