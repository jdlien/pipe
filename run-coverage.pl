#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Std;

my %opts;
getopts('hq', \%opts);

if ($opts{'h'}) {
    print <<EOF;
Usage: $0 [-h] [-q]

Generate code coverage report for pipe.pl project.

Options:
  -h    Show this help
  -q    Quiet mode (minimal output)

This script uses carton to run tests with Devel::Cover.
EOF
    exit 0;
}

# Check if carton is available
unless (system("which carton > /dev/null 2>&1") == 0) {
    print STDERR "ERROR: carton not found. Install with: brew install carton\n";
    exit 1;
}

# Clean up any previous coverage data
if (-d "cover_db") {
    print "Cleaning previous coverage data...\n" unless $opts{'q'};
    system("rm -rf cover_db");
}

print "Running tests with code coverage...\n" unless $opts{'q'};

# Run tests with coverage using carton
# Focus coverage on our project files only
my $cmd = "carton exec -- perl -MDevel::Cover=+select,^lib/,-silent,1 -Ilib -S prove -l t/";
print "Executing: $cmd\n" if !$opts{'q'};

my $output = `$cmd 2>&1`;
my $exit_code = $? >> 8;

if ($exit_code != 0) {
    print STDERR "Tests failed with coverage enabled:\n";
    print STDERR $output;
    exit $exit_code;
}

print $output unless $opts{'q'};

# Generate coverage report
print "\nGenerating coverage report...\n" unless $opts{'q'};
my $cover_cmd = "carton exec -- cover";
my $cover_output = `$cover_cmd 2>&1`;
my $cover_exit = $? >> 8;

if ($cover_exit != 0) {
    print STDERR "Coverage report generation failed:\n";
    print STDERR $cover_output;
    exit $cover_exit;
}

print $cover_output unless $opts{'q'};

if (-f "cover_db/coverage.html") {
    print "\nCoverage report generated: cover_db/coverage.html\n";
    print "Open with: open cover_db/coverage.html\n";
} else {
    print "Coverage report file not found.\n";
}

exit 0;