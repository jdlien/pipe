#!/usr/bin/perl
use strict;
use warnings;

my $line = "c2,c0";
my @list = ();
$line .= "," if ( $line !~ m/,/ );
my @cols = split( /\s?,\s?/, $line );
print "Split into: " . join(" | ", @cols) . "\n";

foreach my $colNum ( @cols ) {
    print "Processing: '$colNum'\n";
    if ( $colNum =~ m/c([0-9]+)/ ) {
        print "  Found column: $1\n";
        push @list, $1;
    }
}
print "Final list: " . join(" ", @list) . "\n";