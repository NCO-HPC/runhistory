#!/usr/bin/perl

# hpss_transfer_rates.pl
# This script parses stdout files (com/output/) for runhistory
# and calculates average transfer rates.
#
# usage: hpss_transfer_rates.pl                       #default run - run_history jobs only
#	 hpss_transfer_rates.pl [filename] [yyyymmdd] #run for filename given
#	 hpss_transfer_rates.pl all [yyyymmdd]        #run for all archive jobs
#	 hpss_transfer_rates.pl run [yyyymmdd]        #run_history jobs only
#	 Default date is today

$totmb=0;
$totsec=0;
$total=0;
$jobtotal=0;

if ($ARGV[1] ne "") {
   $date = $ARGV[1];
}
else {
   $date = "today"
}

if($ARGV[0] ne "" && $ARGV[0] ne "all" && $ARGV[0] ne "run") {
#  if (-e $ARGV[0]) {
    $filelist=$ARGV[0]; 
    &calc_mb_s;
#  }
#  else {
#    print "file $ARGV[0] does not exist\n";
#    exit;
#  }
 
#old wcoss
    #}
    #elsif ($ARGV[0] eq "all") {
    #  $filelist="/gpfs/dell1/nco/ops/com/output/$envir/$date/runhistory*";
    #  &calc_mb_s;
    #  $filelist="/gpfs/dell1/nco/ops/com/output/$envir/$date/*archive*";
    #  &calc_mb_s;
    #}
    #elsif ($$ARGV[0] eq "run") {
    #  $filelist="/gpfs/dell1/nco/ops/com/output/$envir/$date/runhistory*";
    #  &calc_mb_s;
    #}
    #else {
    #  $filelist="/gpfs/dell1/nco/ops/com/output/$envir/$date/runhistory*";
    #  &calc_mb_s;
    #}

}
elsif ($ARGV[0] eq "all") {
  $filelist="/lfs/h1/ops/$envir/output/$date/runhistory*";
  &calc_mb_s;
  $filelist="/lfs/h1/ops/$envir/output/$date/*archive*";
  &calc_mb_s;
}
elsif ($$ARGV[0] eq "run") {
  $filelist="/lfs/h1/ops/$envir/output/$date/runhistory*";
  &calc_mb_s;
}
else {
  $filelist="/lfs/h1/ops/$envir/output/$date/runhistory*";
  &calc_mb_s;
}

if ($totsec gt "0") {
 $total=$totmb/$totsec;
 #print "\nTotal for all Jobs: $total MB/s\n";
 printf "\nTotal for all Jobs: %8.2f MB/s\n", $total ;
}
else {
 printf "\nTotal for all Jobs: N/A \n", $total ;
}

exit;

sub calc_mb_s {
   foreach $rhist_file (`ls $filelist`) {
      print "\ncalculating for file: $rhist_file";
      print "MB             Seconds      MB/s\n";
      $mps=`grep -h "HTAR Create" $rhist_file`;

      @htarline = split('^', $mps);
      @dateline = split('^', $date);

      foreach $htarline (@htarline) {
         @temp = split ('time: | seconds \(| MB', $htarline);
         $mps=$temp[2];
         $sec=$temp[1];
 
         $mb=$mps*$sec;
 
         printf("%-14s %-10s %-10s", $mb, $sec, $mps);
         print "\n";

         $totmb=$mb+$totmb;
         $totsec=$sec+$totsec;
      }
   }
}
