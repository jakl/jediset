#!/usr/bin/perl
use strict; use warnings;
use Term::ANSIColor;
use List::Util 'shuffle';
use List::Util 'max';#used to find the maximum number in @number, for formatting correctly
use subs qw(shade colorize mold);

my $debug = 1;

#black red green yellow blue magenta cyan white
my @color = qw(magenta  green  yellow);
my @number= qw(1        2      3     );
my @shape = qw(tria     rect   oval  );
my @fill  = qw(`	+      @     );

my @rect = qw(
._____.
|@@@@@|
|@@@@@|
|@@@@@|
-------);
my @tria = qw(
..._...
../@\\..
./@@@\\.
/@@@@@\\
-------);
my @oval = qw(
..___..
./@@@\\.
\(@@@@@\)
.\\@@@/.
..---..);


#the current shape used for the next card to print
my @form = @rect;#Needs to be initialized for for-loops using a standard shape's array length

#Keep a record of cards already used per game in this 3D array to avoid dups
my @deck;#axis's of the array are Color/Shape/Fill/Number and element values are defined/undefined : used/unused

my $columns = 3;
my $rows = 1;

my $c; my @c;#color
my $n; my @n;#number
my $s; my @s;#shape
my $f; my @f;#fill

#populate || arrays with non-repeating cards
for $c(0..$#color){for $n(0..$#number){for $s(0..$#shape){for $f(0..$#fill){
  push @c, $c;
  push @n, $n;
  push @s, $s;
  push @f, $f;
}}}}

#shuffle
@c = shuffle(@c);
@n = shuffle(@n);
@s = shuffle(@s);
@f = shuffle(@f);

#print "@c\n@n\n@s\n@f";#prove it is shuffled
#print "$c[$_] $n[$_] $s[$_] $f[$_]\n" for (0..11);

for(1..$rows){
	#cycle height/rows/lines of ascii shape
	for my $i (0..$#form){
		#cycle each card, printing correct row
		for(0..$columns-1){
			mold $s[$_];#make @form a specific shape
			shade $f[$_];#make @form a specific fill
			colorize $c[$_];#ready output for a color
			my $line = $form[$i] x $n[$_];
			print $line ." " x (length($form[0])*max(@number)- length($line))." ";
		}
	print "\n";
	}
}

#Put a shape in @form, randomly or by index into @shape from argument
sub mold{
	my $s = shift; $s = int rand @shape unless defined $s;
	@form = @tria if($shape[$s] eq 'tria');
	@form = @rect if($shape[$s] eq 'rect');
	@form = @oval if($shape[$s] eq 'oval');
	return $s;
}

#Set the fill to random, or from @fill indexed by first argument
sub shade{
	my $f = shift; $f = int rand @fill unless defined $f;
	$_ =~ s/[@fill]/$fill[$f]/g for(@form);
	return $f;
}

#Set the color to random, or from @color indexed by first argument
sub colorize{
	my $c = shift; $c = int rand @color unless defined $c;
	print color "bold $color[$c]";
	#$form[3][4] = $c[0];
	return $c;
}
