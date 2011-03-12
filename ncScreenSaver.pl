#!/usr/bin/perl -w
use strict;
use Curses;
use POSIX;
use Time::HiRes qw(sleep);
initscr;
curs_set 0;#no cursor
keypad 1;#arrow keys and F5-F12 ->`eq KEY_F 5`; why not F1-F4?
cbreak;#grab all but ctrl+* ; use raw for ALL
noecho;#don't echo characters
my $h;my $w;#height width
getmaxyx $h, $w;
my $str;#use this for output, and length $str for centering

use subs qw(cwin);
my $wfat = 10;my $wtall = 10;
my $x = $w/2; my $y = $h/2;
my $win = cwin;
my $ch;
my $speed = 1;
my $isEraser = 0;

addstr 0,0,'F5 is exit';
addstr 1,0,'a/s=shrink d/f=grow q/w/e=speed arrowKeys=movement';
addstr 2,0,'x y        y x      - + 0  <-- What controls effect';
while (1){
  #sleep .001;
  getmaxyx $h, $w;
#addstr 0,0,'F5 is exit';
  #addstr 1,0,'a/s=shrink d/f=grow q/w/e=speed arrowKeys=movement';
  #addstr 2,0,'x y        y x      - + 0  <-- What controls effect';
  #addstr $h/2, $w/2, $ch;
  $str = "Width: $w   Height: $h";
  addstr $h/2+1, $w/2-(length $str)/2,$str;

  my $randAction = floor rand 16;

  $win = move $win, 0,-$speed if $randAction == 0 or $randAction == 1;
  $win = move $win, 0, $speed if $randAction == 2 or $randAction == 3;
  $win = move $win,-$speed, 0 if $randAction == 4 or $randAction == 5;
  $win = move $win, $speed, 0 if $randAction == 6 or $randAction == 7;
#  $speed++ if $ch eq 'w';
#  $speed-- if $ch eq 'q';
#  $speed=0 if $ch eq 'e';
  $wfat++ if $randAction == 8;
  $wfat-- if $randAction == 9 or $randAction == 10;
  $wtall++ if $randAction == 11;
  $wtall-- if $randAction == 12 or $randAction == 13;

  $isEraser = not $isEraser if 1 == floor rand 200;

  $win = move $win,0,0;
}
endwin;

sub cwin{
  $wfat = 1 if $wfat < 1;
  $wtall= 1 if $wtall < 1;
  $wfat = $w if $wfat >$w;
  $wtall= $h if $wtall > $h;
  $x = 0 if $x < 0;
  $y = 0 if $y < 0;
  $x = $w-$wfat if $x+$wfat > $w;
  $y = $h-$wtall if $y+$wtall > $h;
  my $win = newwin $wtall, $wfat, $y, $x;
  box $win, '|', '_';
  refresh $win unless $isEraser;
  return $win;
}

sub dwin {
  my $win = shift;
  border $win, ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ';
  refresh $win if $isEraser;
  delwin $win;
}

sub move{
  dwin shift;
  $y += shift;
  $x += shift;
  return cwin;
}
