package Pipe::Text;
use strict;
use warnings;
use utf8;
use Pipe::Core qw(:constants :keywords);

require Exporter;
our @ISA = qw(Exporter);

# Export all text processing functions
our @EXPORT = qw(
    trim_line normalize_line apply_mask mask_line
    sub_string_line sub_string apply_padding pad_line
    apply_casing modify_case_line flip_char_line apply_flip
    replace_line replace translate_line url_encode_line
    normalize
);

our $VERSION = '2.03.02';

=head1 NAME

Pipe::Text - Text processing operations for pipe.pl

=head1 SYNOPSIS

    use Pipe::Text;
    
    # Trim whitespace from line
    my @trimmed = trim_line(@fields);
    
    # Apply case transformations
    my $result = apply_casing($input, $case_type);
    
    # Apply text masks
    my $masked = apply_mask($text, $mask_pattern);

=head1 DESCRIPTION

This module provides text processing functions for pipe.pl, including case
transformations, text trimming, normalization, masking, padding, substring
operations, and character replacements.

=head1 FUNCTIONS

=cut

# ===================================================
# Text Trimming Operations
# ===================================================

=head2 trim_line

Trims whitespace from specified columns in a line.

=cut

sub trim_line {
    my $line_ref = shift;
    my $trim_cols_ref = shift || \@main::TRIM_COLUMNS;
    my @in_line = @$line_ref;
    my @out_line = ();
    
    foreach my $column_index (0..$#in_line) {
        my $value = $in_line[$column_index];
        
        # Check if we should trim this column
        # Condition 1: Column index is explicitly listed
        my $explicit_match = (@$trim_cols_ref && grep { /^\d+$/ && $_ == $column_index } @$trim_cols_ref);
        # Condition 2: "any" keyword is used
        my $any_keyword = (@$trim_cols_ref && $trim_cols_ref->[0] eq $KEYWORD_ANY);
        # Condition 3: -y flag (trim all numeric values)
        my $y_flag = ($main::opt{'y'} || 0);
        
        if ($explicit_match || $any_keyword || $y_flag) {
            
            # Use trim function from Pipe::Core
            $value = Pipe::Core::trim($value);
            
            # Handle precision for numeric formatting
            if (defined $main::PRECISION && $main::PRECISION ne "") {
                if (Pipe::Core::is_number($value)) {
                    $value = sprintf("%.${main::PRECISION}f", $value);
                }
            }
        }
        push @out_line, $value;
    }
    
    # Modify the original array in place
    @$line_ref = @out_line;
}

=head2 normalize_line

Removes non-word characters from specified columns.

=cut

sub normalize_line {
    my $line_ref = shift;
    my $normal_cols_ref = shift || \@main::NORMAL_COLUMNS;
    my @in_line = @$line_ref;
    my @out_line = ();
    
    foreach my $column_index (0..$#in_line) {
        my $value = $in_line[$column_index];
        
        # Check if we should normalize this column
        my $explicit_match = (@$normal_cols_ref && grep { /^\d+$/ && $_ == $column_index } @$normal_cols_ref);
        my $any_keyword = (@$normal_cols_ref && $normal_cols_ref->[0] eq $KEYWORD_ANY);
        
        if ($explicit_match || $any_keyword) {
            $value = normalize($value);
        }
        push @out_line, $value;
    }
    
    # Modify the original array in place
    @$line_ref = @out_line;
}

=head2 normalize

Helper function to remove non-word characters and convert to uppercase.

=cut

sub normalize {
    my $line = shift;
    $line =~ s/\W//g;
    if (!$main::opt{'I'}) {
        $line = uc($line);
    }
    return $line;
}

# ===================================================
# Text Masking Operations
# ===================================================

=head2 apply_mask

Applies character masking to strings using placeholders.

=cut

