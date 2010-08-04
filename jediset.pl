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
use subs qw(init shade colorize mold allequal allunequal);
use subs qw(debugplay debugdeck);
use subs qw(printcards printscores printhelp menu pick set draw choose);

my $defaultrows = 3;
my $rows = $defaultrows;#Number of rows across the screen
my $defaultcards = 12;
my $cards = $defaultcards;#Number of cards in a board
my $debug=0;#show debug info, shows more with higher numbers
my $version; my $help;#boolean to show version or help
my $match=1;

GetOptions('debug+' => \$debug,'match!' => \$match,
  'cards=i' => \$cards, 'rows=i' => \$rows,
  'version' => \$version, 'help' => \$help);

if($help){
  printhelp;
  exit 0;
}
if ($version) {
  print "$0 1.0\n";
  exit 0;
}

#bounds checks
$cards = $defaultcards if($cards <1 or $cards > 81);
$rows = $defaultrows if $rows <1;


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
{@@@@@}
\\@@@/ 
---);
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
my %scores;

#game loop
init;#gen deck
while(1){
  printcards;#show playing field
  menu;#show menu and handle input
}

sub menu{
  print "(q)uit (p)ick (a)dd1card (s)cores (r)ows (h)elp (n)ewgame: ";
  my $tmp = <>; chomp $tmp;
  exit 0 if $tmp =~ /^q/i;#quit, case (i)nsensitive
  init if $tmp =~ /^n/i;
  if ($tmp =~ /^p/i){#pick
    my $card1;my $card2;my $card3;my $name;
    do{
      print "Enter 1st card: ";
      chomp ($card1 = <>);
    }while($card1=~/\D/ or $card1>$#sp);
    do{
      print "Enter 2nd card: ";
      chomp ($card2 = <>);
    }while($card2=~/\D/ or $card2>$#sp or $card2 == $card1);
    do{
      print "Enter 3rd card: ";
      chomp ($card3 = <>);
    }while($card3=~/\D/ or $card3>$#sp or $card3 == $card2 or $card3 == $card1);
    unless (set $card1, $card2, $card3){
      print "Not a set\n";
      return;
    }
    #only show this message the first time
    print "Names may be the shortest unique abbreviation, or longer with the same root...\n" unless scalar keys %scores;
    print "Enter player  : ";
    chomp ($name = <>);
    pick($name, $card1, $card2, $card3);
  }
  if ($tmp =~ /^r/i){#rows
    my $userrows;
    do{
      print "Enter rows: ";
      chomp ($userrows = <>);
    }while($userrows =~/\D/ or $userrows < 1);
    $rows = $userrows;
  }
  draw if $tmp =~ /^a/i;#add1card
  printscores if $tmp =~ /^s/i;#scores
  printhelp if $tmp =~ /^h/i;#help
}

#args: name,card1,card2,card3
sub pick{
  my $name = shift;
  choose @_;

  debugplay if $debug>2;

  #discard sort {$b <=> $a} @_[0..2];
  #print 'After Discard Before Draw ' if $debug>2;
  #draw for (1..$cards-@sp);#only draw cards up to $cards, the default amount on the board
  my $found = 0;
  if($match){
    for(keys %scores){
      if($name =~ /^$_/i){#name contains key
        $scores{$name} = delete $scores{$_};
        $scores{$name}++;
        print "Matched and replaced $_\n" if $debug>1;
        $found = 1;
        last;
      }
      if(/^$name/i){#key contains name
        $scores{$_}++;
        print "Matched $_\n" if $debug>1;
        $found = 1;
        last;
      }
    }
  }
  $scores{$name}++ unless $found;
  printscores if $debug>1;
}

#takes indexes into in-play arrays: @sp, @fp, $cp, @np ; and checks for valid set
sub set{
  return 0 unless allequal @sp[@_] or allunequal @sp[@_];
  return 0 unless allequal @fp[@_] or allunequal @fp[@_];
  return 0 unless allequal @cp[@_] or allunequal @cp[@_];
  return 0 unless allequal @np[@_] or allunequal @np[@_];
  return 1;
}

#turns each argument into a hash key
#returns whether every arg was the same key
sub allequal{	return keys %{{ map {$_, 1} @_ }} == 1; }
#returns whether every argument is a unique key
sub allunequal{	return keys %{{ map {$_, 1} @_ }} == @_; }

sub init{
#init @form for for-loops that use a standard shape's array length
  @form = @rect;
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
  print 'Unshuffled ' if $debug>2;
  debugdeck if $debug>2;

#shuffle deck
#idea from http://stackoverflow.com/users/13/chris-jester-young
  my @order = shuffle 0..$#c;
  @s = @s[@order];
  @f = @f[@order];
  @c = @c[@order];
  @n = @n[@order];

  print 'Shuffled ' if $debug>2;
  debugdeck if $debug>2;

#draw cards to be in play
  draw for(1..$cards);

  debugplay if $debug>2;

  undef %scores;
}

#args are indexes into in-play arrays
#cards are copied to the graveyard,
#overwritten with a newly drawn card if total cards are below the $cards limit
#or just deleted if there exists add1card cards on the board
sub choose{
  @_ = sort {$b <=> $a} @_;
  for (@_){
    push @sg, $sp[$_];
    push @fg, $fp[$_];
    push @cg, $cp[$_];
    push @ng, $np[$_];

    return 0 if not scalar @s;#can't draw if deck is empty

    if(@sp>$cards){
      splice @sp, $_, 1;
      splice @fp, $_, 1;
      splice @cp, $_, 1;
      splice @np, $_, 1;
    }
    else{
      $sp[$_] = pop @s;
      $fp[$_] = pop @f;
      $cp[$_] = pop @c;
      $np[$_] = pop @n;
    }
  }
}

#take a card from end of deck, and put onto end of cards in play
#return false if deck is empty
sub draw{
  return 0 if not scalar @s;#can't draw if deck is empty
  push @sp, pop @s;
  push @fp, pop @f;
  push @cp, pop @c;
  push @np, pop @n;
}

sub printscores{
  print $_.": ".$scores{$_}."   " for(keys %scores);
  print "\n";
}

sub debugdeck{
  print "Deck:\n";
  print $_." "x(3- length $_) ." $s[$_] $f[$_] $c[$_] $n[$_]\n" for(0..$#s);
}

sub debugplay{
  print "Play:\n";
  print $_." "x (3- length $_) ." $sp[$_] $fp[$_] $cp[$_] $np[$_]\n" for(0..$#sp);
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
        print "$sp[$_] $fp[$_] $cp[$_] $np[$_]" if $debug>2;

#display numbers on cards
#grab the first half of the middle line in a card
#  and combine it with the card's number plus
#  the second half missing whatever is necessary
#  to fit the number. i.e. missing 1 character for <10
#  2 characters for >=10 <100 because 10 is 2 characters
        my $color1='';my $color2='';
        if($i == $#form/2){
          my $cardnumber = @cp-$cardstoprint;
          my $half1 = substr($line,0,length($line)/2);
          my $half2 = substr($line,length($line)/2+length ($cardnumber));
          $color1 = color $color[ $cp[$_]+1 > $#color ? 0 : $cp[$_]+1];
          $color2 = color $color[$cp[$_]];
          $line = $half1.$color1.$cardnumber.$color2.$half2;
#each new card that is printed, decrements cards needed to print
          $cardstoprint--;
        }

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
  debugplay if $debug>2;
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

sub printhelp{
  print <<EOF;
NAME
  The Game of Jedi Set: a pattern matching terminal card game

USAGE
  $0 [ --help|--version|--debug|--rows=<int>|--match|
                         --cards=<int> ]

DESCRIPTION
  See <http://en.wikipedia.org/wiki/Set_(game)>

OPTIONS
  --help     -h   : This help message

  --rows     -r   : Specify the number of rows that will fit on your screen
                    Vertical rows (aka: columns)
                    Range = >0  else it defaults
                    Default = $defaultrows
  --cards    -c   : Specify the number of cards to play with each round
                    Range = 1 through 81  else it defaults
                    Default = $defaultcards
  --version  -v   : Print version on standard output and exit

  --debug    -d   : Enable (likely useless) debuging output data 
                    Use this option multiple times for more verbosity
                    The data will be of the form: int   int  int   int
                                                  shape fill color number
                    shape, fill, and color are indexes:   values 0 through 2
                    number is saved directly:             values 1 through 3
                    Note: Look at the code to see the meanings of indexes
  --no-match -nom : Deactivate player name matching

Naming Players With Matching
  When picking a set, the name of a player may be the shortest unique
  abbreviation, or longer with the same root. When a previously used name could
  be considered an abbreviation/root, the previously used name is overwritten.
    Mew, and MewTwo are not valid players because Mew is an abbreviation/root
    for MewTwo. Regardless of which is used first, Mew will become MewTwo.
    MewTwo and Two are valid players. Their roots/abbreviations don't conflict.

  Option names may be shorter unique abbreviations of the full names shown above
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
}
