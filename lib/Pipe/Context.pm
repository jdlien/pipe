package Pipe::Context;

use strict;
use warnings;
use utf8;

# Constructor for the context object that holds all processing state
sub new {
    my $class = shift;
    my $self = {
        # Command line options (will be set from %opt)
        options => {},
        
        # I/O and Delimiter Settings
        delimiter => '|',
        input_delimiter => '|',
        output_delimiter => '|',
        
        # Line Processing State
        line_number => 0,
        last_line => 0,
        skip_line => 0,
        previous_lines => [],
        buff_size => 0,
        line_buff => [],
        all_lines => [],
        alt_lines => [],
        line_ranges => { '1' => 100000000 },  # Default: all lines
        
        # Processing Control Flags
        read_full => 0,
        keep_lines => 10,
        fast_forward => 0,
        relax_o_exclude => 0,
        collapse_option => 0,
        allow_scripting => 0,  # From $TRUE constant
        
        # Column Operation Arrays and References
        # Each operation has an array of column indices and associated data
        
        # Increment Operations
        incr_columns => [],
        incr3_columns => [],
        increment_ref => {},
        auto_incr_column => undef,
        auto_incr_seed => {},
        auto_incr_reset => {},
        auto_incr_orig_value => 0,
        
        # Math Operations
        sum_columns => [],
        sum_ref => {},
        avg_columns => [],
        avg_ref => {},
        avg_count => {},
        count_columns => [],
        count_ref => {},
        delta4_columns => [],
        delta_cols_ref => {},
        math_columns => [],
        math_ref => {},
        histogram_column => [],
        hist_ref => {},
        
        # Text Manipulation
        case_columns => [],
        case_ref => {},
        trim_columns => [],
        normal_columns => [],
        translate_columns => [],
        trans_ref => {},
        mask_columns => [],
        mask_ref => {},
        subs_columns => [],
        subs_ref => {},
        pad_columns => [],
        pad_ref => {},
        flip_columns => [],
        flip_ref => {},
        format_columns => [],
        format_ref => {},
        replace_columns => [],
        replace_ref => {},
        cond_cmp_columns => [],
        cond_cmp_ref => {},
        u_encode_columns => [],
        url_characters => {},
        
        # Pattern Matching
        match_columns => [],
        match_ref => {},
        not_match_columns => [],
        not_match_ref => {},
        match_start_cols => [],
        match_start_ref => {},
        match_y_columns => [],
        match_y_ref => {},
        
        # Column Analysis
        width_columns => [],
        width_min_ref => {},
        width_max_ref => {},
        width_line_min_ref => {},
        width_line_max_ref => {},
        compare_columns => [],
        no_compare_columns => [],
        empty_columns => [],
        show_empty_columns => [],
        
        # Data Organization
        order_columns => [],
        sort_columns => [],
        ddup_columns => [],
        ddup_ref => {},
        merge_columns => [],
        script_columns => [],
        script_ref => {},
        
        # Merge/Join State
        is_data_to_merge => 1,  # $FALSE = 1
        merge_src_columns => [],
        merge_ref_columns => [],
        merge_expression_ref => {},
        ref_file_data_href => {},
        ref_column_index_true => [],
        ref_literals_false => [],
        
        # Match Frame State
        is_x_match => 0,
        is_y_match => 0,
        is_dumpable_match => 0,
        h_match => -1,
        frame_buffer => [],
        continue_to_process_match => 0,
        is_a_post_match => 0,
        match_limit => 1,
        match_count => 0,
        
        # Output Control State
        start_output => 0,
        end_output => 0,
        tail_output => 0,
        table_output => 0,
        table_attr => '',
        total_csv_cols => 0,
        begin_value => '',
        skip_line_table => 0,
        skip_value => '',
        end_value => '',
        widths_columns => {},
        join_count => 0,
        
        # Bucket Operations
        j_cmd => '',
        j_count => 0,
        j_bucket_counts => {},
        
        # Numeric Precision
        precision => 2,
    };
    
    # Initialize previous_lines with BOF marker
    push @{$self->{previous_lines}}, "BOF";
    
    return bless $self, $class;
}

# Getter/setter methods for common operations

sub get_line_number {
    my $self = shift;
    return $self->{line_number};
}

sub set_line_number {
    my ($self, $value) = @_;
    $self->{line_number} = $value;
}

sub increment_line_number {
    my $self = shift;
    $self->{line_number}++;
    return $self->{line_number};
}

sub get_delimiter {
    my $self = shift;
    return $self->{delimiter};
}

sub set_delimiter {
    my ($self, $value) = @_;
    $self->{delimiter} = $value;
}

sub get_option {
    my ($self, $key) = @_;
    return $self->{options}->{$key};
}

sub set_option {
    my ($self, $key, $value) = @_;
    $self->{options}->{$key} = $value;
}

sub set_options {
    my ($self, $options_ref) = @_;
    $self->{options} = $options_ref;
}

# Methods to access column arrays
sub get_sum_columns {
    my $self = shift;
    return $self->{sum_columns};
}

sub get_count_columns {
    my $self = shift;
    return $self->{count_columns};
}

sub get_avg_columns {
    my $self = shift;
    return $self->{avg_columns};
}

sub get_width_columns {
    my $self = shift;
    return $self->{width_columns};
}

# Methods to access reference hashes
sub get_sum_ref {
    my $self = shift;
    return $self->{sum_ref};
}

