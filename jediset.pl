#!/usr/bin/perl
=pod
Copyright 2010 James Koval

This file is part of Jedi Set

Jedi Set is free software: you can redistribute it
and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation, either version 3
of the License, or (at your option) any later version.

Jedi Set is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Jedi Set. If not, see <http://www.gnu.org/license/>
=cut

use strict; use warnings;
use Term::ANSIColor;
use List::Util qw(shuffle max);
use subs qw(shade colorize mold init printcards);

#all supported colors: black red green yellow blue magenta cyan white
#constant list of values for cards 
my @color = qw(magenta  green  yellow);
my @number= qw(1        2      3);
my @shape = qw(tria     rect   oval);
my @fill  = qw(`        +      @   );

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
my @form;#shape used for the next card printed

#scalers to temporarily hold values during operations
#parallel arrays to hold deck
#extra set of parallel arrays to hold cards in play (suffix p)
my $c; my @c; my @cp;#color
my $n; my @n; my @np;#number
my $s; my @s; my @sp;#shape
my $f; my @f; my @fp;#fill

my $columns = 3;#constant
my $playfieldsize = 15;#constant

init;
printcards;

sub printcards{
	my $col=$columns;#fluxuates when fewer cards need to be printed
	my $cardstoprint = @cp;
	while(1){
		last if($cardstoprint==0);
		$col=$cardstoprint if($cardstoprint < $col);
		$cardstoprint-- for(1..$col);
		
		for my $i (0..$#form){#cycle each line in ascii shape
			for(0..$col-1){#cycle columns
				mold $sp[$_];#make @form a specific shape
				shade $fp[$_];#make @form a specific fill
				colorize $cp[$_];#ready output for a color
				my $line = $form[$i] x $np[$_];#multiple form by the value of number
				print $line ." " x (length($form[0])*max(@number)- length($line))." ";
			}
		print "\n";
		}
		
		for(1..$col){
			push @cp, shift @cp;
			push @np, shift @np;
			push @sp, shift @sp;
			push @fp, shift @fp;
		}
	}
}

sub init{
	@form = @rect;#init @form for for-loops that use a standard shape's array length
	#reset arrays
	undef @c;undef @n;undef @s;undef @f;
	undef @cp;undef @np;undef @sp;undef @fp;

	#populate deck with non-repeating cards
	for $c(0..$#color){for $n(0..$#number){for $s(0..$#shape){for $f(0..$#fill){
		push @c, $c;
		push @n, $number[$n];
		push @s, $s;
		push @f, $f;
	}}}}
	
	#shuffle deck
	@c = shuffle(@c);
	@n = shuffle(@n);
	@s = shuffle(@s);
	@f = shuffle(@f);
	
	#draw 12 cards to be in play
	for(1..$playfieldsize){
		push @cp, pop @c;
		push @np, pop @n;
		push @sp, pop @s;
		push @fp, pop @f;
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
