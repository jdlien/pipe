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
# Run each test file directly with coverage to ensure proper collection
print "Running unit tests with coverage...\n" unless $opts{'q'};

my $total_output = '';
my $failed = 0;

# Get all test files
opendir(my $dh, 't/') or die "Can't open t/ directory: $!";
my @test_files = sort grep { /\.t$/ } readdir($dh);
closedir($dh);

# Run each test file with coverage
foreach my $test_file (@test_files) {
    my $cmd = "carton exec -- perl -MDevel::Cover=-db,cover_db,+select,^lib/Pipe/,+ignore,t/ -Ilib t/$test_file";
    print "  Running $test_file...\n" unless $opts{'q'};
    my $output = `$cmd 2>&1`;
    my $exit_code = $? >> 8;
    
    if ($exit_code != 0) {
        $failed++;
        print STDERR "Test $test_file failed:\n$output\n";
    } else {
        $total_output .= "t/$test_file ... ok\n";
    }
}

my $output = $total_output;
my $exit_code = $failed;

if ($exit_code != 0) {
    print STDERR "Tests failed with coverage enabled:\n";
    print STDERR $output;
    exit $exit_code;
}

print $output unless $opts{'q'};

# Generate coverage report filtered to our modules only
print "\nGenerating coverage report...\n" unless $opts{'q'};
# Generate full report then filter HTML - this ensures we get all module data
my $cover_cmd = "carton exec -- cover -report html_minimal";
my $cover_output = `$cover_cmd 2>&1`;
my $cover_exit = $? >> 8;

if ($cover_exit != 0) {
    print STDERR "Coverage report generation failed:\n";
    print STDERR $cover_output;
    exit $cover_exit;
}

print $cover_output unless $opts{'q'};

# Filter the HTML to only show our modules
if (-f "cover_db/coverage.html") {
    my $html_content = do {
        local $/;
        open my $fh, '<', 'cover_db/coverage.html';
        <$fh>;
    };
    
    # Filter to only include lib/Pipe/ and pipe.pl entries
    $html_content =~ s/<tr><td[^>]*><a[^>]*>(?!(?:lib\/Pipe\/|pipe\.pl))[^<]*<\/a>.*?<\/tr>\n//gs;
    $html_content =~ s/<tr><td[^>]*>(?!(?:lib\/Pipe\/|pipe\.pl|Total))[^<]*<\/td>.*?<\/tr>\n//gs;
    
    # Write the filtered HTML back
    open my $fh, '>', 'cover_db/coverage.html';
    print $fh $html_content;
    close $fh;
    
    print "\nCoverage report generated: cover_db/coverage.html\n";
    print "Open with: open cover_db/coverage.html\n";
} else {
    print "Coverage report file not found.\n";
}

exit 0;