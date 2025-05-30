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
print "Running unit tests with coverage...\n" unless $opts{'q'};

my $total_output = '';
my $failed = 0;

# Get all test files
opendir(my $dh, 't/') or die "Can't open t/ directory: $!";
my @test_files = sort grep { /\.t$/ } readdir($dh);
closedir($dh);

# Run each test file with coverage using the standard approach
foreach my $test_file (@test_files) {
    my $cmd = 'carton exec -- perl '
        . '-MDevel::Cover=-db,cover_db,'
        . '-select,^lib/Pipe/,^pipe\.pl,'
        . '+ignore,^local/lib/perl5/,+ignore,t/ '
        . '-Ilib t/' . $test_file;
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
    print STDERR "Some tests failed but continuing to generate coverage report:\n" unless $opts{'q'};
    print STDERR $output unless $opts{'q'};
}

print $output unless $opts{'q'};

# Run integration tests to capture pipe.pl script coverage
print "\nRunning pipe.pl script coverage tests...\n" unless $opts{'q'};

# Create simple tests that run pipe.pl through carton to capture script coverage
my @pipe_tests = (
    ['echo "a|b|c" | carton exec -- perl '
    . '-MDevel::Cover=-db,cover_db,'
    . '-select,^lib/Pipe/,^pipe\.pl,'
    . '+ignore,^local/lib/perl5/,+ignore,t/ '
    . './pipe.pl', 'Basic execution'],

    ['echo "a|b|c" | carton exec -- perl '
    . '-MDevel::Cover=-db,cover_db,'
    . '-select,^lib/Pipe/,^pipe\.pl,'
    . '+ignore,^local/lib/perl5/,+ignore,t/ '
    . './pipe.pl -oc2,c0', 'Column ordering'],

    ['echo "  a  |  b  " | carton exec -- perl '
    . '-MDevel::Cover=-db,cover_db,'
    . '-select,^lib/Pipe/,^pipe\.pl,'
    . '+ignore,^local/lib/perl5/,+ignore,t/ '
    . './pipe.pl -tany', 'Trim operation'],

    ['carton exec -- perl '
    . '-MDevel::Cover=-db,cover_db,'
    . '-select,^lib/Pipe/,^pipe\.pl,'
    . '+ignore,^local/lib/perl5/,+ignore,t/ '
    . './pipe.pl -x', 'Usage display'],
);

foreach my $test (@pipe_tests) {
    my ($cmd, $desc) = @$test;
    print "  Running: $desc...\n" unless $opts{'q'};
    my $test_output = `$cmd 2>/dev/null`;
    # We don't care about the exit code, just that coverage was collected
}

# Generate coverage reports
print "\nGenerating coverage reports...\n" unless $opts{'q'};

# Generate HTML report for human viewing
my $cover_cmd = "carton exec -- cover -report html_minimal";
my $cover_output = `$cover_cmd 2>&1`;
my $cover_exit = $? >> 8;

if ($cover_exit != 0) {
    print STDERR "Coverage report generation failed:\n";
    print STDERR $cover_output;
    exit $cover_exit;
}

# Generate JSON detailed report for AI analysis
my $json_cmd = "carton exec -- cover -report json_detailed";
my $json_output = `$json_cmd 2>&1`;
my $json_exit = $? >> 8;

if ($json_exit != 0) {
    print "\nNote: JSON detailed coverage report failed. Run 'carton install' to install dependencies.\n" unless $opts{'q'};
    print STDERR $json_output unless $opts{'q'};
} else {
    print "JSON detailed report generated successfully\n" unless $opts{'q'};
}

print $cover_output unless $opts{'q'};

# Filter the HTML to only show our modules
if (-f "cover_db/coverage.html") {
    my $html_content = do {
        local $/;
        open my $fh, '<', 'cover_db/coverage.html';
        <$fh>;
    };

    # Uncomment to filter to only include lib/Pipe/ and pipe.pl entries
    # $html_content =~ s/<tr><td[^>]*><a[^>]*>(?!(?:lib\/Pipe\/|pipe\.pl))[^<]*<\/a>.*?<\/tr>\n//gs;
    # $html_content =~ s/<tr><td[^>]*>(?!(?:lib\/Pipe\/|pipe\.pl|Total))[^<]*<\/td>.*?<\/tr>\n//gs;

    # Write the filtered HTML back
    open my $fh, '>', 'cover_db/coverage.html';
    print $fh $html_content;
    close $fh;

    print "\nCoverage reports generated:\n";
    print "  HTML: cover_db/coverage.html (open with: open cover_db/coverage.html)\n";
    if ($json_exit == 0) {
        print "  JSON: cover_db/cover_detailed.json (for AI analysis)\n";
    }
} else {
    print "Coverage report file not found.\n";
}

exit 0;