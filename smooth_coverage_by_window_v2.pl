#!/usr/bin/perl

################################################################################
print "\n\tPerl script to smooth coverage TAB file by a window of width = w.\n";
print "\tThe TAB files must be in the format:  POSITION  COVERAGE\n\n";
print "\tRamón Peiró-Pastor (CBMSO, 2012)\n";
print "\t", "-" x 65, "\n\n";
################################################################################

# Statements
$| = 1;
use strict; 
use warnings;

# Usage & help
if (scalar @ARGV != 2) {
        print<<END;

Perl script to smooth coverage TAB files by a window os width = w.
The TAB files must be in the format:	POSITION	COVERAGE

	Usage: $0 <TAB_file> <window>

	<TAB_file>	= TAB file to be smoothed
	<window>	= window width

END
        exit 0;
	}

# Global variables
my $in_file = $ARGV[0];
my $window = $ARGV[1];

# Read & store TAB file
my $core_name = $in_file;
$core_name =~ s/\..*$//g;
my %coverage = ();
my %running_coverage = ();
my $half_window = int($window / 2);
print "\tReading and storing TAB file ....\n";
open (TAB,"<$in_file") or die "Could not open '$in_file': $!";
while (<TAB>) {
	chomp $_;
	my @chunks = split("\t", $_);
	my $pos = $chunks[0];
	my $cov = $chunks[1];
	$coverage{$pos} = $cov;
	}
close (TAB);
print "\tTAB file read.\n";

# Calculate running coverage
print "\tCalculating running coverage with a window of width = $window bp ....\n";
my @sorted_pos = sort{$a <=> $b}(keys %coverage);
my $last_pos = $sorted_pos[$#sorted_pos];
my $accum_cov = 0;

for (my $i = 1; $i <= $half_window; $i++) {	# Accumulate (w/2)-1 first values to calculate mean of first position
	if (defined $coverage{$i}) {$accum_cov += $coverage{$i};}
	}
for (my $i = $last_pos-$half_window+1; $i <= $last_pos; $i++) {	# Accumulate (w/2)+1 last values to calculate mean of first position
	if (defined $coverage{$i}) {$accum_cov += $coverage{$i};}
	}

for (my $i = 1; $i <= $last_pos; $i++) {
	if ($i <= $half_window) {	# Calculate mean for "first" position values
		if (defined $coverage{$last_pos-$half_window+$i}) {$accum_cov -= $coverage{$last_pos-$half_window+$i};}
		if (defined $coverage{$half_window+$i}) {$accum_cov += $coverage{$half_window+$i};}
		$running_coverage{$i} = $accum_cov/($window+1);
		}
	elsif ($i > $half_window and $i <= $last_pos-$half_window) {	# Calculate mean for "in between" position values
		if (defined $coverage{$i-$half_window-1}) {$accum_cov -= $coverage{$i-$half_window-1};}
		if (defined $coverage{$i+$half_window}) {$accum_cov += $coverage{$i+$half_window};}
		$running_coverage{$i} = $accum_cov/($window+1);
		}
	elsif ($i > $last_pos-$half_window and $i <= $last_pos) {	# Calculate mean from "last" position values
		if (defined $coverage{$i-$half_window-1}) {$accum_cov -= $coverage{$i-$half_window-1};}
		if (defined $coverage{$half_window-$last_pos+$i}) {$accum_cov += $coverage{$half_window-$last_pos+$i};}
		$running_coverage{$i} = $accum_cov/($window+1);
		}
	}

# Write coverage files
print "\n\tWriting in output file ....\n";
my $raw_out_file = $core_name . '_smooth_W' . $window . '.dat';	# Raw data
my $log_out_file = $core_name . '_smooth_log2W' . $window . '.dat';	# Log2 data
open (ROUT,">$raw_out_file") or die "Could not open $raw_out_file': $!";
open (LOUT,">$log_out_file") or die "Could not open $log_out_file': $!";
for (my $i = 1; $i <= $last_pos; $i++) {
	if (defined $running_coverage{$i}) {
		print ROUT "$i\t$running_coverage{$i}\n";
		if ($running_coverage{$i} > 0) {print LOUT "$i\t", log2(($running_coverage{$i})+1),"\n";}
		else {print LOUT "$i\t0\n";}
		}
	else {
		print ROUT "$i\t0\n";
		print LOUT "$i\t0\n";
		}
	}
close ROUT;
close LOUT;

# Close files and exit
print "\tJOB DONE !!!!\tHave a nice day\t:)\n\n";
exit;

# Subroutines
sub log2 {
	my $n = shift;
	return log($n)/log(2);
	}
