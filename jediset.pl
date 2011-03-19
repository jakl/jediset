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
along with Jedi Set. If not, see <http://www.gnu.org/licenses/gpl.html>
=cut
use strict; use warnings;
use Getopt::Long;
use Term::ANSIColor;
use List::Util qw(shuffle max);
use subs qw(init initweb shade colorize mold allequal allunequal
debugplay debugdeck
printcards printscores help menu pick set draw choose
listsets countsets redraw menuhelp
);

my $defaultrows = 3;
my $rows = $defaultrows;#Number of rows across the screen
my $defaultcards = 12;
my $cards = $defaultcards;#Number of cards in a board
my $debug=0;#show debug info, shows more with higher numbers
my $version; my $help;#boolean to show version or help
my $match=1;
my $web;#turn on cgi/html compatable output
my $listsets;#lists all sets in play
my $atleast=0;#first board will have at least this many sets in it

GetOptions('debug+' => \$debug,'match!' => \$match, 'listsets' => \$listsets,
  'cards=i' => \$cards, 'rows=i' => \$rows, 'atleast=i' => \$atleast,
  'version' => \$version, 'help' => \$help, 'web' => \$web);

if($help){
  help;
  exit 0;
}
if($version){
  print "$0 2\n";
  exit 0;
}
initweb if $web;

#bounds checks
$cards = $defaultcards if $cards <1 or $cards > 81;
$rows = $defaultrows if $rows <1;
$atleast = 0 if $atleast>11;

