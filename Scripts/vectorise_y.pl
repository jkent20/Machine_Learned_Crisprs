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
my $new_value = 1;

# recieve input from user
my $file_to_change = $ARGV[0] or die "Need to get CSV file on the command line\n";
#my $y_value = $ARGV[1] or die "Need to provide y column name on command line\n";
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

open my $fh_input, "<:encoding(utf8)", $file_to_change
                        or die "Error reading CSV file: $!";
my $column_names = $csv->getline($fh_input);
close $fh_input;


# open files handlers
read_csv();


# vectorise values in %my_data_hash
my $max = 0;
foreach my $column_name (@$column_names) {
  # while (my ($key, $value) = each (%{$my_data_hash{$column_name}})) {
  #   if ($value > $max) {
  #     $max = $value;
  #   }
  # }
  while (my ($key, $value) = each (%{$my_data_hash{$column_name}})) {
    my @array = (0) x ($max+1);
    $array[0] = $value;
    $my_data_hash{$column_name}{$key} = \@array;
  }
}
$csv = Text::CSV->new({
  sep_char => ',',
  binary => 1,
  allow_loose_quotes => 1
  });
# call subroutine to create csv to store a record of the changed values and what they were changed to
data_key_table($column_names, %my_data_hash);
# call subroutine to create csv to store vectors
vector_csv($column_names, %my_data_hash);
read_csv();


sub data_key_table {
  	my ($column_names, %data_hash) = @_;
  	# for each column, open csv with column name in created directory
   	foreach my $column_name (@$column_names) {
   		open my $fh_keys, ">:encoding(utf8)", "$file_to_change_results/$column_name.tsv" or die " $column_name.tsv: $!";
   		# add header of column name and 'value'
   		my $row_data;
   		push(@$row_data, ($column_name, "Value"));
      $csv->eol("\n");
   		$csv->print ($fh_keys, $_) for $row_data;
   		# hash version of for each loop (for large hash)... for each column name print saved key with associated value to csv.
   		while (my ($key, $value) = each (%{$data_hash{$column_name}})) {
   			my $row_data;
   			push(@$row_data, $key);
        push(@$row_data, @$value);
   			$csv->eol("\n");
   			$csv->print ($fh_keys, $_) for $row_data;
   		}
   		# close file handler
      close $fh_keys or die "$column_name.tsv $!";
   	}
}

sub vector_csv {
  my ($column_names, %data_hash) = @_;
  # for each column, open csv with column name in created directory
  foreach my $column_name (@$column_names) {
    my $file_name = join('_', $column_name, "y_value");
    open my $fh_ys, ">:encoding(utf8)", "$file_to_change_results/$file_name.tsv" or die " $file_name.tsv: $!";
    # hash for each loop, print arrays to csv
    while (my ($key, $value) = each (%{$data_hash{$column_name}})) {
      my $row_data;
      push(@$row_data, @$value);
      $csv->print ($fh_ys, $_) for $row_data;
    }
    # close filehandler
      close $fh_ys or die "$column_name.tsv $!";
  }
}

sub read_csv {
  open my $fh_output,">:encoding(utf8)","$file_to_change_results/y.tsv" or die " X.csv: $!";
open my $fh_input, "<:encoding(utf8)", $file_to_change
                        or die "Error reading CSV file: $!";


# recieve headers of input file
my $column_names = $csv->getline($fh_input); # Skip the first (header) line with the field names

# while there is data left unread...
while ( my $record = $csv->getline( $fh_input ) ) {
    # Process each line
    # Field values are in $record->[0], $record[1], etc...

    my $i = 0;
    # for each column
    foreach my $column_name (@$column_names) {
          # if value has been seen before rename to stored numerical value
          if (exists $my_data_hash{$column_name}{$record->[$i]}) {
            if (ref $my_data_hash{$column_name}{$record->[$i]} eq 'ARRAY')
            {
              my $replacement = $my_data_hash{$column_name}{$record->[$i]};
              # $replacement
              my @replacement = @$replacement;
              # @replacement
              shift @$record;
              push @$record, @$replacement;
              $i--;
            } else {

              s/$record->[$i]/$my_data_hash{$column_name}{$record->[$i]}/ for $record->[$i];
            }
          } else {
            # create numerical value, store it and rename to said value
            $my_data_hash{$column_name}{$record->[$i]} = ($new_value);
            $new_value++;
            s/$record->[$i]/$my_data_hash{$column_name}{$record->[$i]}/ for $record->[$i];
          }
        #}
         $i++;
    }

    # print record values to csv files
    $csv->eol ("\n");
    $csv->print ($fh_output, $_) for $record;
}

# close csv file handlers
$csv->eof or $csv->error_diag();
close $fh_input;
close $fh_output or die "X.csv: $!";
}