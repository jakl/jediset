#!/usr/bin/perl -w
use strict;
use Curses;
initscr;
keypad 1;#arrow keys and F5-F12 ->`eq KEY_F 5`; why not F1-F4?
cbreak;#grab all but ctrl+* ; use raw for ALL
noecho;#don't echo characters
my $x;my $y;
getmaxyx $y, $x;

#Notes:
#refresh to show text without a `getch` which auto refreshes
#sleep 5;#will remember keyboard input characters for a later getch

####BOLD INPUT####
printw "Type a char and see it bold!";
my $ch = getch;

my $fkey;
for (1..12){
  if($ch eq KEY_F $_){
    printw "\nF$_";
    $fkey = 1;
  }
}

unless ($fkey){
  printw "\n";
  attron A_BOLD;
  printw $ch;
  attroff A_BOLD;
}
####BOLD INPUT END####

####SCREEN SIZE####
addstr $y/2, ($x - length $ch)/2, $ch;
addstr $y-2,0,"X: $x  and  Y: $y";
####SCREEN SIZE END####

#####getstr####
my $str;
addstr $y/2+1, 0,'Enter a string';
getstr $str;
addstr $y-4, 0, "You entered: $str";
#####getstr END####

####COLORS####
#0-7 Black Red Green Yellow Blue Magenta Cyan White
start_color;
use_default_colors;
init_pair 1,COLOR_BLUE,-1;
my $count = 2;
attron COLOR_PAIR 1;
addstr $count,$x/2,'LET THERE BE COLOR';
#attroff COLOR_PAIR 1;
$count++;
$count++;

attron A_UNDERLINE;
addstr $count,$x/2,'LET THERE BE underline';
attroff A_UNDERLINE;
$count++;
$count++;

attron A_STANDOUT;
addstr $count,$x/2,'LET THERE BE standout';
attroff A_STANDOUT;
$count++;
$count++;

attron A_BOLD;
addstr $count,$x/2,'LET THERE BE bold';
attroff A_BOLD;
$count++;
$count++;

attron A_BOLD;
attron A_STANDOUT;
addstr $count,$x/2,'LET THERE BE standout bold';
attroff A_BOLD;
attroff A_STANDOUT;
$count++;
$count++;
####COLORS END####

getch;
endwin;
