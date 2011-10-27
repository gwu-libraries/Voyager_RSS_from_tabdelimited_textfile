#!/usr/bin/perl -w

# FILE: makeRss.pl
# AUTHOR: Jim Farrugia
# DATE: December, 2009
#	edit 10/2011 mc change from www.gwu.edu to exhibits.gelman.gwu.edu
# INPUT: sortedfile.tab via STDIN
# OUTPUT: full .xml file, in ./rss,  for all items in sortedfile.tab, plus
#         a .xml file in ./rss, for each LC main class in sortedfile.tab
# OUTPUT USED BY: autoftp.sh and ftpBatFile
# INVOKED BY makeRss.sh
#
# OVERVIEW:
# 1. Set a bunch of variables to ugly, formatted strings
# 2. If there is no rss directory under current working directory, create it
# 3. Read input from STDIN, save in arrays @lines and @inputLines;
#    Input needs to come from sortedfile.tab
# 4. Foreach line in @lines, create a single-LC-letter .xml file in ./rss
# 5. Create a full .xml in ./rss; 
# 6. Make timestamped copies of .xml files in ./rss/archive   

use strict;



#------------------------------------------------------------------------------
#  STEP 1:

#          Set a bunch of variables to ugly strings
#          
#------------------------------------------------------------------------------


my $date = `date`;
chomp $date;
my $updateDate = $date;

my %seen;

my $LCClass;
my ($callnum, $LCClassFirstLetter, $bibID, $title, $author, $pub); 
my $previousLCClass = "";

my $RSSHeader = '<?xml version="1.0" encoding="UTF-8"?>' . "\n" . '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom"> ' .  "\n" . ' <channel>' . "\n"; 
my $channelTitlePrefix = "  \<title>Gelman Library New Books Shelf \(for call numbers beginning with "; 
my $channelTitleSuffix = ')</title>' . "\n"; 

# my $channelLinkPrefix = '  <link>http://www.gwu.edu/gelman/new_books/rss/newgelmanbooks'; 
my $channelLinkPrefix = '  <link>http://exhibits.gelman.gwu.edu/newbooks/rss/newgelmanbooks'; 
my $channelLinkSuffix = '</link>' . "\n"; 

my $channelDescriptionPrefix = '  <description> This RSS feed lists books currently on the Gelman Library\'s new-books shelf that have a call number beginning with ';
my $channelDescriptionSuffix = 'This list is updated roughly every Friday. Last updated on ' . "$date" . '</description>';


# my $atomPrefix = '  <atom:link href="http://www.gwu.edu/gelman/new_books/rss/';
my $atomPrefix = '  <atom:link href="http://exhibits.gelman.gwu.edu/newbooks/rss/';
my $atomSuffix = ' rel="self" type="application/rss+xml" />';


my $OPACURLPrefix = 'http://catalog.wrlc.org/cgi-bin/Pwebrecon.cgi?BBID=';
my $guidPrefix = 'http://catalog.wrlc.org/cgi-bin/Pwebrecon.cgi?BBID=';
my $sep = "  ---  ";
my $gelmanLogoURL = 'http://www.gwu.edu/gelman/header/logo.jpg';


my $footer = "\n" . ' </channel>' . "\n" . '</rss>';




#------------------------------------------------------------------------------
#  STEP 2:

#          Create ./rss directory if it doesn't exist
#          
#------------------------------------------------------------------------------

my $rssDir = './rss';

if (!(-d $rssDir) ) { 
  system("mkdir $rssDir") == 0 or die "system mkdir $rssDir failed: $? \n";
}




#------------------------------------------------------------------------------
#  STEP 3:

#          Read input from STDIN, save in arrays @lines.
#          Input needs to come from sortedfile.tab.
#
#------------------------------------------------------------------------------

my @lines = <>;




#------------------------------------------------------------------------------
#  STEP 4:

#          Foreach line in @lines, create a single-LC-letter .xml file in ./rss
#
#------------------------------------------------------------------------------

my @cleanerLines =(); # save clean lines for printing full list below, step 5