sub apply_mask {
    my ($line, $mask) = @_;
    my $out_line = "";
    my @line_array = split //, $line;
    my @mask_array = split //, $mask;
    
    for my $position (0..$#mask_array) {
        my $mask_char = $mask_array[$position];
        my $line_char = "";
        
        if ($position <= $#line_array) {
            $line_char = $line_array[$position];
        }
        
        if ($mask_char eq '#') {
            # Numeric characters only
            if ($line_char =~ /\d/) {
                $out_line .= $line_char;
            } elsif ($main::opt{'y'}) {
                # Zero pad if requested
                $out_line .= "0";
            }
        } elsif ($mask_char eq '_') {
            # Alphabetic characters only
            if ($line_char =~ /[a-zA-Z]/) {
                $out_line .= $line_char;
            } elsif ($main::opt{'y'}) {
                # Space pad if requested
                $out_line .= " ";
            }
        } elsif ($mask_char eq '@') {
            # Any character
            if ($line_char ne "") {
                $out_line .= $line_char;
            } elsif ($main::opt{'y'}) {
                # Space pad if requested
                $out_line .= " ";
            }
        } else {
            # Literal character from mask
            $out_line .= $mask_char;
        }
    }
    
    # Handle precision for numeric results
    if (defined $main::PRECISION && $main::PRECISION ne "") {
        if (Pipe::Core::is_number($out_line)) {
            $out_line = sprintf("%.${main::PRECISION}f", $out_line);
        }
    }
    
    return $out_line;
}

=head2 mask_line

Applies masking to specified columns in a line.

=cut

sub mask_line {
    my @in_line = @_;
    my @out_line = ();
    
    foreach my $column_index (0..$#in_line) {
        my $value = $in_line[$column_index];
        
        if (defined $main::mask_ref && exists $main::mask_ref->{$column_index}) {
            my $mask = $main::mask_ref->{$column_index};
            $value = apply_mask($value, $mask);
        } elsif (defined $main::mask_ref && exists $main::mask_ref->{$main::KEYWORD_ANY}) {
            my $mask = $main::mask_ref->{$main::KEYWORD_ANY};
            $value = apply_mask($value, $mask);
        }
        
        push @out_line, $value;
    }
    
    return @out_line;
}

# ===================================================
# Substring Operations
# ===================================================

=head2 sub_string_line

Extracts substrings from specified columns in a line.

=cut

sub sub_string_line {
    my @in_line = @_;
    my @out_line = ();
    
    foreach my $column_index (0..$#in_line) {
        my $value = $in_line[$column_index];
        
        if (defined $main::subs_ref && exists $main::subs_ref->{$column_index}) {
            my $range = $main::subs_ref->{$column_index};
            $value = sub_string($value, $range);
        }
        
        push @out_line, $value;
    }
    
    return @out_line;
}

=head2 sub_string

Extracts substring from text using range specification.

=cut

sub sub_string {
    my ($in_line, $range) = @_;
    
    if ($main::opt{'D'}) {
        print STDERR "sub_string(): input='$in_line', range='$range'\n";
    }
    
    my $line_length = length($in_line);
    my ($start, $end);
    
    # Parse range specification
    if ($range =~ /^(-?\d+)-(-?\d+)$/) {
        # Range: start-end
        $start = $1;
        $end = $2;
    } elsif ($range =~ /^(-?\d+)-$/) {
        # Range: start to end of string
        $start = $1;
        $end = $line_length;
    } elsif ($range =~ /^-(-?\d+)$/) {
        # Range: from beginning to end
        $start = 1;
        $end = $1;
    } elsif ($range =~ /^(-?\d+)$/) {
        # Single character
        $start = $1;
        $end = $1;
    } else {
        print STDERR "** Error: Invalid substring range '$range'\n";
        return $in_line;
    }
    
    # Handle negative indices (from end)
    if ($start < 0) {
        $start = $line_length + $start + 1;
    }
    if ($end < 0) {
        $end = $line_length + $end + 1;
    }
    
    # Convert to 0-based indexing
    $start--;
    $end--;
    
    # Validate bounds
    if ($start < 0) { $start = 0; }
    if ($end >= $line_length) { $end = $line_length - 1; }
    if ($start > $end) { return ""; }
    
    my $length = $end - $start + 1;
    my $result = substr($in_line, $start, $length);
    
    if ($main::opt{'D'}) {
        print STDERR "sub_string(): start=$start, end=$end, length=$length, result='$result'\n";
    }
    
    return $result;
}

# ===================================================
# Text Padding Operations
# ===================================================

=head2 apply_padding

Pads strings with specified characters to a given length.

=cut

