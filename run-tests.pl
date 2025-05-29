#!/usr/bin/perl
#
# Master test runner for pipe.pl project
# Runs both Perl unit tests and shell integration tests
# Supports AI-friendly mode to minimize subprocess spawning
#
use strict;
use warnings;
use Term::ANSIColor qw(colored);
use File::Spec;
use Cwd qw(abs_path);
use Getopt::Std;

# Command line options
my %opts;
getopts('qahic', \%opts);

if ($opts{'h'}) {
    print <<"USAGE";
Usage: $0 [options]

Options:
  -a    AI-friendly mode (minimal subprocess spawning)
  -q    Quiet mode (less verbose output)
  -i    Integration tests only
  -c    Generate code coverage report (requires Devel::Cover)
  -h    Show this help

UNITIL AI mode runs everything in a single process for seamless AI tool integration.
USAGE
    exit 0;
}

# Change to script directory
my $script_dir = (File::Spec->splitpath(abs_path($0)))[1];
chdir $script_dir or die "Can't cd to $script_dir: $!";

print colored(['bold blue'], "=== Pipe.pl Test Suite ===\n\n") unless $opts{'q'};

my ($perl_tests_ok, $shell_tests_ok) = (1, 1);

if ($opts{'a'}) {
    # AI-friendly mode - run everything in this process
    ($perl_tests_ok, $shell_tests_ok) = run_ai_friendly_tests();
} else {
    # Traditional mode with subprocesses
    unless ($opts{'i'}) {
        # Run Perl unit tests
        print colored(['bold'], "Running Perl Unit Tests:\n") unless $opts{'q'};
        if ($opts{'c'}) {
            print colored(['yellow'], "(with code coverage)\n") unless $opts{'q'};
        }
        print "-" x 50, "\n" unless $opts{'q'};
        
        my $prove_result;
        if ($opts{'c'}) {
            # Check if Devel::Cover is available
            my $cover_check = system('perl -e "use Devel::Cover" 2>/dev/null');
            if ($cover_check != 0) {
                print colored(['red'], "ERROR: Devel::Cover is not installed.\n");
                print "To install: cpan Devel::Cover\n";
                print "Or on Ubuntu: sudo apt-get install libdevel-cover-perl\n";
                print "Falling back to regular test run...\n\n";
                $prove_result = system('prove -v t/');
            } else {
                # Clean previous coverage data
                system('cover -delete') if -d 'cover_db';
                
                # Run tests with coverage
                $prove_result = system('cover -test -report html_basic');
                
                if ($prove_result == 0) {
                    print colored(['green'], "\nCoverage report generated in cover_db/coverage.html\n") unless $opts{'q'};
                }
            }
        } else {
            $prove_result = system('prove -v t/');
        }
        
        $perl_tests_ok = ($prove_result == 0);
        print "\n" unless $opts{'q'};
    }
    
    # Run shell integration tests
    print colored(['bold'], "Running Shell Integration Tests:\n") unless $opts{'q'};
    print "-" x 50, "\n" unless $opts{'q'};
    chdir 'tests' or die "Can't cd to tests: $!";
    my $shell_result = system('./run-all-tests.sh');
    $shell_tests_ok = ($shell_result == 0);
}

# Summary
print "\n" unless $opts{'q'};
print colored(['bold blue'], "=== Test Summary ===\n") unless $opts{'q'};

unless ($opts{'i'}) {
    if ($perl_tests_ok) {
        print colored(['green'], "✓ Perl tests: PASSED\n");
    } else {
        print colored(['red'], "✗ Perl tests: FAILED\n");
    }
}

if ($shell_tests_ok) {
    print colored(['green'], "✓ Shell tests: PASSED\n");
} else {
    print colored(['red'], "✗ Shell tests: FAILED\n");
}

# Exit with appropriate code
exit(($perl_tests_ok && $shell_tests_ok) ? 0 : 1);

# AI-friendly test runner - everything in one process
sub run_ai_friendly_tests {
    my ($perl_ok, $shell_ok) = (1, 1);
    
    print "Running tests in AI-friendly mode...\n" unless $opts{'q'};
    
    # Run Perl tests using prove command but capture output
    unless ($opts{'i'}) {
        print "\nPERL UNIT TESTS:\n" unless $opts{'q'};
        my $prove_output = `prove -v t/ 2>&1`;
        my $prove_exit = $? >> 8;
        
        if ($prove_exit == 0) {
            print "All Perl unit tests passed.\n" unless $opts{'q'};
        } else {
            print colored(['red'], "Perl unit tests failed:\n");
            print $prove_output unless $opts{'q'};
            $perl_ok = 0;
        }
    }
    
    # Run shell tests inline
    print "\nSHELL INTEGRATION TESTS:\n" unless $opts{'q'};
    $shell_ok = run_shell_tests_inline();
    
    return ($perl_ok, $shell_ok);
}

