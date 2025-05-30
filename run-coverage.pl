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

# Create comprehensive tests that run pipe.pl through carton to capture script coverage
my $cover_args = '-MDevel::Cover=-db,cover_db,'
    . '-select,^lib/Pipe/,^pipe\.pl,'
    . '+ignore,^local/lib/perl5/,+ignore,t/ ';

my @pipe_tests = (
    # Basic functionality
    ['echo "a|b|c" | carton exec -- perl ' . $cover_args . './pipe.pl', 'Basic execution'],
    ['carton exec -- perl ' . $cover_args . './pipe.pl -x', 'Usage display'],
    ['carton exec -- perl ' . $cover_args . './pipe.pl -D < /dev/null', 'Debug flag'],
    
    # Column operations
    ['echo "a|b|c" | carton exec -- perl ' . $cover_args . './pipe.pl -oc2,c0', 'Column ordering'],
    ['echo "a|b|c" | carton exec -- perl ' . $cover_args . './pipe.pl -oc0', 'Single column'],
    ['echo "hello|world" | carton exec -- perl ' . $cover_args . './pipe.pl -uc0', 'Uppercase column'],
    ['echo "HELLO|WORLD" | carton exec -- perl ' . $cover_args . './pipe.pl -lc0', 'Lowercase column'],
    
    # Text operations
    ['echo "  a  |  b  " | carton exec -- perl ' . $cover_args . './pipe.pl -tany', 'Trim operation'],
    ['echo "  hello  |  world  " | carton exec -- perl ' . $cover_args . './pipe.pl -nc0', 'Normalize column'],
    
    # Math operations
    ['echo -e "1|2\n3|4" | carton exec -- perl ' . $cover_args . './pipe.pl -ac0', 'Sum operation'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -cc0', 'Count operation'],
    ['echo -e "1|2\n3|4\n5|6" | carton exec -- perl ' . $cover_args . './pipe.pl -vc0', 'Average operation'],
    ['echo -e "1|2\n3|4" | carton exec -- perl ' . $cover_args . './pipe.pl -1c0', 'Increment operation'],
    
    # Pattern matching
    ['echo -e "a|1\nb|2\na|3" | carton exec -- perl ' . $cover_args . './pipe.pl -gc0:a', 'Grep operation'],
    ['echo -e "a|1\nb|2\na|3" | carton exec -- perl ' . $cover_args . './pipe.pl -Gc0:b', 'Not grep operation'],
    ['echo -e "abc|def\nxyz|uvw" | carton exec -- perl ' . $cover_args . './pipe.pl -Xc0:^a', 'Match start'],
    
    # Data operations
    ['echo -e "b|2\na|1\nc|3" | carton exec -- perl ' . $cover_args . './pipe.pl -s', 'Sort operation'],
    ['echo -e "a|1\na|1\nb|2" | carton exec -- perl ' . $cover_args . './pipe.pl -d', 'Dedup operation'],
    ['echo -e "header|info\ndata|value" | carton exec -- perl ' . $cover_args . './pipe.pl -H1', 'Header skip'],
    ['echo -e "line1|a\nline2|b\nline3|c" | carton exec -- perl ' . $cover_args . './pipe.pl -T1', 'Tail operation'],
    
    # More comprehensive flag testing
    ['echo -e "1|2\n3|4" | carton exec -- perl ' . $cover_args . './pipe.pl -2c0:5', 'Auto increment'],
    ['echo -e "1|2\n3|4" | carton exec -- perl ' . $cover_args . './pipe.pl -3c0:2', 'Qualified increment'],
    ['echo -e "1|2\n3|4\n5|6" | carton exec -- perl ' . $cover_args . './pipe.pl -4c0', 'Delta operation'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -5', 'Line count'],
    ['echo -e "a|1\nb|2\na|3" | carton exec -- perl ' . $cover_args . './pipe.pl -6c0', 'Histogram'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -7', 'Match limit'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -8', 'Flag 8'],
    
    # Advanced operations
    ['echo -e "1.5|2.7\n3.2|4.1" | carton exec -- perl ' . $cover_args . './pipe.pl -Ac0', 'Average after processing'],
    ['echo -e "aa|bb\nab|cd" | carton exec -- perl ' . $cover_args . './pipe.pl -bc0', 'Begins with comparison'],
    ['echo -e "aa|bb\nab|cd" | carton exec -- perl ' . $cover_args . './pipe.pl -Bc0', 'Not begins with comparison'],
    ['echo -e "1|2\n6|7\n3|4" | carton exec -- perl ' . $cover_args . './pipe.pl -Cc0:>5', 'Conditional comparison'],
    ['echo "HELLO|WORLD" | carton exec -- perl ' . $cover_args . './pipe.pl -ec0:lower', 'Case conversion'],
    ['echo -e "cat|dog\nrat|pig" | carton exec -- perl ' . $cover_args . './pipe.pl -Ec0:s/a/b/', 'Replace pattern'],
    ['echo "abc|def" | carton exec -- perl ' . $cover_args . './pipe.pl -fc0', 'Flip operation'],
    ['echo "123|456" | carton exec -- perl ' . $cover_args . './pipe.pl -Fc0', 'Format operation'],
    ['echo "a,b,c" | carton exec -- perl ' . $cover_args . './pipe.pl -h,', 'Custom delimiter'],
    ['echo "a|b|c" | carton exec -- perl ' . $cover_args . './pipe.pl -iany', 'Information flag'],
    ['echo "a|b|c" | carton exec -- perl ' . $cover_args . './pipe.pl -I', 'Case insensitive'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -jc0', 'Join operation'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -J', 'Join all'],
    ['echo "hello|world" | carton exec -- perl ' . $cover_args . './pipe.pl -kc0:\'$value = uc($value);\'', 'Script execution'],
    ['echo "a|b|c" | carton exec -- perl ' . $cover_args . './pipe.pl -K', 'Keep header'],
    ['echo "hello|world" | carton exec -- perl ' . $cover_args . './pipe.pl -lc0:a-z:A-Z', 'Translate operation'],
    ['echo -e "line1|a\nline2|b\nline3|c" | carton exec -- perl ' . $cover_args . './pipe.pl -Lc0:1-2', 'Line range'],
    ['echo "123456789|data" | carton exec -- perl ' . $cover_args . './pipe.pl -mc0:###-##-####', 'Mask operation'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -Mc0', 'Merge flag'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -N', 'Normalize flag'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -Oc0', 'Merge columns'],
    ['echo "hello|world" | carton exec -- perl ' . $cover_args . './pipe.pl -pc0:10', 'Pad operation'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -P', 'Pad all'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -qc0', 'Join count'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -Q1000', 'Buffer size'],
    ['echo -e "a|b\nc|d\ne|f\ng|h" | carton exec -- perl ' . $cover_args . './pipe.pl -r50', 'Random selection'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -R', 'Reverse flag'],
    ['echo -e "cat|dog\nrat|pig" | carton exec -- perl ' . $cover_args . './pipe.pl -Sc0:s/a/b/', 'Substitute pattern'],
    ['echo "hello|world" | carton exec -- perl ' . $cover_args . './pipe.pl -uc0', 'Uppercase'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -U', 'Uppercase all'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -V', 'Verbose flag'],
    ['echo "hello|world" | carton exec -- perl ' . $cover_args . './pipe.pl -wc0', 'Width operation'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -W', 'Width all'],
    ['echo "1.234567|2.345678" | carton exec -- perl ' . $cover_args . './pipe.pl -yc0', 'Precision'],
    ['echo -e "abc|def\nxyz|uvw" | carton exec -- perl ' . $cover_args . './pipe.pl -Yc0:a', 'Match Y operation'],
    ['echo -e "a||\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -zc0', 'Empty columns'],
    ['echo -e "a||\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -Zc0', 'Show empty columns'],
    
    # Error conditions and edge cases
    ['echo "a|b|c" | carton exec -- perl ' . $cover_args . './pipe.pl -oc999', 'Invalid column index'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -H999', 'Large header skip'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -T999', 'Large tail count'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -Q0', 'Zero buffer size'],
    ['echo "1.234|5.678" | carton exec -- perl ' . $cover_args . './pipe.pl -y0', 'Zero precision'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -r0', 'Zero random percentage'],
    ['echo -e "a|b\nc|d" | carton exec -- perl ' . $cover_args . './pipe.pl -r100', 'Full random percentage'],
    
    # Complex combinations
    ['echo "hello|world" | carton exec -- perl ' . $cover_args . './pipe.pl -oc0 -uc0', 'Column order and uppercase'],
    ['echo -e "apple|fruit\nbanana|fruit" | carton exec -- perl ' . $cover_args . './pipe.pl -gc0:a -uc0', 'Grep and uppercase'],
    ['echo -e "3|b\n1|a\n2|c" | carton exec -- perl ' . $cover_args . './pipe.pl -ac0 -oc1,c0', 'Sum and reorder'],
    ['echo -e "header|info\ndata|value" | carton exec -- perl ' . $cover_args . './pipe.pl -H1 -oc0', 'Skip header and order'],
    ['echo "  hello  |  world  " | carton exec -- perl ' . $cover_args . './pipe.pl -tany -uc0', 'Trim and uppercase'],
    
    # Debug combinations
    ['echo "a|b|c" | carton exec -- perl ' . $cover_args . './pipe.pl -D -oc0', 'Debug with column order'],
    ['echo -e "1|2\n3|4" | carton exec -- perl ' . $cover_args . './pipe.pl -D -ac0', 'Debug with sum'],
    ['echo "abc|def" | carton exec -- perl ' . $cover_args . './pipe.pl -D -gc0:a', 'Debug with grep'],
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