sub apply_padding {
    my ($in_line, $pad_spec) = @_;
    
    if ($main::opt{'D'}) {
        print STDERR "apply_padding(): input='$in_line', spec='$pad_spec'\n";
    }
    
    # Parse padding specification: length[char]
    my ($length, $char) = ("", " ");
    
    if ($pad_spec =~ /^(\d+)(.?)$/) {
        $length = $1;
        $char = $2 if $2 ne "";
    } else {
        print STDERR "** Error: Invalid padding specification '$pad_spec'\n";
        return $in_line;
    }
    
    my $current_length = length($in_line);
    
    if ($current_length >= $length) {
        return $in_line;
    }
    
    my $pad_length = $length - $current_length;
    my $padding = $char x $pad_length;
    
    # Right pad by default
    my $result = $in_line . $padding;
    
    if ($main::opt{'D'}) {
        print STDERR "apply_padding(): length=$length, char='$char', result='$result'\n";
    }
    
    return $result;
}

=head2 pad_line

Applies padding to specified columns in a line.

=cut

sub pad_line {
    my @in_line = @_;
    my @out_line = ();
    
    foreach my $column_index (0..$#in_line) {
        my $value = $in_line[$column_index];
        
        if (defined $main::pad_ref && exists $main::pad_ref->{$column_index}) {
            my $spec = $main::pad_ref->{$column_index};
            $value = apply_padding($value, $spec);
        }
        
        push @out_line, $value;
    }
    
    return @out_line;
}

# ===================================================
# Case Transformation Operations
# ===================================================

=head2 apply_casing

Applies case transformations to text.

=cut

