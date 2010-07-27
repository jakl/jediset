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
use subs qw(shade colorize mold init printcards draw redraw pick menu);

my $defaultrows = 4;#defaults used for help screen
my $rows = $defaultrows;#Number of rows across the screen
my $defaultcards = 12;
my $cards = $defaultcards;#Number of cards in a new draw
my $debug = 0;#show debug info
my $numbers = 0;#bool to toggle on/off the numbers on cards
my $version = 0; my $help = 0;

GetOptions('debug' => \$debug, 'numbers' => \$numbers,
'cards=i' => \$cards, 'rows=i' => \$rows,
'version' => \$version, 'help' => \$help);

if($help){
print <<EOF;
NAME
    The Game of Jedi Set: a pattern matching terminal card game

USAGE
    $0 [--help|--version|--debug|--rows=<int>|--numbers|
                       --cards=<int>]

    Press enter to see a new set of cards. Press q then enter to quit.

DESCRIPTION
    See <http://en.wikipedia.org/wiki/Set_(game)>
   
OPTIONS
--help    -h : This help message

--rows    -r : Specify the number of rows that will fit on your screen
                   Vertical rows (aka: columns)
                 Range = 1 through 20  else it defaults
                 Default = $defaultrows
--cards   -c : Specify the number of cards to play with each round
                 Range = 1 through 81  else it defaults
                 Default = $defaultcards
--numbers -n : Show numbers on the centers of cards

--version -v : Print version on standard output and exit

--debug   -d : Enable (likely useless) debuging output data 
                 The data will be of the form: int   int  int   int
                                               shape fill color number
                 shape, fill, and color are indexes:   values 0 through 2
                 number is saved directly:             values 1 through 3
                   Note: Look at the code to see the meanings of indexes

Option names may be the smallest unique abbreviation of the full names
  shown above
Full or abbreviated options may be preceded by one - or two -- dashes

AUTHOR
    Written by James Koval
REPORTING BUGS
    Report bugs to <jediknight304 () gmail . com>
COPYRIGHT
    Copyright 2010 James Koval
    License GPLv3+: GNU GPL version 3 or later
    <http://gnu.org/licenses/gpl.html>
    This is free software; you are free to change and redistribute it
    There is NO WARRANTY, to the extent permitted by law
EOF
exit 0;
}
if ($version) {
	print "$0 1.0 alpha\n";
	exit 0;
}
#bounds checks
$cards   = $defaultcards   if($cards   <1 or $cards   > 81);
$rows = $defaultrows if($rows <1 or $rows > 21);


