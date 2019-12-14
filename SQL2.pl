#################################################################
# Autor: Grzegorz Okoñ - g³ówny programista
#
# Sprawdzanie wolnego miejsca w bazach danych serwerów MSSQL.
#################################################################

use strict;
use warnings;

my $console = $ARGV[0];
my @bats = ('dbcc_showfilestats_dd_master.bat', 'dbcc_showfilestats_hh_master.bat');
my $bat = '';
my @units = ('B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB');
my $unit = '';
my $CheckNumber = 0;
my $Server = 0;
my $Database = 0;
my $TotalExtents = 0;
my $UsedExtents = 0;
my $FreeExtents = 0;
my $LogSize = 0;
my $LogSpaceUsed = 0;
my $LogSpaceFree = 0;
my $LogSpaceFreeExtents = 0;

open (FREE_SIZE_ETIQUETTE, ">SQL2.txt") || die "nie moge utworzyc pliku";
open (FREE_SIZE_ETIQUETTE, ">>SQL2.txt") || die "nie moge zapisac do pliku";
print_header();
   
if (defined $console) {
   open (FREE_SIZE_ETIQUETTE, ">&STDOUT") || die "nie moge utworzyc polaczenia do konsoli";
   print_header();
}
   
foreach $bat (@bats) {
   if($bat=~/(\d+)\_(\w+)/) {
      $Server = $1;
      $Database = $2;
   }

   open (INPUT_FILE,"$bat|");
   
   while (<INPUT_FILE>) {      
      if(/\d+\s+\d+\s+(\d+)\s+(\d+)\s+\w+\s+/) {        
            $TotalExtents += $1; 
            $UsedExtents += $2;
      } 
      if(/$Database\s+(\d+\.\d+)\s+(\d+\.\d+)/) {        
            $LogSize = $1;
            $LogSpaceUsed = $2;
      }  
   }

   $FreeExtents = ($TotalExtents-$UsedExtents)*64*1024;
   $LogSpaceFree = (100 - $LogSpaceUsed)/100*$LogSize*1024*1024;
   $LogSpaceFreeExtents = $LogSpaceUsed/100*$LogSize*1024*1024;

   open (FREE_SIZE_ETIQUETTE, ">>SQL2.txt") || die "nie moge zapisac do pliku";
   write (FREE_SIZE_ETIQUETTE);

   if (defined $console) {
      open (FREE_SIZE_ETIQUETTE, ">&STDOUT") || die "nie moge utworzyc polaczenia do konsoli";
      write (FREE_SIZE_ETIQUETTE);
   }
   
   close INPUT_FILE;
}

sub print_header {
   print FREE_SIZE_ETIQUETTE "serwer   baza_danych       wolne_na_dane         wolne_w_logu\n------   -----------       ------------------    ------------------\n";
   return;
}

sub format_size {
   my $file_size = $_[0]; #rozmiar w bajtach
   my $precision = $_[1]; #wymagane miejsca dziesiêtne
   my $j = 0;
   $precision = ($precision > 0) ? 10**$precision : 1;
   while($file_size > 1024) {
      $file_size /= 1024;
      $j++;
   }
   if ($units[$j]) { 
      $unit = $units[$j];
      return (int($file_size * $precision) / $precision) 
   } else { 
      return int($file_size) 
   }
} 

format FREE_SIZE_ETIQUETTE =
@<<<     @<<<<<<<<<<<<<<<<    @##.# @< @##.#%       @##.# @< @##.#%
$Server, $Database, format_size((($TotalExtents-$UsedExtents)*64*1024), 1), $unit, (($TotalExtents-$UsedExtents)/$TotalExtents)*100, format_size($LogSpaceFree, 1), $unit, 100 - $LogSpaceUsed
.  
