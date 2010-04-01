#!/usr/bin/perl
use strict; use warnings;
use Term::ANSIColor;
use subs qw(print_shapes shade colorize mold);
#black red green yellow blue magenta cyan white
my @color = qw(magenta  green  yellow);
my @number= qw(1        2      3     );
my @shape = qw(tria     rect   oval  );
my @fill  = qw(`	+      @    );

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

my @form = @rect;#the current shape used for the next card to print

my @deck;

my $columns = 12;
my $rows = 1;

my $s; my @s;#shape
my $f; my @f;#fill
my $c; my @c;#color

for(1..$rows){
for(1..$columns){
	my $count = 0;
	do{
		exit 0 if $count++ > @shape*@fill*@color;
		$s = int rand @shape;
		$f = int rand @fill;
		$c = int rand @color;
	}while(defined $deck[$s][$f][$c]);
	$deck[$s][$f][$c]=0;
	push @s, $s; push @f, $f; push @c, $c;
}

for my $i (0..$#form){
for(0..$#s){
	mold $s[$_];
	shade $f[$_];
	colorize $c[$_];
	print $form[$i]." ";
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
	return $c;
}
