#!/usr/bin/perl -w
#####################################################################################
#
# Perl source file for project pipe.
#
# Pipe performs handy operations on pipe delimited files.
#    Copyright (C) 2015 - 2022  Andrew Nisbet
# The Edmonton Public Library respectfully acknowledges that we sit on
# Treaty 6 territory, traditional lands of First Nations and Metis people.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# Author:  Andrew Nisbet, Edmonton Public Library
# Created: Mon May 25 15:12:15 MDT 2015
#
# Rev:
# 2.03.02 - Mar 22, 2023 Fixed -6 bug that fails on columns with 0 or text values.
#
####################################################################################

use strict;
use warnings;
use vars qw/ %opt /;
use Getopt::Std;
use utf8;
use lib 'lib';
use lib './lib';
use lib '../lib';
use Pipe::Core qw(trim get_number_format);
use Pipe::Context;
use Pipe::IO qw(:output :encoding);
use Pipe::Column qw(:all);
use Pipe::Text;
use Pipe::Match qw(:all);
use Pipe::Math qw(:all);
use Pipe::Data qw(:all);

binmode STDOUT;
binmode STDERR;
binmode STDIN;

### Globals
# Context object will be initialized after option processing
my $ctx;
my $VERSION           = qq{2.03.02};
my $FALSE             = 1;
my $TRUE              = 0;
my $ALLOW_SCRIPTING   = $TRUE;
my $KEYWORD_ANY       = qw{any};
my $KEYWORD_REMAINING = qw{remaining};
my $KEYWORD_CONTINUE  = qw{continue};
my $KEYWORD_LAST      = qw{last};
my $KEYWORD_REVERSE   = qw{reverse};
my $KEYWORD_EXCLUDE   = qw{exclude};
my $KEYWORD_NUM_COLS  = qw{num_cols};
my $RELAX_o_EXCLUDE   = 0; # If exclude selected don't validate the line is the same length as the inverted number fields.
my $COLLAPSE_OPTION   = 0;
# Flag means that the entire file must be read for an operation like sort to work.
my $LINE_RANGES       = {};
my $MAX_LINE          = 100000000;
$LINE_RANGES->{'1'}   = $MAX_LINE;
my $READ_FULL         = 0; # Set true to read the entire file before output as with -L'-n'.
my $KEEP_LINES        = 10; # Number of lines to keep in buffer if -L'-n' is used.
my @LINE_BUFF         = (); # Buffer of last 'n' lines used with -L'-n'.
my $FAST_FORWARD      = 0;  # 0 means keep reading 1 means stop reading input.
our @ALL_LINES         = ();
# For every requested operation we need an array that can hold the columns
# for that operation; in that way we can have multiple operations on different
# columns working at the same time. We store different columns totals on a hash ref.
##### Scripting
my $DELIMITER         = '|';
my $SUB_DELIMITER     = qq{___PIPE___};
my $QUOTED_DELIMITER  = qq{___QUOTED_DELIMITER___};
my @SCRIPT_COLUMNS    = (); my $script_ref    = {};
#####
my $LINE_NUMBER       = 0;
my $LAST_LINE         = 0; # Used for -j to trim last delimiter.
my $SKIP_LINE         = 0; # Used for -L for alternate line output.
my @PREVIOUS_LINES    = (); my $BUFF_SIZE = 0; # Display the 'n' lines before the match.
push @PREVIOUS_LINES, "BOF";
our @INCR_COLUMNS      = ();                          # Columns to increment.
# Column and seed value to insert auto-increment columns into.
our $AUTO_INCR_COLUMN  = (); our $AUTO_INCR_SEED= {};  our $AUTO_INCR_RESET = {};
our $AUTO_INCR_ORIG_VALUE = 0; # Used if a reset value is selected.
our @HISTOGRAM_COLUMN  = (); our $hist_ref      = {};  # Column for histogram and character to use.
our @INCR3_COLUMNS     = (); our $increment_ref = {};  # Stores increment values for each of the target columns.
our @DELTA4_COLUMNS    = (); our $delta_cols_ref= {};  # Stores columns we want deltas for, and previous lines value used in difference.
our @COUNT_COLUMNS     = (); our $count_ref     = {};
our @SUM_COLUMNS       = (); our $sum_ref       = {};
our @WIDTH_COLUMNS     = (); our $width_min_ref = {}; our $width_max_ref = {}; our $width_line_min_ref = {}; our $width_line_max_ref = {};
our @AVG_COLUMNS       = (); our $avg_ref       = {}; our $avg_count = {};
our @DDUP_COLUMNS      = (); our $ddup_ref      = {};
my @CASE_COLUMNS      = (); my $case_ref      = {};
my @REPLACE_COLUMNS   = (); my $replace_ref   = {}; # Replacement columns and content. Handled like -f.
our @COND_CMP_COLUMNS  = (); our $cond_cmp_ref  = {}; # case switching expressions like uc,lc,mc.
my @TRIM_COLUMNS      = ();
my @ORDER_COLUMNS     = ();
my @NORMAL_COLUMNS    = ();
our @SORT_COLUMNS      = ();
my @TRANSLATE_COLUMNS = (); my $trans_ref     = {}; # Translation values.
my @MASK_COLUMNS      = (); my $mask_ref      = {}; # Stores the masks by column number.
my @SUBS_COLUMNS      = (); my $subs_ref      = {}; # Stores the sub string indexes by column number.
my @PAD_COLUMNS       = (); my $pad_ref       = {}; # Stores the pad instructions by column number.
my @FLIP_COLUMNS      = (); my $flip_ref      = {}; # Stores the flip instructions by column number.
my @FORMAT_COLUMNS    = (); my $format_ref    = {}; # Stores the format instructions by column number.
my @MATCH_COLUMNS     = (); my $match_ref     = {}; # Stores regular expressions.
our @NOT_MATCH_COLUMNS = (); our $not_match_ref = {}; # Stores regular expressions for -G.
my $IS_X_MATCH        = 0;                          # True if -X matched.
my $H_MATCH           = -1;                          # between -X and -Y are output on the same line.
my @FRAME_BUFFER      = ();                         # Store the lines that match 
my $IS_Y_MATCH        = 0;                          # True if -Y matched. Turns off -X.
my $IS_DUMPABLE_MATCH = 0;                          # If 1, then '-g' matched during a -X and -Y test.
my $continue_to_process_match = 0;                  # Set true if -X or -Y are not used, but controls output of an arbitrary but specific line.
my @MATCH_START_COLS  = (); my $match_start_ref= {};# Stores each columns IS_MATCHED flag, and turns on -Y.
my @MATCH_Y_COLUMNS   = (), my $match_y_ref    = {}; # Look ahead -Y test conditions supplied by user.
my @U_ENCODE_COLUMNS  = (); my $url_characters = {}; # Stores the character mappings.
our @MERGE_COLUMNS     = (); # List of columns to merge. The first is the anchor column.
our @EMPTY_COLUMNS     = (); # empty column number checks.
our @SHOW_EMPTY_COLUMNS= (); # Show empty column number checks.
our @COMPARE_COLUMNS   = (); # Compare all collected columns and report if equal.
our @NO_COMPARE_COLUMNS= (); # ! Compare all collected columns and report if equal.
my $START_OUTPUT      = 0;
my $END_OUTPUT        = 0;
my $TAIL_OUTPUT       = 0; # Is this a request for the tail of the file.
my $TABLE_OUTPUT      = 0;  my $TABLE_ATTR = '';     my $TOTAL_CSV_COLS = 0; # Does the user want to output to a table.
my $BEGIN_VALUE       = ''; my $SKIP_LINE_TABLE = 0; my $SKIP_VALUE = ''; my $END_VALUE = ''; # Used in CHUNKED tables
our $WIDTHS_COLUMNS    = {};
my $IS_A_POST_MATCH   = 0;  # For '-Q' region search display.
my $JOIN_COUNT        = 0; # lines to continue to join if -H used.
my $PRECISION         = 2; # Default precision of computed floating point number output.
my $MATCH_LIMIT       = 1; my $MATCH_COUNT = 0; # Number of search matches output before exiting.
our $IS_DATA_TO_MERGE  = $FALSE; 
our @MERGE_SRC_COLUMNS = (); our @MERGE_REF_COLUMNS = (); # Columns from STDIN to compare with columns from second file (-0).
our $merge_expression_ref  = {};
our $REF_FILE_DATA_HREF    = {};
our @REF_COLUMN_INDEX_TRUE = ();
our @REF_LITERALS_FALSE    = ();
our @MATH_COLUMNS          = (); our $math_ref = {}; # Math operations stored. math_ref contains the operator.
our $J_CMD             = "";
our $J_COUNT           = 0;
our $J_BUCKET_COUNTS   = {};
my @ALT_LINES         = ();

