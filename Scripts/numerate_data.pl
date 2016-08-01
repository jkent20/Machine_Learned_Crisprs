#! /usr/bin/perl

use strict;
use warnings;
use Text::CSV;
use Smart::Comments;
use DateTime;

my $csv = Text::CSV->new({
	sep_char => "\t",
	binary => 1,
	allow_loose_quotes => 1
	});

my %my_data_hash;
my $new_value = 0;

# recieve input from user
my $file_to_change = $ARGV[0] or die "Need to get CSV file on the command line\n";
my $y_value = $ARGV[1] or die "Need to provide y column name on command line\n";
# store name of inputted file for later
(my $file_to_change_results = $file_to_change) =~ s/\.[^.]+$//;
# store date and time for later
my $dt = DateTime->now;
my $date_time = $dt->datetime();
# join name of inputted file and date and time to create unique directory
$file_to_change_results = join('_', $file_to_change_results, $date_time);
unless(mkdir($file_to_change_results)) {
    	die "Unable to create directory: $file_to_change_results\n";
    }


# open files handlers
open my $fh_input, "<:encoding(utf8)", $file_to_change
                        or die "Error reading CSV file: $!";
open my $fh_output,">:encoding(utf8)","$file_to_change_results/X.tsv" or die " X.csv: $!";
open my $fh_y, ">:encoding(utf8)", "$file_to_change_results/y.tsv" or die " y.tsv: $!";


# set header of y file
$csv->eol ("\n");
my $y_array;
push(@$y_array, $y_value);
$csv->print ($fh_y, $_) for $y_array;

# recieve headers of input file
my $column_names = $csv->getline($fh_input); # Skip the first (header) line with the field names

# while there is data left unread...
while ( my $record = $csv->getline( $fh_input ) ) {
  	my $y_array;
    # Process each line
    # Field values are in $record->[0], $record[1], etc...

    my $i = 0;
    # for each column
    foreach my $column_name (@$column_names) {
    	my $keep = 'true';
    	# if current column is y value, push to y array and remove from record array
     	if ($column_name eq $y_value) {
       		push (@$y_array, $record->[$i]);
       		pop @$record;
       		$i--;
       	} else {
       		# if value has been seen before rename to stored numerical value
       		if (exists $my_data_hash{$column_name}{$record->[$i]}) {
       			s/$record->[$i]/$my_data_hash{$column_name}{$record->[$i]}/ for $record->[$i];
       		} else {
       			# create numerical value, store it and rename to said value
       			$my_data_hash{$column_name}{$record->[$i]} = ($new_value);
       			s/$record->[$i]/$my_data_hash{$column_name}{$record->[$i]}/ for $record->[$i];
       		}
       	}
       	 $i++;
       	 $new_value++;
    }


    # print record / y values to csv files
    $csv->eol ("\n");
    $csv->sep_char (',');
    $csv->print ($fh_output, $_) for $record;
    if ($y_array){
      	$csv->eol ("\n");
       	$csv->print ($fh_y, $_) for $y_array;
    } else {
       	push(@$y_array, "No y data");
       	$csv->eol ("\n");
       	$csv->print ($fh_y, $_) for $y_array;
    }
    $csv->sep_char ("\t");
}

# close csv file handlers
$csv->eof or $csv->error_diag();
close $fh_input;
close $fh_y or die "y.tsv: $!";
close $fh_output or die "X.csv: $!";
# call method to create csv to store a record of the changed values and what they were changed to
data_key_table($column_names, %my_data_hash);

sub data_key_table {
  	my ($column_names, %data_hash) = @_;
  	# for each column, open csv with colmn name in created directory
   	foreach my $column_name (@$column_names) {
   		open my $fh_keys, ">:encoding(utf8)", "$file_to_change_results/$column_name.tsv" or die " $column_name.tsv: $!";
   		# add header of column name and 'value'
   		my $row_data;
   		push(@$row_data, ($column_name, "Value"));
   		$csv->print ($fh_keys, $_) for $row_data;
   		# hash version of for each loop (for large hash)... for each column name print saved key with associated value.
   		while (my ($key, $value) = each (%{$data_hash{$column_name}})) {
   			my $row_data;
   			push(@$row_data, ($key, $value));
   			$csv->eol("\n");
   			$csv->print ($fh_keys, $_) for $row_data;
   		}
   		# close file handler
   		close $fh_keys or die "$column_name.tsv $!";
   	}
}