#!/usr/bin/perl
use strict; use warnings;
use Term::ANSIColor;
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
my @deck;#axis's of the array are Color/Shape/Fill and values are defined/undefined : used/unused

my $columns = shift;
my $rows = shift;

my $s; my @s;#shape
my $f; my @f;#fill
my $c; my @c;#color
my $n; my @n;#number

my $count=0;

for(1..$rows){
	
	#Generate a row of cards based on number of columns
	for(1..$columns){
		
		#Check to see if all cards have been used already
		$count=0;
		for $c(0..$#color){ for $s(0..$#shape){ for $f(0..$#fill){ for $n(0..$#number){
			$count++ if defined $deck[$s][$f][$c][$n];#Count number of cards that have been used
        }                 }                   }              }
		if ($count >= @color*@fill*@shape*@number){
			print "Ran out of $count cards\n" if $debug;
			exit 0;#Exit if all cards have been used
		}
		
		do{
			$s = int rand @shape;
			$f = int rand @fill;
			$c = int rand @color;
			$n = int rand @number +1;
		}while(defined $deck[$s][$f][$c][$n]);#If card has been used, repick
		$deck[$s][$f][$c][$n]=0;#Mark card as used. Defined/0 = Used; Undefined = Not used
		push @s, $s; push @f, $f; push @c, $c; push @n, $n;#put card attributes in parallel arrays
	}#make row
	
	#cycle height/rows/lines of ascii shape
	for my $i (0..$#form){
		#cycle each card, printing correct row
		for(0..$columns-1){
			mold $s[$_];#make @form a specific shape
			shade $f[$_];#make @form a specific fill
			colorize $c[$_];#ready output for a color
			my $line = $form[$i] x $n[$_];
			print $line ." " x (length($form[0])*3- length($line))." ";
		}
	print "\n";
	}
	undef @s;undef @f;undef @c;
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
