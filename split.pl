#!/usr/bin/perl
use warnings;
use strict;

# This script takes a shell script and extracts
# all the functions to the external sourced files

my $in_function = "";
my $path = $ARGV[0] ;
my $quotes_count = 0 ;

while(<>)
{
  my ($start) = m{^(\w+)\(\)\s*\{$};
  my ($end) = m{^\}$};

  my @quotes = $_ =~ /"/g ;
  $quotes_count += scalar @quotes ;

 if (defined $start) {
    $in_function = $1 ;
    open FH, "> $in_function.file" or die $in_function;
    print FH "_",$in_function,"() {\n" ;
    print $in_function,"() {\n" ;
    print "    . \"$path/$in_function.file\"\n" ;
    print "    _$in_function \"\$@\"\n" ;
  } elsif ( ($quotes_count % 2) == 1 and defined $end){
    $in_function = "" ;
    print FH "}\n" ;
    print "}\n" ;
    close FH;
  } elsif ($in_function ne "") {
    print FH $_;
  } else {
    print $_;
  }
}
