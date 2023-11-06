#!/usr/bin/perl

use strict;
use warnings;
use Storable qw/freeze/;
# $| = 1; # refresh early

use Term::ReadKey;
my($termCharWidthX, $termCharHeightY, $wpixels, $hpixels) = GetTerminalSize();


### SETTINGS ###
my $debug = 0;

# default Convay's Life
my $birth   = 3;  #   birth on neighbor count <content>
my $survive = 23; # survive on neighbor count <content>

# life and dead cell indicators (must match input file content)
my $life = "*";
my $dead = " ";
my $trace_dead = " ";


### VARIABLES ###
my $randLifeRatio = 0.25;
my $updateTime = 0.1;

my $maxX;
my $maxY;

my @screen;
my @newScreen;


### SUBROUTINES ###
# Reads a file with a given name and returns its content as a chomped array.
#   Dies if file is not readable!
sub ReadFile {
    my $FileName = shift @_;

    open FH_File, '<', $FileName or die "$!\n";
    my @File = <FH_File>;
    close FH_File;
    chomp @File;

    return @File;
}


# Writes the array content to a file with a given name.
#   Appends .out to the file name if $debug is TRUE.
#   Dies if file is not writeable!
sub WriteFile {
    my $FileName        = shift @_;
    my $refContentArray = shift @_;

    $FileName =~ s/$/.out/i if ($debug);

    open FH_File, '>', $FileName or die "$!\n";
    foreach (@$refContentArray) {
        print FH_File "$_\n";
    }
    close FH_File;
}


sub PrintHelpAndExit {
    print "\n";
    print "Usage: perl GoL.pl [arguments]\n";
    print "\n";
    print "-h, --help:\n";
    print "        Prints this help and exits.\n";
    print "\n";
    print "-f<file>, --file=<file>\n";
    print "        <file> is a path to a file containing the seed to start with.\n";
    print "        Use '$life' for life cells and '$dead' for dead cells.\n";
    print "        Must have the same number of columns in all lines.\n";
    print "        Should match your terminal layout minus one row.\n";
    print "        If omitted a random seed will be used.\n";
    print "\n";
    print "-r<rand>, --random=<rand>:\n";
    print "        <rand> is a float between 0.0 and 1.0 to determine how much life cells\n";
    print "        per dead cells a random seed shoud generate.\n";
    print "        The default is -r0.25 and means one in four cells will be life.\n";
    print "\n";
    print "-[b|B]<birth>, --birth=<birth>, -[s|S]<survive>, --survive=<survive>:\n";
    print "        <birth> and <survive> are strings of digits 0-8 containing\n";
    print "        birth and survive conditions.\n";
    print "        You may join both with or without /, e.g. -S123B456 or -b123/s456.\n";
    print "        If omitted Conway's Life rules are used (-b3 -s23).\n";
    print "\n";
    print "-t<trace>, --trace=<trace>:\n";
    print "        <trace> is one char to trace dead cells that were once life.\n";
    print "\n";
    print "-u<time>, --updatetime=<time>:\n";
    print "        <time> is a float in seconds how fast the screen should update.\n";
    print "        Default update time is 0.1 seconds.\n";
    print "\n";
    print "Example 1: perl GoL.pl\n";
    print "Uses a random seed and Conway's Life rules.\n";
    print "\n";
    print "Example 2: perl GoL.pl -fgol_file.txt -b36s23\n";
    print "Uses gol_file.txt to read the starting seed and HighLife rules.\n";
    print "\n";
    print "Example 3: perl GoL.pl -B45678/S2345 -u1.0\n";
    print "Uses a random seed and Walled Cities rules, update screen every second.\n";
    print "\n";
    print "Example 4: perl GoL.pl -b345s4567 -t.\n";
    print "Uses a random seed, Assimilation rules and . to trace once life cells.\n";
    print "\n";
    print "Example 5: perl GoL.pl -b0123478 -s01234678 -r0.75\n";
    print "Uses a random seed with 3 life per 1 dead cell and Antilife rules.\n";
    print "\n";
    exit 1;
}


sub InitScreenFromFile {
    my $filename = shift @_;

    my @inFile = &ReadFile ($filename);

    $maxX = length($inFile[0]) - 1; # -1 because it's not chomped yet
    $maxY = @inFile;

    for (my $y = 0; $y<$maxY; $y++) {
        for (my $x = 0; $x<$maxX; $x++) {

            my $line = $inFile[ $y ];
            my @char = split('', $line);

            $screen[ $x ][ $y ] = $char[ $x ];

        }
    }

}


sub InitScreenRandom {

    $maxX = $termCharWidthX;
    $maxY = $termCharHeightY-1; # -1 because we need a line for the cursor

    for (my $y = 0; $y<$maxY; $y++) {
        for (my $x = 0; $x<$maxX; $x++) {

            $screen[ $x ][ $y ] = $dead;
            if (rand() <= $randLifeRatio) { $screen[ $x ][ $y ] = $life; }

        }
    }
}


