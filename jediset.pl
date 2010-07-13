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
use Getopt::Long;
use Term::ANSIColor;
use List::Util qw(shuffle max);
use subs qw(shade colorize mold init printcards);

my $columns = 4;#Number of columns across the screen
my $cards = 12;#Number of cards in a new draw
my $debug = 0;#show debug info
my $numbers = 0;#bool to toggle on/off the numbers on cards
my $version = 0; my $help = 0;

GetOptions('debug+' => \$debug, 'numbers' => \$numbers,
'cards=i' => \$cards, 'columns=i' => \$columns,
'version' => \$version, 'help' => \$help);

if($help){
print <<EOF;
$0 : The Game of Jedi Set, a Terminal Card Game

Running: Press enter to see a new set of cards. Press q then enter to quit.
           More functionality will be added as the program matures out of alpha.

Syntax: $0 [--help|--version|--debug|--columns=<int>|--numbers|
                       --cards=<int>]
   
   --help        : This help message
   --version     : Print version on standard output and exit
   --debug       : Enable likely useless debuging output data 
   --columns     : Specify the number of columns that will fit on your screen
                   Default = 4
   --numbers     : Show numbers on the centers of cards
   --cards       : Specify the number of cards to play with each round
EOF
exit 0;
} elsif ($version) {
print "$0 1.0 alpha\n";
exit 0;
}


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

while (1){
init;
printcards;
my $in = <>;
exit 0 if $in =~ /[qQ]/;
}

sub printcards{
	my $col=$columns;#fluxuates when fewer cards need to be printed
	my $cardstoprint = @cp;
	while(1){
		last if($cardstoprint==0);
		$col=$cardstoprint if($cardstoprint < $col);
		#$cardstoprint-- for(1..$col);
		
		for my $i (0..$#form){#cycle each line in ascii shape
			for(0..$col-1){#cycle columns
				mold $sp[$_];#make @form a specific shape
				shade $fp[$_];#make @form a specific fill
				colorize $cp[$_];#ready output for a color
				my $line = $form[$i] x $np[$_];#multiple form by the value of number
				print "$cp[$_] $np[$_] $sp[$_] $fp[$_]" if $debug;
				
				#display numbers on cards
				if($i==$#form/2 and $numbers){
					$line=substr($line,0,length($line)/2). (@cp-$cardstoprint+1) .substr($line,length($line)/2+length (@cp-$cardstoprint+1));
					$cardstoprint--;
				}
				if($i==0 and !$numbers){
					$cardstoprint--;#each new card that is printed, decrements cards needed to print
				}
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
		push @n, $number[$n];#save actual number rather than index
		push @s, $s;
		push @f, $f;
	}}}}
	print "Deck:\n" if $debug;
	for(0..$#c){
		print $_+1 ." : $c[$_] $n[$_] $s[$_] $f[$_]\n" if $debug;
	}
	
	#shuffle deck
	my @order = shuffle 0..$#c;#idea from http://stackoverflow.com/users/13/chris-jester-young
	@c = @c[@order];
	@n = @n[@order];
	@s = @s[@order];
	@f = @f[@order];
	
	
	#draw 12 cards to be in play
	$cards = 81 if $cards>81;
	for(1..$cards){
		push @cp, pop @c;
		push @np, pop @n;
		push @sp, pop @s;
		push @fp, pop @f;
	}
	print "Cards In Play:\n" if $debug;
	for(0..$#cp){
		print $_+1 ." : $cp[$_] $np[$_] $sp[$_] $fp[$_]\n" if $debug;
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