#constant list of values for cards 
my @shape = qw(tria     rect   oval   );
my @fill  = qw(`        +      @      );
my @color = qw(magenta  green  yellow );
my @number= qw(1        2      3      );
#supported colors: black red green yellow blue magenta cyan white

#keep heights the same when modifying shapes
my @rect = qw(
______
|@@@@@@|
|@@@@@@|
|@@@@@@|
------);
my @tria = qw(
_
/@\\  
/@@@\\ 
/@@@@@\\
-------);
my @oval = qw(
__  
/@@\\ 
{@@@@}
\\@@/ 
--);

my @form;#shape used for the next card printed

my $cardwidth=0;
#Find maximum card width
$cardwidth = $cardwidth > length $_ ? $cardwidth : length $_ for(@rect);
$cardwidth = $cardwidth > length $_ ? $cardwidth : length $_ for(@tria);
$cardwidth = $cardwidth > length $_ ? $cardwidth : length $_ for(@oval);

my $cardheight=0;
#Find maximum card width
$cardheight = $cardheight > @rect ? $cardheight : @rect;
$cardheight = $cardheight > @tria ? $cardheight : @tria;
$cardheight = $cardheight > @oval ? $cardheight : @oval;

#shape,fill,color,number Parallel Arrays for game data
#sfcn: parallel arrays to hold deck
#sp fp cp np: parallel arrays to hold cards in play (suffix p)
#sg fg cg ng: parallel arrays to hold cards in graveyard (suffix g)
my @s; my @sp; my @sg;#shape
my @f; my @fp; my @fg;#fill
my @c; my @cp; my @cg;#color
my @n; my @np; my @ng;#number



my %scores;#Track points per player. Player names are keys to their points
my %lookup;#hash lookup uses sfcn as the key to see if card is in play
my $game;#game counter tracks how many games have been played

#game loop
init;
while(1){
  while(countsets() <$atleast){
	# redraw new boards until there are at least so many sets (user defined, default 0)
	# if redrawing is impossible, reinitialize the deck
    init if not redraw;#redraw is false if there are no cards to draw
  }#look for at least $atleast sets
  printcards;#show playing field
  print listsets if $listsets;#show all current sets on the board (CHEATING)
  last if $web;#The web port doesn't support input - end before showing the input menu
  menu;#show menu and handle input
}

#Display the game menu and process input
sub menu{
  print "(q)uit (p)ick (d)raw (s)core (r)ows (n)ew (l)istsets (a)tleast: ";
  chomp (my $tmp = <>);
  exit 0 if $tmp =~ /^q/i;#quit, case (i)nsensitive
  init if $tmp =~ /^n/i;
  if($tmp =~ /^p|^(\d+)\s*(\d*)\s*(\d*)/i){#pick
    my $card1=$1;my $card2=$2;my $card3=$3;my $name;
    while($card1 eq '' or $card1=~/\D/ or $card1>$#sp){
    #while it has no digits, or it has non-digits, or it is not on the board
      print "Enter 1st card: ";
      chomp ($card1 = <>);
    }
    while($card2 eq '' or $card2=~/\D/ or $card2>$#sp or $card2 == $card1){
      print "Enter 2nd card: ";
      chomp ($card2 = <>);
    }
    while($card3 eq '' or $card3=~/\D/ or $card3>$#sp or $card3 == $card2 or $card3 == $card1){
      print "Enter 3rd card: ";
      chomp ($card3 = <>);
    }
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
  if($tmp =~ /^r/i){#rows
    my $userrows;
    do{
      print "Enter rows: ";
      chomp ($userrows = <>);
    }while($userrows =~/\D/ or $userrows < 1);
    $rows = $userrows;
  }
  draw if $tmp =~ /^d/i;#add a card
  printscores if $tmp =~ /^s/i;#scores
  menuhelp if $tmp =~ /^h/i;#help
  print listsets if $tmp =~ /^l/i;#listsets
  if($tmp =~ /^a/i){#atleast this many sets are always on the board
    do{
      chomp($atleast=<>);
    }while($atleast eq '' or $atleast=~/\D/ or $atleast>11);
  }
}

#Search the board for sets and return them
sub listsets{
  #%lookup might be used here to lower the big O notation of this algorithm, but it adds
  #quite a number of steps in other places, and is probably not worth the added
  #complexity and increase in big O notation in other places
  my $return = '';
  for my $i (0..$#sp){
    for my $j ($i+1..$#sp){
      for my $k ($j+1..$#sp){
        $return .= "$i $j $k\n" if set $i, $j, $k;
      }
    }
  }
  return $return;
}

#Count the number of sets returned by listsets
sub countsets{
  my $sets = listsets;
  my $count = 0;
  $count++ while $sets =~ /\n/g;
  return $count;
}

#Process selecting a 3 card set from the current game board
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

#Parameters are indexes into in-play arrays: @sp, @fp, $cp, @np ;
# checks for valid set among those 3 cards
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

#Initialize all game variables, mainly cards in play and in the deck
sub init{
  $game++;
  print "Game $game\n";
#init @form for for-loops that use a standard shape's array length
  @form = @rect;
#reset arrays
  undef @s;undef @f;undef @c;undef @n;
  undef @sp;undef @fp;undef @cp;undef @np;
  undef @sg;undef @fg;undef @cg;undef @ng;

#populate deck with non-repeating cards
  for my $s(0..$#shape){for my $f(0..$#fill){for my $c(0..$#color){for my $n(0..$#number){
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

#Initialize web specific variables, and ready the output for CGI compatability
#Accept GET parameters in place of command line options
sub initweb{
  #init CGI; and yes the \n\n is required
  print "Content-type: text/html\n\n";

  #setup jediset html stuff; its one-line-ugly because multiline affects page
  print '<title>JediSet</title><head><style type="text/css"> .bg { color: #00FF00; background: black; } </style></head><body class=bg><a href="http://github.com/jediknight304/jediset">JediSet Source at GitHub.com/Jediknight304</a><br />';
  print "<pre>";

  #grab GET parameters from URL
  my $buffer;my $name;my $value;my %FORM;
  #read in text
  $ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;#upper case?
  $buffer = $ENV{'QUERY_STRING'} if ($ENV{'REQUEST_METHOD'} eq "GET");
  #split info into name/value pairs
  foreach my $pair (split(/&/, $buffer)){
    ($name, $value) = split(/=/,$pair);
    $value =~ tr/+/ /;
    $value =~ s/%(..)/pack("C", hex($1))/eg;
    $FORM{$name} = $value;
  }
  $rows = $FORM{rows} if $FORM{rows};
  $cards = $FORM{cards} if $FORM{cards};
  $debug = $FORM{debug} if $FORM{debug};
  $version = $FORM{version} if $FORM{version};
  $help = $FORM{help} if $FORM{help};
  $listsets = $FORM{listsets} if $FORM{listsets};
  $atleast = $FORM{atleast} if $FORM{atleast};

  #tell people about the GET options
  unless (keys %FORM){
    print <<EOF;
If looks like you aren't using any options, but options are kool
After your url which should end in .pl type a ? then any or all of these things
rows=7     or any number of columns you want besides 7
cards=81   81 is the maximum; more defaults back to 81
debug=4    numbers less than 4 will show less debug information
version=1  this is 1 or 0, and will show the current version of the program
help=1     this is also 1 or 0, and will show you a terminal manual page
listsets=1 show all sets (CHEATER)
atleast=11 show boards that always contain at least 11 sets, the max
If you want to use more than one option, seperate them with &
like this: URL_YADA_YADA.pl?rows=7&cards=25&debug=2
EOF
  }
}

#args are indexes into in-play arrays
#cards are copied to the graveyard,
#overwritten with a newly drawn card if total cards are below the $cards limit
#or just deleted if there exists added cards on the board
sub choose{
  @_ = sort {$b <=> $a} @_;#must be sorted in backwards order to avoid index shifting from early deletions
  for (@_){
    undef $lookup{$sp[$_].$fp[$_].$cp[$_].$np[$_]};
    push @sg, $sp[$_];
    push @fg, $fp[$_];
    push @cg, $cp[$_];
    push @ng, $np[$_];

    #splice away cards if they were added or if there aren't new cards to draw
    if(@sp>$cards or not @s){
      splice @sp, $_, 1;
      splice @fp, $_, 1;
      splice @cp, $_, 1;
      splice @np, $_, 1;
    }
    return 0 if not scalar @s;#can't draw if deck is empty

    #as long as its possible to draw, overwrite chosen cards with drawn
    if(@sp<=$cards){
      $sp[$_] = pop @s;
      $fp[$_] = pop @f;
      $cp[$_] = pop @c;
      $np[$_] = pop @n;
      $lookup{$sp[$_].$fp[$_].$cp[$_].$np[$_]} = $_;
    }
  }
}

#take a card from end of deck, and put onto the end of cards in play
#return false if deck is empty
sub draw{
  return 0 if not scalar @s;#can't draw if deck is empty
  my $s = pop @s;
  my $f = pop @f;
  my $c = pop @c;
  my $n = pop @n;
  push @sp, $s;
  push @fp, $f;
  push @cp, $c;
  push @np, $n;
  $lookup{$s.$f.$c.$n} = $#sp;
}

#Remove a card just drawn and replace it with a newly drawn card
sub redraw{
  shift @sp; shift @fp; shift @cp; shift @np;
  return draw;
}

sub printscores{
  print $_.": ".$scores{$_}."   " for(keys %scores);
  print "\n";
}

#Print the current deck
sub debugdeck{
  print "Deck:\n";
  print $_." "x(3- length $_) ." $s[$_] $f[$_] $c[$_] $n[$_]\n" for(0..$#s);
}

#Print the current cards in play, formatted as debug information
sub debugplay{
  print "Play:\n";
  print $_." "x (3- length $_) ." $sp[$_] $fp[$_] $cp[$_] $np[$_]\n" for(0..$#sp);
}

#Print the game board as ASCII art
sub printcards{
  my $row=$rows;#fluxuates when fewer cards need to be printed
  my $cardstoprint = @sp;
  while($cardstoprint){
    $row=$cardstoprint if $cardstoprint < $row;

    for my $i (0..$#form){#cycle each line in ascii shape
      for(0..$row-1){#cycle rows
        mold $sp[$_];#make @form a specific shape
        shade $fp[$_];#make @form a specific fill
        print colorize $cp[$_];#ready output for a color
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
          my $half1 = substr($line,0,length($line)/2); #left
          my $half2 = substr($line,length($line)/2+length ($cardnumber)); #right
          $color1 = colorize $cp[$_]+1 > $#color ? 0 : $cp[$_]+1;
          $color2 = colorize $cp[$_];
          $line = $half1.$color1.$cardnumber.$color2.$half2;
#each new card that is printed, decrements cards needed to print
          $cardstoprint--;
        }

#print card with enough spacing to fit the maximum number of shapes
#and center card in place
        $spaces = $cardwidth*max(@number)-length($line)+length($color1)+length($color2);
        my $space1 = " "x($spaces/2);#left
        my $space2 = " "x($spaces/2+($spaces%2 ? 1:0));#right
        print $space1.$line.$space2;
        print ' ' unless $_ == $rows-1;
      }
      print color 'clear' unless $web;
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
  @form = @tria if $shape[$s] eq 'tria';
  @form = @rect if $shape[$s] eq 'rect';
  @form = @oval if $shape[$s] eq 'oval';
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
  return color "bold $color[$c]" unless $web;
  return "<span style='color: $color[$c]'>" if $web;
}

#number doesn't need a function, for it is saved directly in the array
#therefore this doesn't exist: sub number{}

#Print the help screen for the in-game menu
sub menuhelp{
  print <<EOF;
q  Quit immediately
p  Allows you to select, by card number, 3 different cards that make a set
d  Draw one extra card if you determine no sets are in play
s  Show all players' scores
r  Set the number of columns you can safely fit in your terminal
n  Immediately start a new game, erasing all scores
l  List all sets in play, by listing their indexes
a  Guarantee that at least so many sets are always in play. You can specify!
EOF
}

#Print the general help for the entire program
sub help{
  print <<EOF;
NAME
  The Game of Jedi Set: a pattern matching terminal card game

USAGE
  $0 [ --help|--version|--debug|--rows=<int>|--match|--listsets|
                         --cards=<int>|--web|--atleast ]

DESCRIPTION
  See <http://en.wikipedia.org/wiki/Set_(game)>

OPTIONS
  --help     -h   : This help message

  --rows     -r   : Specify the number of rows that will fit on your screen
                    Vertical rows (aka: columns)
                    Range: >0  else it defaults to $defaultrows
  --cards    -c   : Specify the number of cards to play with each round
                    Range: 1 through 81  else it defaults to $defaultcards
  --listsets -l   : Always list valid sets (cheater)

  --atleast  -a   : Boards will contain at least this many sets
                    Range: <12  else it defaults to 0
  --version  -v   : Print version on standard output and exit

  --debug    -d   : Enable (likely useless) debuging output data 
                    Use this option multiple times for more verbosity
                    The data will be of the form: int   int  int   int
                                                  shape fill color number
                    shape, fill, and color are indexes:   values 0 through 2
                    number is saved directly:             values 1 through 3
                    Note: Look at the code to see the meanings of indexes
  --no-match -nom : Deactivate player name matching (see README-Match)

  --web      -w   : Format output for cgi html; This is not ment for a terminal

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