# Run shell tests without spawning subprocesses
sub run_shell_tests_inline {
    my $pipe_cmd = "./pipe.pl";
    my ($pass, $fail) = (0, 0);
    
    # Check if pipe.pl exists
    unless (-f $pipe_cmd && -x $pipe_cmd) {
        print colored(['red'], "ERROR: pipe.pl not found or not executable\n");
        return 0;
    }
    
    # Basic tests
    my @tests = (
        ["Basic pipe handling", "a|b|c", "a|b|c", ""],
        ["Column ordering", "a|b|c", "c|a", "-oc2,c0"],
        ["Trim whitespace", "  a  |  b  |  c  ", "a|b|c", "-tany"],
        ["Grep column match", "a|b|c", "a|b|c", "-gc1:b"],
        ["Grep column no match", "a|b|c", "", "-gc1:x"],
        ["Uppercase conversion", "hello|world", "HELLO|WORLD", "-eany:uc"],
        ["Change delimiter", "a|b|c", "a:b:c", "-h:"],
        ["Multiple column trim", "  a  |  b  |  c  ", "a|  b  |c", "-tc0,c2"],
        ["Normalize column", "Hello World!|test", "HELLOWORLD|test", "-nc0"],
        ["Substring operation", "12345|abcde", "12|abcde", "-Sc0:0-2"],
    );
    
    # Complex tests with multiline input
    my @complex_tests = (
        ["Sum numeric column", "1|apple\n2|banana\n3|cherry", 
         "==       sum\n c0:       6\n1|apple\n2|banana\n3|cherry", "-ac0"],
        ["Count non-empty", "1|apple\n|banana\n3|", 
         "==     count\n c0:       2\n c1:       2\n1|apple\n|banana\n3|", "-cc0,c1"],
        ["Deduplication", "a|1\nb|2\na|3", "a|3\nb|2", "-dc0"],
        ["Line numbers", "a|b\nc|d", "  1 a|b\n  2 c|d", "-A"],
    );
    
    # Run basic tests
    for my $test (@tests) {
        my ($name, $input, $expected, $flags) = @$test;
        my $actual = run_pipe_test($pipe_cmd, $input, $flags);
        
        if ($actual eq $expected) {
            print colored(['green'], "PASS") . ": $name\n" unless $opts{'q'};
            $pass++;
        } else {
            print colored(['red'], "FAIL") . ": $name\n";
            print "  Expected: $expected\n";
            print "  Actual:   $actual\n";
            $fail++;
        }
    }
    
    # Run complex tests
    for my $test (@complex_tests) {
        my ($name, $input, $expected, $flags) = @$test;
        my $actual = run_pipe_test($pipe_cmd, $input, $flags);
        
        if ($actual eq $expected) {
            print colored(['green'], "PASS") . ": $name\n" unless $opts{'q'};
            $pass++;
        } else {
            print colored(['red'], "FAIL") . ": $name\n";
            print "  Expected: $expected\n";
            print "  Actual:   $actual\n";
            $fail++;
        }
    }
    
    # Test help flag
    my $help_output = `$pipe_cmd -x 2>&1`;
    if ($help_output =~ /usage:/) {
        print colored(['green'], "PASS") . ": Usage/help accessible (-x)\n" unless $opts{'q'};
        $pass++;
    } else {
        print colored(['red'], "FAIL") . ": Usage/help not accessible (-x)\n";
        $fail++;
    }
    
    my $total = $pass + $fail;
    print "\nTest Summary: $total tests, " . colored(['green'], "$pass passed") . ", " . 
          colored(['red'], "$fail failed") . "\n" unless $opts{'q'};
    
    return ($fail == 0);
}

# Helper function to run a single pipe test
sub run_pipe_test {
    my ($pipe_cmd, $input, $flags) = @_;
    
    # Handle multiline input
    $input =~ s/\\n/\n/g;
    
    # Use printf to handle multiline input properly
    my $cmd;
    if ($input =~ /\n/) {
        # For multiline input, use printf
        $input =~ s/'/'"'"'/g;  # Escape single quotes for shell
        $cmd = "printf '$input' | $pipe_cmd $flags 2>&1";
    } else {
        # For single line input, use echo
        $input =~ s/'/'"'"'/g;  # Escape single quotes for shell
        $cmd = "echo '$input' | $pipe_cmd $flags 2>&1";
    }
    
    my $output = `$cmd`;
    chomp $output if defined $output;
    return $output || '';
}