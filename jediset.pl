#!/usr/bin/perl
use strict; use warnings;
use Term::ANSIColor;
use subs qw(example_colors print_card);

my $count = 0;

my @color = qw(magenta  green  cyan);#black red green yellow blue magenta cyan white
my @number= qw(1        2      3   );
my @shape = qw(triangle rect   oval);
my @fill  = qw(.        ~      @   );

my @rect = qw(
._______.
|@@@@@@@|
|@@@@@@@|
|@@@@@@@|
._______.
);
my @triangle = qw(
....^....
.../@\\...
../@@@\\..
./@@@@@\\.
/_______\\
);
my @oval = qw(
.../-\\...
./@@@@@\\.
{@@@@@@@}
.\\@@@@@/.
...\\-/...
);
print $_."\n" for(@rect);
print $_."\n" for(@triangle);
print $_."\n" for(@oval);

sub shade{
	my $f = shift;
	$_ =~ s/[@.~]/$fill[$f]/g for(@rect);
	$_ =~ s/[@.~]/$fill[$f]/g for(@triangle);
	$_ =~ s/[@.~]/$fill[$f]/g for(@oval);
}
sub print_card{
#Variable values try to get rand to generate based on length of array
my $c = shift; $c = int(rand(3)) unless defined $c; #color
my $n = shift; $n = int(rand(3)) unless defined $n; #number
my $s = shift; $s = int(rand(3)) unless defined $s; #shape
my $f = shift; $f = int(rand(3)) unless defined $f; #fill

print color "bold $color[$c]";
print "$shape[$s] filled with $fill[$f]\n" for(1..$number[$n]);
print color 'reset';
}

sub example_colors{
my $message = shift;
print color 'reset';
print color 'bold';
for (@color){
	print color $_;
	print $_ unless $message;
	if ($message){for(@shape){print $_."\n";}}
	print "\n";
}
print color 'reset';
}