# Explains the usage of pipe.pl when -x is used or if there was an error with input.
# Message about this program and how to use it.
#
sub usage()
{
    print STDERR << "EOF";

    usage: [cat file|echo value] | pipe.pl [-5ADiIjKLNUVx] [-0{file} -M{options}] [options]
       
pipe.pl is the Swiss Army knife of text editing for the command line. It script 
allows you to do things that are difficult or tedious in other languages.

pipe.pl usually uses STDIN as its input, but can take data from a file specified with -0 (zero).
Generally pipe.pl outputs to STDOUT, however there are notable exceptions, see -5, and -i for example.

Columns are zero-indexed while lines numbers start at 1.

The keyword 'any' takes precedence over other column designations and allows the modifier
flag to operate on all columns on the current line.

 -?{opr}:{c0,c1,...,cn}: Performs math operations over multiple columns. Supported operators are 'add', 'sub',
                  'mul', and 'div'. The order of columns is important for subtraction and division 
                  since '1|2' -?div:c0,c1 => '0.5|1|2' and '1|2' -?div:c1,c0 => '2|1|2'.
                  The result always appears as the first column (c0), see -o to re-order. See -y to 
                  change the precision of the result. Errors like divide by zero will result 
                  'NaN'. If a column contains non-numeric data it is ignored during the calculation.
 -0{file_name}  : Name of a text file to use as input as alternative to taking input on STDIN.
                  See -M for additional features relating data from STDIN and another file.
 -1{c0,c1,...cn}: Increment a numeric value stored in given column(s).
 -2{cn:[start,[end]]} : Adds a field to the data that auto increments starting at a given integer.
                  The auto-increment value will be appended to the end of the line if the
                  column index is specified is greater than, or equal to, the number of 
                  columns a given line. Column increments can be reset with an 'end' period.
 -3{c0[:n],c1,...cn}: Increment the value stored in given column(s) by a given step.
 -4{c0,c1,...cn}: Compute difference between value in previous column. If the values in the
                  line above are numerical the previous line is subtracted from the current line.
                  If the -R switch is used the current line is subtracted from the previous line.
 -5             : Modifier used with -[g|X|Y]'any:{regex}', outputs all the values that match the regular
                  expression to STDERR.
 -6{cn:[char]}  : Displays histogram of columns' numeric value. '5' '-6c0:*' => '*****'.
                  If the column doesn't contain a whole number pipe.pl will issue an error and exit.
 -7{integer}    : Return after n-th line match of a search is output. See -g, -G, -X, -Y, -C.
 -8{record sep|regex} : Change the input record separator. Works with multiple files using -0 and -M.
 -a{c0,c1,...cn}: Sum the non-empty values in given column(s).
 -A             : Modifier that outputs line numbers from input, or if -d is used, the number 
                  of records that match the column key selection that were de-duplicated.
                  The end result is output similar to 'sort | uniq -c'. In other match
                  functions like -g, -G, -X, or -Y the line numbers of successful matches
                  are reported.
 -b{c0,c1,...cn}: Compare fields and output if each is equal to one-another.
 -B{c0,c1,...cn}: Compare fields and output if columns differ.
 -c{c0,c1,...cn}: Count the non-empty values in given column(s), that is
                  if a value for a specified column is empty or doesn't exist,
                  don't count otherwise add 1 to the column tally.
 -C{any|num_cols{n-m}|cn:(gt|ge|eq|le|lt|ne|rg{n-m}|width{n-m})|cc(gt|ge|eq|le|lt|ne)cm,...}:
                  Compare column values and output line if value in column is greater than (gt),
                  less than (lt), equal to (eq), greater than or equal to (ge), not equal to (ne),
                  or less than or equal to (le) the value that follows. The following value can be
                  numeric, but if it isn't the value's comparison is made lexically. All specified
                  columns must match to return true, that is -C is logically AND across columns.
                  This behaviour changes if the keyword 'any' is used, in that case test returns
                  true as soon as any column comparison matches successfully.
                  -C supports comparisons across columns. Using the modified syntax
                  -Cc1:ccgec0 where 'c1' refers to source of the comparison data,
                  'cc' is the keyword for column comparison, 'ge' - the comparison
                  operator, and 'c0' the column who's value is used for comparison.
                  "2|1" => -Cc0:ccgec1 means compare if the value in c1 is greater
                  than or equal to the value in c1, which is true, so the line is output.
                  A range can be specified with the 'rg' modifier. Start and end values may be
                  [+/-] integers or [+/-] floating values. Once set only numeric
                  values that are greater or equal to the lower bound, and less than equal
                  to the upper bound will be output. The range is separated with a '-'
                  character. Outputting rows that have value within the range of 
                  0 and 5 is as follows ```-Cany:rg0-5```. To output rows with values
                  between -100 and -50 is specified with ```-Cany:rg-100--50```.
                  Further, -Cc0:rg-5-5 is the same as -Cc0:rg-5-+5. See also -I and -N.
                  Row output can also be controlled with the 'width' modifier.
                  Like the 'rg' modifier, you can output rows with columns of a 
                  given width. "abc|1" => -Cc0:"width0+3", or output the rows if c0
                  is between 0 and 3 characters wide.
                  Also outputs lines that match a range of expected columns. For example
                  "2|1" => -Cnum_cols:'width2-10' prints output, because the number of 
                  columns falls between 2 and 10. 'num_cols' has precedence over 
                  other comparisons.
 -d{c0,c1,...cn}: De-duplicates column(s) of data. The order of the columns informs pipe.pl 
                  the priority of column de-duplication. The last duplicate found is output to STDOUT.
 -D             : Debug switch.
 -e{[any|cn]:[csv|lc|mc|pipe|uc|us|spc|normal_[W|w,S|s,D|d,P|q|Q]|order_{from}-{to}][,...]|collapse]}: 
                  Change the case, normalize, or order field data 
                  in a column to upper case (uc), lower case (lc), mixed case (mc), or
                  underscore (us). An extended set of commands include (spc) to replace multiple white spaces with a
                  single space character, and (normal_{char}) which allows the removal of 
                  classes of characters. For example 'NORMAL_d' removes all digits, 'NORMAL_D'
                  removes all non-digits from the input string. Different classes are
                  supported based on Perl's regex class qualifiers W,w word, D,d digit,
                  and S,s whitespace. 
                  Multiple qualifiers can be separated with a '|' character. For example normalize 
                  removing digits and non-word characters.
                  NORMAL_q removes single quotes, NORMAL_Q removes double quotes in field.
                  NORMAL_p removes all characters that are not upper/lower case characters, digits or spaces.
                  normal_csv converts input CSV data into pipe-delimited data, preserving commas in quotes, 
                  but removing quote characters.
                  'pipe' removes pipe.pl sensitive characters (:,|).
                  'csv' removes commas from within quoted strings.
                  The order key word allows character sequences to be ordered within a field
                  like using -o can order fields, but order names each character within a  
                  field and allows those named characters to be mapped to new positions 
                  on output. For example: '123' -ec0:order_xyz-zyx => '321' or 
                  '20180911' -ec0:order_yyyymmdd-ddmmyyyy => '11092018'. If the length of
                  the input is longer than the variable string, the remainder of the string
                  is output as is. The input variable declaration must match the output 
                  in length and is case sensitive. If 'collapse' is used empty and undefined values
                  will be removed from the line.
 -E{cn:[r|?c.r[.e]],...}: Replace an entire field conditionally. Similar
                  to the '-f' flag but replaces the entire field instead of a specific
                  character position. r=replacement string, c=conditional string, the
                  value the field must have to be replaced by r, and optionally
                  e=replacement if the condition failed.
                  Example: '111|222|333' '-E'c1:nnn' => '111|nnn|333'
                  '111|222|333' '-E'c1:?222.444'     => '111|444|333'
                  '111|222|333' '-E'c1:?aaa.444.bbb' => '111|bbb|333'
 -f{cn:n.p[?p[.q]],...}: Flips an arbitrary but specific character conditionally,
                  where 'n' is the 0-based index of the target character. 
                  Use '?' to test the character's value before changing it
                  and optionally use a different character if the test fails.
                  Example: -f c0:1.1?A.B 0100 => 0A00
 -F[cn:[b|c|d|h][.[b|c|d|h]],...}: Outputs the field in character (c), binary (b), decimal (d)
                  or hexadecimal (h). A single radix defines the desired output and assumes
                  decimal input. A second radix (delimited from the first with a '.') instructs
                  pipe.pl to convert from radix 'a' to radix 'b'. Example -Fc0:b.h specifies
                  the input as binary, and outputs hexadecimal: '1111' -Fc0:b.h => 'f'
 -g{[any|cn]:regex,...}: Searches the specified field using Perl regular expressions.
                  Escape any commas in a regular expression because comma
                  is the column definition delimiter. Selecting multiple fields acts
                  like an AND function, all fields must match their corresponding regex
                  for the line to be output. The behaviour of -g turns into OR if the
                  keyword 'any' is used. In that case all other column specifications
                  are ignored and any successful match will return true.
                  Comparisons across columns is also possible, by omitting the regex for a given column.
                  Columns with empty regular expressions will be compared to the first regex specified.
                  Example: "a|b|c|b|d" '-gc1:b,c3:' => "a|b|c|b|d" succeeds because c3 matches
                  c1 as specified in the first expression 'c1:b', while
                  "a|b|c|b|d" '-gc2:c,c3:' => nil because the value in c3 doesn't match 'c' of c2.
                  If the first column's regex is empty, the value of the first column is used
                  as the regex in subsequent columns' comparisons. "a|b|c|b|d" '-gc1:,c3:' => "a|b|c|b|d"
                  succeeds because the value in c1 matches the value in c3. Behaviour changes
                  if used in combination with [-X](#flag-x) and [-Y](#flag-y). The -g outputs just the frame that is 
                  bounded by [-X](#flag-x) and [-Y](#flag-y), but if -g matches, only the matching frame is output 
                  to STDERR, while only the -g that matches within the frame is output to STDOUT. 
 -G{[any|cn]:regex,...}: Inverse of -g, and can be used together to perform AND operation as
                  return true if match on column 1, and column 2 not match. If the keyword
                  'any' is used, all columns must fail the match to return true. Empty regular
                  expressions are permitted. See -g for more information.
 -h{new_delimiter}: Change output delimiter delimiter. See -P and -K.
 -H             : Suppress new line on output. Some switches can modify this behaviour. -i will
                  suppress a new line only if the -g matches. New lines are suppressed starting
                  with any -X match until a -Y match is found. 
 -i             : Turns on virtual matching for -b, -B, -C, -g, -G, -H, -z and -Z. Normally fields are 
                  conditionally suppressed or output depending on the above conditional flags. '-i'  
                  allows further modifications on lines that match these conditions, while allowing 
                  all other lines to pass through, in order, unmodified.
 -I             : Ignore case on operations -b, -B, -C, -d, -E, -f, -g, -G, -l, -n and -s.
                  By default sorts are case-sensitive, -I sorts ascending order or decending if -R is used.
 -j             : Removes the last delimiter from the last line of output when using -P, -K, or -h.
 -J[min|max|avg|sum|count]{cn}: Math operations on buckets created by de-duplicates '-d',
                  providing a sum over group-like functionality.
                  Functions include min, max, avg, sum, and count. See -d, -A, and -P.
                  Flag -A and -J are mutually exclusive.
 -k{cn:expr,(...)}: Use Perl scripting to manipulate a field. Syntax: -kcn:'(script)'
                  The existing value of the column is stored in an internal variable called '\$value'.
                  If ALLOW_SCRIPTING is set to FALSE, pipe.pl will issue an error and exit.
 -K             : Use line breaks as column delimiters.
 -l{[any|cn]:exp,... }: Translate a character sequence if present. Example: 'abcdefd' -l"c0:d.P".
                  produces 'abcPefP'. 3 white space characters are supported '\\s', '\\t',
                  and '\\n'. "Hello" -lc0:"e.\\t" => 'H       llo'
                  Can be made case insensitive with -I.
 -L{[[+|-]?n-?m?|skip n]}: Output line number [+n] head, [n] exact, [-n] tail [n-m] range.
                  Examples: '+5', first 5 lines, '-5' last 5 lines, '7-', from line 7 on,
                  '99', line 99 only, '35-40', from lines 35 to 40 inclusive. Multiple
                  requests can be comma separated like this -L'1,3,8,23-45,12,-100'.
                  The 'skip' keyword will output alternate lines. 'skip2' will output every other line.
                  'skip 3' every third line and so on. The skip keyword takes precedence over
                  over other line output selections.
 -m{[any|cn]:*[_|#]|[@]*} : Mask specified column with the mask defined after a ':', where '_'
                  means suppress, '#' means output character, any other character at that
                  position will be inserted.
                  If the last character in a mask is either '_' or '#' that rule is repeated for 
                  all remaining characters in the field. Any non-rule characters are output as literals.
                  Characters '_', '#' and ',' can be output by escaping them with a back slash (\\).
                  The symbol '\@' outputs the field contents without any change.
                  This is useful when you want to append content to a field but not change the field.
                  Using -y instructs -m to insert a '.' into the string at -y places from the 
                  end of the string (See -y). This works on both numeric or alphanumeric strings.
 -M{cn:cm?cp[+cq...][.{literal}[+{literal}...]]: Compares columns from two files and either outputs the specified
                  column(s) from file two, or an optional literal string value.
                  File one (f1) is STDIN to pipe.pl, file two (f2) is specified with '-0' (zero).
                  if a specific column from f1 matches f2 columns from f2 are appended to the 
                  line output from f1. Additional columns can be appended with the '+' operator
                  and can be any order. Example -M c0:c0?c1+c3+c2 means if f1's c0 matches f2's c0
                  then add f2's c1, c3, and c2 in that order. Further, -M c0:c0?c1+c3+c2.none means
                  if f1's c0 does not match f2's c0 then output "none".
                  Matching behaviour can also be modified with -I and -N.
                  Both files must use the same column delimiter, and any use of -W will
                  apply to both.
 -n{[any|cn],...}: Normalize the selected columns, that is, removes all non-word characters
                  (non-alphanumeric and '_' characters), and changing the remaining characters 
                  to upper case. Using the -I switch will preserve case. See -N and -I.
 -N             : Normalize keys before comparison when using (-d, -C, and -s) dedup and sort.
                  Normalization removes all non-word characters before comparison. Use the -I
                  switch to preserve keys' case during comparison. See -n, and -I.
                  Outputs absolute value of -a, -v, -1, -3, -4, results.
                  Causes summaries to be output with delimiter to STDERR on last line.
 -o{c0,c1,...,cn[,continue][,last][,remaining][,reverse][,exclude]}: Re-orders and control which columns are output.
                  Only the specified columns are output unless the keyword 'remaining', or 'continue' are used.  
                  The 'remaining' keyword outputs all columns that have not already been specified, 
                  in order. The 'continue' keyword outputs all the columns from the last specified 
                  column to the last column in the line. 'last' will output the last column in a row.
                  'reverse' reverses the column order. The 'exclude' keyword all but the listed columns
                  in order. Once a keyword is encountered (except 'exclude'), any additional columns are omitted.
 -O{[any|cn],...}: Merge columns. The first column is the anchor column, any others are appended to it
                  ie: 'aaa|bbb|ccc' -Oc2,c0,c1 => 'aaa|bbb|cccaaabbb'. Use -o to remove extraneous columns.
                  Using the 'any' keyword causes all columns to be merged in the data in the first column (c0).
 -p{cn:N.char,... }: Pad fields left or right with arbitrary 'N' characters. The expression is separated by a
                  '.' character. '123' -pc0:"-5", -pc0:"-5.\\s" both do the same thing: '123  '. Literal
                  digit(s) can be used as padding. '123' -pc0:"-5.0" => '12300'. Spaces are qualified 
                  with either '\\s', '\\t', '\\n', or '_DOT_' for a literal period.
 -P             : Terminates each row with the defined delimiter. By default '|' but can be changed. 
                  See '-h' for more information. When used in conjunction with -d, -J, and -A,
                  a pipe character is inserted between the count and output data.
 -q{integer}    : Modifies '-H' behaviour to allow new lines for every n-th line of output.
                  This has the effect of joining n-number of lines into one line.
 -Q{integer}    : Output 'n' lines before and line after a -g, or -G match to STDERR. Used to
                  view the context around a match, that is, the line before the match and the line after.
                  The lines are written to STDERR, and are immutable. The line preceding a match
                  is denoted by '<=', the line after by '=>'. If the match occurs on the first line
                  the preceding match is '<=BOF', beginning of file, and if the match occurs on
                  the last line the trailing match is '=>EOF'. The arrows can be suppressed with -N.
 -r{percent}    : Output a random percentage of records, ie: -r100 output all lines in random
                  order. -r15 outputs 15% of the input in random order. -r0 produces all output in order.
 -R             : Reverse sort when using -d, -4 or -s.
 -s{c0,c1,...cn}: Sort lines based on data in specific column(s).
 -S{cn:range}   : Sub-string of a columns' contents.
                  Use '.' to separate discontinuous indexes, and '-' to specify ranges.
                  Ie: '12345' -S'c0:0.2.4' => '135', -S'c0:0-2.4' => '1235', and -S'c0:2-' => '345'.
                  Reverse a string: '12345' -S'c0:4-0' => '54321'. Characters can be removed
                  from the end of columns with the syntax (n - m), where 'n' is a literal
                  that stands for the column length and 'm' the number of characters
                  to be trimmed from the end of the string, ie '12345' => -S'c0:0-(n -1)' = '1234'.
 -t{[any|cn],...}: Trim leading and trailing white space from column data. If -y is
                  used, the string is trimmed of white space then truncated to the length specified by -y.
 -T{HTML[:attributes]|MEDIA_WIKI[:h1,h2,...]|WIKI[:h1,h2,...]|MD[:h1,h2,...]|CSV[_UTF-8][:h1,h2,...]}
                  |CHUNKED:[BEGIN={literal}][,SKIP={integer}.{literal}][,END={literal}]
                : Output as a Media/Wiki, Markdown, CSV, CSV_UTF-8 or an HTML table, with attributes.
                  With CSV or CSV_UTF-8 the attributes become column titles and queue pipe.pl
                  to consider the width of the rows on output, filling in empty values as required.
                  Example: -TCSV:"Name,Date,Address,Phone" or -TCSV:'Name,Date, , '.
                  HTML also allows for adding CSS or other HTML attributes to the <table> tag.
                  A bootstrap example is '1|2|3' -T'HTML:class="table table-hover"'. CHUNKED tables
                  can take one, or more, of the optional keywords 'BEGIN', 'SKIP', and 'END'. Each
                  corresponds to the insertion location of the literal string that follows the keyword.
                  SKIP will place the literal string every 'n' lines.
 -u{[any|cn],...}: Encodes strings in specified columns into URL safe versions.
 -U             : Forces sorts and reverse sorts to be done based on numeric values
                  rather than alpha-numeric. If the data in a specified column is not 
                  numeric, matches fail. Example:
                  '12345a' -C'c0:ge12345' => '12345a' but '12345a' -C'c0:ge12345' -U fails.
 -v{c0,c1,...cn}: Average over non-empty values in specified columns.
 -V             : Deprecated. Validate that the output has the same number of columns as the input.
 -w{c0,c1,...cn}: Report min and max number of characters in specified columns, and reports
                  the minimum and maximum number of columns by line.
 -W{delimiter|regex}  : Change the input delimiter.
 -x             : Outputs this usage message and exits.
 -X{[any|cn]:regex,...}: Like the -g, but once a line matches all subsequent lines are also
                  output until a -Y match succeeds. See -Y and -g.
                  If the keyword 'any' is used the first column to match will return true.
 -y{integer}    : Controls precision of computed floating point number output. 
                  When used with -t, selected columns are truncated to 'n' characters wide.
 -Y{[any|cn]:regex,...}: Stops -X output if -Y matches. See -X and -g.
 -z{c0,c1,...cn}: Suppress line if the specified column(s) are empty, or don't exist. 
                   Works with the virtualization flag '-i'.
 -Z{c0,c1,...cn}: Show line if the specified column(s) are empty, or don't exist. See -i.

Version: $VERSION
EOF
    exit;
}

# Takes a single argument from the command line in pipe.pl style input and returns a list of the column index and the value supplied.
# Looks like this: -2c1:1000, where '-2' is the flag, c1 is the column requested, and 1000 the additional input for the column. A reset value is also allowed as in -2c1:1000,1200, which resets the increment to 1000 after 1200 is reached.
# param:  string argument from the command line.
# return: List of 2 values, the column index and the requested value. In the example above the return values are (1, 1000).
sub parse_single_column_single_argument( $ )
{
    my $input = shift;
    if ( $input =~ m/^c\d{1,}/i )
    {
        my ( $colNum, $value ) = split ':', $input;
        my $reset = '';    # might not be used if user doesn't specify a reset value.
        $colNum =~ s/c//i; # get rid of the 'c' because it causes problems later.
        # There may be an additional value after the column specifier (or not).
        if ( $input =~ m/:/ )
        {
            $value = $';
            if ( $input =~ m/,/ )
            {
                ( $value, $reset ) = split '\s?,\s?', $value;
                $value = trim( $value );
                $reset = trim( $reset );
            }
            printf STDERR "increment start='%s', end='%s'\n", $value, $reset if ( $opt{'D'} );
        }
        if ( ! $value )
        {
            $value = 0;
        }
        return ( $colNum, $value, $reset );
    }
    printf STDERR "** error parsing column specification in '%s'\n", $input;
    exit( 0 );
}


# Parses the ranges of lines requested by the user.
# parse the user's instructions and print out the lines selected.
# n = exactly the 'n'th line.
# n- = print from line 'n' on.
# +n = print the first 'n' lines.
# -n = print the last 'n' lines.
# n-m = exactly the range of lines from n to m.
# n,m-p = print n and range n-p (optional).
# param:  String that lists all of the ranges.
# return: <none>.
sub parse_line_ranges( $ )
{
    my $range_str = shift;
    if ( $range_str =~ m/^skip/ )
    {
        my $skip = $' + 0;
        if ( ! $skip or $skip !~ m/\d+/ )
        {
            printf STDERR "** error '-L' skip option takes an integer value greater than 0, supplied '%s'\n", $opt{'L'};
            exit;
        }
        $SKIP_LINE = $skip; # The integer value stored here will be used to modulus the line numbers in process_line().
        return;
    }
    $range_str    =~ s/\s+//g;
    my @r         = split ',', $range_str;
    my $ranges    = \@r;
    while ( @{ $ranges } )
    {
        my $range = shift @{ $ranges };
        # Clear the default of all lines, or else all lines will be considered.
        # Parse the ranges from the input strings.
        # Set the start (key) and end (value) to a specific value.
        if ( $range =~ m/^\-\d+$/ ) # parses from line 'n' to the end of the file.
        {
            $READ_FULL = 1; # Set true to read the entire file before output as with -L'-n'.
            # get rid of the previous rule that outputs all lines.
            delete $LINE_RANGES->{ '1' } if ( exists $LINE_RANGES->{ '1' } and $LINE_RANGES->{ '1' } == $MAX_LINE );
            my $num = substr $range, 1;
            $LINE_RANGES->{ (0 -$num) } = $MAX_LINE;
            $KEEP_LINES  = $num; # Number of lines to keep in buffer if -L'-n' is used.
        }
        elsif ( $range =~ m/^\+\d+$/ ) # parses from beginning of file upto the given range.
        {
            # The rule for line 1 is automatically over written.
            my $num = substr $range, 1;
            $LINE_RANGES->{ '1' } = $num;
        }
        elsif ( $range =~ m/^\d+\-\d+$/ ) # User has selected a range of lines from n-m.
        {
            # Remove the default rule for the entire range.
            delete $LINE_RANGES->{ '1' } if ( exists $LINE_RANGES->{ '1' } and $LINE_RANGES->{ '1' } == $MAX_LINE );
            my @v = split '-', $range;
            $LINE_RANGES->{ $v[ 0 ] } = $v[ 1 ];
        }
        elsif ( $range =~ m/^\d+\-$/ ) # Select all lines from 'n' on.
        {
            # Remove the default rule for the entire range.
            delete $LINE_RANGES->{ '1' } if ( exists $LINE_RANGES->{ '1' } and $LINE_RANGES->{ '1' } == $MAX_LINE );
            my $num = substr $range, 0, length( $range ) -1;
            $LINE_RANGES->{ $num } = $MAX_LINE;
        }
        elsif ( $range =~ m/^\d+$/ ) # Select a specific line number.
        {
            # Remove the default rule for the entire range.
            delete $LINE_RANGES->{ '1' } if ( exists $LINE_RANGES->{ '1' } and $LINE_RANGES->{ '1' } == $MAX_LINE );
            $LINE_RANGES->{ $range } = $range;
        }
        else
        {
            printf STDERR "** pipe syntax error in line number range definition: '%s'\n", $range_str;
            exit 1;
        }
    }
}

# Reads the values supplied on the command line and parses them out into the argument list.
# param:  command line string of requested columns.
# param:  command "any" if the caller is allowed to operate on any column without restriction.
# return: New array.
sub read_requested_columns
{
    my $line             = shift;
    my @allowed_keywords = @_;
    # printf STDERR "-->%s<--\n", @allowed_keywords;
    my @list = ();
    # Since we can't split if there is no delimiter character, let's introduce one if there isn't one.
    $line .= "," if ( $line !~ m/,/ );
    my @cols = split( '\s?,\s?', $line );
    # my @cols = split( ',', $line );
    foreach my $colNum ( @cols )
    {
        # Columns are designated with 'c' prefix to get over the problem of perl not recognizing
        # '0' as a legitimate column number.
        if ( $colNum =~ m/[C|c]\d{1,}/ )
        {
            $colNum =~ s/c//i; # get rid of the 'c' because it causes problems later.
            push( @list, (trim( $colNum ) + 0) );
        }
        elsif ( $colNum =~ m/^any$/i && grep /($KEYWORD_ANY)/, @allowed_keywords )
        {
            # Clear any other column selections the user may have already requested.
            @list = ();
            push( @list, $KEYWORD_ANY );
            last; # don't allow user to add more.
        }
        elsif ( $colNum =~ m/^remaining$/i && grep /($KEYWORD_REMAINING)/, @allowed_keywords )
        {
            # Keep all the columns collected so far, but tack on the keyword as a marker
            # that the remaining fields (if any) should be appended in order.
            push( @list, $KEYWORD_REMAINING );
            last; # don't allow user to add more.
        }
        elsif ( $colNum =~ m/^continue$/i && grep /($KEYWORD_CONTINUE)/, @allowed_keywords )
        {
            # Keep all the columns collected so far, but tack on the keyword as a marker
            # that the remaining fields (if any) should be appended in order.
            push( @list, $KEYWORD_CONTINUE );
            last; # don't allow user to add more.
        }
        # $, $KEYWORD_REVERSE
        elsif ( $colNum =~ m/^last$/i && grep /($KEYWORD_LAST)/, @allowed_keywords )
        {
            # use the last column.
            push( @list, $KEYWORD_LAST );
            last; # don't allow user to add more.
        }
        elsif ( $colNum =~ m/^reverse$/i && grep /($KEYWORD_REVERSE)/, @allowed_keywords )
        {
            # use the last column.
            push( @list, $KEYWORD_REVERSE );
            last; # don't allow user to add more.
        }
        elsif ( $colNum =~ m/^exclude$/i && grep /($KEYWORD_EXCLUDE)/, @allowed_keywords )
        {
            # use the inverted set of columns.
            # Add the keyword as the FIRST element, then order_line() will exclude the rest of the listed columns
            unshift( @list, $KEYWORD_EXCLUDE );
        }
        else
        {
            print STDERR "** Warning: illegal column designation '$colNum', ignoring.\n";
        }
    }
    if ( scalar(@list) == 0 )
    {
        print STDERR "*** Error no valid columns selected. ***\n";
        exit;
    }
    print STDERR "columns requested: '@list'\n" if ( $opt{'D'} );
    return @list;
}

# Compression refers to removing white space and normalizing all
# alphabetic characters into upper case.
# param:  any string.
# return: input string with spaces removed and in upper case.

# Trim function to remove white space from the start and end of the string.
# This function is now imported from Pipe::Core
# (Original implementation moved to lib/Pipe/Core.pm)

# Prints the contents of the argument hash reference.
# param:  title of output.
# param:  hash reference of data.
# param:  List of columns requested by user.
# return: <none>
# print_summary function is now imported from Pipe::IO

# count function is now imported from Pipe::Math

# sum function is now imported from Pipe::Math

# width function is now imported from Pipe::Math

# average function is now imported from Pipe::Math

# Removes the white space from of specified columns.
# param:  line to pull out columns from.
# return: <none>.

# Normalizes specified columns, removing non-word characters.
# param:  line of columns of data.
# return: <none>.



# Test if argument is a number between 0-100.
# param:  number to test.
# return: 1 if the argument is a number between 0-100, and 0 otherwise.
sub is_between_zero_and_hundred( $ )
{
    my $testValue = shift;
    chomp $testValue;
    if ( $testValue =~ m/^\d{1,3}$/)
    {
        if ( 0 <= $testValue and $testValue <= 100 )
        {
            return 1;
        }
    }
    return 0;
}

# sort_list function is now imported from Pipe::Data

# Outputs data from argument line as a table of one type or another.
# param:  String of line data - pipe-delimited.
# return: <none>.

# Applies the mask specified in argument 2 to string in argument 1.
# param:  String - target of masking operation, the string data from this column.
# param:  String - mask specification.
# return: String modified by mask.

# Outputs masked column data as per specification. See usage().
# param:  String of line data - pipe-delimited.
# return: <none>.

# Outputs sub strings of column data as per specification. See usage().
# param:  String of line data - pipe-delimited.
# return: string with table formatting.

# Outputs sub strings of column data as per specification. See usage().
# param:  String of line data - pipe-delimited.
# return: string with table formatting.






# Applies padding to a given field.
# param:  string field to pad.
# param:  padding instructions.
# return: padded field.

# Outputs padded column data as per specification. See usage().
# Syntax: n.c, where n is an integer (either + for leading, or - for trailing), '.' and character(s) to
# be used as padding.
# param:  String of line data - pipe-delimited.
# return: string with padded formatting.




# Switches casing based on values supplied.
# param:  String field to be modified.
# param:  casing string expression. Must be one of [mc|lc|uc].
# return: New string with changes if any.

# Modifies the case of a string.
# param:  line from file.
# return: <none>.

# Flips Flips an arbitrary but specific character Conditionally,
# where 'n' is the 0-based index of the target character. A '?' means
# test the character equals p before changing it to q, and optionally change
# to r if the test fails. Works like an if statement.
# Example: '0000' -f'c0:2' => '0020', '0100' -f'c0:1.A?1' => '0A00',
# '0001' -f'c0:3.B?0.c' => '000c'.
# param:  line from file.
# return: <none>.

# Flips the specified character to the provided alternate character.
# param:  String containing the site of the target character.
# param:  target integer of index into the string of the replacement site.
# param:  Character to test, also equal to replacement character in simple case.
# param:  character condition to be met before replacing.
# param:  character replacement if condition not met.
# return: String with the specified modifications.

# Replaces one string for another.
# param:  line from file.
# return: <none>.

# Applies a translation to specified column(s).
# param:  line of pipe delimited columns.
# return: <none>.

# This function fixes lines that have trailing empty pipe columns. If it is not used
# lines are truncated after the last content-filled column.
# param:  original line sent to the calling function.
# param:  line after any modification.
# param:  line number for reporting.
# return: modified line with additional pipes if required.
sub validate( $$$ )
{
    my ( $original, $modified, $line_no ) = @_;
    my $count       = ( $original =~ tr/\|// );
    my $final_count = ( $modified =~ tr/\|// );
    printf STDERR "original: %d, modified: %d fields at line number %s.\n", $count, $final_count, $line_no if ( $opt{'D'} );
    # if ( $opt{'V'} ) # Original
    if ( $opt{'o'} ) # If you select -o this doesn't get done or extra fields are added even if you select 'V'
    {
        # But pad to the width of the columns selected -1, because pipe doesn't add a terminal pipe by default.
        if ( $RELAX_o_EXCLUDE )
        {
            my @original_cols = split( /\|/, $original );
            $count = ( scalar( @original_cols ) -1 ) - ( scalar(@ORDER_COLUMNS) -1 );
        }
        else
        {
            $count = scalar @ORDER_COLUMNS -1 if ( $count > scalar @ORDER_COLUMNS -1 );
        }
    }
    # Normally this ensures the total number of columns in == out, but collapse
    # can be set in the '-e' flag (modify_case_line() function).
    if ( $final_count < $count && $COLLAPSE_OPTION == 0 )
    {
        my $iterations = $count - $final_count;
        my $i = 0;
        for ( $i = 0; $i < $iterations; $i++ )
        {
            $modified .= '|';
        }
    }
    return $modified;
}

# Replaces a string conditionally.
# param:  target string of the replacement.
# param:  String to replace the target.
# param:  condition to test target string.
# param:  replacement string on failure of conditional testing.
# return: resultant string.

# Applies format to requested string.
# param:  String for conversion.
# param:  Conversion type 'c', 'b', 'h', 'd'.
# return: String with the specified modifications.
sub convert_format( $$ )
{
    my ( $field, $format ) = @_;
    my @format_parts       = split /\./, $format;
    @format_parts          = grep /\S/, @format_parts;
    # @format_parts can have 1 or 2 radix defined. If there is 1 the radix is
    # the destination radix. If there are 2 the second is the destination radix
    # and the source radix is the first value. If the user defines a from radix
    # no matter what the data is, convert it to decimal, ready for the next step
    # which will take the decimal number and convert it to the appropriate
    # destination radix.
    # To accomadate strings use an array.
    my @in_array = ();
    if ( $format_parts[1] )
    {
        if ( $format_parts[0] =~ /b/i )
        {
            push @in_array, oct( "0b" . $field );
        }
        elsif ( $format_parts[0] =~ /h/i )
        {
            push @in_array, oct( "0x" . $field );
        }
        elsif ( $format_parts[0] =~ /c/i )
        {
            @in_array = unpack( "C*", $field ); # Converts all values into ints.
        }
        else # Decimal
        {
            push @in_array, $field;
        }
        # Set the destination radix for the remainder of the calculation 
        $format_parts[0] = $format_parts[1];
    }
    if ( $format_parts[0] =~ /c/i )
    {
        return pack( "C*", @in_array);
    }
    # So not a string so the value in $in_array[0] should be all there is to convert.
    $field = join '', @in_array;
    if ( $format_parts[0] =~ /b/i )
    {
        return sprintf( "%b", $field );
    }
    elsif ( $format_parts[0] =~ /h/i )
    {
        return sprintf( "%x", $field );
    }
    elsif ( $format_parts[0] =~ /d/i )
    {
        return sprintf( "%d", $field );
    }
    else
    {
        printf STDERR "** error unsupported option: '%s' \n", $format_parts[0];
        exit(1);
    }
}

# Formats the specified column to the desired base type.
# param:  Original line input.
# return: <none>.
sub format_radix( $ )
{
    my $line = shift;
    my $i    = 0;
    for ( $i = 0; $i < scalar( @{ $line } ); $i++ )
    {
        if ( defined $FORMAT_COLUMNS[ $i ] and exists $format_ref->{ $i } )
        {
            printf STDERR "format expression: '%s' \n", $format_ref->{$i} if ( $opt{'D'} );
            @{ $line }[ $i ] = convert_format( @{ $line }[ $i ], lc ( $format_ref->{ $i } ) );
        }
    }
}

# Executes script listed in '-k'.
# param:  line input.
# return: <none>.
# throws: exits on syntax error.
sub execute_script_line( $ )
{
    if ( $ALLOW_SCRIPTING == $FALSE )
    {
        printf STDERR "* warning scripting not allowed, ask an administrator for assistance.\n";
        exit( 99 );
    }
    my $line = shift;
    foreach my $colIndex ( @SCRIPT_COLUMNS )
    {
        if ( defined @{ $line }[ $colIndex ] )
        {
            if ( $script_ref->{ $colIndex } !~ m/(rm|unlink|erase|del)/i )
            {
                my $value = @{ $line }[ $colIndex ]; # Reference name for the executing script.
                printf STDERR "\$value = '%s', script: '%s'\n", $value, $script_ref->{ $colIndex } if ( $opt{'D'} );
                eval $script_ref->{ $colIndex };
                if ( $@ )
                {
                    print "Warning: error during evaluation, no changes made. $@";
                }
                else
                {
                    @{ $line }[ $colIndex ] = $value;
                    printf STDERR "\@{ \$line }[ \$colIndex ] = '%s'\n", @{ $line }[ $colIndex ] if ( $opt{'D'} );
                }
            }
            else
            {
                printf STDERR "* warning refusing to execute: '%s'\n", $script_ref->{ $colIndex };
            }
        }
    }
}

# inc_line function is now imported from Pipe::Math

# inc_line_by_value function is now imported from Pipe::Math

# do_math function is now imported from Pipe::Math

# delta_previous_line function is now imported from Pipe::Math

# add_auto_increment function is now imported from Pipe::Math

# histogram function is now imported from Pipe::Math

# Computes and returns a value based on whether -A (count) or -J (sum) is used.
# param:  column to select within line. Like 'c2'.
# param:  line of input.
# return: numerical value to be added to the running total.

# Formats a value into a string suitable for display. In the case of a float it provides
# 2 decimal place precision, and if the value is an integer, no decimals places are added.
# param:  value, which is tested against various number formats and returns a string
#         version of the argument value.
# param:  Expected values 0=any, 1=whole number (optional).
# param:  Precision of decimal places in floating values (optional).
# return: Formatted string value of the argument.
# get_number_format function is now imported from Pipe::Core
# (Original implementation moved to lib/Pipe/Core.pm)

# do_op function is now imported from Pipe::Math

# dedup_list function is now imported from Pipe::Data

# randomize_list function is now imported from Pipe::Data

# Performs operations that require the entire file to be read
# This includes deduplication, sorting, randomization, and averaging  
# param: None (operates on global variables)
# return: None
sub finalize_full_read_functions()
{
    if ( $opt{'d'} )
    {
        Pipe::Data::dedup_list( \@DDUP_COLUMNS );
    }
    if ( $opt{'r'} ) # select 'n'% of file at random for output.
    {
        Pipe::Data::randomize_list();
    }
    if ( $opt{'s'} )# Sort the items from STDIN.
    {
        # We have a list of lines. We will split them creating a key that we append to the start with a delimiter of ''
        # When it comes time to sort use the default sort in perl and then remove the prefix.
        Pipe::Data::sort_list( \@SORT_COLUMNS );
    }
    if ( $opt{'v'} ) # Compute averages now we have read the entire input.
    {
        foreach my $column ( keys %{$avg_ref} )
        {
            if ( exists $avg_count->{ $column } and $avg_count->{ $column } != 0 )
            {
                my $result = sprintf "%.3f", ( $avg_ref->{ $column } / $avg_count->{ $column } );
                # replace the previous column sum with the average.
                $avg_ref->{ $column } = $result;
            }
        }
    }
}

# After you have finished reading and processing all lines in the input file
# this function will manage the output.
# param:  <none>
# return: <none>

# Tests if this is a line that the user requested to be output.
# param:  integer line number.
# param:  Line read in.
# return: 1 if this line is requested by the user and 0 otherwise.
sub is_printable_range( $$ )
{
    # The key is the start range the value the end of the range.
    my $line_num = shift;
    my $max_line_so_far = 0;
    my $ret_value= 0;
    foreach my $key ( keys %$LINE_RANGES )
    {
        $max_line_so_far = $LINE_RANGES->{ $key } if ( $max_line_so_far <= $LINE_RANGES->{ $key } );
        # are we talking about the end of the file? If so the the key will be negative and full read set true.
        if ( $READ_FULL and $key < 0 )
        {
            push @LINE_BUFF, shift;
            shift @LINE_BUFF if ( scalar @LINE_BUFF > $KEEP_LINES );
            next;
        }
        # printf STDERR "testing if %d is >= %d and <= %d\n", $line_num, $key, $LINE_RANGES->{ $key };
        if ( $line_num >= $key and $line_num <= $LINE_RANGES->{ $key } )
        {
            $ret_value = 1;
        }
    }
    $FAST_FORWARD = 1 if ( $line_num >= $max_line_so_far );
    return $ret_value;
}

# Takes a string and encodes it with URL-safe characters.
# param:  string.
# return: encoded string.
# map_url_characters function is now imported from Pipe::IO

# Performs URL encoding of given columns.
# param:  line from input.
# return: <none>.

# Builds a map of URL characters to URL encoded values.
# param:  <none>
# return: <none>
# build_encoding_table function is now imported from Pipe::IO

# Outputs table header or footer, depending on argument string.
# param:  String of either 'HEAD' or 'FOOT'.
# return: <none>




# This function abstracts all line operations for line by line operations.
# param:  line from file.
# return: Modified line.
sub process_line( $ )
{
    # Always output if -g, -C, or -G match or not, but if matches additional processing will be done.
    # We turn it on by default so if -g or -G not used the line will get processed as normal.
    my $line = shift;
    chomp $line;
    # With -W the line will look like this; '11|abc{_PIPE_}def'
    my @columns = split '\|', $line;
    if ( $opt{'W'} )
    {
        foreach my $col ( @columns )
        {
            # Replace the sub delimiter to preserve the default pipe delimiter when using -W.
            $col =~ s/($SUB_DELIMITER)/\|/g;
        }
    }
    if ( $opt{'X'} || $opt{'Y'} )
    {
        if ( $opt{'Y'} && $IS_X_MATCH && Pipe::Match::is_match( \@columns, $match_y_ref, \@MATCH_Y_COLUMNS ) )
        {
            $IS_Y_MATCH = 1;
            $continue_to_process_match = 0;
        }
        if ( $opt{'X'} && Pipe::Match::is_match( \@columns, $match_start_ref, \@MATCH_START_COLS ) )
        {
            $continue_to_process_match = 1;
            $IS_X_MATCH = 1;
            $H_MATCH++;
        }
        if ( $IS_X_MATCH )
        {
            push @FRAME_BUFFER, $line if ( $opt{'g'} ); # Don't fill the buffer unless -g is used.
        }
        if ( $opt{'g'} && $IS_X_MATCH && Pipe::Match::is_match( \@columns, $match_ref, \@MATCH_COLUMNS ) )
        {
            $IS_DUMPABLE_MATCH = 1;
        }
        if ( $IS_Y_MATCH ) # If we had a match turn it off. This line of the file will continue to process, capturing
        { # and outputting the Y match. The next line will be suppressed.
            while ( @FRAME_BUFFER )
            {
                my $frame_line = shift @FRAME_BUFFER;
                if ( $IS_DUMPABLE_MATCH )
                {
                    if ( $opt{'N'} )
                    {
                        printf STDERR "%s\n", $frame_line;
                    }
                    else
                    {
                        printf STDERR "=>%s\n", $frame_line;
                    }
                }
            }
            $IS_DUMPABLE_MATCH = 0;
            $IS_X_MATCH = 0;
            $IS_Y_MATCH = 0;
        }
        else
        {
            return '' if ( ! $continue_to_process_match );
        }
    }
    else # If 'X' or 'Y' not selected then make sure the rest of the lines get processed normally.
    {
        $continue_to_process_match = 1;
    }
    # if the line isn't to be selected for output by '-L skip' return early.
    return '' if ( $SKIP_LINE > 0 and $LINE_NUMBER % $SKIP_LINE != 0 );
    # This function allows the line by line operations to work with operations
    # that require the entire file to be read before working (like sort and dedup).
    # Each operation specified by a different flag.
    if ( $opt{'g'} or $opt{'G'} )
    {
        if ( $opt{'Q'} and $IS_A_POST_MATCH ) # There was a match so dump the buffer if we have been filling it.
        {
            if ( $opt{'N'} )
            {
                printf STDERR "%s\n", $line;
            }
            else
            {
                printf STDERR "=>%s\n", $line;
            }
            $IS_A_POST_MATCH -= 1;
        }
        # Grep comes first because it assumes that non-matching lines don't require additional operations.
        if ( $opt{'g'} and $opt{'G'} )
        {
            if ( $opt{'Q'} )
            {
                # no match but save the line in case there is a match some time within the next '-Q' lines.
                unshift @PREVIOUS_LINES, $line;
                pop @PREVIOUS_LINES if ( @PREVIOUS_LINES && scalar @PREVIOUS_LINES > $BUFF_SIZE );
            }
            if ( ! ( Pipe::Match::is_match( \@columns, $match_ref, \@MATCH_COLUMNS ) and Pipe::Match::is_not_match( \@columns ) ) )
            {
                if ( $opt{'i'} )
                {
                    $continue_to_process_match = 0; # let the line contents through but additional processing will be done.
                }
                else
                {
                    return '';
                }
            }
        }
        elsif ( $opt{'g'} and ! Pipe::Match::is_match( \@columns, $match_ref, \@MATCH_COLUMNS ) )
        {
            if ( $opt{'Q'} )
            {
                # no match but save the line in case there is a match some time within the next '-Q' lines.
                unshift @PREVIOUS_LINES, $line;
                pop @PREVIOUS_LINES if ( @PREVIOUS_LINES && scalar @PREVIOUS_LINES > $BUFF_SIZE );
            }
            if ( $opt{'i'} )
            {
                $continue_to_process_match = 0;
            }
            else
            {
                return '';
            }
        }
        elsif ( $opt{'G'} and ! Pipe::Match::is_not_match( \@columns ) )
        {
            if ( $opt{'Q'} )
            {
                # no match but save the line in case there is a match some time within the next '-Q' lines.
                unshift @PREVIOUS_LINES, $line;
                pop @PREVIOUS_LINES if ( @PREVIOUS_LINES && scalar @PREVIOUS_LINES > $BUFF_SIZE );
            } 
            if ( $opt{'i'} )
            {
                $continue_to_process_match = 0;
            }
            else
            {
                return '';
            }
        }
        else # One of the above conditions matched.
        {
            $MATCH_COUNT++;
            if ( $opt{'Q'} && $BUFF_SIZE > 0) # There was a match so dump the buffer but only if user wanted more than 0 buffers in the first place.
            {
                while ( @PREVIOUS_LINES )
                {
                    if ( $opt{'N'} )
                    {
                        printf STDERR "%s\n", pop @PREVIOUS_LINES;
                    }
                    else
                    {
                        printf STDERR "<=%s\n", pop @PREVIOUS_LINES;
                    }
                }
                $IS_A_POST_MATCH = $BUFF_SIZE;
            }
        }
    }
    if ( $opt{'C'} )
    {
        if ( ! Pipe::Match::test_condition( \@columns ) )
        {
            if ( $opt{'i'} )
            {
                $continue_to_process_match = 0; # let the line contents through but additional processing will be done.
            }
            else
            {
                return '';
            }
        }
        else
        {
            $MATCH_COUNT++;
        }
    }
    if ( $opt{'b'} )
    {
        if ( ! Pipe::Match::contain_same_value( \@columns, \@COMPARE_COLUMNS ) )
        {
            if ( $opt{'i'} )
            {
                $continue_to_process_match = 0; # let the line contents through but additional processing will be done.
            }
            else
            {
                return '';
            }
        }
        else
        {
            $MATCH_COUNT++;
        }
    }
    if ( $opt{'B'} )
    {
        if ( Pipe::Match::contain_same_value( \@columns, \@NO_COMPARE_COLUMNS ) )
        {
            if ( $opt{'i'} )
            {
                $continue_to_process_match = 0; # let the line contents through but additional processing will be done.
            }
            else
            {
                return '';
            }
        }
        else
        {
            $MATCH_COUNT++;
        }
    }
    if ( $opt{'z'} )
    {
        if ( Pipe::Match::is_empty( \@columns ) )
        {
            if ( $opt{'i'} )
            {
                $continue_to_process_match = 0; # let the line contents through but additional processing will be done.
            }
            else
            {
                return '';
            }
        }
        else
        {
            $MATCH_COUNT++;
        }
    }
    if ( $opt{'Z'} )
    {
        if ( Pipe::Match::is_not_empty( \@columns ) )
        {
            if ( $opt{'i'} )
            {
                $continue_to_process_match = 0; # let the line contents through but additional processing will be done.
            }
            else
            {
                return '';
            }
        }
        else
        {
            $MATCH_COUNT++;
        }
    }
    if ( $continue_to_process_match )  ##### Majority of the testing and operations take place in this block.
    {
        Pipe::Column::merge_reference_file( \@columns )   if ( $IS_DATA_TO_MERGE ); ## -M + -0
        Pipe::Math::inc_line( \@columns  )              if ( $opt{'1'} );
        Pipe::Math::inc_line_by_value( \@columns )      if ( $opt{'3'} );
        Pipe::Math::delta_previous_line( \@columns )    if ( $opt{'4'} );
        execute_script_line( \@columns  )   if ( $opt{'k'} );
        Pipe::Text::modify_case_line( \@columns, $case_ref ) if ( $opt{'e'} );
        Pipe::Text::replace_line( \@columns )           if ( $opt{'E'} );
        Pipe::Text::flip_char_line( \@columns )         if ( $opt{'f'} );
        format_radix( \@columns )           if ( $opt{'F'} );
        Pipe::Text::url_encode_line( \@columns )        if ( $opt{'u'} );
        Pipe::Text::translate_line( \@columns )         if ( $opt{'l'} );
        Pipe::Text::mask_line( \@columns )              if ( $opt{'m'} );
        Pipe::Text::sub_string_line( \@columns )        if ( $opt{'S'} );
        Pipe::Text::normalize_line( \@columns, \@NORMAL_COLUMNS ) if ( $opt{'n'} );
        Pipe::Text::trim_line( \@columns, \@TRIM_COLUMNS ) if ( $opt{'t'} );
        Pipe::Text::pad_line( \@columns )               if ( $opt{'p'} );
        Pipe::Math::width( \@columns, $LINE_NUMBER )    if ( $opt{'w'} );
        Pipe::Math::sum( \@columns )                    if ( $opt{'a'} );
        Pipe::Math::count( \@columns )                  if ( $opt{'c'} );
        Pipe::Math::average( \@columns )                if ( $opt{'v'} );
        Pipe::Math::do_math( \@columns )                if ( $opt{'?'} );
        Pipe::Column::merge_line( \@columns )             if ( $opt{'O'} );
        Pipe::Column::order_line( \@columns, \@ORDER_COLUMNS ) if ( $opt{'o'} );
        Pipe::Math::add_auto_increment( \@columns )     if ( $opt{'2'} );
        Pipe::Math::histogram( \@columns )              if ( $opt{'6'} );
    }
    my $modified_line = '';
    if ( $TABLE_OUTPUT )
    {
        Pipe::IO::prepare_table_data( \@columns );
        $modified_line = join '', @columns;
        return $modified_line; # The rest of the computation is not relavent to tables.
    }
    if ( $opt{'W'} )
    {
        foreach my $col ( @columns )
        {
            # Replace the sub delimiter to preserve the default pipe delimiter when using -W.
            $col =~ s/\|/$SUB_DELIMITER/g;
        }
    }
    $modified_line = join '|', @columns;
    $line = validate( $line, $modified_line, $LINE_NUMBER );
    chomp $line;
    $line =~ s/\|/\n/g if ( $opt{'K'} );
    # Don't add a delimiter on the last line if not -j and not the last line.
    $line .= '|' if ( trim( $line ) !~ m/\|$/ and $opt{'P'} );
    chop $line if ( $opt{'j'} and $LAST_LINE and $opt{'P'} );
    $line =~ s/\|/$DELIMITER/g if ( $opt{'h'} );
    # Replace the sub delimiter to preserve the default pipe delimiter when using -W.
    $line =~ s/($SUB_DELIMITER)/\|/g if ( $opt{'W'} );
    if ( $opt{'Q'} )
    {
        # no match but save the line in case there is a match some time within the next '-Q' lines.
        unshift @PREVIOUS_LINES, $line;
        pop @PREVIOUS_LINES if ( @PREVIOUS_LINES && scalar @PREVIOUS_LINES > $BUFF_SIZE );
    }
    # Output line numbering, but if -d selected, output dedup'ed counts instead.
    if ( ( $opt{'A'} or $opt{'J'} ) and ! $opt{'d'} )
    {
        if ( $opt{'P'} )
        {
            return sprintf "%d%s%s\n", $LINE_NUMBER, $DELIMITER, $line;
        }
        else
        {
            return sprintf "%3d %s\n", $LINE_NUMBER, $line;
        }
    }
    if ( $opt{'H'} )
    {
        # The initial value is -1. -X inc count but to avoid an unnecessary '\n' for first -X match.
        if ( $H_MATCH > 0 )
        { 
            $H_MATCH = 0; # Set this when -X first match occurs, but reset it until -X matches again.
            return "\n" . $line;
        }
        return $line . "\n" if ( $opt{'q'} && $LINE_NUMBER % $JOIN_COUNT == 0 ); # Join lines until -q number of lines is emitted.
        return $line . "\n" if ( $opt{'i'} && ! $continue_to_process_match ); # Suppress line output on -g match but no other lines.
        return $line;
    }
    return $line . "\n";
}

# Kicks off the setting of various switches.
# param:
# return:
sub init
{
    my $opt_string = '?:0:1:2:3:4:56:7:8:a:Ab:B:c:C:d:De:E:f:F:g:G:h:HiIjJ:k:Kl:L:m:M:Nn:o:O:p:Pq:Q:r:Rs:S:t:T:Uu:v:Vw:W:xX:y:Y:z:Z:';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if ( $opt{'x'} );
    if ( $opt{'M'} && $opt{'0'} )
    {
        @MERGE_SRC_COLUMNS = Pipe::Column::read_requested_qualified_columns( $opt{'M'}, $merge_expression_ref );
    }
    elsif ( $opt{'M'} )
    {
        printf STDERR      "*** -M is obsolete without '-0'.\nSee usage (-x) for more information.\n";
    }
    $BUFF_SIZE         = Pipe::Column::read_whole_number( $opt{'Q'} ) if ( $opt{'Q'} );
    $PRECISION         = Pipe::Column::read_whole_number( $opt{'y'} ) if ( $opt{'y'} );
    $MATCH_LIMIT       = Pipe::Column::read_whole_number( $opt{'7'} ) if ( $opt{'7'} );
    $DELIMITER         = $opt{'h'} if ( $opt{'h'} );
    $JOIN_COUNT        = Pipe::Column::read_whole_number( $opt{'q'} ) if ( $opt{'q'} );
    @INCR_COLUMNS      = read_requested_columns( $opt{'1'} ) if ( $opt{'1'} );
    @INCR3_COLUMNS     = Pipe::Column::read_requested_qualified_columns( $opt{'3'}, $increment_ref ) if ( $opt{'3'} );
    @DELTA4_COLUMNS    = read_requested_columns( $opt{'4'} ) if ( $opt{'4'} );
    @SUM_COLUMNS       = read_requested_columns( $opt{'a'} ) if ( $opt{'a'} );
    @COUNT_COLUMNS     = read_requested_columns( $opt{'c'} ) if ( $opt{'c'} );
    @EMPTY_COLUMNS     = read_requested_columns( $opt{'z'} ) if ( $opt{'z'} );
    @SHOW_EMPTY_COLUMNS= read_requested_columns( $opt{'Z'} ) if ( $opt{'Z'} );
    if ( $opt{'u'} )
    {
        Pipe::IO::build_encoding_table();
        @U_ENCODE_COLUMNS = read_requested_columns( $opt{'u'}, $KEYWORD_ANY );
    }
    @COND_CMP_COLUMNS  = Pipe::Column::read_requested_qualified_columns( $opt{'C'}, $cond_cmp_ref, $KEYWORD_ANY, $KEYWORD_NUM_COLS )    if ( $opt{'C'} );
    @MATH_COLUMNS      = Pipe::Column::read_requested_qualified_columns( $opt{'?'}, $math_ref )        if ( $opt{'?'} );
    @CASE_COLUMNS      = Pipe::Column::read_requested_qualified_columns( $opt{'e'}, $case_ref, $KEYWORD_ANY )        if ( $opt{'e'} );
    @REPLACE_COLUMNS   = Pipe::Column::read_requested_qualified_columns( $opt{'E'}, $replace_ref )     if ( $opt{'E'} );
    @NOT_MATCH_COLUMNS = Pipe::Column::read_requested_qualified_columns( $opt{'G'}, $not_match_ref, $KEYWORD_ANY )   if ( $opt{'G'} );
    @MATCH_COLUMNS     = Pipe::Column::read_requested_qualified_columns( $opt{'g'}, $match_ref, $KEYWORD_ANY )       if ( $opt{'g'} );
    @MATCH_START_COLS  = Pipe::Column::read_requested_qualified_columns( $opt{'X'}, $match_start_ref, $KEYWORD_ANY ) if ( $opt{'X'} );
    @MATCH_Y_COLUMNS   = Pipe::Column::read_requested_qualified_columns( $opt{'Y'}, $match_y_ref, $KEYWORD_ANY )     if ( $opt{'Y'} );
    @SCRIPT_COLUMNS    = Pipe::Column::read_requested_qualified_columns( $opt{'k'}, $script_ref )      if ( $opt{'k'} );
    @MASK_COLUMNS      = Pipe::Column::read_requested_qualified_columns( $opt{'m'}, $mask_ref, $KEYWORD_ANY  )        if ( $opt{'m'} );
    @SUBS_COLUMNS      = Pipe::Column::read_requested_qualified_columns( $opt{'S'}, $subs_ref )        if ( $opt{'S'} );
    @TRANSLATE_COLUMNS = Pipe::Column::read_requested_qualified_columns( $opt{'l'}, $trans_ref, $KEYWORD_ANY )       if ( $opt{'l'} );
    @PAD_COLUMNS       = Pipe::Column::read_requested_qualified_columns( $opt{'p'}, $pad_ref )         if ( $opt{'p'} );
    @FLIP_COLUMNS      = Pipe::Column::read_requested_qualified_columns( $opt{'f'}, $flip_ref )        if ( $opt{'f'} );
    @FORMAT_COLUMNS    = Pipe::Column::read_requested_qualified_columns( $opt{'F'}, $format_ref )      if ( $opt{'F'} );
    @COMPARE_COLUMNS   = read_requested_columns( $opt{'b'} )                             if ( $opt{'b'} );
    @NO_COMPARE_COLUMNS= read_requested_columns( $opt{'B'} )                             if ( $opt{'B'} );
    @NORMAL_COLUMNS    = read_requested_columns( $opt{'n'}, $KEYWORD_ANY )               if ( $opt{'n'} );
    @MERGE_COLUMNS     = read_requested_columns( $opt{'O'}, $KEYWORD_ANY )               if ( $opt{'O'} );
    @ORDER_COLUMNS     = read_requested_columns( $opt{'o'}, $KEYWORD_REMAINING, $KEYWORD_CONTINUE, $KEYWORD_LAST, $KEYWORD_REVERSE, $KEYWORD_EXCLUDE )    if ( $opt{'o'} );
    @TRIM_COLUMNS      = read_requested_columns( $opt{'t'}, $KEYWORD_ANY )               if ( $opt{'t'} );
    if ( $opt{'2'} )
    {
        ($AUTO_INCR_COLUMN, $AUTO_INCR_SEED, $AUTO_INCR_RESET) = parse_single_column_single_argument( $opt{'2'} );
        $AUTO_INCR_ORIG_VALUE = $AUTO_INCR_SEED;
    }
    @HISTOGRAM_COLUMN  = Pipe::Column::read_requested_qualified_columns( $opt{'6'}, $hist_ref )        if ( $opt{'6'} );
    if ( $opt{'v'} )
    {
        @AVG_COLUMNS   = read_requested_columns( $opt{'v'} ) if ( $opt{'v'} );
        $READ_FULL = 1;
    }
    if ( $opt{'d'} )
    {
        @DDUP_COLUMNS  = read_requested_columns( $opt{'d'} );
        $READ_FULL = 1;
    }
    # Output specific lines.
    if ( $opt{'L'} )
    {
        parse_line_ranges( $opt{'L'} );
        if ( $opt{'D'} )
        {
            foreach ( my ( $start, $end ) = each %$LINE_RANGES )
            {
                printf STDERR "line selection range %d to %d\n", $start, $end;
            }
        }
    }
    if ( $opt{'r'} )
    {
        $READ_FULL = 1;
        if ( ! is_between_zero_and_hundred( $opt{'r'} ) )
        {
            print STDERR "** error, invalid random percentage selection.\n";
            exit;
        }
    }
    if ( $opt{'s'} )
    {
        @SORT_COLUMNS  = read_requested_columns( $opt{'s'} );
        $READ_FULL = 1;
    }
    if ( $opt{'w'} )
    {
        @WIDTH_COLUMNS  = read_requested_columns( $opt{'w'} );
        $READ_FULL = 1;
    }
    if ( $opt{'T'} )
    {
        my @attrs     = split ':', $opt{'T'};
        $TABLE_OUTPUT = shift @attrs;
        # Shift of 'HTML' or 'WIKI' and re-join the rest of the string to account for ':' separators in both CSS AND Wiki attributes.
        $TABLE_ATTR   = ' ' . join ':', @attrs if ( scalar( @attrs ) > 0 );
    }
}

# This parses a string into a set of commands to be consumed by other functions. The 
# command strings include columns (denoted with 'cn'), separated with a delimiter token of '+'.
# The returned string may also include literal strings. Use '\+' if you wish to include 
# a '+' in the literal string.
# param:  array reference of column indexes. This is where you intend to store the columns that
#         the consuming function will operate on.
# param:  The input string. Example: 'c100+"dog eat dog"+c 2'
# param:  1 if literal terms (used to fill in false values optionally), or 0, specifies columns
#         all of which will be expected to be in the form of '[c|C]n' where n is a positive integer.
# return: None. Side effect: argument array reference will contain integers, and strings.
sub get_col_num_or_literal_command( $$$ )
{
    my $array_ref = shift;
    my $line_string = shift;
    my $is_literal_string = shift;
    # Split on column identifiers, making sure we don't pick up any empty or blank column identifiers.
    my @tmp = ();
    if ( $is_literal_string )
    {
        @tmp = split( /\+/, $line_string ) if ( $line_string );
        push(@tmp, $line_string) if ( ! @tmp );
    }
    else
    {
        @tmp = grep { /\S/ } split( /\+?\s?c/i, $line_string ) if ( $line_string );
    }
    foreach my $i ( @tmp )
    {
        push @{$array_ref}, $i if ( defined $i );
    }
}

# Take the line input. Its the columns from the alternate file with the key of the comparison field.
# Later we will add it to the line(s) from the data coming in (from STDIN).
# return: nothing, but a hash reference is built of compare column keys, with merge columns as values.
sub parse_M_line()
{
    # parse the expression that describes which columns of the ref file we want.
    # -Mc1:c2?c3.c4 but more generally -Mcn:"[cm,...|'literal']?[cp,...|'literal'].[cq,...|'literal']"
    foreach my $key ( keys %{$merge_expression_ref} )
    {
        printf STDERR "key : '%s' \n", $merge_expression_ref->{ $key } if ( $opt{'D'} );
        # EXPRESSION [col_input]:[col_ref]?[true column index or literal].[false literal]
        # Example: [col_input]:'c2?c3', OR: 'c4'
        # Split on the '.'. The LHS is the test operator and true expression, the RHS is the false expression.
        my ( $token, $ref_false_literals ) = split( m/(?<!\\)\./, $merge_expression_ref->{ $key } );
        # Split the LHS on the '?'. The LHS of this operation is the column to compare to the column of the input file. The RHS is the true expression.
        my ( $ref_file_columns, $ref_true_cols ) = split( m/(?<!\\)\?/, $token );
        printf STDERR "ref_file_columns : '%s', ref_true_cols : '%s', ref_false_literals: '%s'\n", $ref_file_columns, $ref_true_cols, $ref_false_literals if ( $opt{'D'} );
        get_col_num_or_literal_command( \@MERGE_REF_COLUMNS, $ref_file_columns, 0 ); # Parse out the column(s) for matching.
        get_col_num_or_literal_command( \@REF_COLUMN_INDEX_TRUE, $ref_true_cols, 0 ); # Parse out the column(s) used if match true.
        get_col_num_or_literal_command( \@REF_LITERALS_FALSE, $ref_false_literals, 1 ); # Parse out the literals used if match false.
    }
}

# Used to collect the requested fields from the reference document read with -0. 
# Each column selection is saved and appended if the match turns out to be true.
# push_merge_ref_columns function is now imported from Pipe::Data

init();

# Initialize context object after options are processed
$ctx = Pipe::Context->new();
$ctx->set_options(\%opt);

Pipe::IO::table_output("HEAD") if ( $TABLE_OUTPUT );
my $ifh;
my $is_stdin = 0;
# If both switches are used together we expect input on STDIN and with '-0'.
if ( defined $opt{'0'} && defined $opt{'M'} )
{
    # parse the command line after -M
    parse_M_line();
    #### We store an array ref of all the columns to merge if true (and false) but we have to have
    #### them in a hash for quick lookup by the specified value key. *** ADD THAT HERE.
    if ( $opt{'D'} )
    {
        printf STDERR "start => ";
        foreach my $i ( keys %{$REF_FILE_DATA_HREF} )
        {
            printf STDERR "%s, ", %{$REF_FILE_DATA_HREF}->[$i];
        }
        printf STDERR "TRUE_VALUES<=\n=>FALSE_VALUES ";
        foreach my $i ( @REF_LITERALS_FALSE )
        {
            printf STDERR "%s, ", $i;
        }
        printf STDERR "<= end\n";
    }
    open $ifh, "<", $opt{'0'} or die $!;
    binmode $ifh;
    # Read the entire merging file.
    while (<$ifh>)
    {
        my $line = trim( $_ );
        if ( $opt{'8'} )
        {
            @ALT_LINES = split( /($opt{'8'})/, $line );
        }
        else
        {
            unshift( @ALT_LINES, $line );
        }
        while ( @ALT_LINES )
        {
            $line = shift( @ALT_LINES );
            next if ( $opt{'8'} && $line =~ /($opt{'8'})/ );
            if ( $opt{'W'} )
            {
                my @segments = split /"/, $line;  # fix SO syntax highlighting: "
                push @segments, '' if ( scalar( @segments ) % 2 == 0 );
                s/($opt{'W'})/$QUOTED_DELIMITER/g for @segments[ grep $_ % 2, 0 .. $#segments ];
                $line = join '"', @segments;
                # Replace delimiter selection with '|' pipe.
                $line =~ s/\|/$SUB_DELIMITER/g; # _PIPE_
                # Now replace the user selected delimiter with a pipe.
                $line =~ s/($opt{'W'})/\|/g;
                my $spc_delim = $opt{'W'};
                $spc_delim =~ s/\\s[+]?/ /g;
                $line =~ s/($QUOTED_DELIMITER)/$spc_delim/g;
            }
            my @columns = split '\|', $line;
            if ( $opt{'W'} )
            {
                foreach my $col ( @columns )
                {
                    # Replace the sub delimiter to preserve the default pipe delimiter when using -W.
                    $col =~ s/($SUB_DELIMITER)/\|/g;
                }
            }
            # Save all the true and false column values.
            Pipe::Data::push_merge_ref_columns( \@REF_COLUMN_INDEX_TRUE, \@columns, $MERGE_REF_COLUMNS[0] );
            # The false values are literals taken from the command line.
        }
    }
    close $ifh;
    
    # Now return STDIN as the input stream.
    $ifh = *STDIN;
    binmode $ifh;
    $is_stdin++;
    $IS_DATA_TO_MERGE = keys %{$REF_FILE_DATA_HREF}; # Set true if there are values stored in the hash reference.
}
elsif ( defined $opt{'0'} )
{
    open $ifh, "<", $opt{'0'} or die $!;
    binmode $ifh;
}
else
{
    $ifh = *STDIN;
    binmode $ifh;
    $is_stdin++;
}
while (<$ifh>)
{
    my $line = $_;
    if ( $opt{'8'} )
    {
        @ALT_LINES = split( /($opt{'8'})/, $line );
    }
    else
    {
        unshift( @ALT_LINES, $line );
    }
    while ( @ALT_LINES )
    {
        $line = shift( @ALT_LINES );
        next if ( $opt{'8'} && $line =~ /($opt{'8'})/ );
        $LINE_NUMBER++;
        if ( is_printable_range( $LINE_NUMBER, $line ) )
        {
            # remove leading trailing white space to avoid initial empty pipe fields.
            # Also gracefully handles Windows' EOL handling.
            $line = trim( $line );
            if ( $opt{'W'} )
            {
                my @segments = split /"/, $line;  # fix SO syntax highlighting: "
                push @segments, '' if ( scalar( @segments ) % 2 == 0 );
                s/($opt{'W'})/$QUOTED_DELIMITER/g for @segments[ grep $_ % 2, 0 .. $#segments ];
                $line = join '"', @segments;
                # Replace delimiter selection with '|' pipe.
                $line =~ s/\|/$SUB_DELIMITER/g; # _PIPE_
                # Now replace the user selected delimiter with a pipe.
                $line =~ s/($opt{'W'})/\|/g;
                my $spc_delim = $opt{'W'};
                $spc_delim =~ s/\\s[+]?/ /g;
                $line =~ s/($QUOTED_DELIMITER)/$spc_delim/g;
            }
            push @ALL_LINES, $line;
        }
        last if ( $FAST_FORWARD );
    }
}
close $ifh;
push @ALL_LINES, @LINE_BUFF;
# Print out all results now we have fully read the entire input file and processed it.
finalize_full_read_functions() if ( $READ_FULL );
$LINE_NUMBER = 0;
while ( @ALL_LINES )
{
    $LINE_NUMBER++;
    my $line = shift @ALL_LINES;
    $LAST_LINE = 1 if ( scalar( @ALL_LINES ) == 0 ); # last line of report.
    printf "%s", process_line( $line );
    last if ( $opt{'7'} && $MATCH_COUNT >= $MATCH_LIMIT );
}
if ( $opt{'Q'} and $IS_A_POST_MATCH ) # There was a match so dump the buffer, but we got to the EOF, there is no next line to view.
{
    printf STDERR "=>EOF\n";
    $IS_A_POST_MATCH = 0;
}
Pipe::IO::table_output("FOOT") if ( $TABLE_OUTPUT );
# Summary section.
Pipe::IO::print_summary( "count", $count_ref, \@COUNT_COLUMNS, $ctx ) if ( $opt{'c'} );
Pipe::IO::print_summary( "sum", $sum_ref, \@SUM_COLUMNS, $ctx )        if ( $opt{'a'} );
if ( $opt{'v'} )
{
    # compute average for each column.
    foreach my $key ( keys %{ $avg_ref } )
    {
        if ( exists $avg_count->{ $key } and $avg_count->{ $key } > 0 )
        {
            $avg_ref->{ $key } = $avg_ref->{ $key } / $avg_count->{ $key };
        }
        else
        {
            $avg_ref->{ $key } = 0.0;
        }
    }
    Pipe::IO::print_summary( "average", $avg_ref, \@AVG_COLUMNS, $ctx );
}
if ( $opt{'w'} )
{
    printf STDERR "== width\n" if ( ! $opt{'N'} );
    foreach my $column ( sort @WIDTH_COLUMNS )
    {
        if ( defined $width_max_ref->{ 'c'.$column } )
        {
            if ( $opt{'N'} )
            {
                printf STDERR "%s%s%d%s%d%s%d%s%d%s%2.1f\n",
                    'c'.$column, $DELIMITER,
                    $width_min_ref->{ 'c'.$column }, $DELIMITER,
                    $width_line_min_ref->{ 'c'.$column }, $DELIMITER,
                    $width_max_ref->{ 'c'.$column }, $DELIMITER,
                    $width_line_max_ref->{ 'c'.$column }, $DELIMITER,
                    ($width_max_ref->{ 'c'.$column } + $width_min_ref->{ 'c'.$column }) / 2;
            }
            else
            {
                printf STDERR " %2s: min: %2d at line %d, max: %2d at line %d, mid: %2.1f\n",
                    'c'.$column,
                    $width_min_ref->{ 'c'.$column },
                    $width_line_min_ref->{ 'c'.$column },
                    $width_max_ref->{ 'c'.$column },
                    $width_line_max_ref->{ 'c'.$column },
                    ($width_max_ref->{ 'c'.$column } + $width_min_ref->{ 'c'.$column }) / 2;
            }
        }
        else
        {
            if ( $opt{'N'} )
            {
                printf STDERR " %s%s0%s-%s0%s-%s0\n",
                    'c'.$column, $DELIMITER, $DELIMITER, $DELIMITER, $DELIMITER, $DELIMITER;
            }
            else
            {
                printf STDERR " %2s: min: %2d at line -, max: %2d at line -, mid: %2.1f\n",
                    'c'.$column, 0, 0, 0;
            }
        }
    }
    if ( %{$WIDTHS_COLUMNS} )
    {
        my @keys   = sort { $a <=> $b } keys %{$WIDTHS_COLUMNS};
        my $metric = shift @keys;
        my $min    = $metric;
        unshift @keys, $metric;
        $metric = pop @keys;
        push @keys, $metric;
        if ( $min == $metric )
        {
            if ( $opt{'N'} )
            {
                printf STDERR "%d\n", $metric;
                printf STDERR "%d\n", (scalar( keys %{$WIDTHS_COLUMNS} ) -1);
            }
            else
            {
                printf STDERR " number of columns: min and max: %d, ", $metric;
                printf STDERR "variance: %d\n", (scalar( keys %{$WIDTHS_COLUMNS} ) -1);
            }
        }
        else
        {
            if ( $opt{'N'} )
            {
                printf STDERR "%d%s%d%s ", $min, $DELIMITER, $WIDTHS_COLUMNS->{ $min }, $DELIMITER;
                printf STDERR "%d%s%d%s", $metric, $DELIMITER, $WIDTHS_COLUMNS->{ $metric }, $DELIMITER;
                printf STDERR "%d\n", (scalar( keys %{$WIDTHS_COLUMNS} ) -1);
            }
            else
            {
                printf STDERR " number of columns:  min: %d at line: %d, ", $min, $WIDTHS_COLUMNS->{ $min };
                printf STDERR "max: %d at line: %d, ", $metric, $WIDTHS_COLUMNS->{ $metric };
                printf STDERR "variance: %d\n", (scalar( keys %{$WIDTHS_COLUMNS} ) -1);
            }
        }
    }
}
# EOF