sub InitBirthSurvive {
    my $par    = shift @_;

    foreach my $bs ("b","s") {
        my $val = $par;

        if ($val =~ m/$bs\d+/) {
            $val =~ s/.*$bs(\d+).*/$1/;
            if ($val !~ m/^[0-8]{1,9}$/) {
                print   "birth and/or survive not valid!\n";
                &PrintHelpAndExit;
            }
            if ($bs eq "b") { $birth   = $val; }
            if ($bs eq "s") { $survive = $val; }
        }
    }

}


sub ProcessArgs {
    while (defined $ARGV[0]) {
        my $arg = shift @ARGV;

        if (($arg eq "--help") or ($arg eq "-h")) {
            &PrintHelpAndExit;
        }

        if (($arg =~ m/^-f/) or ($arg =~ m/^--file=/)) {
            $arg =~ s/^(-f|--file=)//;
            &InitScreenFromFile ( $arg );
        }

        if (($arg =~ m/^-r/) or ($arg =~ m/^--random=/)) {
            $arg =~ s/^(-r|--random=)//;
            $randLifeRatio = $arg;
        }

        if (($arg =~ m/^-(b|s)/i) or ($arg =~ m/^--(birth|survive)=/)) {
            $arg =~ s/(irth|urvive)=?//g;
            &InitBirthSurvive ( lc $arg );
        }

        if (($arg =~ m/^-t/) or ($arg =~ m/^--trace=/)) {
            $arg =~ s/^(-t|--trace=)//;
            $trace_dead = $arg;
        }

        if (($arg =~ m/^-u/) or ($arg =~ m/^--updatetime=/)) {
            $arg =~ s/^(-u|--updatetime=)//;
            $updateTime = $arg;
        }
    }
    if (not defined $screen[0]) {
        &InitScreenRandom;
    }
}


sub GetScreen {
    my $x = shift @_;
    my $y = shift @_;
    if (($x) == $maxX) {$x = 0;}
    if (($y) == $maxY) {$y = 0;}
    return $screen[ $x ][ $y ];
}


sub CalcNewScreenFromScreen {
    for (my $y = 0; $y<$maxY; $y++) {
        for (my $x = 0; $x<$maxX; $x++) {

            # neighbor count
            my $neighborCount = 0;
            if ( &GetScreen ( $x-1 , $y-1 ) eq $life) { $neighborCount++; }
            if ( &GetScreen ( $x   , $y-1 ) eq $life) { $neighborCount++; }
            if ( &GetScreen ( $x+1 , $y-1 ) eq $life) { $neighborCount++; }
            if ( &GetScreen ( $x-1 , $y   ) eq $life) { $neighborCount++; }
            if ( &GetScreen ( $x+1 , $y   ) eq $life) { $neighborCount++; }
            if ( &GetScreen ( $x-1 , $y+1 ) eq $life) { $neighborCount++; }
            if ( &GetScreen ( $x   , $y+1 ) eq $life) { $neighborCount++; }
            if ( &GetScreen ( $x+1 , $y+1 ) eq $life) { $neighborCount++; }

            # calc new screen
            $newScreen[ $x ][ $y ] = $screen[ $x ][ $y ];
            if ($screen[ $x ][ $y ] eq $life) {
                foreach (0..8) {if (($neighborCount == $_) and not ($survive =~ /$_/)) { $newScreen[ $x ][ $y ] = $trace_dead; }}
            } 
            else {
                foreach (0..8) {if (($neighborCount == $_) and       ($birth =~ /$_/)) { $newScreen[ $x ][ $y ] = $life; }}
            }

        }
    }
}


sub UpdateScreen {
    print "\n";
    select undef, undef, undef, $updateTime;
}


sub PrintInitialScreen {
    for (my $y = 0; $y<$maxY; $y++) {
        for (my $x = 0; $x<$maxX; $x++) {
            print $screen[ $x ][ $y ];
        }
    }
    &UpdateScreen;
}


sub PrintNewScreen {
    for (my $y = 0; $y<$maxY; $y++) {
        for (my $x = 0; $x<$maxX; $x++) {
            print $newScreen[ $x ][ $y ];
            $screen[ $x ][ $y ] = $newScreen[ $x ][ $y ];
        }
    }
    &UpdateScreen;
}


### INIT ###
&ProcessArgs;
&PrintInitialScreen;


### MAIN ###
while (1) {

    &CalcNewScreenFromScreen;

    # if two screens in a row are equal, there will be no more progress, exit
    if (freeze(\@screen) eq freeze(\@newScreen)) {exit 1};

    &PrintNewScreen;
}