sub apply_casing {
    my ($line, $case_type) = @_;
    my $out_line = $line;
    
    if ($case_type eq "uc") {
        $out_line = uc($line);
    } elsif ($case_type eq "lc") {
        $out_line = lc($line);
    } elsif ($case_type eq "mc") {
        # Mixed case - capitalize first letter of each word
        $out_line = lc($line);
        $out_line =~ s/\b(\w)/uc($1)/ge;
    } elsif ($case_type eq "us") {
        # Underscore - replace spaces with underscores
        $out_line =~ s/\s+/_/g;
    } elsif ($case_type eq "spc") {
        # Space - replace underscores with spaces
        $out_line =~ s/_/ /g;
    } elsif ($case_type eq "pipe") {
        # Pipe - replace spaces/commas with pipe delimiter
        $out_line =~ s/[\s,]+/|/g;
    } elsif ($case_type eq "csv") {
        # CSV format with proper quoting
        if ($out_line =~ /[,"']/) {
            $out_line =~ s/"/""/g;  # Escape quotes
            $out_line = '"' . $out_line . '"';
        }
        # Replace delimiter with comma
        $out_line =~ s/\Q$main::DELIMITER\E/,/g;
    } elsif ($case_type =~ /^normal_(.+)$/) {
        # Normalize and apply case
        my $sub_case = $1;
        $out_line = normalize($out_line);
        $out_line = apply_casing($out_line, $sub_case);
    } elsif ($case_type =~ /^order_(.+)$/) {
        # Sort characters and apply case
        my $sub_case = $1;
        my @chars = sort split //, $out_line;
        $out_line = join('', @chars);
        $out_line = apply_casing($out_line, $sub_case);
    } elsif ($case_type eq "collapse") {
        # Collapse multiple spaces
        $out_line =~ s/\s+/ /g;
        $out_line =~ s/^\s+|\s+$//g;
    }
    
    return $out_line;
}

=head2 modify_case_line

Applies case modifications to specified columns in a line.

=cut

sub modify_case_line {
    my $line = shift;
    my $case_ref = shift || \%main::case_ref;
    my $i    = 0;
    my $exp  = "";
    
    for ( $i = 0; $i < scalar( @{ $line } ); $i++ )
    {
        my $should_apply = 0;
        if ( exists $case_ref->{ $i } ) {
            $exp = $case_ref->{ $i };
            $should_apply = 1;
        } elsif ( exists $case_ref->{ $KEYWORD_ANY } ) {
            $exp = $case_ref->{ $KEYWORD_ANY };
            $should_apply = 1;
        }
        
        if ( $should_apply ) {
            if ( $exp !~ m/(csv|lc|mc|uc|us|spc|csv|pipe|normal_[Ww,Ss,Dd,Pp,Qq,QQ]|order_\w+-\w+|collapse)/ )
            {
                printf STDERR "*** error case specifier. Expected (csv|lc|mc|uc|us|spc|csv|pipe|normal_(W|w,S|s,D|d,p|q|Q)|order_{xyz}-{zyx}|collapse) but got '%s'.\n", $case_ref->{ $i };
                exit;
            }
            @{ $line }[ $i ] = Pipe::Text::apply_casing( @{ $line }[ $i ], $exp );
        }
    }
    if ( $exp eq 'collapse' ) 
    {
        my @clean = ();
        for ( $i = 0; $i < scalar( @{ $line } ); $i++ )
        {
            next if ( ! defined @{ $line }[ $i ] or @{ $line }[ $i ] =~ m/^\s*$/ );
            push @clean, @{ $line }[ $i ];
        }
        @{ $line } = @clean;
    }
}

# ===================================================
# Character Flipping Operations
# ===================================================

=head2 flip_char_line

Conditionally flips specific characters at given positions.

=cut

sub flip_char_line {
    my $line = shift;
    my $i    = 0;
    for ( $i = 0; $i < scalar( @{ $line } ); $i++ )
    {
        if ( exists $main::flip_ref->{ $i } )
        {
            printf STDERR "flip expression: '%s' \n", $main::flip_ref->{ $i } if ( $main::opt{'D'} );
            my $exp = $main::flip_ref->{ $i };
            my $char_index;
            my $test;
            my $condition_true;
            my $condition_false;
            if ( $exp =~ m/\?/ )
            {
                ( $char_index, $test ) = split '\.', $`;
                ( $condition_true, $condition_false ) = split( m/(?<!\\)\./, $' );
                $condition_true   =~ s/\\//g; # Strip off the '\' if the delimiter '.' is part of the change.
                $condition_false     =~ s/\\//g if ( defined $condition_false );
            }
            else # simple case of n.p
            {
                ( $char_index, $test ) = split '\.', $exp;
            }
            if ( ! defined $char_index or ! defined $test )
            {
                printf STDERR "*** syntax error in -f, expected '{integer index}.{test|value}' but got '%s'\n", $exp;
                exit;
            }
            if ( $main::opt{'D'} )
            {
                printf STDERR " index='%s'", $char_index if ( defined $char_index );
                printf STDERR " value='%s'", $test if ( defined $test );
                printf STDERR " true='%s'", $condition_true if ( defined $condition_true );
                printf STDERR " false='%s'", $condition_false if ( defined $condition_false );
                printf STDERR "\n";
            }
            @{ $line }[ $i ] = apply_flip( @{ $line }[ $i ], $char_index, $test, $condition_true, $condition_false );
        }
    }
}

=head2 apply_flip

Helper for character flipping operations.

=cut

sub apply_flip {
    my ( $field, $char_index, $test_char, $condition_true, $condition_false ) = @_;
    # field, char_index and test_char must be defined, condition_true and condition_false may not be.
    if ( $char_index !~ m/^\d{1,}$/ )
    {
        printf STDERR "*** syntax error in -f, expected integer index but got '%s'\n", $char_index;
        exit;
    }
    my @f = split //, $field;
    return $field if ( $char_index >= @f ); # if the char_index site is past the end of the field just return it untouched.
    my $site = $f[ $char_index ];
    if ( defined $condition_true )
    {
        if ( $main::opt{'I'} )
        {
            $test_char = lc $test_char;
            $site = lc $site;
        }
        if ( $site eq $test_char )
        {
            $f[ $char_index ] = $condition_true;
        }
        else
        {
            if ( defined $condition_false )
            {
                $f[ $char_index ] = $condition_false;
            }
        }
    }
    else # Unconditionally change the site's character.
    {
        $f[ $char_index ] = $test_char;
    }
    return join '', @f;
}

# ===================================================
# String Replacement Operations
# ===================================================

=head2 replace_line

Applies conditional string replacement to columns.

=cut

sub replace_line {
    my @in_line = @_;
    my @out_line = ();
    
    foreach my $column_index (0..$#in_line) {
        my $value = $in_line[$column_index];
        
        if (defined $main::replace_ref && exists $main::replace_ref->{$column_index}) {
            my $replace_spec = $main::replace_ref->{$column_index};
            $value = replace($value, $replace_spec);
        }
        
        push @out_line, $value;
    }
    
    if ($main::opt{'D'}) {
        print STDERR "replace_line(): result=(" . join(",", @out_line) . ")\n";
    }
    
    return @out_line;
}

=head2 replace

Helper for conditional string replacement.

=cut

sub replace {
    my ( $field, $replacement, $condition, $on_else ) = @_;
    if ( defined $condition )
    {
        if ( $condition eq $field or ( $main::opt{'I'} and lc( $condition ) eq lc( $field ) ) )
        {
            printf STDERR "* '%s'\n", $replacement if ( $main::opt{'D'} );
            return $replacement;
        }
        elsif ( defined $on_else )
        {
            printf STDERR "* '%s'\n", $on_else if ( $main::opt{'D'} );
            return $on_else;
        }
        else
        {
            printf STDERR "* '%s'\n", $field if ( $main::opt{'D'} );
            return $field;
        }
    }
    # Unconditionally change the site's character.
    printf STDERR "* '%s'\n", $replacement if ( $main::opt{'D'} );
    return $replacement;
}

# ===================================================
# Translation Operations
# ===================================================

=head2 translate_line

Performs regex-based search and replace on columns.

=cut

sub translate_line {
    my @in_line = @_;
    my @out_line = ();
    
    foreach my $column_index (0..$#in_line) {
        my $value = $in_line[$column_index];
        
        if (@main::TRANSLATE_COLUMNS && grep { $_ == $column_index } @main::TRANSLATE_COLUMNS ||
            (@main::TRANSLATE_COLUMNS && $main::TRANSLATE_COLUMNS[0] == $main::KEYWORD_ANY)) {
            
            if (defined $main::trans_ref && exists $main::trans_ref->{$column_index}) {
                my $trans_spec = $main::trans_ref->{$column_index};
                $value = apply_translation($value, $trans_spec);
            } elsif (defined $main::trans_ref && exists $main::trans_ref->{$main::KEYWORD_ANY}) {
                my $trans_spec = $main::trans_ref->{$main::KEYWORD_ANY};
                $value = apply_translation($value, $trans_spec);
            }
        }
        
        push @out_line, $value;
    }
    
    if ($main::opt{'D'}) {
        print STDERR "translate_line(): result=(" . join(",", @out_line) . ")\n";
    }
    
    return @out_line;
}

sub apply_translation {
    my ($in_line, $trans_spec) = @_;
    
    if ($main::opt{'D'}) {
        print STDERR "apply_translation(): input='$in_line', spec='$trans_spec'\n";
    }
    
    # Parse translation specification: search/replace/flags
    my ($search, $replacement, $flags) = split /\//, $trans_spec, 3;
    
    if (!defined $search) {
        print STDERR "** Error: Invalid translation specification '$trans_spec'\n";
        return $in_line;
    }
    
    $replacement = "" if !defined $replacement;
    $flags = "" if !defined $flags;
    
    # Apply translation with appropriate flags
    my $case_flag = ($main::opt{'I'} || $flags =~ /i/) ? "i" : "";
    my $global_flag = ($flags =~ /g/) ? "g" : "";
    
    eval {
        if ($case_flag && $global_flag) {
            $in_line =~ s/$search/$replacement/gi;
        } elsif ($case_flag) {
            $in_line =~ s/$search/$replacement/i;
        } elsif ($global_flag) {
            $in_line =~ s/$search/$replacement/g;
        } else {
            $in_line =~ s/$search/$replacement/;
        }
    };
    
    if ($@) {
        print STDERR "** Error in translation: $@\n";
    }
    
    if ($main::opt{'D'}) {
        print STDERR "apply_translation(): result='$in_line'\n";
    }
    
    return $in_line;
}

# ===================================================
# URL Encoding Operations
# ===================================================

=head2 url_encode_line

URL encodes specified columns.

=cut

sub url_encode_line {
    my @in_line = @_;
    my @out_line = ();
    
    foreach my $column_index (0..$#in_line) {
        my $value = $in_line[$column_index];
        
        if (@main::U_ENCODE_COLUMNS && grep { $_ == $column_index } @main::U_ENCODE_COLUMNS ||
            (@main::U_ENCODE_COLUMNS && $main::U_ENCODE_COLUMNS[0] == $main::KEYWORD_ANY)) {
            
            # Use URL encoding from Pipe::IO
            $value = Pipe::IO::map_url_characters($value);
        }
        
        push @out_line, $value;
    }
    
    return @out_line;
}

1;

__END__

=head1 AUTHOR

pipe.pl development team

=head1 COPYRIGHT

Copyright (c) 2024 pipe.pl project. All rights reserved.

=head1 SEE ALSO

L<Pipe::Core>, L<Pipe::IO>, L<Pipe::Column>

=cut