#constant list of values for cards 
my @shape = qw(tria     rect   oval   );
my @fill  = qw(`        +      @      );
my @color = qw(magenta  green  yellow );
my @number= qw(1        2      3      );
#all supported colors: black red green yellow blue magenta cyan white

#keep these an odd number across
my @rect = qw(
 _____
|@@@@@|
|@@@@@|
|@@@@@|
-------);
my @tria = qw(
   _
  /@\\  
 /@@@\\ 
/@@@@@\\
-------);
my @oval = qw(
  ___  
 /@@@\\ 
\(@@@@@\)
 \\@@@/ 
  ---  );
my @form;#shape used for the next card printed

my $cardwidth=0;
#Find maximum card width
$cardwidth = $cardwidth > length $_ ? $cardwidth : length $_ for(@rect);
$cardwidth = $cardwidth > length $_ ? $cardwidth : length $_ for(@tria);
$cardwidth = $cardwidth > length $_ ? $cardwidth : length $_ for(@oval);

#scalers to temporarily hold values during operations
#parallel arrays to hold deck
#extra set of parallel arrays to hold cards in play (suffix p)
#extra set of parallel arrays to hold cards in graveyard (suffix g)
my $s; my @s; my @sp; my @sg;#shape
my $f; my @f; my @fp; my @fg;#fill
my $c; my @c; my @cp; my @cg;#color
my $n; my @n; my @np; my @ng;#number

#pseudo-parallel array remembers who found a set
#indexes into graveyard by x3 because it remembers who found a set
# not individual cards, and sets are always groups of 3 cards
my @points;

#game loop
init;#gen deck
while(1){
printcards;#show playing field
menu;#show menu and quit if q
}

sub printcards{
	my $row=$rows;#fluxuates when fewer cards need to be printed
	my $cardstoprint = @sp;
	while($cardstoprint){
		$row=$cardstoprint if($cardstoprint < $row);
		
		for my $i (0..$#form){#cycle each line in ascii shape
			for(0..$row-1){#cycle rows
				mold $sp[$_];#make @form a specific shape
				shade $fp[$_];#make @form a specific fill
				colorize $cp[$_];#ready output for a color
				my $spaces = " "x(($cardwidth-length $form[$i])/2);
				my $line = $spaces.$form[$i].$spaces;#center and space the shapes out
				$line x= $np[$_];#put the right number of shapes on a line

				#show card's variable values beside card
				print "$sp[$_] $fp[$_] $cp[$_] $np[$_]" if $debug;
				
				my $color1 = "";my $color2 = "";#require larger scope for space calculation
				#display numbers on cards
				if($i==$#form/2 and $numbers){
				#grab the first half of the middle line in a card
				#  and combine it with the card's number plus
				#  the second half missing whatever is necessary
				#  to fit the number. i.e. missing 1 character for <10
				#  2 characters for >=10 <100 because 10 is 2 characters
					my $cardnumber = @cp-$cardstoprint;
					my $half1 = substr($line,0,length($line)/2);
					my $half2 = substr($line,length($line)/2+length ($cardnumber));
					$color1 = color $color[ $cp[$_]+1 > $#color ? 0 : $cp[$_]+1];
					$color2 = color $color[$cp[$_]];
					$line = $half1.$color1.$cardnumber.$color2.$half2;
					$cardstoprint--;
				}
				
				#each new card that is printed, decrements cards needed to print
				$cardstoprint-- if($i==0 and !$numbers);

				#print card with enough spacing to fit the maximum number of shapes
				#and center card in place
				$spaces = $cardwidth*max(@number)-length($line)+length($color1)+length($color2);
				print " "x($spaces/2).$line." "x($spaces/2+($spaces%2 ? 1:0))." ";
			}
		print color 'clear';
		print "\n";
		}

		#put cards on the other end of the array after being printed
		for(1..$row){
			push @sp, shift @sp;
			push @fp, shift @fp;
			push @cp, shift @cp;
			push @np, shift @np;
		}
	}
	if($debug){
		print "Cards In Play:\n";
		print $_." "x(3- length $_) ." $sp[$_] $fp[$_] $cp[$_] $np[$_]\n" for(0..$#sp);
	}
}

sub pick{
	#indexes into the cards in play parallel arrays i.e. @sp
	my $card1 = shift;
	my $card2 = shift;
	my $card3 = shift;
	#name of player who found set
	my $name = shift; push @points, $name;
	#remove card from play and put in graveyard
	push @sg, $sp[$card1];splice @sp, $card1, 1;
	push @fg, $fp[$card1];splice @fp, $card1, 1;
	push @cg, $cp[$card1];splice @cp, $card1, 1;
	push @ng, $np[$card1];splice @np, $card1, 1;
	push @sg, $sp[$card2];splice @sp, $card2, 1;
	push @fg, $fp[$card2];splice @fp, $card2, 1;
	push @cg, $cp[$card2];splice @cp, $card2, 1;
	push @ng, $np[$card2];splice @np, $card2, 1;
	push @sg, $sp[$card3];splice @sp, $card3, 1;
	push @fg, $fp[$card3];splice @fp, $card3, 1;
	push @cg, $cp[$card3];splice @cp, $card3, 1;
	push @ng, $np[$card3];splice @np, $card3, 1;
	draw;
}

sub redraw{
	for(0..$#sp){
		if(not scalar @sp){
			return 0;
		}
		push @sg, pop @sp;
		push @fg, pop @fp;
		push @cg, pop @cp;
		push @ng, pop @np;
	}
	draw;
}

sub draw{
	for(1..($cards-@sp)){
		if(not scalar @s){
			return 0;
		}
		push @sp, pop @s;
		push @fp, pop @f;
		push @cp, pop @c;
		push @np, pop @n;
	}
	if($debug){
		print "Cards In Play:\n";
		print $_." "x (3- length $_) ." $sp[$_] $fp[$_] $cp[$_] $np[$_]\n" for(0..$#sp);
	}
}

sub init{
	@form = @rect;#init @form for for-loops that use a standard shape's array length
	#reset arrays
	undef @s;undef @f;undef @c;undef @n;
	undef @sp;undef @fp;undef @cp;undef @np;

	#populate deck with non-repeating cards
	for $s(0..$#shape){for $f(0..$#fill){for $c(0..$#color){for $n(0..$#number){
		push @s, $s;
		push @f, $f;
		push @c, $c;
		push @n, $number[$n];#save actual number rather than index
	}}}}
	if($debug){
		print "Deck:\n";
		print $_." "x(3- length $_) . " $s[$_] $f[$_] $c[$_] $n[$_]\n" for(0..$#s);
	}
	
	#shuffle deck
	#idea from http://stackoverflow.com/users/13/chris-jester-young
	my @order = shuffle 0..$#c;
	@s = @s[@order];
	@f = @f[@order];
	@c = @c[@order];
	@n = @n[@order];

	if($debug){
		print "Shuffled Deck:\n";
		print $_." "x(3- length $_) ." $s[$_] $f[$_] $c[$_] $n[$_]\n" for(0..$#s);
	}

	
	#draw cards to be in play
	for(1..$cards){
		push @sp, pop @s;
		push @fp, pop @f;
		push @cp, pop @c;
		push @np, pop @n;
	}
	if($debug){
		print "Cards In Play:\n";
		print $_." "x (3- length $_) ." $sp[$_] $fp[$_] $cp[$_] $np[$_]\n" for(0..$#sp);
	}
}

sub menu{
	print "(q)uit (p)ick: ";
	my $tmp = <>;
	exit 0 if $tmp =~ /[qQ]/;
	if ($tmp =~ /[pP]/){
		print "Enter player: " ;
		my $name = <>;
		print "Enter first card: ";
		my $card1 = <>;
		print "Enter second card: ";
		my $card2 = <>;
		print "Enter third card: ";
		my $card3 = <>;
		pick($card1, $card2, $card3, $name);
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

#number doesn't need a function, for it is saved directly in the array