sub get_count_ref {
    my $self = shift;
    return $self->{count_ref};
}

sub get_avg_ref {
    my $self = shift;
    return $self->{avg_ref};
}

sub get_avg_count {
    my $self = shift;
    return $self->{avg_count};
}

# Reset methods for accumulators
sub reset_accumulators {
    my $self = shift;
    $self->{sum_ref} = {};
    $self->{count_ref} = {};
    $self->{avg_ref} = {};
    $self->{avg_count} = {};
    $self->{width_min_ref} = {};
    $self->{width_max_ref} = {};
    $self->{ddup_ref} = {};
    $self->{hist_ref} = {};
}

# Match state methods
sub is_in_match_frame {
    my $self = shift;
    # This could be written more idiomatically as:
    #   return $self->{is_x_match} || $self->{is_y_match};
    # However, it has been expanded to achieve 100% condition coverage
    # with Devel::Cover, which has difficulty tracking certain OR conditions.
    return 1 if $self->{is_x_match};
    return 1 if $self->{is_y_match};
    return 0;
}

sub start_match_frame {
    my $self = shift;
    $self->{is_x_match} = 1;
    $self->{frame_buffer} = [];
}

sub end_match_frame {
    my $self = shift;
    $self->{is_x_match} = 0;
    $self->{is_y_match} = 0;
    return $self->{frame_buffer};
}

# Line buffer management
sub add_to_line_buffer {
    my ($self, $line) = @_;
    push @{$self->{line_buff}}, $line;
    
    # Keep only the last N lines
    if (@{$self->{line_buff}} > $self->{keep_lines}) {
        shift @{$self->{line_buff}};
    }
}

sub get_line_buffer {
    my $self = shift;
    return $self->{line_buff};
}

# Check if we need to read the full file
sub needs_full_read {
    my $self = shift;
    # This could be written more idiomatically as:
    #   return $self->{read_full} || @{$self->{sort_columns}} > 0 || $self->{tail_output};
    # However, it has been expanded to achieve 100% condition coverage
    # with Devel::Cover, which has difficulty tracking certain OR conditions.
    return 1 if $self->{read_full};
    return 1 if @{$self->{sort_columns}} > 0;
    return 1 if $self->{tail_output};
    return 0;
}

# Debugging method to dump context state
sub dump_state {
    my $self = shift;
    use Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    print STDERR "Context State:\n", Dumper($self);
}

1;

__END__

=head1 NAME

Pipe::Context - State management for pipe.pl

=head1 SYNOPSIS

    use Pipe::Context;
    
    my $ctx = Pipe::Context->new();
    
    # Set options from command line
    $ctx->set_options(\%opt);
    
    # Access and modify state
    $ctx->set_delimiter(',');
    $ctx->increment_line_number();
    
    # Access column arrays
    my $sum_columns = $ctx->get_sum_columns();
    
    # Reset accumulators
    $ctx->reset_accumulators();

=head1 DESCRIPTION

This module encapsulates all the global state that was previously
scattered throughout pipe.pl as global variables. It provides a
centralized location for all processing state, making the code
more maintainable and testable.

=head1 METHODS

=head2 new()

Creates a new context object with all state initialized to defaults.

Returns a blessed hash reference containing all the state variables
needed for pipe.pl processing.

=head2 get_line_number()

Returns the current line number being processed.

=head2 set_line_number($value)

Sets the current line number to the specified value.

=head2 increment_line_number()

Increments the line number by 1 and returns the new value.

=head2 get_delimiter()

Returns the current field delimiter.

=head2 set_delimiter($value)

Sets the field delimiter to the specified value.

=head2 get_option($key)

Returns the value of the specified command-line option.

=head2 set_option($key, $value)

Sets a command-line option to the specified value.

=head2 set_options(\%options)

Replaces the entire options hash with the provided hash reference.

=head2 get_sum_columns()

Returns an array reference of column indices for sum operations.

=head2 get_count_columns()

Returns an array reference of column indices for count operations.

=head2 get_avg_columns()

Returns an array reference of column indices for average operations.

=head2 get_width_columns()

Returns an array reference of column indices for width analysis operations.

=head2 get_sum_ref()

Returns a hash reference containing sum accumulator data.

=head2 get_count_ref()

Returns a hash reference containing count accumulator data.

=head2 get_avg_ref()

Returns a hash reference containing average accumulator data.

=head2 get_avg_count()

Returns a hash reference containing count data for average calculations.

=head2 reset_accumulators()

Resets all accumulator hashes (sum, count, average, width, dedup, histogram)
to empty state.

=head2 is_in_match_frame()

Returns true if currently inside a match frame (X or Y match is active).

=head2 start_match_frame()

Starts a new match frame by setting X match flag and resetting the frame buffer.

=head2 end_match_frame()

Ends the current match frame by clearing match flags and returning the frame buffer.

=head2 add_to_line_buffer($line)

Adds a line to the line buffer, maintaining the configured buffer size limit.

=head2 get_line_buffer()

Returns an array reference containing the current line buffer.

=head2 needs_full_read()

Returns true if the entire input file needs to be read before processing
(required for sort, tail, or read_full operations).

=head2 dump_state()

Debug method that prints the entire context state to STDERR using Data::Dumper.

=head1 AUTHOR

Pipe.pl contributors

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut