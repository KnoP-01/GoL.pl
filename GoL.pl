#!/usr/bin/perl

use strict;
use warnings;
# $| = 1; # refresh early


my $debug = 0;


my @screen;
my @screenNew;


my $waitTime = 0.1;
my $randRatio = 5;


# live and dead cell indicators (must match input file content)
my $live = "0";
my $dead = " ";


# grid dimension (must match input file size)
my $maxY = 50;
my $maxX = 180;


my $b; # birth on neighbor count <content>
my $s; # survive on neighbor count <content>

# convay life
$b  = '3';
$s  = '23';

# highlife
# $b  = '36';
# $s  = '23';

# cities
# $b  = '45678';
# $s  = '2345';



sub getNeighbor {
    my $x = $_[0];
    my $y = $_[1];
    if (($x) == $maxX) {$x = 0;}
    if (($y) == $maxY) {$y = 0;}

    return $screen[ $x ][ $y ];
}


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
    my $FileName = shift @_;
    my $refContentArray  = shift @_;

    $FileName =~ s/$/.out/i if ($debug);

    open FH_File, '>', $FileName or die "$!";
    foreach (@$refContentArray) {
        print FH_File "$_\n";
    }
    close FH_File;
}



if ($ARGV[0] eq undef) {
    # initialize screen with random values
    for (my $y = 0; $y<$maxY; $y++) {
        for (my $x = 0; $x<$maxX; $x++) {
            $screen[ $x ][ $y ] = $dead;
            if (int(rand($randRatio)) == 1) { $screen[ $x ][ $y ] = $live; }
            print $screen[ $x ][ $y ];
        }
    }
} else {
    # initialize screen with file content
    my @inFile = &ReadFile ($ARGV[0]);
    for (my $y = 0; $y<$maxY; $y++) {
        my $line = $inFile[ $y ];
        for (my $x = 0; $x<$maxX; $x++) {
            my @char = split('', $line);
            $screen[ $x ][ $y ] = $char[ $x ];
            print $screen[ $x ][ $y ];
        }
    }
}

while (1) {

    print "\n";
    select undef, undef, undef, $waitTime;

    for (my $y = 0; $y<$maxY; $y++) {
        for (my $x = 0; $x<$maxX; $x++) {

            # neighbor count
            my $neighborCount = 0;
            if (&getNeighbor($x-1,$y-1)  eq $live) {$neighborCount++;}
            if (&getNeighbor($x  ,$y-1)  eq $live) {$neighborCount++;}
            if (&getNeighbor($x+1,$y-1)  eq $live) {$neighborCount++;}
            if (&getNeighbor($x-1,$y  )  eq $live) {$neighborCount++;}
            if (&getNeighbor($x+1,$y  )  eq $live) {$neighborCount++;}
            if (&getNeighbor($x-1,$y+1)  eq $live) {$neighborCount++;}
            if (&getNeighbor($x  ,$y+1)  eq $live) {$neighborCount++;}
            if (&getNeighbor($x+1,$y+1)  eq $live) {$neighborCount++;}

            # calc new screen
            $screenNew[ $x ][ $y ] = $screen[ $x ][ $y ];
            if ($screen[ $x ][ $y ] eq $live) {
                # calc survive
                foreach (0..8) {if (($neighborCount == $_) and $s !~ /$_/) { $screenNew[ $x ][ $y ] = $dead; }}
            } 
            else {
                # calc birth
                foreach (0..8) {if (($neighborCount == $_) and $b =~ /$_/) { $screenNew[ $x ][ $y ] = $live; }}
            }

        }
    }


    # print new screen
    for (my $y = 0; $y<$maxY; $y++) {
        for (my $x = 0; $x<$maxX; $x++) {
            print $screenNew[ $x ][ $y ];
            $screen[ $x ][ $y ] = $screenNew[ $x ][ $y ];
        }
    }
}