my $i = 0;
foreach (@lines) {

  s/\s+\t/\t/g;
  #s/\s+$/\n/;
  s/\&nbsp\;/ /g;
  chomp;
  #s/ \& / and /g;
  s/ \& / \&amp\; /g;
  #print;
  push (@cleanerLines, $_); # used for printing full list below, step 5

  ($callnum, $LCClassFirstLetter, $bibID, $title, $author, $pub) = split /\t/;
  $bibID =~ s/^ (\d+)/$1/;  


  $i++;
  $seen{$LCClassFirstLetter}++;


  my $filename = $rssDir . '/' . 'newgelmanbooks' . $LCClassFirstLetter . '.xml';


    # When first seeing a given LC class (anyone but the first one), do this:
    # 1. Print footer for PREVIOUS LC class file, then close that file.
    # 2. Open file for given LC class and print header to that file

  if ($seen{$LCClassFirstLetter} == 1) {
    if ($i > 1) {
      #print OUTFILE "FOOTER FOR LCClass $previousLCClass\n";
      print OUTFILE "$footer\n";
      close OUTFILE;
    }
    open (OUTFILE, ">$filename") || die "cant open file $!\n";
    print OUTFILE $RSSHeader;
    print OUTFILE $channelTitlePrefix . $LCClassFirstLetter . $channelTitleSuffix;
    print OUTFILE $channelLinkPrefix . "$LCClassFirstLetter" . '.xml';
    print OUTFILE $channelLinkSuffix;
    print OUTFILE $channelDescriptionPrefix . "$LCClassFirstLetter \. " . $channelDescriptionSuffix . "\n";
    print OUTFILE $atomPrefix . "newgelmanbooks" . $LCClassFirstLetter . '.xml"' . $atomSuffix . "\n\n\n";

  }


  # print main contents to given LC class file

  print OUTFILE '   <item>' . "\n";
  print OUTFILE '    <title>' .  "$title" . '</title>' . "\n";
  print OUTFILE '    <link>' . $OPACURLPrefix . $bibID . '</link>' . "\n";
  print OUTFILE '    <guid>' . $guidPrefix . $bibID . '</guid>' . "\n";
  print OUTFILE '    <description>' . $callnum  . $sep . $author . $sep . $pub . '</description>' . "\n";
  #print OUTFILE '    <pubDate>' . $updateDate  .  '</pubDate>' . "\n";
  print OUTFILE '   </item>' . "\n\n";



  # capture LCClassFirstLetter, so that when we get to next LC class letter, 
  # we can then print the footer to the previous LCClass file

  $previousLCClass = $LCClassFirstLetter;


} # end foreach (@lines)


# print footer for last file, then close it
print OUTFILE "$footer\n";
close OUTFILE;




#------------------------------------------------------------------------------
#  STEP 5:

#          Print out full list as .xml file
#
#------------------------------------------------------------------------------


my $allCallnumsString = "A_through_Z";

my $fullOutFile = $rssDir . '/newgelmanbooks.xml';
open (FULLOUTFILE, ">$fullOutFile") or die "cant open file $fullOutFile $!\n";

print FULLOUTFILE $RSSHeader;
print FULLOUTFILE '  <title>Gelman Library New Books Shelf (all call numbers A-Z)</title>' . "\n";
print FULLOUTFILE $channelLinkPrefix . "$allCallnumsString" . '.xml';
print FULLOUTFILE $channelLinkSuffix;
print FULLOUTFILE $channelDescriptionPrefix . "$allCallnumsString \. " . $channelDescriptionSuffix . "\n";
print FULLOUTFILE $atomPrefix . "newgelmanbooks" . '.xml"' . $atomSuffix . "\n\n\n";

foreach (@cleanerLines) {
 
  ($callnum, $LCClassFirstLetter, $bibID, $title, $author, $pub) = split /\t/;
  $bibID =~ s/^ (\d+)/$1/;  

  print FULLOUTFILE '   <item>' . "\n";
  print FULLOUTFILE '    <title>' .  "$title" . '</title>' . "\n";
  print FULLOUTFILE '    <link>' . $OPACURLPrefix . $bibID . '</link>' . "\n";
  print FULLOUTFILE '    <guid>' . $guidPrefix . $bibID . '</guid>' . "\n";
  print FULLOUTFILE '    <description>' . $callnum  . $sep . $author . $sep . $pub . '</description>' . "\n";
  #print FULLOUTFILE '    <pubDate>' . $updateDate  .  '</pubDate>' . "\n";
  print FULLOUTFILE '   </item>' . "\n\n";

}
print FULLOUTFILE "$footer\n";



#------------------------------------------------------------------------------
#  STEP 6:

#          Make timestamped copies of .xml files; put them in ./rss/archive   
#
#------------------------------------------------------------------------------



my $dirname = $rssDir;
my $archiveDir = $rssDir . '/archive';
# if ./$archiveDir does not exist, create it, or fail with error message
if (!(-d $archiveDir) ) { 
  system("mkdir $archiveDir") == 0 or die "system mkdir $rssDir failed: $? \n";
}
my $timestamp=`date --rfc-3339=date`;
chomp $timestamp;

opendir my($dh), $dirname or die "Couldn't open dir '$dirname': $!";
my @files = readdir $dh;
closedir $dh;


# this is slow, invoking system for each iteration; would need to find better
# way if ever had more than 20-some files to copy

foreach my $file (@files) {
  if ($file =~ m/(\w+)(\.xml)/) {
   my $sourceFile = $dirname . '/' . $file;
   my $targetFile = $archiveDir . '/' . $1 . $timestamp . $2;

   #print "$targetFile\n";
   system("cp $sourceFile $targetFile");
  }
}

exit 0;

